# Part gating: only tests up to MANOR_PART (default 1) run.
#
#   mix test                    # parts 0..1
#   MANOR_PART=4 mix test       # parts 0..4 (earlier parts stay in — regressions surface)
#   mix test --only part:3      # just part 3, regardless of MANOR_PART
#
# The "N excluded" count in the summary is your progress bar.
current_part = "MANOR_PART" |> System.get_env("1") |> String.to_integer()

locked_parts = for part <- (current_part + 1)..9//1, do: {:part, part}

ExUnit.start(exclude: locked_parts)
