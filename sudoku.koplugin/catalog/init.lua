local Puzzle = require("sudoku.puzzle")
local Factories = require("catalog.factories")

local definitions = {
    Factories.grid("classic-01", "classic", 9, 3, 3),
    Factories.diagonal("diagonal-01"),
    Factories.grid("mini-4-01", "mini-4", 4, 2, 2),
    Factories.grid("mini-6-01", "mini-6", 6, 2, 3),
    Factories.killer("killer-01"), Factories.mega("mega-01"),
    Factories.kakuro("kakuro-01"), Factories.samurai("samurai-01"),
}
local Catalog, by_id = {}, {}
for _, definition in ipairs(definitions) do by_id[definition.id] = definition end

function Catalog.list(mode)
    local result = {}
    for _, definition in ipairs(definitions) do if definition.mode == mode then result[#result + 1] = definition.id end end
    return result
end
function Catalog.get(id)
    local definition = by_id[id]
    if not definition then return nil, "desafio inexistente" end
    return Puzzle.new(definition)
end
return Catalog
