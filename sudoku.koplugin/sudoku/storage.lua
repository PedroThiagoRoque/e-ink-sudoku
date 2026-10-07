local Storage = {}

local function escape(value) return value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") end
local function encode(value)
    local value_type = type(value)
    if value_type == "nil" then return "null" end
    if value_type == "boolean" or value_type == "number" then return tostring(value) end
    if value_type == "string" then return '"' .. escape(value) .. '"' end
    if value_type ~= "table" then error("tipo não serializável") end
    local array, count = true, 0
    for key in pairs(value) do count = count + 1; if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then array = false end end
    if array then
        local chunks = {}; for index = 1, count do chunks[index] = encode(value[index]) end
        return "[" .. table.concat(chunks, ",") .. "]"
    end
    local chunks = {}; for key, item in pairs(value) do chunks[#chunks + 1] = encode(tostring(key)) .. ":" .. encode(item) end
    return "{" .. table.concat(chunks, ",") .. "}"
end

local function decode(text)
    local position = 1
    local function whitespace() local _, end_pos = text:find("^%s*", position); position = (end_pos or position - 1) + 1 end
    local parse_value
    local function parse_string()
        position = position + 1; local chunks = {}
        while position <= #text do
            local char = text:sub(position, position); position = position + 1
            if char == '"' then return table.concat(chunks) end
            if char == "\\" then
                local escaped = text:sub(position, position); position = position + 1
                chunks[#chunks + 1] = ({ ['"']='"', ['\\']='\\', ['n']='\n' })[escaped] or error("escape inválido")
            else chunks[#chunks + 1] = char end
        end
        error("string sem fim")
    end
    local function parse_object()
        position = position + 1; whitespace(); local object = {}
        if text:sub(position, position) == "}" then position = position + 1; return object end
        while true do
            if text:sub(position, position) ~= '"' then error("chave esperada") end
            local key = parse_string(); whitespace()
            if text:sub(position, position) ~= ":" then error("dois pontos esperados") end
            position = position + 1; object[key] = parse_value(); whitespace()
            local char = text:sub(position, position); position = position + 1
            if char == "}" then return object end
            if char ~= "," then error("vírgula esperada") end
            whitespace()
        end
    end
    local function parse_array()
        position = position + 1; whitespace(); local array = {}
        if text:sub(position, position) == "]" then position = position + 1; return array end
        while true do
            array[#array + 1] = parse_value(); whitespace()
            local char = text:sub(position, position); position = position + 1
            if char == "]" then return array end
            if char ~= "," then error("vírgula esperada") end
            whitespace()
        end
    end
    function parse_value()
        whitespace(); local char = text:sub(position, position)
        if char == '"' then return parse_string() end
        if char == "{" then return parse_object() end
        if char == "[" then return parse_array() end
        local token = text:match("^-?[0-9]+%.?[0-9]*", position)
        if token then position = position + #token; return tonumber(token) end
        for literal, value in pairs({ ["true"] = true, ["false"] = false, ["null"] = nil }) do
            if text:sub(position, position + #literal - 1) == literal then position = position + #literal; return value end
        end
        error("valor JSON inválido")
    end
    local value = parse_value(); whitespace(); if position <= #text then error("dados após JSON") end; return value
end

local function read_record(path)
    local file = io.open(path, "r"); if not file then return nil, "arquivo ausente" end
    local text = file:read("*a"); file:close()
    local ok, record = pcall(decode, text)
    if not ok or type(record) ~= "table" then return nil, "save corrompido" end
    return record
end

function Storage.save(path, record)
    local temporary = path .. ".tmp"
    local file, err = io.open(temporary, "w"); if not file then return nil, err end
    local ok, encoded = pcall(encode, record)
    if not ok then file:close(); os.remove(temporary); return nil, encoded end
    file:write(encoded); file:close()
    os.remove(path .. ".bak"); os.rename(path, path .. ".bak")
    local moved, move_err = os.rename(temporary, path)
    if not moved then return nil, move_err end
    return true
end

function Storage.load(path, puzzle_id)
    local record, err = read_record(path); local recovery
    if not record then record, err = read_record(path .. ".bak"); recovery = "backup" end
    if not record then return nil, nil, err end
    if record.version ~= 1 or record.puzzle_id ~= puzzle_id then return nil, nil, "save incompatível" end
    return record, recovery
end

return Storage
