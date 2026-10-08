package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Puzzle = require("sudoku.puzzle")
local Definition = require("sudoku.definition")

Test.run({
    ["encoded definitions cannot mutate their puzzle"] = function()
        local puzzle = assert(Puzzle.new({ id="owned", mode="mini-4", rows=4, columns=4,
            symbols={1,2,3,4},
            cells={{id="1:1",row=1,column=1},{id="1:2",row=1,column=2}},
            units={{kind="row",cells={"1:1","1:2"}}},
            sums={{cells={"1:1","1:2"},target=3,distinct=true}},
            block={rows=2,columns=2}, givens={ ["1:1"]=1 } }))
        local encoded = Definition.encode(puzzle)
        encoded.symbols[1] = 9
        encoded.units[1].cells[1] = "changed"
        encoded.sums[1].target = 99
        encoded.block.rows = 9
        Test.equal(puzzle.symbols[1], 1)
        Test.equal(puzzle.units[1].cells[1], "1:1")
        Test.equal(puzzle.sums[1].target, 3)
        Test.equal(puzzle.block.rows, 2)
    end,
})
