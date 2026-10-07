# Reliable Full-Screen Sudoku Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a reliable, full-screen, offline Kindle Sudoku with Classic, Mini 4×4, Mini 6×6, and Mega 16×16, magazine-medium generation, safe saves, and responsive cancellation.

**Architecture:** A validated constraint model feeds an incremental solver, logical difficulty evaluator, and cooperative regular-grid generator. An application controller owns menu/generation/game transitions, while a pure layout/presentation layer drives a full-screen KOReader `InputContainer`; versioned persistence and distribution checks protect user data and installation.

**Tech Stack:** Lua 5.1/LuaJIT, KOReader v2025.04 widget/UIManager APIs, framebuffer drawing through `ffi/blitbuffer`, POSIX shell, Python 3 `unittest` for KUAL/package boundaries.

**Spec:** `docs/superpowers/specs/2026-10-07-reliable-sudoku-fullscreen-design.md`

## Global Constraints

- Target Kindle Basic 2 (8th generation), firmware 5.16.2.1.1, KOReader v2025.04.
- Remain offline and add no runtime dependency outside KOReader and standard Lua 5.1/LuaJIT facilities.
- Ship only Classic 9×9, Mini 4×4, Mini 6×6, and Mega 16×16 in the menu.
- Default difficulty is Medium; Classic Medium has 30–36 clues, exactly one solution, and requires no guessing.
- A generator or solver step must honor its node budget and return control to KOReader.
- Opening the game clears the entire screen to white; structural transitions use full refresh and moves use bounded partial refresh.
- Never overwrite a prior save until a new puzzle or temporary save has passed full validation.
- Preserve unrelated working-tree changes and commit only files named by the active task.
- Do not claim physical compatibility until the device checklist has been run on the target Kindle.

## Review Focus

- Sparse notes (`2`, `9`, and Mega `A`–`G`) must round-trip without `null`, loss, or invalid saves; Task 5 pins this.
- Fully filled contradictory grids and out-of-alphabet values must never count as solutions; Tasks 1–2 pin this.
- Cancel during active generation—not merely before it—must stop future work without replacing a save; Tasks 4 and 6 pin this.
- Write, close, and rename failures must keep the previous save recoverable and surface an error; Task 5 pins this.
- Taps on board/key/action boundaries at 600×800 and 758×1024 must route to exactly one target; Task 7 pins this.

---

## File Structure

| Path | Responsibility |
| --- | --- |
| `sudoku.koplugin/sudoku/puzzle.lua` | Validate and own immutable puzzle definitions. |
| `sudoku.koplugin/sudoku/validator.lua` | Validate values and report completion/conflicts. |
| `sudoku.koplugin/sudoku/solver.lua` | Incremental uniqueness search with a real node budget. |
| `sudoku.koplugin/sudoku/difficulty.lua` | Logical technique evaluator and profiles. |
| `sudoku.koplugin/sudoku/generator.lua` | Cooperative regular-grid solution/removal state machine. |
| `sudoku.koplugin/sudoku/storage.lua` | Strict JSON-compatible encoding and recoverable file writes. |
| `sudoku.koplugin/sudoku/save_repository.lua` | Versioned session serialization, migration, and validation. |
| `sudoku.koplugin/sudoku/app_controller.lua` | Own menu, generation, board, save, errors, and shutdown. |
| `sudoku.koplugin/sudoku/screen_layout.lua` | Pure geometry and hit-testing for all supported sizes. |
| `sudoku.koplugin/sudoku/presenter.lua` | Pure display model for cells, notes, conflicts, and actions. |
| `sudoku.koplugin/sudoku/fullscreen_board.lua` | KOReader full-screen painting, gestures, and refresh regions. |
| `sudoku.koplugin/main.lua` | Plugin registration, KUAL request handoff, controller construction. |
| `scripts/run-tests.sh` | Complete local verification entry point. |
| `scripts/package.sh` | Root-extractable plugin and KUAL packages. |

### Task 1: Strict Puzzle Model, Validator, and PRNG

**Files:**
- Modify: `sudoku.koplugin/sudoku/puzzle.lua`
- Modify: `sudoku.koplugin/sudoku/validator.lua`
- Modify: `sudoku.koplugin/sudoku/definition.lua`
- Modify: `sudoku.koplugin/sudoku/random.lua`
- Test: `sudoku.koplugin/tests/test_puzzle.lua`
- Test: `sudoku.koplugin/tests/test_validator.lua`
- Test: `sudoku.koplugin/tests/test_random.lua`
- Create: `sudoku.koplugin/tests/test_definition.lua`

**Interfaces:**
- Produces: `Puzzle.new(definition) -> puzzle | nil, error` with deep-owned `symbols`, `units`, `sums`, and `block`.
- Produces: `Validator.inspect(puzzle, values) -> { conflicts, invalid, complete, solved }`.
- Produces: `Definition.encode(puzzle) -> plain_table` and `Definition.decode(record) -> puzzle | nil, error`.
- Produces: `Random.new(seed)` where state is always in `1..2147483646`; `next_int(limit)` rejects non-positive limits.

- [ ] **Step 1: Write failing model tests**

Add cases that reject duplicate symbols, invalid dimensions/block geometry, units with missing cells, sums with missing/duplicate cells or non-numeric targets, conflicting/out-of-alphabet givens, and unsupported modes. Assert encoded mutations cannot mutate the source puzzle.

- [ ] **Step 2: Run model tests and verify RED**

Run: `lua sudoku.koplugin/tests/test_puzzle.lua && lua sudoku.koplugin/tests/test_validator.lua && lua sudoku.koplugin/tests/test_definition.lua`

Expected: FAIL on accepted malformed definitions, invalid values reported solved, or missing `test_definition.lua`.

- [ ] **Step 3: Implement strict construction and value validation**

Deep-copy all definition collections, validate the four supported regular-grid modes, validate every referenced cell/symbol, and make `Validator.inspect` mark unknown values and changed givens invalid before checking units.

- [ ] **Step 4: Write and run failing PRNG edge tests**

Assert seeds `0`, `2147483647`, and negative values produce a non-degenerate reproducible sequence; assert `next_int(0)` fails with a clear message.

Run: `lua sudoku.koplugin/tests/test_random.lua`

Expected: FAIL because seed zero remains stuck and limit zero is unchecked.

- [ ] **Step 5: Normalize PRNG seeds and verify the task**

Run: `lua sudoku.koplugin/tests/test_puzzle.lua && lua sudoku.koplugin/tests/test_validator.lua && lua sudoku.koplugin/tests/test_definition.lua && lua sudoku.koplugin/tests/test_random.lua`

Expected: all listed tests pass.

- [ ] **Step 6: Commit Task 1**

```bash
git add sudoku.koplugin/sudoku/puzzle.lua sudoku.koplugin/sudoku/validator.lua sudoku.koplugin/sudoku/definition.lua sudoku.koplugin/sudoku/random.lua sudoku.koplugin/tests/test_puzzle.lua sudoku.koplugin/tests/test_validator.lua sudoku.koplugin/tests/test_definition.lua sudoku.koplugin/tests/test_random.lua
git commit -m "fix: validate sudoku definitions and values"
```

### Task 2: Incremental Constraint Solver

**Files:**
- Modify: `sudoku.koplugin/sudoku/solver.lua`
- Modify: `sudoku.koplugin/tests/test_solver.lua`

**Interfaces:**
- Consumes: strict `Puzzle` and `Validator` from Task 1.
- Produces: `Solver.new(puzzle, values?, random?) -> solver`.
- Produces: `solver:step(node_budget) -> finished_boolean` and rejects budgets below one.
- Produces: `solver:result() -> { done, solutions, solution, nodes, error? }`, stopping at two solutions.

- [ ] **Step 1: Write failing solver correctness tests**

Add cases for zero solutions, one solution, two-or-more solutions, contradictory filled givens, out-of-alphabet initial values, and sum constraints. Assert invalid terminal states report zero solutions.

- [ ] **Step 2: Write failing budget/resume tests**

For a puzzle requiring multiple decisions, assert `step(1)` returns `false`, increments nodes by at most one, preserves search state, and repeated calls eventually match the one-shot solution count.

- [ ] **Step 3: Run solver tests and verify RED**

Run: `lua sudoku.koplugin/tests/test_solver.lua`

Expected: FAIL because the current solver finishes in one call and certifies contradictory filled input.

- [ ] **Step 4: Implement explicit-stack incremental search**

Replace recursive `search` with retained frames containing selected cell, candidate list, next candidate, and rollback data. Use puzzle indexes for affected constraints, count one attempted assignment as one node, and validate the initial and terminal states.

- [ ] **Step 5: Verify solver and dependent tests**

Run: `lua sudoku.koplugin/tests/test_solver.lua && lua sudoku.koplugin/tests/test_validator.lua`

Expected: all tests pass; no single call exceeds its node budget.

- [ ] **Step 6: Commit Task 2**

```bash
git add sudoku.koplugin/sudoku/solver.lua sudoku.koplugin/tests/test_solver.lua
git commit -m "feat: make sudoku solver incremental"
```

### Task 3: Human-Logic Difficulty Evaluator

**Files:**
- Create: `sudoku.koplugin/sudoku/difficulty.lua`
- Create: `sudoku.koplugin/tests/test_difficulty.lua`

**Interfaces:**
- Consumes: validated regular-grid `Puzzle` from Task 1.
- Produces: `Difficulty.evaluate(puzzle) -> { solved, guessed, score, hardest, steps, clue_count }`.
- Produces: `Difficulty.matches(mode, profile, report) -> boolean, reason` for `easy`, `medium`, and `hard`.
- Profile rule: Classic Medium has 30–36 clues, no guess, and requires at least one locked-candidate or pair step; hardest allowed technique is pair.
- Scoring rule per productive step: naked single `1`, hidden single `2`, locked candidate `4`, pair `6`.
- Initial clue ranges: Classic `38–45/30–36/24–30`, Mini 4×4 `10–12/7–9/4–6`, Mini 6×6 `24–28/16–22/10–15`, Mega `192–216/144–176/112–143` for Easy/Medium/Hard respectively.
- Easy permits only singles; Medium must use a locked candidate or pair; Hard must use at least two pair steps. All profiles forbid guessing.

- [ ] **Step 1: Add failing technique fixture tests**

Add fixed Classic fixtures demonstrating naked single, hidden single, locked candidate, and pair. Assert the reported hardest technique and deterministic score for each fixture.

- [ ] **Step 2: Add failing Medium profile tests**

Assert a 30–36-clue logical puzzle requiring locked candidates or a pair matches Medium; a singles-only puzzle, a puzzle requiring guessing, and puzzles outside 30–36 do not.

- [ ] **Step 3: Run evaluator tests and verify RED**

Run: `lua sudoku.koplugin/tests/test_difficulty.lua`

Expected: FAIL because the module does not exist.

- [ ] **Step 4: Implement deterministic logical evaluation**

Apply techniques in fixed order—naked singles, hidden singles, locked candidates, pairs—recording eliminations and assignments without invoking the backtracking solver. Define Easy/Medium/Hard profile tables per supported mode; describe Mini/Mega as relative profiles, not magazine equivalents.

- [ ] **Step 5: Verify Task 3**

Run: `lua sudoku.koplugin/tests/test_difficulty.lua && lua sudoku.koplugin/tests/test_solver.lua`

Expected: all tests pass and fixtures receive stable reports.

- [ ] **Step 6: Commit Task 3**

```bash
git add sudoku.koplugin/sudoku/difficulty.lua sudoku.koplugin/tests/test_difficulty.lua
git commit -m "feat: evaluate human sudoku difficulty"
```

### Task 4: Cooperative Regular-Grid Generator

**Files:**
- Modify: `sudoku.koplugin/sudoku/generator.lua`
- Modify: `sudoku.koplugin/sudoku/generation_controller.lua`
- Modify: `sudoku.koplugin/tests/test_generator.lua`
- Modify: `sudoku.koplugin/tests/test_generation_controller.lua`

**Interfaces:**
- Consumes: `Solver` from Task 2 and `Difficulty` from Task 3.
- Produces: `Generator.new(mode, difficulty, seed) -> generator | nil, error` for the four supported modes only.
- Produces: `generator:step(node_budget) -> finished_boolean` and `generator:cancel()`.
- Produces: `generator:status() -> { phase, attempt, nodes, progress? }` and `generator:result() -> puzzle | nil, error`.
- Produces: `Controller:cancel()` that cancels the generator, calls `cancelled` once, and prevents completion.

- [ ] **Step 1: Replace weak generator tests with failing acceptance tests**

For fixed seeds in all four modes, assert dimensions, block geometry, clue count below total cells, validity, exact uniqueness, complete-definition reproducibility, and mode/difficulty/seed metadata. Assert unknown mode/difficulty returns an error instead of Classic fallback.

- [ ] **Step 2: Add failing cooperation and cancellation tests**

Assert `step(1)` cannot complete a Medium Classic generation, each call advances at most its budget, status phase changes, and cancelling after work has begun prevents a result and preserves the old-save callback sentinel.

- [ ] **Step 3: Run generator tests and verify RED**

Run: `lua sudoku.koplugin/tests/test_generator.lua && lua sudoku.koplugin/tests/test_generation_controller.lua`

Expected: FAIL on fallback, full completion in one step, missing metadata, and cancellation during work.

- [ ] **Step 4: Implement cooperative generation state machine**

Create solution, removal, uniqueness, difficulty, retry, and final-validation states. Randomize valid row/column bands and symbols, prefer symmetric removal, retain child solver work between calls, and cap attempts with an explicit error.

- [ ] **Step 5: Verify generation determinism and profiles**

Run: `lua sudoku.koplugin/tests/test_generator.lua && lua sudoku.koplugin/tests/test_generation_controller.lua && lua sudoku.koplugin/tests/test_difficulty.lua`

Expected: all tests pass; fixed Classic Medium fixtures have 30–36 clues and match the Medium profile.

- [ ] **Step 6: Commit Task 4**

```bash
git add sudoku.koplugin/sudoku/generator.lua sudoku.koplugin/sudoku/generation_controller.lua sudoku.koplugin/tests/test_generator.lua sudoku.koplugin/tests/test_generation_controller.lua
git commit -m "feat: generate supported sudoku modes cooperatively"
```

### Task 5: Versioned and Recoverable Saves

**Files:**
- Modify: `sudoku.koplugin/sudoku/storage.lua`
- Modify: `sudoku.koplugin/sudoku/game.lua`
- Modify: `sudoku.koplugin/sudoku/session.lua`
- Modify: `sudoku.koplugin/sudoku/save_repository.lua`
- Modify: `sudoku.koplugin/tests/test_storage.lua`
- Modify: `sudoku.koplugin/tests/test_game.lua`
- Modify: `sudoku.koplugin/tests/test_save_repository.lua`

**Interfaces:**
- Produces: `Storage.encode(record) -> text | nil, error`, `Storage.decode(text) -> record | nil, error` for direct testing.
- Produces: `Storage.save(path, record, io_adapter?) -> true | nil, error` with verified temporary write and rollback.
- Produces: `Repo:save(mode, session) -> true | nil, error` using schema version 2.
- Produces: `Repo:load(mode) -> session | nil, error, recovery_source?`, migrating valid version-1 saves.
- Produces: exactly one `Game.on_change(game, action)` callback for value, note, undo, and redo.

- [ ] **Step 1: Add failing serialization and migration tests**

Round-trip notes `{2}`, `{9}`, and `{"A","G"}`, selection, notes mode, undo, and redo. Assert no encoded text contains unintended `[null]`; assert a valid v1 record migrates and malformed history is rejected without deleting files.

- [ ] **Step 2: Add failing I/O fault tests**

With an injected adapter, simulate write, flush/close, temporary reread, first rename, and promotion failures. Assert `save` returns an error and the prior current or backup remains loadable in every case.

- [ ] **Step 3: Add failing change-notification tests**

Assert value, note, undo, and redo each emit one callback; invalid/no-op commands emit none. Assert close-triggered save does not duplicate an already persisted command.

- [ ] **Step 4: Run persistence tests and verify RED**

Run: `lua sudoku.koplugin/tests/test_storage.lua && lua sudoku.koplugin/tests/test_game.lua && lua sudoku.koplugin/tests/test_save_repository.lua`

Expected: FAIL on sparse notes, undo notification, duplicate-save contract, and simulated I/O errors.

- [ ] **Step 5: Implement schema v2 and safe write rotation**

Encode notes as ordered symbol arrays, strictly validate decoded state and snapshots, check every I/O result, validate the temporary file before rotating, and restore `.bak` when promotion fails.

- [ ] **Step 6: Verify Task 5**

Run: `lua sudoku.koplugin/tests/test_storage.lua && lua sudoku.koplugin/tests/test_game.lua && lua sudoku.koplugin/tests/test_save_repository.lua`

Expected: all tests pass, including injected failures and v1 migration.

- [ ] **Step 7: Commit Task 5**

```bash
git add sudoku.koplugin/sudoku/storage.lua sudoku.koplugin/sudoku/game.lua sudoku.koplugin/sudoku/session.lua sudoku.koplugin/sudoku/save_repository.lua sudoku.koplugin/tests/test_storage.lua sudoku.koplugin/tests/test_game.lua sudoku.koplugin/tests/test_save_repository.lua
git commit -m "fix: make sudoku saves recoverable"
```

### Task 6: Application Controller and Responsive Flow

**Files:**
- Create: `sudoku.koplugin/sudoku/app_controller.lua`
- Modify: `sudoku.koplugin/sudoku/generation_dialog.lua`
- Modify: `sudoku.koplugin/main.lua`
- Create: `sudoku.koplugin/tests/test_app_controller.lua`
- Create: `sudoku.koplugin/tests/test_generation_dialog.lua`

**Interfaces:**
- Consumes: cooperative generator from Task 4 and repository from Task 5.
- Produces: `AppController.new{ui, path, repository, screen_factory, dialog_factory, from_kual}`.
- Produces: `show_menu()`, `start_new(mode, difficulty)`, `continue(mode)`, `cancel_generation()`, `close_game()`, and `shutdown()`.
- Produces: `GenerationDialog.start(generator, callbacks) -> handle` with `handle:cancel()` and `handle:close()` that unschedule its exact tick function.

- [ ] **Step 1: Add failing controller transition tests**

Using fake UI/repository/screen, assert only four supported modes appear, Medium is default, old save is queried at click time, menu closes before generation/game opens, replacement requires confirmation, and a validated result is saved before screen display.

- [ ] **Step 2: Add failing lifecycle/error tests**

Assert cancel during generation leaves the previous save untouched; save/generation errors show a message; shutdown closes menu, generation, screen, and popup handles; KUAL exit uses the controller completion callback rather than a captured stale widget.

- [ ] **Step 3: Run controller/dialog tests and verify RED**

Run: `lua sudoku.koplugin/tests/test_app_controller.lua && lua sudoku.koplugin/tests/test_generation_dialog.lua`

Expected: FAIL because ownership and cancellation handles do not exist.

- [ ] **Step 4: Implement controller ownership and generation scheduling**

Move flow decisions out of `main.lua`, retain every widget/task handle, schedule bounded generator steps only after the loading widget can repaint, and funnel save failures through one visible error callback.

- [ ] **Step 5: Verify Task 6**

Run: `lua sudoku.koplugin/tests/test_app_controller.lua && lua sudoku.koplugin/tests/test_generation_dialog.lua && lua sudoku.koplugin/tests/test_generation_controller.lua`

Expected: all tests pass and no fake UI widget/task remains active after shutdown.

- [ ] **Step 6: Commit Task 6**

```bash
git add sudoku.koplugin/sudoku/app_controller.lua sudoku.koplugin/sudoku/generation_dialog.lua sudoku.koplugin/main.lua sudoku.koplugin/tests/test_app_controller.lua sudoku.koplugin/tests/test_generation_dialog.lua
git commit -m "feat: coordinate sudoku lifecycle safely"
```

### Task 7: Pure Full-Screen Layout and Presentation

**Files:**
- Create: `sudoku.koplugin/sudoku/screen_layout.lua`
- Create: `sudoku.koplugin/sudoku/presenter.lua`
- Replace: `sudoku.koplugin/sudoku/view.lua`
- Create: `sudoku.koplugin/tests/test_screen_layout.lua`
- Modify: `sudoku.koplugin/tests/test_view.lua`

**Interfaces:**
- Produces: `Layout.compute(width, height, rows, columns, symbols) -> layout` with `header`, `board`, `cells`, `keys`, and `actions` rectangles.
- Produces: `Layout.hit_test(layout, x, y) -> { kind, id? } | nil` using half-open rectangle bounds.
- Produces: `Presenter.build(session, inspection) -> { cells, selected, keys, actions, status }` including clue/input/note/conflict styles.

- [ ] **Step 1: Add failing geometry and boundary tests**

For 600×800 and 758×1024, test 4×4, 6×6, 9×9, and 16×16 layouts. Assert board is square and inside the screen; controls do not overlap; every first/last cell center maps correctly; each shared boundary maps to exactly one target; points outside map to nil.

- [ ] **Step 2: Add failing presentation tests**

Assert givens and user values have different styles, notes are ordered and visible, selected/conflicting cells carry flags, Mega keys contain `1..9,A..G`, note-mode erase clears notes, and solved/incomplete/conflict statuses differ.

- [ ] **Step 3: Run pure UI tests and verify RED**

Run: `lua sudoku.koplugin/tests/test_screen_layout.lua && lua sudoku.koplugin/tests/test_view.lua`

Expected: FAIL because layout/presenter interfaces do not exist and current view ignores notes/conflicts.

- [ ] **Step 4: Implement geometry and display models**

Compute sizes from actual screen dimensions, reserve a two-row Mega keyboard, center Mini boards, use cell IDs from the puzzle coordinates, and keep all output free of KOReader imports for headless tests.

- [ ] **Step 5: Verify Task 7**

Run: `lua sudoku.koplugin/tests/test_screen_layout.lua && lua sudoku.koplugin/tests/test_view.lua`

Expected: all geometry, boundary, symbol, note, and status tests pass.

- [ ] **Step 6: Commit Task 7**

```bash
git add sudoku.koplugin/sudoku/screen_layout.lua sudoku.koplugin/sudoku/presenter.lua sudoku.koplugin/sudoku/view.lua sudoku.koplugin/tests/test_screen_layout.lua sudoku.koplugin/tests/test_view.lua
git commit -m "feat: model full-screen sudoku presentation"
```

### Task 8: KOReader Full-Screen Board

**Files:**
- Create: `sudoku.koplugin/sudoku/fullscreen_board.lua`
- Remove: `sudoku.koplugin/sudoku/board.lua`
- Modify: `sudoku.koplugin/sudoku/app_controller.lua`
- Create: `sudoku.koplugin/tests/test_fullscreen_board.lua`

**Interfaces:**
- Consumes: `Layout` and `Presenter` from Task 7.
- Produces: `FullScreenBoard.new{session, on_command, on_exit, full_refresh_every?}` as a KOReader `InputContainer`.
- Produces: `paintTo(bb, x, y)`, `onTap(_, gesture)`, `refresh(region?, full?)`, `redraw_full()`, and `close()`.
- Commands emitted: `{type="select", cell_id}`, `{type="input", value}`, `erase`, `toggle_notes`, `undo`, `redo`, `verify`, `redraw`, and `exit`.

- [ ] **Step 1: Add failing headless paint tests**

Stub Screen, UIManager, fonts, and blitbuffer. Assert the first paint is a white rectangle covering the complete screen before any other drawing; block lines are thicker; clues, entries, notes, selection, and conflicts produce distinct drawing commands.

- [ ] **Step 2: Add failing gesture/refresh tests**

Route representative cell, key, action, edge, and outside taps through the real widget. Assert a move dirties only bounded regions, structural changes use full refresh, periodic threshold triggers full refresh, and **Redesenhar** always requests full refresh.

- [ ] **Step 3: Add failing cleanup tests**

Assert `close()` is idempotent, removes the widget, releases text widgets/resources, and leaves no scheduled refresh callbacks.

- [ ] **Step 4: Run board tests and verify RED**

Run: `lua sudoku.koplugin/tests/test_fullscreen_board.lua`

Expected: FAIL because the full-screen widget does not exist.

- [ ] **Step 5: Implement the KOReader widget**

Use v2025.04 `InputContainer`, full-screen `GestureRange`, `TextWidget`/font metrics, `Blitbuffer.COLOR_WHITE/BLACK`, and `UIManager:setDirty`. Paint an opaque white background first and use the pure layout for all hit-testing.

- [ ] **Step 6: Integrate commands through AppController and verify UI tests**

Run: `lua sudoku.koplugin/tests/test_fullscreen_board.lua && lua sudoku.koplugin/tests/test_app_controller.lua && lua sudoku.koplugin/tests/test_view.lua`

Expected: all tests pass, including exit and save-error behavior.

- [ ] **Step 7: Commit Task 8**

```bash
git add sudoku.koplugin/sudoku/fullscreen_board.lua sudoku.koplugin/sudoku/board.lua sudoku.koplugin/sudoku/app_controller.lua sudoku.koplugin/tests/test_fullscreen_board.lua
git commit -m "feat: draw sudoku in a full-screen eink widget"
```

### Task 9: Complete Runner, Packages, and Documentation

**Files:**
- Modify: `scripts/run-tests.sh`
- Modify: `scripts/package.sh`
- Modify: `tests/test_kual_launcher.py`
- Create: `tests/test_packages.py`
- Modify: `README.md`
- Modify: `docs/ATALHO-KUAL.md`
- Modify: `dist/INSTALACAO.md`
- Regenerate: `dist/sudoku.koplugin.zip`
- Regenerate: `dist/kual-sudoku.zip`

**Interfaces:**
- Produces: `sh scripts/run-tests.sh` as the single local verification command.
- Produces: `SUDOKU_DIST_DIR=/path sh scripts/package.sh` to redirect artifacts for isolated package tests; default output remains `dist/`.
- Produces: plugin ZIP rooted at `koreader/plugins/sudoku.koplugin/` and KUAL ZIP rooted at `extensions/sudoku/`.

- [ ] **Step 1: Add failing package-layout tests**

In `tests/test_packages.py`, run packaging into a temporary output directory, list both ZIPs, and assert exact required prefixes, required manifests, absence of runtime logs/locks/temp files, and no extra wrapping directory.

- [ ] **Step 2: Extend failing KUAL boundary tests**

Cover an already-running KOReader, existing lock, plugin absence, request consumption contract, and corrected dynamic JSON menu declaration.

- [ ] **Step 3: Run Python tests and verify RED**

Run: `python3 -m unittest discover -s tests -p 'test_*.py' -v`

Expected: FAIL because plugin ZIP currently starts at `sudoku.koplugin/` and package tests do not exist.

- [ ] **Step 4: Correct packaging and unified verification**

Stage both ZIP layouts under separate `mktemp -d` roots, avoid `OLDPWD`, and make `run-tests.sh` run all Lua tests, Python tests, `luac -p`, `sh -n`, JSON/XML parsing, packaging, and `unzip -t`.

- [ ] **Step 5: Update user documentation**

Document only the four shipped modes, Medium default, full-screen controls, safe update paths, direct root extraction, logs, save location, cancellation, recovery, and the physical-validation disclaimer.

- [ ] **Step 6: Run complete fresh verification**

Run: `sh scripts/run-tests.sh`

Expected: exit 0; every Lua/Python test passes; syntax, manifests, and archives validate.

- [ ] **Step 7: Inspect generated artifacts**

Run: `unzip -l dist/sudoku.koplugin.zip && unzip -l dist/kual-sudoku.zip && git diff --check`

Expected: plugin begins with `koreader/plugins/sudoku.koplugin/`; KUAL begins with `extensions/sudoku/`; no whitespace errors.

- [ ] **Step 8: Commit Task 9**

```bash
git add scripts/run-tests.sh scripts/package.sh tests/test_kual_launcher.py tests/test_packages.py README.md docs/ATALHO-KUAL.md dist/INSTALACAO.md dist/sudoku.koplugin.zip dist/kual-sudoku.zip
git commit -m "chore: package reliable sudoku release"
```

### Task 10: Target Kindle Validation and Release Record

**Files:**
- Create: `docs/validation/kindle-basic-2-v2025.04.md`
- Modify only if a reproduced device defect requires it: implementation/test files owned by Tasks 1–9.

**Interfaces:**
- Consumes: verified ZIPs from Task 9 and a mounted target Kindle.
- Produces: a dated validation record with device, firmware, KUAL, KOReader, timings, failures, and pass/fail result.

- [ ] **Step 1: Record device and installed versions before copying**

Capture model, firmware 5.16.2.1.1, KOReader v2025.04, KUAL version if discoverable, existing plugin hashes, and save backup location in the validation document.

- [ ] **Step 2: Install the two ZIPs using the documented root-extraction flow**

Verify the resulting paths are exactly `/mnt/us/koreader/plugins/sudoku.koplugin/` and `/mnt/us/extensions/sudoku/` before ejecting.

- [ ] **Step 3: Execute the physical checklist**

Test KUAL and KOReader opening, opaque white background, all four board sizes, Medium generation, progress/cancel, touch edges, notes, conflicts, completion, undo/redo, redraw, 100-action ghosting, suspend/resume, save recovery, and exit.

- [ ] **Step 4: Measure and record behavior**

Record generation duration per mode, worst observed input latency, memory if available, full-refresh behavior, crash/launcher logs, and any deviation. Do not mark compatible while a required case fails.

- [ ] **Step 5: If a device-only defect occurs, reproduce and fix through TDD**

Add the smallest headless regression reproducing the evidence, verify RED, implement one fix, run `sh scripts/run-tests.sh`, reinstall, and repeat only the failed physical case plus surrounding lifecycle cases.

- [ ] **Step 6: Commit the validation record**

```bash
git add docs/validation/kindle-basic-2-v2025.04.md
git commit -m "test: validate sudoku on target kindle"
```
