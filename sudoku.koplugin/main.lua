local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local ButtonDialog = require("ui/widget/buttondialog")
local DataStorage = require("datastorage")
local Catalog = require("catalog.init")
local Session = require("sudoku.session")
local Board = require("sudoku.board")
local Generator = require("sudoku.generator")
local GenerationDialog = require("sudoku.generation_dialog")
local SaveRepository = require("sudoku.save_repository")

local Sudoku = WidgetContainer:extend{ name = "sudoku" }

function Sudoku:init()
    self.ui.menu:registerToMainMenu(self)
    self.saves = SaveRepository.new(DataStorage:getDataDir() .. "/sudoku-saves")
    local request = io.open(self.path .. "/launch.request", "r")
    if request then
        local target = request:read("*l")
        request:close()
        os.remove(self.path .. "/launch.request")
        if target == "menu" then
            self.launch_callback = function()
                self.launch_callback = nil
                self:show_mode_menu(true)
            end
            UIManager:nextTick(self.launch_callback)
        end
    end
end

function Sudoku:addToMainMenu(menu_items)
    menu_items.sudoku = {
        text = "Sudoku",
        sorting_hint = "games",
        callback = function() self:show_mode_menu() end,
    }
end

function Sudoku:open_session(mode, session, on_close)
    session.game.on_change = function() self.saves:save(mode, session) end
    self.session = session
    self.board = Board.new(session, function() self.saves:save(mode, session) end, on_close)
    self.saves:save(mode, session)
    self.board:render()
end

function Sudoku:new_game(mode, on_close)
    local generator = Generator.new(mode, "easy", os.time())
    GenerationDialog.start(generator, {completed=function(puzzle)
        if puzzle then self:open_session(mode, Session.new(puzzle), on_close) end
    end})
end

function Sudoku:show_mode_menu(from_kual)
    local modes = {"classic", "diagonal", "mini-4", "mini-6", "killer", "kakuro", "mega", "samurai"}
    local buttons = {}
    for _, mode in ipairs(modes) do
        local current_mode = mode
        local saved = self.saves:load(current_mode)
        buttons[#buttons + 1] = {
            { text = current_mode, enabled = false },
            { text = saved and "Continuar" or "Novo jogo", callback = function()
                local close_koreader = from_kual and function() self.ui:onClose() end or nil
                if saved then self:open_session(current_mode, saved, close_koreader) else self:new_game(current_mode, close_koreader) end
            end },
            { text = "Novo", callback = function()
                local close_koreader = from_kual and function() self.ui:onClose() end or nil
                self:new_game(current_mode, close_koreader)
            end },
        }
    end
    UIManager:show(ButtonDialog:new{ title = "Sudoku", buttons = buttons, dismissable = true })
end

function Sudoku:onCloseWidget()
    if self.launch_callback then UIManager:unschedule(self.launch_callback) end
    if self.board then self.board:close(); self.board = nil end
end

function Sudoku:open_default_game()
    local puzzle, err = Catalog.get("classic-01")
    if not puzzle then
        UIManager:show(InfoMessage:new{ text = "Não foi possível abrir o Sudoku: " .. err })
        return
    end
    self:open_session("classic", Session.new(puzzle))
end

return Sudoku
