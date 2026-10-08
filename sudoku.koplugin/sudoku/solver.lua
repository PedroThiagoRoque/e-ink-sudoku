local Validator = require("sudoku.validator")

local Solver = {}
Solver.__index = Solver

local function copy(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

local function has_entries(value)
    return value and next(value) ~= nil
end

function Solver.new(puzzle, values, random)
    return setmetatable({
        puzzle = puzzle,
        values = copy(values or puzzle.givens),
        random = random,
        solutions = 0,
        first = nil,
        done = false,
        error = nil,
        nodes = 0,
        initialized = false,
        pending_expand = false,
        stack = {},
    }, Solver)
end

function Solver:candidates(cell_id)
    local out = {}
    local previous = self.values[cell_id]
    for _, value in ipairs(self.puzzle.symbols) do
        self.values[cell_id] = value
        local inspection = Validator.inspect(self.puzzle, self.values)
        if not has_entries(inspection.conflicts) and not has_entries(inspection.invalid) then
            out[#out + 1] = value
        end
    end
    self.values[cell_id] = previous
    return self.random and self.random:shuffle(out) or out
end

function Solver:_initialize()
    if self.initialized then return end
    self.initialized = true
    local inspection = Validator.inspect(self.puzzle, self.values)
    if has_entries(inspection.invalid) or has_entries(inspection.conflicts) then
        self.done = true
        self.error = "estado inicial inválido"
    elseif inspection.complete then
        if inspection.solved then
            self.solutions = 1
            self.first = copy(self.values)
        end
        self.done = true
    else
        self.pending_expand = true
    end
end

function Solver:_choose_cell()
    local best, choices
    for _, cell_id in ipairs(self.puzzle:cell_ids()) do
        if self.values[cell_id] == nil then
            local candidate = self:candidates(cell_id)
            if #candidate == 0 then return cell_id, candidate end
            if not choices or #candidate < #choices then best, choices = cell_id, candidate end
        end
    end
    return best, choices
end

function Solver:_record_terminal()
    local inspection = Validator.inspect(self.puzzle, self.values)
    if inspection.solved then
        self.solutions = self.solutions + 1
        self.first = self.first or copy(self.values)
        if self.solutions >= 2 then self.done = true end
    end
end

function Solver:_prepare_assignment()
    while not self.done do
        if self.pending_expand then
            self.pending_expand = false
            local cell_id, choices = self:_choose_cell()
            if cell_id and #choices > 0 then
                self.stack[#self.stack + 1] = {
                    cell_id = cell_id,
                    choices = choices,
                    next_choice = 1,
                    assigned = false,
                }
            elseif not cell_id then
                self:_record_terminal()
            end
        end

        if self.done then return nil end

        local frame = self.stack[#self.stack]
        while frame do
            if frame.assigned then
                self.values[frame.cell_id] = nil
                frame.assigned = false
            end
            if frame.next_choice <= #frame.choices then return frame end
            table.remove(self.stack)
            frame = self.stack[#self.stack]
        end
        self.done = true
    end
end

function Solver:_advance_one()
    local frame = self:_prepare_assignment()
    if not frame then return false end
    local value = frame.choices[frame.next_choice]
    frame.next_choice = frame.next_choice + 1
    frame.assigned = true
    self.values[frame.cell_id] = value
    self.nodes = self.nodes + 1
    self.pending_expand = true
    return true
end

function Solver:step(node_budget)
    assert(type(node_budget) == "number" and node_budget >= 1 and node_budget % 1 == 0,
        "orçamento deve ser inteiro positivo")
    self:_initialize()
    local consumed = 0
    while not self.done and consumed < node_budget do
        if self:_advance_one() then consumed = consumed + 1 end
    end
    return self.done
end

function Solver:result()
    return {
        solutions = self.solutions,
        solution = self.first,
        done = self.done,
        nodes = self.nodes,
        error = self.error,
    }
end

return Solver
