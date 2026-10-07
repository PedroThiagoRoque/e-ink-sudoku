package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local View = require("sudoku.view")
local Puzzle = require("sudoku.puzzle")
local Session = require("sudoku.session")
Test.run({
    ["maps a touch to a logical cell"] = function()
        local cell = View.cell_at({ x = 10, y = 20, width = 180, height = 180, rows = 9, columns = 9 }, 39, 59)
        Test.equal(cell, "2:2")
    end,
    ["keeps taps outside a board out of play"] = function()
        Test.equal(View.cell_at({ x = 10, y = 20, width = 180, height = 180, rows = 9, columns = 9 }, 9, 20), nil)
    end,
    ["formats mega symbols"] = function()
        Test.equal(View.symbol(10), "A")
    end,
    ["offers only puzzle symbols plus erase in the popup"] = function()
        local choices = View.popup_choices({ 1, 2, 3 })
        Test.equal(choices[1].value, 1)
        Test.equal(choices[3].value, 3)
        Test.equal(choices[4].label, "Apagar")
        Test.equal(choices[4].value, nil)
    end,
    ["erases the selected entry through the session"] = function()
        local puzzle = assert(Puzzle.new({ id="ui", symbols={1,2}, cells={{id="a"},{id="b"}}, units={{cells={"a","b"}}} }))
        local session = Session.new(puzzle)
        assert(session:select("a")); assert(session:input(2)); assert(session:input(nil))
        Test.equal(session.game.values.a, nil)
    end,
    ["creates board rows with immutable clues disabled"] = function()
        local puzzle = assert(Puzzle.new({ id="rows", rows=2, columns=2, symbols={1,2}, cells={{id="1:1"},{id="1:2"},{id="2:1"},{id="2:2"}}, givens={["1:1"]=1}, units={{cells={"1:1","1:2"}}} }))
        local session = Session.new(puzzle)
        local rows = View.board_rows(session)
        Test.equal(#rows, 2)
        Test.equal(rows[1][1].text, "1")
        Test.falsy(rows[1][1].enabled)
        Test.equal(rows[2][2].text, "·")
    end,
})
