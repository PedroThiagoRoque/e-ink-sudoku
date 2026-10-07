package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Catalog = require("catalog.init")

Test.run({
    ["lists every requested mode"] = function()
        for _, mode in ipairs({ "classic", "diagonal", "mini-4", "mini-6", "killer", "mega", "kakuro", "samurai" }) do
            Test.truthy(#Catalog.list(mode) >= 1, mode)
        end
    end,
    ["uses letters after nine in mega sudoku"] = function()
        local puzzle = assert(Catalog.get("mega-01"))
        Test.equal(puzzle.symbols[10], "A")
        Test.equal(#puzzle:cell_ids(), 256)
    end,
    ["shares identities in samurai overlaps"] = function()
        local puzzle = assert(Catalog.get("samurai-01"))
        Test.truthy(#puzzle:units_for("r7:c7") >= 6)
    end,
})
