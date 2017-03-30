# Johanna

This project, orchestrating the processes and performing all the routine tasks to keep the environment clean and robust, is named after and dedicated to **Johanna**, to honor the best office manager I ever worked with.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `johanna` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:johanna, "~> 0.1.0"}]
end
```
Wrapper for [`erlcron`](https://github.com/erlware/erlcron) with some smartness and goodness.

```elixir
Johanna.at({3, :pm}, fn -> IO.puts "Fridge cleaning time!" end)
Johanna.once(10, fn -> IO.puts "New sushi menu!" end)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/johanna](https://hexdocs.pm/johanna).

