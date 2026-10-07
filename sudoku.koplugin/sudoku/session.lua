local Game = require("sudoku.game")
local Validator = require("sudoku.validator")
local Session = {}
Session.__index = Session
function Session.new(puzzle) return setmetatable({ puzzle = puzzle, game = Game.new(puzzle), selected = nil, notes = false }, Session) end
function Session:select(cell_id) if self.puzzle.cells[cell_id] then self.selected = cell_id; return true end return false end
function Session:input(value)
    if not self.selected then return nil, "selecione uma célula" end
    if self.notes then return self.game:toggle_note(self.selected, value) end
    return self.game:set_value(self.selected, value)
end
function Session:inspect() return Validator.inspect(self.puzzle, self.game.values) end
return Session
