local Puzzle = {}
Puzzle.__index = Puzzle

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

    local cells, cell_order = {}, {}
    for _, cell in ipairs(definition.cells) do
        if type(cell) ~= "table" or type(cell.id) ~= "string" or cells[cell.id] then
            return nil, "células inválidas ou duplicadas"
        end
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
        units[#units + 1] = { kind = unit.kind or "unit", cells = unit.cells }
        for _, cell_id in ipairs(unit.cells) do
            units_for[cell_id][#units_for[cell_id] + 1] = units[#units]
        end
    end

    return setmetatable({
        id = definition.id,
        mode = definition.mode,
        rows = definition.rows,
        columns = definition.columns,
        symbols = definition.symbols,
        cells = cells,
        cell_order = cell_order,
        givens = givens,
        units = units,
        units_by_cell = units_for,
        sums = definition.sums or {},
        block = definition.block,
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
