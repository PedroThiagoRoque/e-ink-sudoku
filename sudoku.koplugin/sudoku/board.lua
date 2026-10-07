local ButtonDialog = require("ui/widget/buttondialog")
local UIManager = require("ui/uimanager")
local View = require("sudoku.view")

local Board = {}
Board.__index = Board

local mode_names = {
    classic = "Clássico", diagonal = "Diagonal", killer = "Killer",
    kakuro = "Kakuro", mega = "Mega", ["mini-4"] = "Mini 4×4",
    ["mini-6"] = "Mini 6×6", samurai = "Samurai",
}

function Board.new(session)
    return setmetatable({ session = session }, Board)
end

function Board:close()
    if self.dialog then UIManager:close(self.dialog); self.dialog = nil end
end

function Board:open_number_popup(cell_id)
    if not self.session:select(cell_id) then return end
    local popup
    local buttons, row = {}, {}
    for _, choice in ipairs(View.popup_choices(self.session.puzzle.symbols)) do
        local value, label = choice.value, choice.label
        row[#row + 1] = {
            text = label,
            callback = function()
                UIManager:close(popup)
                self.session:input(value)
                self:render()
            end,
        }
        if #row == 3 then buttons[#buttons + 1], row = row, {} end
    end
    if #row > 0 then buttons[#buttons + 1] = row end
    buttons[#buttons + 1] = {{ text = "Cancelar", callback = function() UIManager:close(popup) end }}
    popup = ButtonDialog:new{
        title = "Número para " .. cell_id,
        buttons = buttons,
        dismissable = true,
        width_factor = 0.82,
    }
    UIManager:show(popup)
end

function Board:render()
    self:close()
    local buttons = {}
    for _, source_row in ipairs(View.board_rows(self.session)) do
        local row = {}
        for _, cell in ipairs(source_row) do
            local cell_id = cell.cell_id
            row[#row + 1] = {
                text = cell.text,
                enabled = cell.enabled,
                callback = function() self:open_number_popup(cell_id) end,
            }
        end
        buttons[#buttons + 1] = row
    end
    local inspection = self.session:inspect()
    buttons[#buttons + 1] = {
        { text = "Desfazer", callback = function() self.session.game:undo(); self:render() end },
        { text = self.session.notes and "Notas: sim" or "Notas: não", callback = function() self.session.notes = not self.session.notes; self:render() end },
        { text = next(inspection.conflicts) and "Conflitos" or "Verificar", callback = function() self:render() end },
    }
    buttons[#buttons + 1] = {{ text = "Fechar", callback = function() self:close() end }}
    self.dialog = ButtonDialog:new{
        title = "Sudoku · " .. (mode_names[self.session.puzzle.mode] or self.session.puzzle.mode),
        buttons = buttons,
        width_factor = 0.98,
        rows_per_page = self.session.puzzle.rows + 2,
        dismissable = false,
    }
    UIManager:show(self.dialog)
end

return Board
