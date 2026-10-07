local Units = require("sudoku.units")

local Factories = {}

local function cells(rows, columns, prefix)
    local result = {}
    for row = 1, rows do for column = 1, columns do
        result[#result + 1] = { id = (prefix or "") .. row .. ":" .. column, row = row, column = column }
    end end
    return result
end

local function numbers(count)
    local result = {}
    for value = 1, count do result[value] = value end
    return result
end

function Factories.grid(id, mode, size, block_rows, block_columns, symbols)
    return { id = id, mode = mode, rows = size, columns = size, symbols = symbols or numbers(size), cells = cells(size, size), block = { rows = block_rows, columns = block_columns }, units = Units.grid(size, size, block_rows, block_columns), givens = {} }
end

function Factories.diagonal(id)
    local definition = Factories.grid(id, "diagonal", 9, 3, 3)
    local left, right = {}, {}
    for row = 1, 9 do left[#left + 1], right[#right + 1] = row .. ":" .. row, row .. ":" .. (10 - row) end
    definition.units[#definition.units + 1] = { kind = "diagonal", cells = left }
    definition.units[#definition.units + 1] = { kind = "diagonal", cells = right }
    return definition
end

function Factories.killer(id)
    local definition = Factories.grid(id, "killer", 9, 3, 3)
    definition.sums = { { cells = { "1:1", "1:2" }, target = 3, distinct = true } }
    return definition
end

function Factories.kakuro(id)
    return { id = id, mode = "kakuro", rows = 2, columns = 2, symbols = numbers(9), cells = cells(2, 2), units = {}, sums = { { cells = { "1:1", "1:2" }, target = 3, distinct = true }, { cells = { "1:1", "2:1" }, target = 4, distinct = true } }, givens = {} }
end

function Factories.mega(id)
    local symbols = { 1, 2, 3, 4, 5, 6, 7, 8, 9, "A", "B", "C", "D", "E", "F", "G" }
    return Factories.grid(id, "mega", 16, 4, 4, symbols)
end

function Factories.samurai(id)
    local cells_by_id, all_cells, all_units = {}, {}, {}
    local function add_grid(first_row, first_column)
        local ids = {}
        for row = first_row, first_row + 8 do for column = first_column, first_column + 8 do
            local cell_id = "r" .. row .. ":c" .. column
            if not cells_by_id[cell_id] then
                cells_by_id[cell_id] = { id = cell_id, row = row, column = column }
                all_cells[#all_cells + 1] = cells_by_id[cell_id]
            end
            ids[row - first_row + 1] = ids[row - first_row + 1] or {}
            ids[row - first_row + 1][column - first_column + 1] = cell_id
        end end
        for row = 1, 9 do all_units[#all_units + 1] = { kind = "row", cells = ids[row] } end
        for column = 1, 9 do
            local line = {}; for row = 1, 9 do line[#line + 1] = ids[row][column] end
            all_units[#all_units + 1] = { kind = "column", cells = line }
        end
        for row = 1, 9, 3 do for column = 1, 9, 3 do
            local block = {}; for r = row, row + 2 do for c = column, column + 2 do block[#block + 1] = ids[r][c] end end
            all_units[#all_units + 1] = { kind = "block", cells = block }
        end end
    end
    add_grid(1, 1); add_grid(1, 13); add_grid(7, 7); add_grid(13, 1); add_grid(13, 13)
    return { id = id, mode = "samurai", rows = 21, columns = 21, symbols = numbers(9), cells = all_cells, units = all_units, givens = {} }
end

return Factories
