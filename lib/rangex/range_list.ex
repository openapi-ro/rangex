defmodule Rangex.RangeList do
  alias Rangex.Range, as: R
  @doc """
    adds a range to a range_list.
  """
  def add_range(range_list, to_insert, options \\ [sorted: true]) do
    range_list = options[:sorted] && range_list || Enum.sort(range_list)
    {result, last}=
      range_list
      |> Enum.reduce_while( {[],to_insert} , fn
        range, {[prev| rest]=list, nil} ->
          #this branch is the finisher after to_innsert has already been inserted
          #check if the last one can be joined
          if R.mergeable?(prev, range) do
            R.merge!(prev, range)
            {:cont , {[ R.merge!(prev, range)| rest], nil }}
          else
            remainder =
              range_list
              |> Enum.drop_while(&(not (&1 == range)))
              |> Enum.reverse()
            {:halt, { remainder ++ list, nil}}
            #{:cont , {[ range| list], nil }}
          end
        range,{list, new_range} ->
          cond  do
            R.to(new_range) < R.from(range) ->
              {:cont, {[range,new_range| list] , nil}}
            R.mergeable?(range, new_range) ->
              {:cont ,{[R.merge!(new_range, range)| list], nil}}
            true->
              {:cont, {[range|list], new_range}}
          end
      end)
    # result
    (last && [last|result] || result)
    |> Enum.reverse()
  end
  # used to read cut options
  defp normalize_cut_options(options) when is_list(options) do
    [
      overlapping:
        case options[:overlapping] do
          false -> :drop
          :include-> :include
          true -> :include
          :drop-> :drop
          _default-> :cut
        end
    ]
  end
  @doc """
  Cut the `range_list` to contain all elements after the marker `from`

  In case an individual range encloses `from` the behaviour is giben by the
  option `:overlapping`:

  - `:cut` cuts the range to start with `from`
  - `:drop` [or false] drops the range from the result
  - `:include` [or `true` or any other value] includes the overlapping range as is

  The `from` argument is matched inclusively.
  """
  def cut_before(range_list, from, options \\ []) do
    [overlapping: overlapping] = normalize_cut_options options

    range_list
    |>Enum.flat_map(fn range ->
      cond do
        R.to(range) <= from ->
          []
        R.from(range) < from and overlapping==:drop ->
          []
        R.from(range) <= from and overlapping==:cut ->
          [R.new(range, from, R.to(range))]
        true ->
          # This is already included in this clause:
          #  R.from(range) <= from and overlapping==:include ->
          [range]
      end
    end)
  end


  @doc """
  Cut the `range_list` to contain all elements before the marker `to`

  In case an individual range encloses `from` the behaviour is giben by the
  option `:overlapping`:

  - `:cut` cuts the range to end with `to`
  - `:drop` [or false] drops the range from the result
  - `:include` [or `true` or any other value] includes the overlapping range as is

  The `to` argument is matched excluding it's own value(as with the `to` component of a range).
  """
  def cut_after(range_list, to, options \\ []) do
    [overlapping: overlapping] = normalize_cut_options options
    range_list
    |>Enum.flat_map(fn range ->
      cond do
        R.from(range) >= to ->
          []
        R.to(range) > to and overlapping==:drop ->
          []
        R.to(range) >= to and overlapping==:cut ->
          [R.new(range, R.from(range),to)]
        true ->
          # This is already included in this clause:
          #  R.to(range)  > to and overlapping==:include ->
          [range]
          end
    end)
  end
  @doc """
    returns the longest gap between two successive ranges in the list.
    Returns a range describing the gap.
    The list must be sorted
  """
  def longest_gap(range_list, big_range\\nil) do
    range_list=
      if big_range do
        range_list=
          range_list
          |>cut_after(R.to(big_range), overlapping: :cut)
          |>cut_before(R.from(big_range), overlapping: :cut)
        #insert begin and end markers
        [R.new(big_range, R.from(big_range),R.from(big_range) )| range_list] ++ [R.new(big_range, R.to(big_range),R.to(big_range) )]
      else
        range_list
      end

    range_list
    |> Enum.reduce(nil, fn
        range, nil -> {range, R.to(range), 0}
        range,{max, last_end, max_len} ->
          case R.difference(range,R.from(range) ,  last_end) do
            diff when diff > max_len -> {R.new(range, last_end, R.from(range)), R.to(range), diff }
            _->{max, R.to(range), max_len}
          end
    end)
    |> elem(0)
  end

end