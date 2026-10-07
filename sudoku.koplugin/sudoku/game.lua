local Game = {}
Game.__index = Game

local function copy_values(values)
    local result = {}
    for key, value in pairs(values) do result[key] = value end
    return result
end

local function copy_notes(notes)
    local result = {}
    for cell_id, cell_notes in pairs(notes) do result[cell_id] = copy_values(cell_notes) end
    return result
end

local function snapshot(game)
    return { values = copy_values(game.values), notes = copy_notes(game.notes) }
end

local function restore_snapshot(game, state)
    game.values, game.notes = copy_values(state.values), copy_notes(state.notes)
end

function Game.new(puzzle)
    local values = copy_values(puzzle.givens)
    return setmetatable({ puzzle = puzzle, values = values, notes = {}, undo_stack = {}, redo_stack = {} }, Game)
end

function Game:_change(action)
    self.undo_stack[#self.undo_stack + 1] = snapshot(self)
    self.redo_stack = {}
    action()
    return true
end

function Game:set_value(cell_id, value)
    if not self.puzzle.cells[cell_id] then return nil, "célula inexistente" end
    if self.puzzle:given(cell_id) ~= nil then return nil, "pista não pode ser alterada" end
    if value ~= nil and not self.puzzle:has_symbol(value) then return nil, "símbolo inválido" end
    return self:_change(function()
        self.values[cell_id] = value
        self.notes[cell_id] = nil
    end)
end

function Game:toggle_note(cell_id, value)
    if not self.puzzle.cells[cell_id] then return nil, "célula inexistente" end
    if self.puzzle:given(cell_id) ~= nil or self.values[cell_id] ~= nil then return nil, "não é possível anotar nesta célula" end
    if not self.puzzle:has_symbol(value) then return nil, "símbolo inválido" end
    return self:_change(function()
        self.notes[cell_id] = self.notes[cell_id] or {}
        self.notes[cell_id][value] = not self.notes[cell_id][value] or nil
        if next(self.notes[cell_id]) == nil then self.notes[cell_id] = nil end
    end)
end

function Game:undo()
    local state = table.remove(self.undo_stack)
    if not state then return false end
    self.redo_stack[#self.redo_stack + 1] = snapshot(self)
    restore_snapshot(self, state)
    return true
end

function Game:redo()
    local state = table.remove(self.redo_stack)
    if not state then return false end
    self.undo_stack[#self.undo_stack + 1] = snapshot(self)
    restore_snapshot(self, state)
    return true
end

function Game:serialize()
    return { version = 1, puzzle_id = self.puzzle.id, values = copy_values(self.values), notes = copy_notes(self.notes), undo_stack = self.undo_stack, redo_stack = self.redo_stack }
end

function Game.restore(puzzle, record)
    if type(record) ~= "table" or record.version ~= 1 or record.puzzle_id ~= puzzle.id then return nil, "save incompatível" end
    local game = Game.new(puzzle)
    for cell_id, value in pairs(record.values or {}) do
        if not puzzle.cells[cell_id] or not puzzle:has_symbol(value) then return nil, "save inválido" end
        if puzzle:given(cell_id) == nil then game.values[cell_id] = value end
    end
    game.notes = copy_notes(record.notes or {})
    game.undo_stack, game.redo_stack = record.undo_stack or {}, record.redo_stack or {}
    return game
end

return Game
