package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Storage = require("sudoku.storage")
local path = "/tmp/eink-sudoku-save-test.json"
os.remove(path); os.remove(path .. ".bak")

Test.run({
    ["round trips a safe json record"] = function()
        assert(Storage.save(path, { version = 1, puzzle_id = "classic-01", values = { ["1:1"] = 2 } }))
        local record = assert(Storage.load(path, "classic-01"))
        Test.equal(record.values["1:1"], 2)
    end,
    ["uses a backup after a truncated save"] = function()
        assert(Storage.save(path, { version = 1, puzzle_id = "classic-01", values = { ["1:1"] = 2 } }))
        assert(Storage.save(path, { version = 1, puzzle_id = "classic-01", values = { ["1:1"] = 3 } }))
        local file = assert(io.open(path, "w")); file:write("{"); file:close()
        local record, recovery = assert(Storage.load(path, "classic-01"))
        Test.equal(recovery, "backup")
        Test.equal(record.puzzle_id, "classic-01")
    end,
    ["rejects a mismatched puzzle"] = function()
        assert(Storage.save(path, { version = 1, puzzle_id = "classic-01", values = {} }))
        local record, _, err = Storage.load(path .. ".bak", "other")
        Test.falsy(record); Test.truthy(err)
    end,
})
os.remove(path); os.remove(path .. ".bak")
