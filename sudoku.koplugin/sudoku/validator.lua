local Validator = {}

local function add(conflicts, cells)
    for _, cell_id in ipairs(cells) do conflicts[cell_id] = true end
end

function Validator.inspect(puzzle, values)
    local conflicts, filled = {}, true
    for _, cell_id in ipairs(puzzle:cell_ids()) do if values[cell_id] == nil then filled = false end end
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
                total = total + value
                if group.distinct and seen[value] then add(conflicts, { cell_id, seen[value] }) end
                seen[value] = cell_id
            else group_filled = false end
        end
        if total > group.target or (group_filled and total ~= group.target) then add(conflicts, group.cells) end
    end
    return { conflicts = conflicts, complete = filled, solved = filled and next(conflicts) == nil }
end

return Validator
