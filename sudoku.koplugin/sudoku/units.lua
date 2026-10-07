local Units = {}

function Units.grid(rows, columns, block_rows, block_columns)
    local units = {}
    for row = 1, rows do
        local cells = {}
        for column = 1, columns do cells[#cells + 1] = row .. ":" .. column end
        units[#units + 1] = { kind = "row", cells = cells }
    end
    for column = 1, columns do
        local cells = {}
        for row = 1, rows do cells[#cells + 1] = row .. ":" .. column end
        units[#units + 1] = { kind = "column", cells = cells }
    end
    if block_rows and block_columns then
        for first_row = 1, rows, block_rows do
            for first_column = 1, columns, block_columns do
                local cells = {}
                for row = first_row, first_row + block_rows - 1 do
                    for column = first_column, first_column + block_columns - 1 do
                        cells[#cells + 1] = row .. ":" .. column
                    end
                end
                units[#units + 1] = { kind = "block", cells = cells }
            end
        end
    end
    return units
end

return Units
