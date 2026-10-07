package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path

local Test = require("tests.testlib")
local Puzzle = require("sudoku.puzzle")
local Game = require("sudoku.game")

local puzzle = assert(Puzzle.new({
    id = "game",
    mode = "mini",
    rows = 2,
    columns = 2,
    symbols = { 1, 2 },
    cells = { { id = "1:1" }, { id = "1:2" }, { id = "2:1" }, { id = "2:2" } },
    givens = { ["1:1"] = 1 },
    units = { { cells = { "1:1", "1:2" } } },
}))

Test.run({
    ["protects given cells"] = function()
        local game = Game.new(puzzle)
        local ok, err = game:set_value("1:1", 2)
        Test.falsy(ok)
        Test.truthy(err)
        Test.equal(game.values["1:1"], 1)
    end,
    ["undoes and discards redo after a new move"] = function()
        local game = Game.new(puzzle)
        assert(game:set_value("1:2", 2))
        assert(game:undo())
        Test.equal(game.values["1:2"], nil)
        assert(game:set_value("2:1", 2))
        Test.falsy(game:redo())
    end,
    ["stores notes separately from values"] = function()
        local game = Game.new(puzzle)
        assert(game:toggle_note("1:2", 2))
        Test.truthy(game.notes["1:2"][2])
        Test.equal(game.values["1:2"], nil)
    end,
    ["restores a serialized game"] = function()
        local game = Game.new(puzzle)
        assert(game:set_value("1:2", 2))
        local restored = assert(Game.restore(puzzle, game:serialize()))
        Test.equal(restored.values["1:2"], 2)
    end,
})
