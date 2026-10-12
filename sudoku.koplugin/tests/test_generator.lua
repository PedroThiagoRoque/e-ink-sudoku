package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Generator = require("sudoku.generator")
local Solver = require("sudoku.solver")
local Validator = require("sudoku.validator")

local function finish(generator)
    local calls = 0
    while not generator:step(200) do
        calls = calls + 1
        Test.truthy(calls < 20000, "generation did not finish")
    end
    return generator:result()
end

local function count(map) local total=0; for _ in pairs(map) do total=total+1 end; return total end

local specs = {
    classic={9,3,3}, ["mini-4"]={4,2,2}, ["mini-6"]={6,2,3}, mega={16,4,4},
}

Test.run({
    ["rejects modes and difficulties that are not shipped"] = function()
        local unsupported, mode_err = Generator.new("diagonal", "medium", 1)
        Test.falsy(unsupported); Test.truthy(mode_err)
        local unknown, difficulty_err = Generator.new("classic", "expert", 1)
        Test.falsy(unknown); Test.truthy(difficulty_err)
    end,
    ["generates valid unique puzzles for every shipped mode"] = function()
        for mode, spec in pairs(specs) do
            local generator = assert(Generator.new(mode, "easy", 17))
            local puzzle, err = finish(generator)
            Test.truthy(puzzle, mode..": "..tostring(err))
            Test.equal(puzzle.rows, spec[1]); Test.equal(puzzle.columns, spec[1])
            Test.equal(puzzle.block.rows, spec[2]); Test.equal(puzzle.block.columns, spec[3])
            Test.truthy(count(puzzle.givens) < #puzzle:cell_ids())
            Test.falsy(next(Validator.inspect(puzzle, puzzle.givens).conflicts))
            local solver = Solver.new(puzzle)
            while not solver:step(1000) do end
            Test.equal(solver:result().solutions, 1, mode)
            Test.equal(puzzle.mode, mode)
            Test.equal(puzzle.difficulty, "easy")
            Test.equal(puzzle.seed, 17)
        end
    end,
    ["generates a reproducible magazine-medium classic"] = function()
        local first = assert(Generator.new("classic", "medium", 23))
        local second = assert(Generator.new("classic", "medium", 23))
        local a, aerr = finish(first); local b, berr = finish(second)
        Test.truthy(a, tostring(aerr)); Test.truthy(b, tostring(berr))
        Test.truthy(count(a.givens) >= 30 and count(a.givens) <= 36)
        Test.equal(a.difficulty, "medium"); Test.equal(a.seed, 23)
        for _, cell_id in ipairs(a:cell_ids()) do Test.equal(a.givens[cell_id], b.givens[cell_id]) end
        Test.equal(a.metrics.hardest, b.metrics.hardest)
    end,
    ["honors one unit budgets and cancels active work"] = function()
        local generator = assert(Generator.new("classic", "medium", 99))
        local before = generator:status().nodes
        Test.falsy(generator:step(1))
        Test.truthy(generator:status().nodes - before <= 1)
        Test.truthy(generator:cancel())
        Test.truthy(generator:step(1))
        local puzzle, err = generator:result()
        Test.falsy(puzzle); Test.truthy(err)
    end,
})
