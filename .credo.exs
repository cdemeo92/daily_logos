%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["mix.exs", "config/", "lib/", "test/"],
        excluded: ["_build/", "deps/"]
      },
      strict: true,
      requires: [],
      plugins: []
    }
  ]
}
