# Geração procedural e retomada por modo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gerar desafios inéditos no Kindle e retomar uma partida independente por modo após reabrir o KOReader.

**Architecture:** Um PRNG reproduzível e um solver de restrições independente geram e validam desafios. Um repositório de saves armazena a definição completa e o estado por modo; controladores KOReader transformam o gerador em passos canceláveis e atualizam menu, carregamento e tabuleiro.

**Tech Stack:** Lua 5.1/LuaJIT, KOReader v2025.04, JSON local, testes Lua sem dependência externa.

**Spec:** `docs/superpowers/specs/2026-10-06-procedural-generation-and-saves-design.md`

## Global Constraints

- Gerar no Kindle, offline, sem congelar a interface e com cancelamento.
- Aceitar somente desafios com exatamente uma solução.
- Preservar uma partida por modo, incluindo definição, valores, notas, histórico, seleção e modo de notas.
- Manter intacto o save existente se a geração for cancelada ou falhar.
- Compatibilidade física declarada somente após validação no Kindle Basic 2, firmware 5.16.2.1.1 e KOReader v2025.04.

## Review Focus

- Solver para na segunda solução, evitando gasto infinito; teste na Task 2.
- Mesma semente produz mesma definição; teste na Task 1 e Task 3.
- Novo jogo não sobrescreve o save até a geração estar concluída; teste na Task 5.
- Save de um modo não afeta outro; teste na Task 4.
- Cancelamento entre passos não escreve arquivo parcial; teste na Task 6.

---

### Task 1: PRNG e serialização de desafio

**Files:** criar `sudoku.koplugin/sudoku/random.lua`, `sudoku.koplugin/sudoku/definition.lua`, `sudoku.koplugin/tests/test_random.lua`, `sudoku.koplugin/tests/test_definition.lua`.

**Interfaces:** Produz `Random.new(seed)`, `random:next_int(limit)`, `random:shuffle(values)`, `Definition.encode(puzzle)` e `Definition.decode(record)`.

- [ ] Escrever testes vermelhos para sequência reproduzível, embaralhamento e round trip de definição.
- [ ] Implementar PRNG local e conversão validada de `Puzzle` para dados de save.
- [ ] Executar testes da tarefa e suíte completa.

### Task 2: Solver incremental e contagem de soluções

**Files:** criar `sudoku.koplugin/sudoku/solver.lua`, `sudoku.koplugin/tests/test_solver.lua`.

**Interfaces:** Consome `Puzzle`; produz `Solver.new(puzzle, values, random)`, `solver:step(budget)` e `solver:result()` com `solutions` limitado a 2.

- [ ] Escrever testes vermelhos para zero, uma e múltiplas soluções e corte na segunda.
- [ ] Implementar candidatos, escolha por menor domínio e validação de unidades/somas.
- [ ] Executar testes da tarefa e suíte completa.

### Task 3: Geradores de grades

**Files:** criar `sudoku.koplugin/sudoku/generator.lua`, `sudoku.koplugin/tests/test_generator.lua`; modificar `catalog/factories.lua`.

**Interfaces:** Produz `Generator.new(mode, difficulty, seed)`, `generator:step(budget)`, `generator:status()` e `generator:result()`.

- [ ] Escrever testes vermelhos para desafio reproduzível, solução única e regras de Clássico, Diagonal, Mini e Mega.
- [ ] Implementar solução aleatória, remoção de pistas e perfis de dificuldade.
- [ ] Adicionar construtores Killer, Kakuro e Samurai, cada um validado pelo solver.
- [ ] Executar testes da tarefa e suíte completa.

### Task 4: Repositório de saves por modo

**Files:** criar `sudoku.koplugin/sudoku/save_repository.lua`, `sudoku.koplugin/tests/test_save_repository.lua`; modificar `storage.lua`, `session.lua`.

**Interfaces:** Produz `SaveRepository.new(directory)`, `repository:load(mode)`, `repository:save(mode, session, metadata)`, `repository:last_mode()` e `repository:set_last_mode(mode)`.

- [ ] Escrever testes vermelhos para retomada completa, isolamento de modos, backup e dados incompatíveis.
- [ ] Implementar diretórios, registros de última modalidade e reconstrução segura de puzzle/sessão.
- [ ] Executar testes da tarefa e suíte completa.

### Task 5: Fluxo de continuar e novo jogo

**Files:** modificar `main.lua`, `board.lua`; criar `sudoku.koplugin/sudoku/menu.lua`, `sudoku.koplugin/tests/test_menu.lua`.

**Interfaces:** Consome repositório e gerador; produz menu por modo, continuar e confirmação de substituição.

- [ ] Escrever testes vermelhos para decidir `Continuar`/`Novo jogo` e para não substituir save antes da conclusão.
- [ ] Implementar menu e callback de autosave em cada alteração de sessão.
- [ ] Executar testes da tarefa e suíte completa.

### Task 6: Controlador de geração no KOReader

**Files:** criar `sudoku.koplugin/sudoku/generation_controller.lua`, `sudoku.koplugin/tests/test_generation_controller.lua`; modificar `main.lua`.

**Interfaces:** Produz `GenerationController.new(generator, callbacks)`, `controller:step()` e `controller:cancel()`.

- [ ] Escrever testes vermelhos para progresso, cancelamento e conclusão sem gravação parcial.
- [ ] Implementar controlador puro e adaptador `UIManager:scheduleIn` com diálogo de carregamento e cancelar.
- [ ] Executar testes da tarefa, suíte completa e validação sintática Lua.

### Task 7: Validação e distribuição

**Files:** modificar `README.md`, `scripts/package.sh`, testes existentes e pacote.

- [ ] Adicionar roteiro de validação no Kindle para geração, cancelamento, suspensão e retomada nos oito conjuntos.
- [ ] Rodar toda a suíte, `luac -p`, gerar ZIP e inspecionar o arquivo.
- [ ] Registrar desempenho observado e versões reais após o teste físico.

## Self-review

As Tasks 1–2 definem os dados e a validação consumidos pela geração; Task 3 produz desafios que Task 4 persiste. Tasks 5–6 integram as duas camadas sem introduzir dependência do KOReader no núcleo. A validação física é explicitamente separada na Task 7, pois não pode ser simulada pelo ambiente local.
