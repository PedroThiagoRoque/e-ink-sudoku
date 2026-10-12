local Controller = {}
Controller.__index = Controller
function Controller.new(generator, callbacks)
    return setmetatable({generator=generator, callbacks=callbacks or {}, cancelled=false, done=false}, Controller)
end
function Controller:cancel()
    if self.done then return false end
    self.cancelled=true; self.done=true
    if self.generator.cancel then self.generator:cancel() end
    if self.callbacks.cancelled then self.callbacks.cancelled() end
    return true
end
function Controller:step(budget)
    if self.cancelled or self.done then return true end
    local finished=self.generator:step(budget or 100)
    if self.callbacks.progress then self.callbacks.progress(self.generator:status()) end
    if finished then
        self.done=true
        if self.callbacks.completed then self.callbacks.completed(self.generator:result()) end
    end
    return self.done
end
return Controller
