# Rangex

RangeEx is a Library for working with ranges.
Ranges can be of different types, while the examples here are used using `{from,to}` `Tuple`s.

```
alias Rangex.RangeList
range_list =[{1,10}, {20,30}]
```

Now, given the above list we could insert a new range:
```
iex(3)> range_list=RangeList.add_range range_list , {11,19}
[{1, 10}, {11, 19}, {20, 30}]

```

Now if you insert `{10,11}` the first two ranges are combined into one:

```
iex(5)> range_list=RangeList.add_range range_list , {10,11}
[{1, 19}, {20, 30}]
```

This is just a short example, more documentation can be found in Hex.pm

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rangex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rangex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/rangex](https://hexdocs.pm/rangex).

