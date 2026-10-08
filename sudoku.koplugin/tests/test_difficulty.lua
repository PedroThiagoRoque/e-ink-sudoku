package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Puzzle = require("sudoku.puzzle")
local Difficulty = require("sudoku.difficulty")

local function puzzle(id, symbols, cells, units, givens)
    return assert(Puzzle.new({id=id, symbols=symbols, cells=cells, units=units, givens=givens}))
end

Test.run({
    ["scores a naked single"] = function()
        local p = puzzle("naked", {1,2}, {{id="a"},{id="b"}}, {{cells={"a","b"}}}, {a=1})
        local report = Difficulty.evaluate(p)
        Test.truthy(report.solved)
        Test.equal(report.hardest, "naked_single")
        Test.equal(report.score, 1)
    end,
    ["recognizes a hidden single"] = function()
        local p = puzzle("hidden", {1,2,3},
            {{id="a"},{id="b"},{id="c"},{id="x"},{id="y"}},
            {{kind="row",cells={"a","b","c"}},{cells={"a","x"}},{cells={"b","y"}}},
            {x=3,y=3})
        local report = Difficulty.evaluate(p)
        Test.equal(report.hardest, "hidden_single")
        Test.equal(report.score, 2)
    end,
    ["recognizes a locked candidate"] = function()
        local p = puzzle("locked", {1,2,3},
            {{id="a",row=1,column=1},{id="b",row=1,column=2},{id="c",row=2,column=1},
             {id="d",row=1,column=3},{id="x",row=2,column=2},{id="y",row=3,column=3}},
            {{kind="block",cells={"a","b","c"}},{kind="row",cells={"a","b","d"}},
             {cells={"c","x"}},{cells={"d","y"}}}, {x=3,y=1})
        local report = Difficulty.evaluate(p)
        Test.equal(report.hardest, "locked_candidate")
        Test.truthy(report.score >= 4)
    end,
    ["recognizes a naked pair"] = function()
        local p = puzzle("pair", {1,2,3,4,5},
            {{id="a"},{id="b"},{id="c"},{id="d"},{id="e"},{id="x3"},{id="x4"},{id="x5"}},
            {{kind="row",cells={"a","b","c","d","e"}},
             {cells={"a","x3"}},{cells={"b","x3"}},
             {cells={"a","x4"}},{cells={"b","x4"}},
             {cells={"a","x5"}},{cells={"b","x5"}}},
            {x3=3,x4=4,x5=5})
        local report = Difficulty.evaluate(p)
        Test.equal(report.hardest, "pair")
        Test.truthy(report.score >= 6)
    end,
    ["matches only magazine-medium reports"] = function()
        local medium = {solved=true, guessed=false, clue_count=33, hardest="locked_candidate",
            counts={naked_single=20,hidden_single=4,locked_candidate=1,pair=0}}
        Test.truthy(Difficulty.matches("classic", "medium", medium))
        local easy = {solved=true, guessed=false, clue_count=33, hardest="hidden_single",
            counts={naked_single=30,hidden_single=2,locked_candidate=0,pair=0}}
        Test.falsy(Difficulty.matches("classic", "medium", easy))
        local guessed = {solved=true, guessed=true, clue_count=33, hardest="pair",
            counts={naked_single=1,hidden_single=1,locked_candidate=1,pair=1}}
        Test.falsy(Difficulty.matches("classic", "medium", guessed))
        medium.clue_count = 37
        Test.falsy(Difficulty.matches("classic", "medium", medium))
    end,
})
