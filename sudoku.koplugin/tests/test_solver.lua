package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Puzzle = require("sudoku.puzzle")
local Solver = require("sudoku.solver")
local function p(givens)
    return assert(Puzzle.new({id="solver", symbols={1,2}, cells={{id="a"},{id="b"}}, units={{cells={"a","b"}}}, givens=givens or {}}))
end
Test.run({
    ["stops counting after a second solution"] = function()
        local solver = Solver.new(p())
        solver:step(100)
        Test.equal(solver:result().solutions, 2)
    end,
    ["finds a unique solved puzzle"] = function()
        local solver = Solver.new(p({a=1,b=2}))
        solver:step(100)
        Test.equal(solver:result().solutions, 1)
    end,
    ["rejects contradictory filled input"] = function()
        local solver = Solver.new(p(), {a=1,b=1})
        while not solver:step(1) do end
        Test.equal(solver:result().solutions, 0)
    end,
    ["rejects values outside the alphabet"] = function()
        local solver = Solver.new(p(), {a=8,b=9})
        while not solver:step(1) do end
        Test.equal(solver:result().solutions, 0)
        Test.truthy(solver:result().error)
    end,
    ["finds no solution when a sum cannot be met"] = function()
        local puzzle = assert(Puzzle.new({id="sum", symbols={1,2}, cells={{id="a"},{id="b"}},
            units={}, sums={{cells={"a","b"},target=5,distinct=true}}}))
        local solver = Solver.new(puzzle)
        while not solver:step(1) do end
        Test.equal(solver:result().solutions, 0)
    end,
    ["resumes search without exceeding its node budget"] = function()
        local puzzle = assert(Puzzle.new({id="budget", symbols={1,2},
            cells={{id="a"},{id="b"},{id="c"},{id="d"}},
            units={{cells={"a","b"}},{cells={"c","d"}}} }))
        local incremental = Solver.new(puzzle)
        local previous = 0
        local calls = 0
        while not incremental:step(1) do
            calls = calls + 1
            local nodes = incremental:result().nodes
            Test.truthy(nodes - previous <= 1)
            previous = nodes
            Test.truthy(calls < 100)
        end
        Test.truthy(calls > 1)
        local one_shot = Solver.new(puzzle)
        one_shot:step(100)
        Test.equal(incremental:result().solutions, one_shot:result().solutions)
        Test.equal(incremental:result().solutions, 2)
    end,
    ["rejects invalid budgets"] = function()
        local ok, err = pcall(function() Solver.new(p()):step(0) end)
        Test.falsy(ok)
        Test.truthy(tostring(err):match("orçamento"))
    end,
})
