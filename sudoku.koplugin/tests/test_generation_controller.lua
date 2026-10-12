package.path = "sudoku.koplugin/?.lua;sudoku.koplugin/?/init.lua;" .. package.path
local Test = require("tests.testlib")
local Controller = require("sudoku.generation_controller")
Test.run({
    ["does not complete after cancellation"] = function()
        local completed = false
        local generator = { step=function() return false end, status=function() return {phase="Criando"} end }
        local controller = Controller.new(generator, {completed=function() completed=true end})
        controller:cancel(); controller:step()
        Test.falsy(completed)
        Test.truthy(controller.cancelled)
    end,
    ["notifies completion after generator finishes"] = function()
        local completed = false
        local generator = { step=function() return true end, result=function() return {id="x"} end, status=function() return {phase="Concluído"} end }
        local controller = Controller.new(generator, {completed=function() completed=true end})
        controller:step()
        Test.truthy(completed)
    end,
    ["cancels active generator exactly once without completing"] = function()
        local cancelled, completed, generator_cancels = 0, 0, 0
        local generator = {
            step=function() return false end,
            status=function() return {phase="Removendo",nodes=1} end,
            cancel=function() generator_cancels=generator_cancels+1; return true end,
        }
        local controller = Controller.new(generator, {
            cancelled=function() cancelled=cancelled+1 end,
            completed=function() completed=completed+1 end,
        })
        controller:step(1)
        Test.truthy(controller:cancel())
        Test.falsy(controller:cancel())
        controller:step(1)
        Test.equal(generator_cancels, 1)
        Test.equal(cancelled, 1)
        Test.equal(completed, 0)
    end,
})
