local ButtonDialog = require("ui/widget/buttondialog")
local UIManager = require("ui/uimanager")
local Controller = require("sudoku.generation_controller")
local Dialog = {}
function Dialog.start(generator, callbacks)
    local dialog, controller
    local function tick()
        if controller:step(200) then return end
        UIManager:scheduleIn(0, tick)
    end
    controller = Controller.new(generator, {
        progress=function(state)
            if dialog then dialog:setTitle("Gerando\n" .. (state.phase or "Preparando")) end
        end,
        cancelled=function() if dialog then UIManager:close(dialog) end; if callbacks.cancelled then callbacks.cancelled() end end,
        completed=function(puzzle) if dialog then UIManager:close(dialog) end; if callbacks.completed then callbacks.completed(puzzle) end end,
    })
    dialog = ButtonDialog:new{title="Gerando\nCriando solução", dismissable=false, buttons={{{text="Cancelar", callback=function() controller:cancel() end}}}}
    UIManager:show(dialog)
    UIManager:scheduleIn(0, tick)
    return controller
end
return Dialog
