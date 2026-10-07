local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local Catalog = require("catalog.init")
local Session = require("sudoku.session")
local Board = require("sudoku.board")

local Sudoku = WidgetContainer:extend{ name = "sudoku" }

function Sudoku:init()
    self.ui.menu:registerToMainMenu(self)
end

function Sudoku:addToMainMenu(menu_items)
    menu_items.sudoku = {
        text = "Sudoku",
        sorting_hint = "games",
        callback = function() self:open_default_game() end,
    }
end

function Sudoku:open_default_game()
    local puzzle, err = Catalog.get("classic-01")
    if not puzzle then
        UIManager:show(InfoMessage:new{ text = "Não foi possível abrir o Sudoku: " .. err })
        return
    end
    self.session = Session.new(puzzle)
    self.board = Board.new(self.session)
    self.board:render()
end

return Sudoku
