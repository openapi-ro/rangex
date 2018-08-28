defmodule Rangex.RangeList do
  alias Rangex.Range, as: R

  #function wrapper for on_contradiction argument of add_range to observe the nessesary iteration order
  defp on_contradiction_wrap(fun) do
    fn (left, right) ->
      ## function to sort inversely the range for return
      ret=
        case fun.(left,right) do
          [_|_]=ret->ret
          range_obj-> [range_obj]
        end
      ret
        |>sort()
        |>Enum.reverse()
    end
  end
  @doc """
    adds a range to a range_list.
    options:
      * `remove_contradicting`: if `true` removes any overlapping ranges for non-mergeable entries. 
        if ranges overlap partially the ones in `rangelist` are cut to "make room"
      * `on_conflict`: A function `fn left,right -> result_list end` returning the transformed list of left right to keep.

  """
  def add_range(range_list, to_insert, options \\ [sorted: true, remove_contradicting: true]) when is_list(range_list) do
    #require Logger
    #Logger.error("inaserting #{inspect to_insert}")
    range_list = options[:sorted] && range_list || Enum.sort(range_list)
    remove_contradicting = Keyword.get(options, :remove_contradicting, true)
    on_contradiction= 
      case Keyword.get(options, :on_contradiction) do
        nil when remove_contradicting ->
          fn left, right -> 
            if R.includes?(left,right) do
              [left]
            else
              case R.difference( left, right) do
                nil->[right]
                diff->
                 [ right, diff]
              end
            end
          end
        nil when not remove_contradicting ->
          fn left, right -> [left, right] end
        fun when is_function(fun)->fun
      end
      |> on_contradiction_wrap()
    {result, last}=
      range_list
      |> Enum.reduce_while( {[],to_insert} , fn
        range, {[prev| rest]=list, nil} ->
          #this branch is the finisher after to_insert has already been inserted
          #check if the last one can be joined
          cond do
            R.mergeable?(prev, range) ->
              {:cont , {[ R.merge!(prev, range)| rest], nil }}
            R.overlaps?(range,prev) and on_contradiction ->
              {:cont, {on_contradiction.( range, prev) ++ rest, nil} }
            true->
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
              #new_range comes before this range
              {:cont, {[range,new_range| list] , nil}}
            R.mergeable?(range, new_range) ->
              # we can merge the new range with this one
              {:cont ,{[R.merge!(new_range, range)| list], nil}}
            R.overlaps?(range,new_range) and on_contradiction ->
              {:cont, {on_contradiction.(range,new_range)++list, nil}}
            R.from(new_range) <= R.from(range)->
              #time to insert new range
              {:cont, {[range,new_range|list], nil}}
            true->
              #new range after this one
              {:cont, {[range|list], new_range}}
          end
      end)
    (last && [last|result] || result)
    |> Enum.reverse()
  end
  def sort([]), do: []
  def sort([_]=l), do: l
  def sort([_first| _rest]=l), do: Enum.sort(l, fn first, second ->
      R.sort(first,second)
    end)
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
    same as `add_range/3` but accept a list of ranges to be inserted
  """
  def add_ranges(range_list, list) when is_list(range_list) and is_list(list), do: add_ranges(range_list,list, [sorted: true])
  def add_ranges(range_list, [], _options) when is_list(range_list), do: range_list
  def add_ranges(range_list,list, options) when is_list(range_list) do
    Enum.reduce  list , range_list, fn new, prev ->
      add_range(prev, new, options)
    end
  end

  @doc """
  Cut the `range_list` to contain all elements after the marker `from`

  In case an individual range encloses `to` the behaviour is given by the
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

  In case an individual range encloses `from` the behaviour is given by the
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
    cuts a range_list to only include ranges which are also covered by `covering_range`

    In case an individual range exceeds the limits of `cover_range` the behaviour is given by the
    option `:overlapping`:

    - `:cut` cuts the range to start with `Rangex.Range.from(covering_range)` and end with `Rangex.Range.to(covering_range)`
    - `:drop` [or false] drops ranges exceeding cover_range from the result
    - `:include` [or `true` or any other value] includes the ranges overlapping with `cover_range`, with no other regard for their limits

  """
  def cut(range_list, covering_range, options \\ []) do
    [overlapping: overlapping] =
      normalize_cut_options options
    {from,to} =
      {R.from(covering_range), R.to(covering_range)}
    range_list
    |>cut_before(from, options)
    |>cut_after(to, options)
  end
  @doc """
    returns the longest gap between two successive ranges in the list.
    Returns a range describing the gap.
    The list must be sorted
  """
  def longest_gap([], big_range) , do: big_range
  def longest_gap([]) , do: nil
  def longest_gap(range_list, big_range\\nil) do
    range_list=
      if big_range do
        range_list=
          range_list
          |>cut(big_range, overlapping: :cut)
        #insert begin and end markers
        {first,last} =
          {List.first(range_list), List.last(range_list)}
        [R.new(first, R.from(big_range),R.from(big_range) )| range_list] ++ [R.new(last, R.to(big_range),R.to(big_range) )]
      else
        [first|rest] = range_list
        [R.new(first,R.from(first), R.from(first)),first|rest]
      end
    ret=
      range_list
      |> Enum.reduce(nil, fn
          range, nil -> {range, R.to(range), 0}
          range,{max, last_end, max_len} ->
            case R.difference(range,R.from(range) ,  last_end) do
              diff when diff > max_len -> 
                  {R.new(range, last_end, R.from(range)), R.to(range), diff }
              _->
                  {max, R.to(range), max_len}
            end
      end)
      |> elem(0)
    if R.length(ret) == 0 do
      nil
    else
      ret
    end
  end
  @doc """
    `gaps/2` returns a range list containing all the ranges which are not covered

    - if `covering_range` is supplied any range covered by `covering_range` but not by any `range` in `rangelist` will bbe part of the result
    - if `covering_range` is nil, the ranges not covered _between_ `range`s in `range_list` will be returned
    - any range outside of `covering_range` will not be part of the ranges
  """
  def gaps([]), do: []
  def gaps([], nil), do: []
  def gaps([], covering_range), do: [covering_range]
  def gaps(range_list, nil), do: gaps(range_list)
  def gaps(range_list, covering_range) do
    gaps [
      R.new(covering_range, R.from(covering_range), R.from(covering_range))
      | cut(range_list, covering_range)
    ] ++ [R.new(covering_range, R.to(covering_range), R.to(covering_range))]
  end
  def gaps(range_list) do
    [first | range_list] = range_list
    {result, _}=
      range_list
      |> Enum.reduce( {[], first}, fn
          range, {result, last} ->
            last_to = R.to(last)
            {range_from, range_to} = {R.from(range), R.to(range)}
            if R.difference(range,range_from, last_to) > 0 do
              {[ R.new(last, last_to, range_from)|result],range}
            else
              {result, range}
            end
        end)
    Enum.reverse result
  end

  @doc """
    `first_gap/2` returns the first gap found, logging
    - between at the each successive pair of ranges
    - between the limits optionally provided by `covering_range`

    in case a covering range is supplied any gaps before or after it are ignored
  """
  def first_gap(range_list, covering_range\\nil) do
    n_th_gap(1,range_list,covering_range)
  end
  #TODO: maybe expose this, but also add the possibility to look from the end
  defp n_th_gap(n, [], nil), do: nil
  defp n_th_gap(n, [], covering_range), do: covering_range
  defp n_th_gap(n, range_list, covering_range) do
    ret=
      case covering_range do
        nil-> range_list
        range->
          mod=
            range_list
            |> cut_before(  R.from(covering_range))
            |> cut_after(  R.to(covering_range))
            {first,last} = {List.first(range_list), List.last(range_list)}
          [R.new(first, R.from(covering_range),  R.from(covering_range))|mod]++ [
            R.new(last, R.to(covering_range),  R.to(covering_range))
          ]
      end
      |> Enum.reduce_while( nil , fn
        range, nil -> {:cont, {0,R.to(range)}}
        range, {prev_count,last_to} ->
          if R.difference(range,R.from(range), last_to) == 0 do
            {:cont, {prev_count, R.to(range)}}
          else
            if n == prev_count+1 do
              {:halt, {:result, R.new(range,last_to, R.from(range))}}
            else
              {:cont, {prev_count+1,R.to(range)}}
            end
          end
        end)
    case ret do
      {:result,ret}-> ret
      _ -> nil#not found
    end
  end

end