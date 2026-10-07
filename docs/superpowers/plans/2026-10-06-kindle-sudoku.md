# Sudoku para Kindle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar um plugin KOReader instalável, acionável por KUAL, que permita jogar offline todas as variantes especificadas no Kindle de 8ª geração.

**Architecture:** O núcleo Lua modela desafios como unidades de restrição e mantém o estado mutável da partida separado da interface. Um plugin KOReader adapta entradas e desenho a esse núcleo; catálogo, persistência e extensão KUAL ficam fora do motor para que sejam validados no computador e no aparelho separadamente.

**Tech Stack:** Lua 5.1/LuaJIT, framework de widgets do KOReader, scripts Lua de teste sem dependência externa, JSON para metadados KUAL.

**Spec:** `docs/superpowers/specs/2026-10-06-kindle-sudoku-design.md`

## Global Constraints

- O alvo principal é Kindle de 8ª geração com jailbreak; só declarar compatibilidade após teste físico na combinação de firmware e KOReader instalada.
- O jogo funciona offline e a interface e mensagens ficam em português.
- Não criar aplicativo de framebuffer independente; fornecer um plugin KOReader e a integração KUAL documentada.
- Catálogo inicial contém ao menos 10 desafios únicos para cada conjunto definido na especificação.
- Preservar progresso durante atualização e nunca interpretar conteúdo de desafio ou save como código.
- Usar teste primeiro para toda função de produção e registrar a execução no Kindle antes da distribuição.

## Review Focus

- Arquivo de save truncado ou com versão desconhecida deve preservar o original e oferecer recuperação; coberto pela Task 5.
- Células sobrepostas do Samurai devem ter um valor único e obedecer simultaneamente a duas grades; coberto pela Task 4.
- Sequências completas de Kakuro e grupos Killer devem rejeitar soma errada sem revelar a solução; coberto pela Task 3.
- Um ramo de refazer deve sumir quando uma jogada nova é aplicada após desfazer; coberto pela Task 2.
- A integração KUAL não pode abrir uma segunda instância do KOReader; coberto pela Task 7 no Kindle.

---

## Estrutura de arquivos

| Caminho | Responsabilidade |
| --- | --- |
| `sudoku.koplugin/_meta.lua` | Declaração do plugin para KOReader. |
| `sudoku.koplugin/main.lua` | Menu e ciclo de vida do plugin. |
| `sudoku.koplugin/sudoku/*.lua` | Modelo, regras, estado, persistência, catálogo e desenho, sem dependência circular. |
| `sudoku.koplugin/catalog/*.lua` | Desafios distribuídos, em dados declarativos. |
| `sudoku.koplugin/tests/*.lua` | Testes executáveis por Lua no computador. |
| `kual/sudoku/menu.json` | Entrada KUAL e script de lançamento idempotente. |
| `scripts/run-tests.sh` | Executa a suíte sem depender do Kindle. |
| `README.md` | Instalação, compatibilidade e recuperação de saves. |

### Task 1: Modelo de desafio e unidades de restrição

**Files:** criar `sudoku.koplugin/sudoku/puzzle.lua`, `sudoku.koplugin/sudoku/units.lua`, `sudoku.koplugin/tests/test_puzzle.lua`, `scripts/run-tests.sh`.

**Interfaces:** Produz `Puzzle.new(definition) -> puzzle, err`, `puzzle:cell_ids()`, `puzzle:units_for(cell_id)` e `puzzle:given(cell_id)`.

- [ ] Escrever testes vermelhos para Sudoku 9×9, Mini 6×6 e dados inválidos.
- [ ] Implementar validação declarativa de células, pistas e unidades sem repetição.
- [ ] Executar os testes da tarefa e a suíte completa.
- [ ] Registrar o resultado no ledger e criar commit quando o repositório permitir escrita em `.git`.

### Task 2: Estado de partida e histórico

**Files:** criar `sudoku.koplugin/sudoku/game.lua`, `sudoku.koplugin/tests/test_game.lua`.

**Interfaces:** Consome `Puzzle`; produz `Game.new(puzzle)`, `game:set_value`, `game:toggle_note`, `game:undo`, `game:redo`, `game:serialize` e `Game.restore`.

- [ ] Escrever testes vermelhos para pistas imutáveis, notas, desfazer/refazer e descarte do ramo após nova jogada.
- [ ] Implementar comandos imutáveis no histórico e serialização sem solução.
- [ ] Executar os testes da tarefa e a suíte completa.
- [ ] Registrar o resultado no ledger e criar commit quando possível.

### Task 3: Validador de restrições

**Files:** criar `sudoku.koplugin/sudoku/validator.lua`, `sudoku.koplugin/tests/test_validator.lua`.

**Interfaces:** Consome `Puzzle` e `Game`; produz `Validator.inspect(puzzle, values) -> { conflicts, complete, solved }`.

- [ ] Escrever testes vermelhos para clássico, diagonal, Killer e Kakuro.
- [ ] Implementar unidades, diagonais, somas e repetição em grupos e sequências.
- [ ] Executar os testes da tarefa e a suíte completa.
- [ ] Registrar o resultado no ledger e criar commit quando possível.

### Task 4: Definições de todos os modos e catálogo

**Files:** criar `sudoku.koplugin/catalog/init.lua`, `sudoku.koplugin/catalog/factories.lua`, `sudoku.koplugin/tests/test_catalog.lua`.

**Interfaces:** Produz `Catalog.list(mode)`, `Catalog.get(id)` e construtores para clássico, diagonal, Mini, Killer, Mega, Kakuro e Samurai.

- [ ] Escrever testes vermelhos para símbolos Mega, blocos Mini e identidade compartilhada no Samurai.
- [ ] Criar catálogo declarativo e validador de unicidade executado na preparação da distribuição.
- [ ] Incluir dez desafios por conjunto após o gerador/validador estar pronto.
- [ ] Executar os testes da tarefa e a suíte completa.

### Task 5: Persistência recuperável

**Files:** criar `sudoku.koplugin/sudoku/storage.lua`, `sudoku.koplugin/tests/test_storage.lua`.

**Interfaces:** Produz `Storage.save(path, record) -> ok, err` e `Storage.load(path, puzzle_id) -> record, recovery, err`.

- [ ] Escrever testes vermelhos para round trip, arquivo truncado, versão incompatível e backup.
- [ ] Implementar gravação temporária no mesmo diretório, substituição e cópia recuperável.
- [ ] Executar os testes da tarefa e a suíte completa.

### Task 6: Interface KOReader

**Files:** criar `sudoku.koplugin/sudoku/view.lua`, `sudoku.koplugin/sudoku/session.lua`, `sudoku.koplugin/main.lua`, `sudoku.koplugin/_meta.lua`.

**Interfaces:** Consome catálogo, `Game` e `Validator`; expõe menu, seleção, teclado, notas, verificação, redesenho e navegação de grades grandes.

- [ ] Escrever testes puros para mapeamento de toque/navegação antes de importar widgets KOReader.
- [ ] Implementar menu e sessão; adaptar o desenho e eventos às APIs verificadas da versão instalada.
- [ ] Validar abertura, toque, saída e suspensão no Kindle de 8ª geração.

### Task 7: KUAL, pacote e documentação

**Files:** criar `kual/sudoku/menu.json`, `kual/sudoku/launch.sh`, `README.md`, `scripts/package.sh`.

**Interfaces:** Produz arquivo `.koplugin` e extensão KUAL instaláveis por cópia.

- [ ] Escrever teste de estrutura de pacote e idempotência do lançador quando observável no computador.
- [ ] Implementar pacote, instruções de instalação, atualização, recuperação e tabela de versões testadas.
- [ ] Verificar no Kindle todas as variantes, salvamento, suspensão, legibilidade e caminho KUAL.

## Ordem de execução

As Tasks 1–3 formam o núcleo; Task 4 depende delas. Task 5 pode ser feita depois da Task 2. Task 6 depende de Tasks 1–5. Task 7 depende da Task 6 e da validação física. Se o ambiente não expuser APIs compatíveis do KOReader ou KUAL, registrar o bloqueio e manter o núcleo e a suíte de testes funcionais como entrega verificável.
