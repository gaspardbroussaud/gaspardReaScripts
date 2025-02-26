--@noindex
--@description Pattern generator midi file read functions
--@author gaspard
--@about All functions used in gaspard_Pattern generator.lua script

local midi_read = {}

local PPQ = 480  -- Default PPQ (will be extracted from MIDI header)
local BPM = 120  -- Default BPM (will be extracted from tempo events)

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

-- Function to read the MIDI file and extract PPQ and BPM
function midi_read.ReadMidiFile(filepath)
    local notes = {}

    local file = io.open(filepath, "rb")
    if not file then return nil end

    local data = file:read("*all")
    file:close()
    notes = {}

    local pos = 1
    local time = 0
    local active_notes = {}

    local interval = { min = 0, max = 0 }

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
                    if pitch < interval.min then interval.min = pitch end
                    if pitch > interval.max then interval.max = pitch end
                    local velocity = data:byte(pos + 2)

                    if (status >= 0x90 and status <= 0x9F) and velocity > 0 then -- Note On
                        active_notes[pitch] = time
                    elseif (status >= 0x80 and status <= 0x8F) or (status >= 0x90 and velocity == 0) then -- Note Off
                        if active_notes[pitch] then
                            local start_time = active_notes[pitch]
                            local length = time - start_time
                            table.insert(notes, { pitch = pitch, start = start_time, length = length })
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

    return notes, interval
end

function midi_read.Show()
    reaper.ImGui_DrawList_AddRectFilled(draw_list, 600, 150, 700, 170, 0xFF0000FF)
end

return midi_read
