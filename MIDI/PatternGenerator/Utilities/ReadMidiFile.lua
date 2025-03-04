--@noindex
--@description Pattern generator midi file read functions
--@author gaspard
--@about All functions used in gaspard_Pattern generator.lua script

local midi_read = {}

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

--[[ Function to read the MIDI file and extract PPQ and BPM
function midi_read.ReadMidiFile(filepath)
    System.pianoroll_notes = {}

    local file = io.open(filepath, "rb")
    if not file then return false end

    local data = file:read("*all")
    file:close()

    local pos = 1
    local time = 0
    local active_notes = {}

    System.pianoroll_range = {}

    -- Read the header chunk
    if data:sub(1, 4) == "MThd" then
        pos = pos + 4
        local header_length = data:byte(pos) * 0x1000000 + data:byte(pos + 1) * 0x10000 + data:byte(pos + 2) * 0x100 + data:byte(pos + 3)
        pos = pos + 4
        if header_length == 6 then
            PPQ = data:byte(pos + 1) * 0x100 + data:byte(pos + 2)
            pos = pos + 6
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
                    local meta_data = data:sub(pos + 1, pos + meta_length)

                    -- Tempo Meta Event (0x51)
                    if meta_type == 0x51 then
                        local microseconds_per_beat = (string.byte(meta_data, 1) << 16) + (string.byte(meta_data, 2) << 8) + string.byte(meta_data, 3)
                        BPM = 60000000 / microseconds_per_beat  -- Convert to BPM
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
                            if not System.pianoroll_range.min or pitch <= System.pianoroll_range.min then System.pianoroll_range.min = pitch end
                            if not System.pianoroll_range.max or pitch >= System.pianoroll_range.max then System.pianoroll_range.max = pitch end
                            table.insert(System.pianoroll_notes, { pitch = pitch, start = start_time, length = length })
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

    return true
end]]

function midi_read.ReadMidiFile(filepath)
    System.pianoroll_notes = {}

    local file = io.open(filepath, "rb")
    if not file then return false end

    local data = file:read("*all")
    file:close()

    local pos = 1
    local time = 0
    local active_notes = {}
    local furthest_pos = 0

    System.pianoroll_range = {}
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
                            if not System.pianoroll_range.min or pitch <= System.pianoroll_range.min then System.pianoroll_range.min = pitch end
                            if not System.pianoroll_range.max or pitch >= System.pianoroll_range.max then System.pianoroll_range.max = pitch end
                            table.insert(System.pianoroll_notes, { pitch = pitch, start = start_time, length = length })
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

    System.pianoroll_param.ppq = PPQ
    System.pianoroll_param.bpm = BPM
    System.pianoroll_param.bpi = BPI
    System.pianoroll_param.bpl = BPL
    System.pianoroll_param.end_pos = furthest_pos

    return true
end


return midi_read
