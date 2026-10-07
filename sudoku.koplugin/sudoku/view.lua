local View = {}
function View.cell_at(board, x, y)
    if x < board.x or y < board.y or x >= board.x + board.width or y >= board.y + board.height then return nil end
    local column = math.floor((x - board.x) / (board.width / board.columns)) + 1
    local row = math.floor((y - board.y) / (board.height / board.rows)) + 1
    return row .. ":" .. column
end
function View.symbol(value)
    if type(value) == "number" and value > 9 and value <= 16 then return string.char(string.byte("A") + value - 10) end
    return tostring(value)
end
function View.popup_choices(symbols)
    local choices = {}
    for _, value in ipairs(symbols) do
        choices[#choices + 1] = { label = View.symbol(value), value = value }
    end
    choices[#choices + 1] = { label = "Apagar", value = nil }
    return choices
end
function View.board_rows(session)
    local puzzle, rows = session.puzzle, {}
    for row = 1, puzzle.rows do
        local button_row = {}
        for column = 1, puzzle.columns do
            local cell_id = row .. ":" .. column
            local value = session.game.values[cell_id]
            button_row[#button_row + 1] = {
                cell_id = cell_id,
                text = value == nil and "·" or View.symbol(value),
                enabled = puzzle:given(cell_id) == nil,
            }
        end
        rows[#rows + 1] = button_row
    end
    return rows
end
return View
