# Manor

A Blue Prince–inspired roguelike, built as a self-paced Elixir/BEAM lab.
This repo is the **starter kit**: module skeletons with documented function
heads that raise `Manor.NotImplemented`, plus a pre-written test suite you
turn green, part by part. The full lab handbook (exercises, hint ladders,
reference solutions, reading map) lives in the companion lab document:

> **The Manor Lab** — https://claude.ai/code/artifact/9da295db-dbdd-4a46-8834-0b48edbaee71

This README is just the field card.

## The game in one paragraph

Each day you start in the Entrance Hall at the center-bottom of a 5×9 grid
with a purse of **steps, keys, gems, and coins**. Walking through a door
costs a step; locked doors cost a key (or a lockpick). Walking into an
*unbuilt* cell triggers a **draft**: three rarity-weighted room candidates
are offered, you pick one, it becomes part of the mansion, and you step
inside. Rooms have effects (grant resources on place, on entry, or every
turn), shops sell for coins, the workshop combines items via recipes.
Reach the **Antechamber** at rank 9 before your steps run out.

## Working the lab

```sh
mix test                    # runs parts 0..1 (the default gate)
MANOR_PART=4 mix test       # unlocks parts 0..4, cumulatively
mix test --only part:3      # just one part, any time
grep -rn "TODO(Part 3)" lib # your worklist for a part
iex -S mix                  # your other lab bench; .iex.exs pre-aliases everything
```

The `N excluded` count in the test summary is your progress bar. Tests are
named after exercise requirements (`3.3-R1 …`) and run against the mini
catalog in `test/support/fixtures.ex` — `lib/manor/catalog.ex` is *yours*
to rebalance freely.

## The part map

| Part | You build | You earn |
|---|---|---|
| 0 | the lab bench | mix, IEx, ExUnit, the red-green loop |
| 1 | `Grid`, `Resources` | pattern matching, guards, structs, tagged tuples |
| 2 | `Room`, `PlacedRoom`, `Mansion` | maps as grids, absence-as-state, derived facts |
| 3 | `Game.move/2` and the railway | `with`, multi-clause dispatch, phase sum types |
| 4 | `RNG`, `DraftPool`, drafting | explicit-state randomness, higher-order functions |
| 5 | `Effect`, shop, workshop | data-as-code interpreters, behaviours |
| 6 | the `Game` public API | doctests, `Keyword.validate!`, API design |
| 7 | `RunServer` by hand | spawn/send/receive, mailboxes, links vs monitors |
| 8 | `Game.Server` + supervision | GenServer, Registry, DynamicSupervisor, let-it-crash |
| 9 | `Render`, `CLI`, `Parser`, bots | iodata, protocols, binary matching, the whole game |

Provided complete (read, don't implement): `not_implemented.ex`,
`catalog.ex`, `special.ex`, `game/draft.ex`, `item.ex`, the `RunConfig`
struct, `Strategy.Random`, the `manor.play` mix task, and everything under
`test/support/`.

Part 8 note: `mod: {Manor.Application, []}` in `mix.exs` stays commented
until you implement the application — then uncomment it and `iex -S mix`
boots your tree. The finish line is Part 9:

```sh
mix manor.play --seed 42
```

## Ten traps for the Java-trained hand

1. **Discarded returns.** `Map.put(rooms, coord, room)` *returns* the new
   map; nothing was mutated. Rebind or you dropped the change.
2. **Process-per-entity.** Rooms are data. One process per *run*, and only
   from Part 7. A process that never handles concurrent messages wanted to
   be a function.
3. **Defensive nil-checks.** Expected absence gets a tagged value
   (`fetch → :error`); impossible absence gets an assertive crash
   (`{:ok, room} = fetch(...)`). Never `if x != nil`.
4. **if/else pyramids.** Three levels of nesting want to be three function
   clauses.
5. **String concat in loops.** Build iodata lists; flatten once at the edge.
6. **Hidden RNG.** `:rand.uniform/1` mutates process state. The core only
   threads `_s`-variant state explicitly.
7. **Read-modify-write through a server.** The transition happens *inside*
   `handle_call`, atomically. Fetch-compute-writeback is a race.
8. **Getters/setters/builders.** Pattern-match fields out; construct with
   literals; update with `%{s | ...}`.
9. **Exceptions as control flow.** Domain outcomes are values:
   `{:ok, _} | {:error, _}`. `rescue` belongs at boundaries (the parser).
10. **`String.to_atom/1` on input.** The atom table never shrinks. Parse
    against existing atoms only.
