local Puzzle = {}
Puzzle.__index = Puzzle

local known_modes = {
    classic=true, ["mini-4"]=true, ["mini-6"]=true, mini=true, mega=true,
    diagonal=true, killer=true, kakuro=true, samurai=true,
}

local regular_geometry = {
    classic={9,9,3,3}, ["mini-4"]={4,4,2,2}, ["mini-6"]={6,6,2,3},
    mega={16,16,4,4},
}

local function contains(values, needle)
    for _, value in ipairs(values) do
        if value == needle then
            return true
        end
    end
    return false
end

local function copy_map(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do result[index] = value end
    return result
end

local function valid_positive_integer(value)
    return type(value) == "number" and value >= 1 and value % 1 == 0
end

function Puzzle.new(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string" then
        return nil, "desafio sem identificador"
    end
    if type(definition.cells) ~= "table" or #definition.cells == 0 then
        return nil, "desafio sem células"
    end
    if type(definition.symbols) ~= "table" or #definition.symbols == 0 then
        return nil, "desafio sem símbolos"
    end
    if definition.mode ~= nil and not known_modes[definition.mode] then
        return nil, "modo de desafio desconhecido"
    end

    local symbol_seen = {}
    local owned_symbols = {}
    for index, symbol in ipairs(definition.symbols) do
        if symbol_seen[symbol] then return nil, "símbolos duplicados" end
        symbol_seen[symbol] = true
        owned_symbols[index] = symbol
    end

    local expected = regular_geometry[definition.mode]
    if expected then
        if definition.rows ~= expected[1] or definition.columns ~= expected[2] then
            return nil, "dimensões incompatíveis com o modo"
        end
        if definition.block and (definition.block.rows ~= expected[3] or definition.block.columns ~= expected[4]) then
            return nil, "blocos incompatíveis com o modo"
        end
    elseif definition.rows ~= nil and not valid_positive_integer(definition.rows) then
        return nil, "quantidade de linhas inválida"
    elseif definition.columns ~= nil and not valid_positive_integer(definition.columns) then
        return nil, "quantidade de colunas inválida"
    end

    local cells, cell_order = {}, {}
    for _, cell in ipairs(definition.cells) do
        if type(cell) ~= "table" or type(cell.id) ~= "string" or cells[cell.id] then
            return nil, "células inválidas ou duplicadas"
        end
        if cell.row ~= nil and not valid_positive_integer(cell.row) then return nil, "linha de célula inválida" end
        if cell.column ~= nil and not valid_positive_integer(cell.column) then return nil, "coluna de célula inválida" end
        cells[cell.id] = { id = cell.id, row = cell.row, column = cell.column }
        cell_order[#cell_order + 1] = cell.id
    end

    local givens = copy_map(definition.givens)
    for cell_id, value in pairs(givens) do
        if not cells[cell_id] then
            return nil, "pista aponta para célula inexistente"
        end
        if not contains(definition.symbols, value) then
            return nil, "pista fora do conjunto de símbolos"
        end
    end

    local units_for = {}
    for _, cell_id in ipairs(cell_order) do
        units_for[cell_id] = {}
    end
    local units = {}
    for _, unit in ipairs(definition.units or {}) do
        if type(unit.cells) ~= "table" or #unit.cells < 2 then
            return nil, "unidade deve ter ao menos duas células"
        end
        local seen = {}
        for _, cell_id in ipairs(unit.cells) do
            if not cells[cell_id] or seen[cell_id] then
                return nil, "unidade contém célula inválida"
            end
            seen[cell_id] = true
        end
        units[#units + 1] = { kind = unit.kind or "unit", cells = copy_array(unit.cells) }
        for _, cell_id in ipairs(unit.cells) do
            units_for[cell_id][#units_for[cell_id] + 1] = units[#units]
        end
    end


    local sums = {}
    for _, group in ipairs(definition.sums or {}) do
        if type(group) ~= "table" or type(group.cells) ~= "table" or #group.cells < 1
            or type(group.target) ~= "number" then
            return nil, "grupo de soma inválido"
        end
        local seen = {}
        for _, cell_id in ipairs(group.cells) do
            if not cells[cell_id] or seen[cell_id] then return nil, "grupo de soma contém célula inválida" end
            seen[cell_id] = true
        end
        sums[#sums + 1] = { cells=copy_array(group.cells), target=group.target, distinct=group.distinct and true or false }
    end

    for _, unit in ipairs(units) do
        local seen = {}
        for _, cell_id in ipairs(unit.cells) do
            local value = givens[cell_id]
            if value ~= nil then
                if seen[value] then return nil, "pistas conflitantes" end
                seen[value] = true
            end
        end
    end
    for _, group in ipairs(sums) do
        local total, seen = 0, {}
        for _, cell_id in ipairs(group.cells) do
            local value = givens[cell_id]
            if value ~= nil then
                if type(value) ~= "number" then return nil, "soma exige símbolos numéricos" end
                if group.distinct and seen[value] then return nil, "pistas conflitantes em soma" end
                seen[value] = true
                total = total + value
            end
        end
        if total > group.target then return nil, "pistas excedem soma" end
    end

    local block
    if definition.block then block = {rows=definition.block.rows, columns=definition.block.columns} end

    return setmetatable({
        id = definition.id,
        mode = definition.mode,
        rows = definition.rows,
        columns = definition.columns,
        symbols = owned_symbols,
        cells = cells,
        cell_order = cell_order,
        givens = givens,
        units = units,
        units_by_cell = units_for,
        sums = sums,
        block = block,
    }, Puzzle)
end

function Puzzle:cell_ids()
    return self.cell_order
end

function Puzzle:units_for(cell_id)
    return self.units_by_cell[cell_id] or {}
end

function Puzzle:given(cell_id)
    return self.givens[cell_id]
end

function Puzzle:has_symbol(value)
    return contains(self.symbols, value)
end

return Puzzle
