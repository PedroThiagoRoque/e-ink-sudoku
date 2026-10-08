local Puzzle = require("sudoku.puzzle")
local Definition = {}

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}; seen[value] = result
    for key, item in pairs(value) do result[copy(key, seen)] = copy(item, seen) end
    return result
end
function Definition.encode(puzzle)
    local cells={}; for _,id in ipairs(puzzle:cell_ids()) do cells[#cells+1]=puzzle.cells[id] end
    return copy({id=puzzle.id,mode=puzzle.mode,rows=puzzle.rows,columns=puzzle.columns,symbols=puzzle.symbols,cells=cells,givens=puzzle.givens,units=puzzle.units,sums=puzzle.sums,block=puzzle.block})
end
function Definition.decode(record) return Puzzle.new(copy(record)) end
return Definition
