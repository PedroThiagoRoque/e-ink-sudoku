package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path

local Test = require("tests.testlib")
local Puzzle = require("sudoku.puzzle")

local function grid_cells(rows, columns)
    local cells = {}
    for row = 1, rows do
        for column = 1, columns do
            cells[#cells + 1] = { id = row .. ":" .. column, row = row, column = column }
        end
    end
    return cells
end

Test.run({
    ["builds a classic puzzle with given cells"] = function()
        local puzzle, err = Puzzle.new({
            id = "classic-1",
            mode = "classic",
            rows = 9,
            columns = 9,
            symbols = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            cells = grid_cells(9, 9),
            givens = { ["1:1"] = 5 },
            units = { { kind = "row", cells = { "1:1", "1:2" } } },
        })
        Test.truthy(puzzle, err)
        Test.equal(#puzzle:cell_ids(), 81)
        Test.equal(puzzle:given("1:1"), 5)
        Test.equal(#puzzle:units_for("1:1"), 1)
    end,
    ["accepts rectangular mini blocks"] = function()
        local puzzle, err = Puzzle.new({
            id = "mini-6",
            mode = "mini",
            rows = 6,
            columns = 6,
            symbols = { 1, 2, 3, 4, 5, 6 },
            cells = grid_cells(6, 6),
            block = { rows = 2, columns = 3 },
            units = {},
        })
        Test.truthy(puzzle, err)
        Test.equal(puzzle.block.columns, 3)
    end,
    ["rejects a given outside the symbol set"] = function()
        local puzzle, err = Puzzle.new({
            id = "invalid",
            mode = "classic",
            rows = 1,
            columns = 1,
            symbols = { 1 },
            cells = grid_cells(1, 1),
            givens = { ["1:1"] = 2 },
            units = {},
        })
        Test.falsy(puzzle)
        Test.truthy(err)
    end,
})
