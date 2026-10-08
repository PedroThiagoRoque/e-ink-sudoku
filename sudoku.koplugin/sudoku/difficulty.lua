local Validator = require("sudoku.validator")

local Difficulty = {}

local weights = {naked_single=1, hidden_single=2, locked_candidate=4, pair=6}
local ranks = {none=0, naked_single=1, hidden_single=2, locked_candidate=3, pair=4}
local clue_ranges = {
    classic={easy={38,45},medium={30,36},hard={24,30}},
    ["mini-4"]={easy={10,12},medium={7,9},hard={4,6}},
    ["mini-6"]={easy={24,28},medium={16,22},hard={10,15}},
    mega={easy={192,216},medium={144,176},hard={112,143}},
}

local function copy(source)
    local result = {}; for key, value in pairs(source or {}) do result[key] = value end; return result
end

local function count(map)
    local total = 0; for _ in pairs(map or {}) do total = total + 1 end; return total
end

local function has(candidates, value)
    return candidates and candidates[value] == true
end

local function set_key(values, symbols)
    local parts = {}
    for _, symbol in ipairs(symbols) do if values[symbol] then parts[#parts + 1] = type(symbol)..":"..tostring(symbol) end end
    return table.concat(parts, "|")
end

local function build_candidates(puzzle, values)
    local candidates = {}
    for _, cell_id in ipairs(puzzle:cell_ids()) do
        if values[cell_id] == nil then
            local available = {}
            for _, symbol in ipairs(puzzle.symbols) do available[symbol] = true end
            for _, unit in ipairs(puzzle:units_for(cell_id)) do
                for _, peer in ipairs(unit.cells) do
                    local value = values[peer]
                    if value ~= nil then available[value] = nil end
                end
            end
            candidates[cell_id] = available
        end
    end
    return candidates
end

local function assign(puzzle, values, candidates, cell_id, value)
    values[cell_id] = value
    candidates[cell_id] = nil
    for _, unit in ipairs(puzzle:units_for(cell_id)) do
        for _, peer in ipairs(unit.cells) do
            if candidates[peer] then candidates[peer][value] = nil end
        end
    end
end

local function first_candidate(symbols, values)
    for _, symbol in ipairs(symbols) do if values[symbol] then return symbol end end
end

local function in_cells(cells, needle)
    for _, value in ipairs(cells) do if value == needle then return true end end
    return false
end

function Difficulty.evaluate(puzzle)
    local values = copy(puzzle.givens)
    local candidates = build_candidates(puzzle, values)
    local report = {
        solved=false, guessed=false, score=0, hardest="none", steps={}, clue_count=count(puzzle.givens),
        counts={naked_single=0,hidden_single=0,locked_candidate=0,pair=0},
    }

    local function record(kind, detail)
        report.counts[kind] = report.counts[kind] + 1
        report.score = report.score + weights[kind]
        if ranks[kind] > ranks[report.hardest] then report.hardest = kind end
        report.steps[#report.steps + 1] = {technique=kind, detail=detail}
    end

    while true do
        local progressed = false

        for _, cell_id in ipairs(puzzle:cell_ids()) do
            local options = candidates[cell_id]
            if options and count(options) == 1 then
                local value = first_candidate(puzzle.symbols, options)
                assign(puzzle, values, candidates, cell_id, value)
                record("naked_single", cell_id)
                progressed = true
                break
            end
        end
        if progressed then goto continue end

        for _, unit in ipairs(puzzle.units) do
            if #unit.cells == #puzzle.symbols then
                for _, symbol in ipairs(puzzle.symbols) do
                    local only, occurrences = nil, 0
                    for _, cell_id in ipairs(unit.cells) do
                        if has(candidates[cell_id], symbol) then only, occurrences = cell_id, occurrences + 1 end
                    end
                    if occurrences == 1 then
                        assign(puzzle, values, candidates, only, symbol)
                        record("hidden_single", only)
                        progressed = true
                        break
                    end
                end
            end
            if progressed then break end
        end
        if progressed then goto continue end

        for _, unit in ipairs(puzzle.units) do
            if unit.kind == "block" then
                for _, symbol in ipairs(puzzle.symbols) do
                    local possible = {}
                    for _, cell_id in ipairs(unit.cells) do
                        if has(candidates[cell_id], symbol) then possible[#possible + 1] = cell_id end
                    end
                    if #possible >= 2 then
                        local first = puzzle.cells[possible[1]]
                        local same_row, same_column = first.row ~= nil, first.column ~= nil
                        for index = 2, #possible do
                            local cell = puzzle.cells[possible[index]]
                            same_row = same_row and cell.row == first.row
                            same_column = same_column and cell.column == first.column
                        end
                        local removed = false
                        if same_row or same_column then
                            for cell_id, options in pairs(candidates) do
                                local cell = puzzle.cells[cell_id]
                                local aligned = (same_row and cell.row == first.row) or (same_column and cell.column == first.column)
                                if aligned and not in_cells(unit.cells, cell_id) and options[symbol] then
                                    options[symbol] = nil; removed = true
                                end
                            end
                        end
                        if removed then record("locked_candidate", symbol); progressed = true; break end
                    end
                end
            end
            if progressed then break end
        end
        if progressed then goto continue end

        for _, unit in ipairs(puzzle.units) do
            local pair_groups = {}
            for _, cell_id in ipairs(unit.cells) do
                local options = candidates[cell_id]
                if options and count(options) == 2 then
                    local key = set_key(options, puzzle.symbols)
                    pair_groups[key] = pair_groups[key] or {cells={}, values=options}
                    pair_groups[key].cells[#pair_groups[key].cells + 1] = cell_id
                end
            end
            for _, pair in pairs(pair_groups) do
                if #pair.cells == 2 then
                    local removed = false
                    for _, cell_id in ipairs(unit.cells) do
                        if candidates[cell_id] and cell_id ~= pair.cells[1] and cell_id ~= pair.cells[2] then
                            for value in pairs(pair.values) do
                                if candidates[cell_id][value] then candidates[cell_id][value] = nil; removed = true end
                            end
                        end
                    end
                    if removed then record("pair", pair.cells); progressed = true; break end
                end
            end
            if progressed then break end
        end

        ::continue::
        if not progressed then break end
        for _, options in pairs(candidates) do if count(options) == 0 then report.guessed=true; return report end end
    end

    report.solved = Validator.inspect(puzzle, values).solved
    report.guessed = not report.solved
    return report
end

function Difficulty.matches(mode, profile, report)
    local profiles = clue_ranges[mode]
    local range = profiles and profiles[profile]
    if not range then return false, "perfil desconhecido" end
    if not report.solved or report.guessed then return false, "exige adivinhação" end
    if report.clue_count < range[1] or report.clue_count > range[2] then return false, "pistas fora da faixa" end
    if profile == "easy" then
        if ranks[report.hardest or "none"] > ranks.hidden_single then return false, "técnica acima do fácil" end
    elseif profile == "medium" then
        if (report.counts.locked_candidate or 0) + (report.counts.pair or 0) < 1 then return false, "sem técnica intermediária" end
        if ranks[report.hardest or "none"] > ranks.pair then return false, "técnica acima do médio" end
    elseif profile == "hard" and (report.counts.pair or 0) < 2 then
        return false, "sem pares suficientes"
    end
    return true
end

Difficulty.profiles = clue_ranges

return Difficulty
