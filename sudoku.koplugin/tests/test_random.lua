package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Random = require("sudoku.random")
Test.run({
    ["repeats the same sequence for the same seed"] = function()
        local a, b = Random.new(123), Random.new(123)
        Test.equal(a:next_int(1000), b:next_int(1000))
        Test.equal(a:next_int(1000), b:next_int(1000))
    end,
    ["shuffles reproducibly"] = function()
        local a, b = Random.new(3), Random.new(3)
        Test.equal(table.concat(a:shuffle({1,2,3,4})), table.concat(b:shuffle({1,2,3,4})))
    end,
    ["normalizes degenerate and negative seeds"] = function()
        for _, seed in ipairs({0, 2147483647, -1}) do
            local first, second = Random.new(seed), Random.new(seed)
            local a1, a2 = first:next_int(100), first:next_int(100)
            Test.equal(a1, second:next_int(100))
            Test.equal(a2, second:next_int(100))
            Test.truthy(a1 ~= a2, "normalized seed must not stay constant")
        end
    end,
    ["rejects non-positive limits"] = function()
        local ok, err = pcall(function() Random.new(1):next_int(0) end)
        Test.falsy(ok)
        Test.truthy(tostring(err):match("positivo"))
    end,
})
