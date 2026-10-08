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
    ["rejects duplicate symbols"] = function()
        local puzzle, err = Puzzle.new({ id="bad-symbols", mode="classic", rows=2, columns=2,
            symbols={1,1}, cells={{id="1:1",row=1,column=1}}, units={} })
        Test.falsy(puzzle)
        Test.truthy(err)
    end,
    ["rejects invalid regular grid geometry"] = function()
        local puzzle, err = Puzzle.new({ id="bad-grid", mode="classic", rows=9, columns=9,
            symbols={1,2,3,4,5,6,7,8,9}, cells={{id="1:1",row=1,column=1}},
            block={rows=2,columns=3}, units={} })
        Test.falsy(puzzle)
        Test.truthy(err)
    end,
    ["rejects units that reference missing cells"] = function()
        local puzzle, err = Puzzle.new({ id="bad-unit", symbols={1,2},
            cells={{id="a"},{id="b"}}, units={{cells={"a","missing"}}} })
        Test.falsy(puzzle)
        Test.truthy(err)
    end,
    ["rejects malformed sums"] = function()
        local definitions = {
            {cells={"a","missing"}, target=3},
            {cells={"a","a"}, target=3},
            {cells={"a","b"}, target="3"},
        }
        for index, sum in ipairs(definitions) do
            local puzzle, err = Puzzle.new({ id="bad-sum-"..index, symbols={1,2},
                cells={{id="a"},{id="b"}}, units={}, sums={sum} })
            Test.falsy(puzzle)
            Test.truthy(err)
        end
    end,
    ["rejects conflicting givens and unknown modes"] = function()
        local conflict = Puzzle.new({ id="bad-givens", symbols={1,2}, cells={{id="a"},{id="b"}},
            units={{cells={"a","b"}}}, givens={a=1,b=1} })
        Test.falsy(conflict)
        local unknown = Puzzle.new({ id="bad-mode", mode="mystery", rows=1, columns=1,
            symbols={1}, cells={{id="1:1",row=1,column=1}}, units={} })
        Test.falsy(unknown)
    end,
})
