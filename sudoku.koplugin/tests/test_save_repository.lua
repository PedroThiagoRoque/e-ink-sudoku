package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Puzzle = require("sudoku.puzzle")
local Session = require("sudoku.session")
local Repo = require("sudoku.save_repository")
local root = "/tmp/eink-sudoku-repo"
os.execute("rm -rf " .. root)
Test.run({
    ["keeps a game independently for each mode"] = function()
        local puzzle = assert(Puzzle.new({id="c",symbols={1,2},cells={{id="a"},{id="b"}},units={{cells={"a","b"}}}}))
        local session=Session.new(puzzle); assert(session:select("a")); assert(session:input(1))
        local repo=Repo.new(root); assert(repo:save("classic",session)); assert(repo:save("diagonal",Session.new(puzzle)))
        local restored=assert(repo:load("classic")); Test.equal(restored.game.values.a,1)
        Test.truthy(repo:load("diagonal"))
    end,
})
os.execute("rm -rf " .. root)
