--@noindex
--@description Pattern manipulator utility System Patterns
--@author gaspard
--@about Pattern manipulator utility

local gpmsys_patterns = {}

gpmsys_patterns.file_list = {}
gpmsys_patterns.pianoroll = {notes = {}, range = {min = nil, max = nil}, params = {ppq = nil, bpm = nil, bpi = nil, bpl = nil, end_pos = nil}}
gpmsys_patterns.stop_play = false
gpmsys_patterns.is_playing = false
gpmsys_patterns.has_looped = false
gpmsys_patterns.paused = 1

-- Function to read a variable length number from MIDI data
local function ReadVarLen(data, pos)
    local value = 0
    repeat
        local byte = data:byte(pos)
        value = (value << 7) | (byte & 0x7F)
        pos = pos + 1
    until byte < 0x80
    return value, pos
end

function gpmsys_patterns.GetMidiInfoFromFile(filepath)
    gpmsys_patterns.pianoroll.notes = {}

    local file = io.open(filepath, "rb")
    if not file then return false end

    local data = file:read("*all")
    file:close()

    local pos = 1
    local time = 0
    local active_notes = {}
    local furthest_pos = 0

    gpmsys_patterns.pianoroll.range = {min = nil, max = nil}
    local PPQ, BPM, BPI = 0, 120, 4 -- Default values

    -- Read the header chunk
    if data:sub(1, 4) == "MThd" then
        pos = pos + 4
        local header_length = data:byte(pos) * 0x1000000 + data:byte(pos + 1) * 0x10000 + data:byte(pos + 2) * 0x100 + data:byte(pos + 3)
        pos = pos + 4
        if header_length == 6 then
            pos = pos + 4
            PPQ = data:byte(pos) * 0x100 + data:byte(pos + 1)
            pos = pos + 2
        end
    end

    -- Extract tempo and events
    while pos < #data do
        if data:sub(pos, pos + 3) == "MTrk" then
            pos = pos + 4
            local track_length = data:byte(pos) * 0x1000000 + data:byte(pos + 1) * 0x10000 + data:byte(pos + 2) * 0x100 + data:byte(pos + 3)
            pos = pos + 4
            local track_end = pos + track_length

            -- Scan through track events
            while pos < track_end do
                local delta, first_new_pos = ReadVarLen(data, pos)
                time = time + delta
                pos = first_new_pos

                local status = data:byte(pos)
                if status == 0xFF then  -- Meta event
                    local meta_type = data:byte(pos + 1)
                    local meta_length, new_pos = ReadVarLen(data, pos + 2)
                    pos = new_pos
                    local meta_data = data:sub(pos, pos + meta_length - 1)

                    -- Tempo Meta Event (0x51)
                    if meta_type == 0x51 and meta_length == 3 then
                        local b1, b2, b3 = meta_data:byte(1, 3)
                        local microseconds_per_quarter = (b1 << 16) | (b2 << 8) | b3
                        BPM = 60000000 / microseconds_per_quarter  -- Convert to BPM

                    -- Time Signature Meta Event (0x58)
                    elseif meta_type == 0x58 and meta_length >= 2 then
                        BPL = meta_data:byte(1) -- First byte is numerator (beats per measure)
                        BPI = 2 ^ meta_data:byte(2) -- Second byte is denominator as power of 2
                    end

                    pos = pos + meta_length
                elseif status >= 0x80 and status <= 0xEF then  -- Channel event
                    local pitch = data:byte(pos + 1)
                    local velocity = data:byte(pos + 2)

                    if (status >= 0x90 and status <= 0x9F) and velocity > 0 then -- Note On
                        active_notes[pitch] = time
                    elseif (status >= 0x80 and status <= 0x8F) or (status >= 0x90 and velocity == 0) then -- Note Off
                        if active_notes[pitch] then
                            local start_time = active_notes[pitch]
                            local length = time - start_time
                            if not gpmsys_patterns.pianoroll.range.min or pitch <= gpmsys_patterns.pianoroll.range.min then gpmsys_patterns.pianoroll.range.min = pitch end
                            if not gpmsys_patterns.pianoroll.range.max or pitch >= gpmsys_patterns.pianoroll.range.max then gpmsys_patterns.pianoroll.range.max = pitch end
                            table.insert(gpmsys_patterns.pianoroll.notes, {pitch = pitch, velocity = velocity, start = start_time, length = length})
                            if start_time + length > furthest_pos then furthest_pos = start_time + length end
                            active_notes[pitch] = nil
                        end
                    end
                    pos = pos + 3
                else
                    pos = pos + 1
                end
            end
        else
            pos = pos + 1
        end
    end

    gpmsys_patterns.pianoroll.params.ppq = PPQ
    gpmsys_patterns.pianoroll.params.bpm = BPM
    gpmsys_patterns.pianoroll.params.bpi = BPI
    gpmsys_patterns.pianoroll.params.bpl = BPL
    gpmsys_patterns.pianoroll.params.end_pos = furthest_pos

    return true
end

-- Create presets directory if not exist
local function CreateDirectoryIfNotExists(path)
    local attr = reaper.EnumerateFiles(path, 0)
    if not attr then
        reaper.RecursiveCreateDirectory(path, 0)
    end
end

local function SortByName(t)
    table.sort(t, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    return t
end

function gpmsys_patterns.ScanPatternFiles()
    gpmsys_patterns.file_list = {}
    local files = {}

    for i = 1, #Settings.pattern_folder_paths.list do
        local index = 0
        local pattern = Settings.pattern_folder_paths.list[i].path
        CreateDirectoryIfNotExists(pattern)
        local file = reaper.EnumerateFiles(pattern, index)

        while file do
            if file:match('%.MID$') or file:match('%.mid$') then
                local name = file:gsub('%.MID$', '')
                name = file:gsub('%.mid$', '')
                table.insert(files, {path = pattern..'/'..file, name = name, selected = false})
            end
            index = index + 1
            file = reaper.EnumerateFiles(pattern, index)
        end
    end

    gpmsys_patterns.file_list = SortByName(files)
end

--[[local function PlayNotesLive()
    local track = gpmsys.midi_track
    local notes = gpmsys_patterns.pianoroll.notes
    local interval_sec = 0.5
    local velocity = 100
    local length_ppq = gpmsys_patterns.pianoroll.params.ppq

    local i, t0 = 1, reaper.time_precise()
    interval_sec = interval_sec or 0.5
    velocity = velocity or 100
    length_ppq = length_ppq or 480

    local function play()
        if i > #notes then return end
        if reaper.time_precise() - t0 >= (i - 1) * interval_sec then
            reaper.StuffMIDIMessage(0, 0x90, notes[i].pitch, velocity) -- Note On (MIDI note, Vel 100)
            i = i + 1
        end
        if i <= #notes then reaper.defer(play) end
    end

    play()
end]]

function gpmsys_patterns.PlayMidiPattern()
    -- Create groups of notes using start position
    local times = {}
    local group_list = {}
    local group_index = 1
    local note_index = 1
    local prev_note = nil

    for i, note in ipairs(gpmsys_patterns.pianoroll.notes) do
        prev_note = prev_note and prev_note or note

        if note.start ~= prev_note.start then
            group_index = group_index + 1
            group_list[group_index] = {}
            note_index = 1
            times[group_index] = {start = note.start, index = group_index}
        end

        if i == 1 then
            group_list[group_index] = {}
            times[group_index] = {start = note.start, index = group_index}
        end

        group_list[group_index][note_index] = note

        note_index = note_index + 1

        prev_note = note
    end

    local function SortOnValue(t,...)
        local a = {...}
        table.sort(t, function (u,v)
            for i in pairs(a) do
                if u[a[i]] > v[a[i]] then return false end
                if u[a[i]] < v[a[i]] then return true end
            end
            return false
        end)
    end

    SortOnValue(times, "start")

    -- Play groups of notes
    gpmsys_patterns.timeline = 0
    group_index = 1

    local function stop(note)
        if gpmsys_patterns.timeline >= gpmsys_patterns.pianoroll.params.end_pos then
            reaper.StuffMIDIMessage(0, 0x80, note.pitch, 0)
        end

        local note_end = note.start + note.length
        if note_end <= gpmsys_patterns.timeline then
            reaper.StuffMIDIMessage(0, 0x80, note.pitch, 0)
        else
            if not gpmsys_patterns.stop_play and gpmsys_patterns.is_playing and not gpmsys_patterns.has_looped then
                reaper.defer(function() stop(note) end)
            else
                reaper.StuffMIDIMessage(0, 0x80, note.pitch, 0)
            end
        end
    end

    local function play()
        local bpm = reaper.Master_GetTempo()
        local speed = math.floor(bpm / 60 * gpmsys_patterns.pianoroll.params.ppq / 30) * gpmsys_patterns.paused
        gpmsys_patterns.timeline = gpmsys_patterns.timeline + speed

        if times and times[group_index] and times[group_index].start <= gpmsys_patterns.timeline then
            for i = 1, #group_list[times[group_index].index] do
                local note = group_list[times[group_index].index][i]
                reaper.StuffMIDIMessage(0, 0x90, note.pitch, note.velocity)
                stop(note)
            end
            group_index = group_index + 1
        end

        if not gpmsys_patterns.stop_play and gpmsys_patterns.timeline < gpmsys_patterns.pianoroll.params.end_pos then
            gpmsys_patterns.is_playing = true
            gpmsys_patterns.has_looped = false
            reaper.defer(play)
        else
            if Settings.pattern_looping.value and not gpmsys_patterns.stop_play and gpmsys_patterns.is_playing then
                gpmsys_patterns.timeline = 0
                group_index = 1
                note_index = 1
                prev_note = nil
                gpmsys_patterns.has_looped = true
                reaper.defer(play)
            else
                if gpmsys_patterns.stop_play then
                    for _, group in ipairs(group_list) do
                        for _, note in ipairs(group) do
                            reaper.StuffMIDIMessage(0, 0x80, note.pitch, 0)
                        end
                    end
                end

                gpmsys_patterns.stop_play = false
                gpmsys_patterns.is_playing = false
                gpmsys_patterns.timeline = 0
                gpmsys_patterns.paused = 1
                group_index = 1
                note_index = 1
                times = {}
                group_list = {}
                prev_note = nil
            end
        end
    end

    play()
end

return gpmsys_patterns
