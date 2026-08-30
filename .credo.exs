# Credo, strict — with one documented disagreement:
#
# Refactor.Nesting is raised from 2 to 3 for the sake of
# Manor.Mansion.passage/3, whose nested case the lab's handbook defends
# by design: "the one Part-2 function that has earned a nested case —
# nesting mirrors the actual decision structure." We argued with the
# tool's taste (Annex D's own instruction) and ruled for the handbook.
%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{included: ["lib/", "test/"], excluded: ["test/support/"]},
      checks: %{
        extra: [
          {Credo.Check.Refactor.Nesting, max_nesting: 3}
        ]
      }
    }
  ]
}
