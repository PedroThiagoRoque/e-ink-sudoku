local Validator = {}

local function add(conflicts, cells)
    for _, cell_id in ipairs(cells) do conflicts[cell_id] = true end
end

function Validator.inspect(puzzle, values)
    values = values or {}
    local conflicts, invalid, filled = {}, {}, true
    for _, cell_id in ipairs(puzzle:cell_ids()) do
        local value = values[cell_id]
        if value == nil then
            filled = false
        else
            if not puzzle:has_symbol(value) then invalid[cell_id] = true end
            local given = puzzle:given(cell_id)
            if given ~= nil and value ~= given then invalid[cell_id] = true end
        end
    end
    for cell_id in pairs(values) do if not puzzle.cells[cell_id] then invalid[cell_id] = true end end
    for _, unit in ipairs(puzzle.units) do
        local seen = {}
        for _, cell_id in ipairs(unit.cells) do
            local value = values[cell_id]
            if value then
                if seen[value] then add(conflicts, { cell_id, seen[value] }) else seen[value] = cell_id end
            end
        end
    end
    for _, group in ipairs(puzzle.sums) do
        local total, group_filled, seen = 0, true, {}
        for _, cell_id in ipairs(group.cells) do
            local value = values[cell_id]
            if value then
                if type(value) ~= "number" then
                    invalid[cell_id] = true
                    group_filled = false
                else
                    total = total + value
                end
                if group.distinct and seen[value] then add(conflicts, { cell_id, seen[value] }) end
                seen[value] = cell_id
            else group_filled = false end
        end
        if total > group.target or (group_filled and total ~= group.target) then add(conflicts, group.cells) end
    end
    return { conflicts = conflicts, invalid = invalid, complete = filled, solved = filled and next(conflicts) == nil and next(invalid) == nil }
end

return Validator
