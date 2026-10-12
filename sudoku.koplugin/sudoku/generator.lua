local Difficulty = require("sudoku.difficulty")
local Factories = require("catalog.factories")
local Puzzle = require("sudoku.puzzle")
local Random = require("sudoku.random")
local Solver = require("sudoku.solver")

local Generator = {}
Generator.__index = Generator

local regular = {
    classic={size=9, br=3, bc=3},
    ["mini-4"]={size=4, br=2, bc=2},
    ["mini-6"]={size=6, br=2, bc=3},
    mega={size=16, br=4, bc=4},
}
local difficulties = {easy=true, medium=true, hard=true}

local function symbols(size)
    local result = {}
    for index = 1, size do result[index] = index <= 9 and index or string.char(55 + index) end
    return result
end

local function sequence(size)
    local result = {}; for index = 1, size do result[index] = index end; return result
end

local function count(map)
    local total = 0; for _ in pairs(map or {}) do total = total + 1 end; return total
end

local function ordered_by_groups(random, size, group_size)
    local result = {}
    local groups = random:shuffle(sequence(size / group_size))
    for _, group in ipairs(groups) do
        local offsets = random:shuffle(sequence(group_size))
        for _, offset in ipairs(offsets) do
            result[#result + 1] = (group - 1) * group_size + offset
        end
    end
    return result
end

function Generator.new(mode, difficulty, seed)
    local spec = regular[mode]
    if not spec then return nil, "modo não disponível nesta versão" end
    difficulty = difficulty or "medium"
    if not difficulties[difficulty] then return nil, "dificuldade desconhecida" end
    seed = math.floor(tonumber(seed) or os.time())
    local self = setmetatable({
        mode=mode, difficulty=difficulty, seed=seed, spec=spec,
        random=Random.new(seed), phase="Preparando", attempt=0, max_attempts=20,
        nodes=0, done=false, cancelled=false, puzzle=nil, error=nil,
    }, Generator)
    self:_start_attempt()
    return self
end

function Generator:_target_clues()
    local range = Difficulty.profiles[self.mode][self.difficulty]
    local target = math.floor((range[1] + range[2]) / 2)
    local total = self.spec.size * self.spec.size
    if (total - target) % 2 ~= 0 and self.spec.size % 2 == 0 then target = target - 1 end
    return math.max(range[1], target)
end

function Generator:_removal_groups()
    local size, seen, groups = self.spec.size, {}, {}
    for row = 1, size do
        for column = 1, size do
            local id = row..":"..column
            if not seen[id] then
                local mirror = (size + 1 - row)..":"..(size + 1 - column)
                local group = {id}; seen[id] = true
                if mirror ~= id then group[#group + 1] = mirror; seen[mirror] = true end
                groups[#groups + 1] = group
            end
        end
    end
    return self.random:shuffle(groups)
end

function Generator:_start_attempt()
    self.attempt = self.attempt + 1
    if self.attempt > self.max_attempts then
        self.done = true
        self.error = "não foi possível gerar o perfil solicitado"
        self.phase = "Falha"
        return
    end
    local spec = self.spec
    self.definition = Factories.grid(
        table.concat({self.mode, self.difficulty, self.seed, self.attempt}, "-"),
        self.mode, spec.size, spec.br, spec.bc, spec.size == 16 and symbols(16) or nil)
    self.definition.difficulty = self.difficulty
    self.definition.seed = self.seed
    self.definition.attempt = self.attempt
    self.solution_symbols = self.random:shuffle(self.definition.symbols)
    self.row_order = ordered_by_groups(self.random, spec.size, spec.br)
    self.column_order = ordered_by_groups(self.random, spec.size, spec.bc)
    self.fill_index = 1
    self.groups = nil
    self.group_index = 1
    self.target_clues = self:_target_clues()
    self.current_solver = nil
    self.current_group = nil
    self.phase = "Criando solução"
end

function Generator:_fill_one()
    local size, spec = self.spec.size, self.spec
    local logical_row = math.floor((self.fill_index - 1) / size) + 1
    local logical_column = ((self.fill_index - 1) % size) + 1
    local row, column = self.row_order[logical_row], self.column_order[logical_column]
    local index = ((row - 1) * spec.bc + math.floor((row - 1) / spec.br) + column - 1) % size + 1
    self.definition.givens[logical_row..":"..logical_column] = self.solution_symbols[index]
    self.fill_index = self.fill_index + 1
    self.nodes = self.nodes + 1
    if self.fill_index > size * size then
        self.groups = self:_removal_groups()
        self.phase = "Removendo pistas"
    end
end

function Generator:_begin_uniqueness_check()
    while self.group_index <= #self.groups do
        local group = self.groups[self.group_index]
        if count(self.definition.givens) - #group < self.target_clues then
            self.group_index = self.group_index + 1
        else
            self.current_group = {}
            for _, cell_id in ipairs(group) do
                self.current_group[#self.current_group + 1] = {id=cell_id, value=self.definition.givens[cell_id]}
                self.definition.givens[cell_id] = nil
            end
            local candidate, err = Puzzle.new(self.definition)
            if not candidate then
                self.error = err; self.done = true; self.phase = "Falha"; return
            end
            self.current_solver = Solver.new(candidate)
            self.phase = "Validando solução única"
            return
        end
    end
    self:_finish_or_retry()
end

function Generator:_complete_uniqueness_check()
    if self.current_solver:result().solutions ~= 1 then
        for _, removed in ipairs(self.current_group) do self.definition.givens[removed.id] = removed.value end
    end
    self.current_solver, self.current_group = nil, nil
    self.group_index = self.group_index + 1
    self.phase = "Removendo pistas"
end

function Generator:_finish_or_retry()
    local puzzle, err = Puzzle.new(self.definition)
    if not puzzle then self.done=true; self.error=err; self.phase="Falha"; return end
    local report = Difficulty.evaluate(puzzle)
    local matches = Difficulty.matches(self.mode, self.difficulty, report)
    if matches then
        self.definition.metrics = report
        self.puzzle = assert(Puzzle.new(self.definition))
        self.done = true
        self.phase = "Concluído"
    else
        self:_start_attempt()
    end
end

function Generator:step(node_budget)
    assert(type(node_budget) == "number" and node_budget >= 1 and node_budget % 1 == 0,
        "orçamento deve ser inteiro positivo")
    if self.done then return true end
    local consumed = 0
    while not self.done and consumed < node_budget do
        if self.phase == "Criando solução" then
            self:_fill_one(); consumed = consumed + 1
        elseif self.current_solver then
            local before = self.current_solver:result().nodes
            local finished = self.current_solver:step(node_budget - consumed)
            local used = self.current_solver:result().nodes - before
            consumed = consumed + used
            self.nodes = self.nodes + used
            if finished then self:_complete_uniqueness_check() end
            if used == 0 and not finished then break end
        elseif self.phase == "Removendo pistas" then
            if count(self.definition.givens) <= self.target_clues then self:_finish_or_retry()
            else self:_begin_uniqueness_check() end
        else
            break
        end
    end
    return self.done
end

function Generator:cancel()
    if self.done then return false end
    self.cancelled, self.done, self.error, self.phase = true, true, "geração cancelada", "Cancelado"
    return true
end

function Generator:status()
    return {phase=self.phase, attempt=self.attempt, nodes=self.nodes,
        progress=self.done and self.puzzle and 100 or nil}
end

function Generator:result()
    if self.puzzle then return self.puzzle end
    return nil, self.error
end

return Generator
