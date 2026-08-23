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

# Knowledge graph (graphify, local only)

- This repo has a local graphify graph in `graphify-out/` (gitignored). For structure/architecture questions — "what calls X", "how do these modules relate", "trace the draft flow" — query it first (`graphify query "<question>"`) before sweeping files.
- Refresh after a part lands: `/graphify . --update` post-commit (incremental; only changed files re-extract). Don't rebuild mid-part for every edit.
- This repo is NOT indexed in the remote graphify workspace — the `mcp__graphify__*` tools serve other repos and will not know manor. Use the local graph here.
- The graph is a map, not a TA loophole: it describes the learner's own code and never substitutes for the AI-pair protocol above.
