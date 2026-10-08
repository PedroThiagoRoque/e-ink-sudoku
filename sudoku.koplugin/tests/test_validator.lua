package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Puzzle = require("sudoku.puzzle")
local Validator = require("sudoku.validator")

local function puzzle(definition) return assert(Puzzle.new(definition)) end

Test.run({
    ["finds duplicates in classic and diagonal units"] = function()
        local p = puzzle({ id = "diagonal", symbols = { 1, 2 }, cells = { {id="a"},{id="b"},{id="c"} }, units = { {kind="row", cells={"a","b"}}, {kind="diagonal", cells={"a","c"}} } })
        local result = Validator.inspect(p, { a = 1, b = 1, c = 1 })
        Test.truthy(result.conflicts.a)
        Test.truthy(result.conflicts.c)
    end,
    ["rejects killer repetition and excessive sum"] = function()
        local p = puzzle({ id="killer", symbols={1,2,3}, cells={{id="a"},{id="b"}}, units={}, sums={{cells={"a","b"}, target=3, distinct=true}} })
        local result = Validator.inspect(p, { a=2, b=2 })
        Test.truthy(result.conflicts.a)
        Test.truthy(result.conflicts.b)
    end,
    ["rejects a completed kakuro sequence with wrong sum"] = function()
        local p = puzzle({ id="kakuro", symbols={1,2,3}, cells={{id="a"},{id="b"}}, units={}, sums={{cells={"a","b"}, target=3, distinct=true}} })
        local result = Validator.inspect(p, { a=1, b=3 })
        Test.truthy(result.conflicts.a)
        Test.falsy(result.solved)
    end,
    ["rejects values outside symbols and changed givens"] = function()
        local p = puzzle({ id="strict", symbols={1,2}, cells={{id="a"},{id="b"}},
            units={{cells={"a","b"}}}, givens={a=1} })
        local unknown = Validator.inspect(p, {a=1,b=9})
        Test.truthy(unknown.invalid.b)
        Test.falsy(unknown.solved)
        local changed = Validator.inspect(p, {a=2,b=1})
        Test.truthy(changed.invalid.a)
        Test.falsy(changed.solved)
    end,
})
