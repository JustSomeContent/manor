# Manor — lab starter kit

This repo is a structured learning lab, not a normal codebase. The human working here is a senior engineer (strong FP + concurrency background, new to Elixir/BEAM) deliberately learning by implementing the exercise skeletons themselves. The full handbook (exercises, hint ladders, reference solutions) is the "Manor Lab" artifact: https://claude.ai/code/artifact/9da295db-dbdd-4a46-8834-0b48edbaee71

# The AI-pair protocol (binding)

Skeleton functions that `raise Manor.NotImplemented` are the user's exercises.

- **You may:** explain any concept, error message, compiler warning, or provided code; help read test failures; review the user's *finished* solutions against Elixir idiom (clause ordering, naming, pattern-matching opportunities — critique, don't silently rewrite); quiz them Socratically using the handbook's per-part TA questions.
- **You may not:** write or complete exercise function bodies before the user has made an attempt at the handbook's Hint-3 level — even if asked casually. If the user explicitly says "override the lab protocol", comply, but name the tradeoff first.
- **Never modify `test/`** — the tests are the lab's contract. (Fixing a genuinely broken test is fine after explaining why it's broken.)
- Reference solutions exist in the handbook artifact and are verified against this suite; if code and test ever disagree, the test wins.

# Working the repo

- Part gating: `mix test` runs parts 0–1; `MANOR_PART=<n> mix test` unlocks parts 0–n cumulatively; `mix test --only part:<n>` focuses one part. The learner's worklist for a part: `grep -rn "TODO(Part <n>)" lib/`.
- `mix compile --warnings-as-errors` and `mix format --check-formatted` must stay clean.
- Provided-complete (fair game to discuss, not exercises): `catalog.ex`, `not_implemented.ex`, `special.ex`, `game/draft.ex`, `item.ex`, the `RunConfig` struct, `Strategy.Random`, the `manor.play` mix task, `test/support/`.
- `mix.exs` keeps `mod: {Manor.Application, []}` commented until Part 8 — do not uncomment it for the user.
- Zero hex dependencies until the Annex parts, by design. Don't add deps to "help".

# Architecture ground rules (hold reviews to these)

- Functional core / imperative shell: all game rules live in pure modules (`Manor.Game` and below); processes (`RunServer`, `Game.Server`) hold state and delegate — zero rules in the shell.
- `{:error, reason}` means rejected-and-unchanged; day endings (win / out of steps) are `{:ok, game}` transitions, never errors.
- Only explicit-state `:rand` `_s` functions in the core; the RNG value threads through `game.rng`.
- Unbuilt grid cells are absent map keys — no nils, no sentinels. Passages are derived by `Mansion.passage/3`, never stored.
- Effects are data interpreted by `Manor.Effect`; behaviours only for computed logic (`Manor.Special`) and pluggable roles (`Manor.Strategy`); protocols only for printing.

# Post-lab: the bot lab (benchmark-first development)

The core lab (parts 0–9) is complete and the AI-pair protocol's exercise
restrictions no longer bind new work; the architecture ground rules above still do.
Development now runs benchmark-first:

- `mix manor.bench --strategy <name> --runs N` simulates N seeded days headless
  (`Manor.Benchmark`). Seeds are always 1..N, so two invocations with the same
  arguments compare apples to apples.
- The loop: change a strategy or mechanic → benchmark → compare aggregates
  (win rate, rejections, revisits, closets drafted, resources left over) against
  the previous numbers → keep or revert. Quote the aggregate line that justified
  a change in its commit message — the repo's numbers are its memory.
- Baselines (2026-08-30, 50 seeds, real catalog, 400-command budget):
  Random 0% wins, 53 rejections/day. Greedy 32% wins, 8.9 turns/win, 24.9
  revisits (pacing death). Surveyor 94% wins, 17.0 turns/win, 2.3 revisits,
  3.96 closets/day — that closet rate is pool exhaustion, a mechanics signal.
- After the 2026-08-30 mechanics round (second wing of 9 rooms, `{:drain, ..}` +
  `:on_exit` effects, spyglass = +1 candidate, shop sinks; 200 seeds): Greedy 74%
  (30 days budget-exhausted — its `|| 0` draft fallback loops on an unaffordable
  candidate; left as-is, it is the handbook's reference bot). Surveyor 99.5%,
  9.0 turns/win, 0 closets, 0 rejections. The difficulty lever is gems, not
  steps: Surveyor still wins 95% at 10 starting steps, 92% at 1 gem, 33% at 0.
  Every retired day was a genuinely closed mansion once the bot learned to keep
  the Antechamber's 2 gems in reserve.
- `mix credo --strict` and the Annex B property tests are part of the gates now,
  alongside warnings-as-errors and format. `.credo.exs` documents one deliberate
  overrule (passage/3's nesting); argue in that file, not by deleting findings.

# Knowledge graph (graphify, local only)

- This repo has a local graphify graph in `graphify-out/` (gitignored). For structure/architecture questions — "what calls X", "how do these modules relate", "trace the draft flow" — query it first (`graphify query "<question>"`) before sweeping files.
- Refresh after a part lands: `/graphify . --update` post-commit (incremental; only changed files re-extract). Don't rebuild mid-part for every edit.
- This repo is NOT indexed in the remote graphify workspace — the `mcp__graphify__*` tools serve other repos and will not know manor. Use the local graph here.
- The graph is a map, not a TA loophole: it describes the learner's own code and never substitutes for the AI-pair protocol above.
