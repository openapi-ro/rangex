defprotocol Rangex.Range do
  @moduledoc """
  Common range calculations
  """
  @doc """
  extracts the `from` component
  """
  def from(range)
  @doc """
  extracts the `to` component
  """
  def to(range)
  @doc """
  difference between x and y of the type used in `Range.from` and `Range.to`
  """
  def difference(model, x,y)
  @doc """
  creates a new rtange objexct from `from` and `to`
  """
  def new(model,from, to)
  @doc """
    two ranges that do share a intersection range
  """
  def overlaps?(first, second)
  @doc """
    two ranges that do not share an intersection range
  """
  def disjunct?(first, secons)
  @doc """
    The first range includes the second completely
  """
  def includes?(includes, included)
  @doc """
    the first range and the second one have a common [point] boundary
  """
  def adiacent?(range1,range2)
  @doc """
    returns true if two ranges are mergeable, false otherwhise
    Ths prevents joining of ranges which would otherwhise be adiacent or overlapping
    returns false in case of non-sdiacent and non-overlapping ranges
  """
  def mergeable?(range1, range2)
  @doc """
    Merges the first and the second range, if they are mergeable.

    This has the implicit meaning that this holds:
    `(overlap(range1,range2) or adiacent(range1,range2)) == true`).

    `&mergeable?/2` Ranges will be merged by

    - combining from/to to their respective min/max
    - combining other data of both `Range` objects into one

    Returns either `{:ok, Range.t}` or :error if the two are not mergeable
   """
  def merge(range1, range2)
  @doc """
    same as `&extend/2` but throws if the range cannot be extended
  """
  def merge!(range1, range2)
  @doc """
    splits a range into [up to] n equal [almost] ranges.
    returns:

    - n ranges of the same `&length/1` if `mod(length(range), n) ==0`
    - length(range) ranges of length 1 if `n>length(range)`
    - ranges which have different sizes (but the difference is at most 1)
  """
  def split(range, n \\2)
  @doc """
    split a range into n ranges of (almost) equal length
    the ranges will only be equally long if:

    - the domain is integer mod(difference(range,to(range),from(range) , n ) == 0
    - the domain is float (and it works well with the given precision)
  """
  def split_points(range, n \\2)

  @doc """
    returns the length of a range
  """
  def length(range)
end
defmodule Rangex.Range.Default do
  defmacro __using__(_) do
    quote do
      def from(range), do: range.from
      def to(range), do: range.to
      def difference(model, a, b), do: a-b
      #def difference(x,y), do: x-y
      def new(model,from,to) do
        # is it ok to use a tuple in  `Any`'s implementation?'
        %{from: from, to: to}
      end
      def overlaps?(first, second) do
        not disjunct?(first,second)
      end
      def disjunct?(first, second) do
        if from(first) > from(second) do
          disjunct?(second,first)
        else
          to(first) < from(second)
        end
      end
      def includes?(includes, included) do
        from(includes) <= from(included) and to(included) <= to(includes)
      end
      def adiacent?(range1,range2) do
        to(range1) == from(range2) || to(range2) == from(range1)
      end
      def mergeable?(range1, range2) do
        overlaps?(range1, range2) or adiacent?(range1, range2)
      end
      def merge(range1, range2) do
        if adiacent?(range1, range2) or overlaps?(range1, range2) do
          {:ok, new(range1, min( from(range1), from(range2) ), max(to(range1),to(range2) ) )}
        else
          :error
        end
      end
      def merge!(range1, range2) do
        {:ok,ret}=merge(range1,range2)
        ret
      end
      def length(range) do
        difference(range,to(range),from(range))
      end
      def split_points(range, n\\2) do
        Rangex.Range.Default.split_points(from(range), to(range), n)
      end
      def split(range,n \\2), do:  Rangex.Range.Default.split(range, n)
      defoverridable  from: 1, to: 1, new: 3,
                      overlaps?: 2,disjunct?: 2, includes?: 2, adiacent?: 2, mergeable?: 2,
                      merge!: 2, merge: 2,
                      difference: 3 , length: 1,
                      split_points: 2, split_points: 1, split: 1, split: 2

    end
  end
  def split(range, n) do
    case Rangex.Range.split_points(range,n) do
      [] -> [range]
      list ->
      {list, last_from}=
        list
        |> Enum.reduce({[],Rangex.Range.from(range)} , fn to, { list, from}->
          { [Rangex.Range.new(range,from,to)| list], to}
        end)
      [Rangex.Range.new(range,last_from,Rangex.Range.to(range))|list]
      |> Enum.reverse()
    end
  end
  def split_points(from,to), do: split_points(from,to,2)
  def split_points(from,to,n) when to<=(from+1) , do: []
  def split_points(from,to,n) when n>(to-from),   do: (from+1)..(to-1)|> Enum.to_list()
  def split_points(from,to,n) do
    step= (to-from) / n
    Stream.unfold( {from,from}, fn
      {_now, ^to } -> nil
      {now, last} ->
        now = now+step
        if round(now) == last do
          {nil, {now, last}}
        else
          ret = round(now)
          {ret,{now, ret}}
        end
    end)
    |> Stream.filter(&( &1 && &1 < to))
    |> Enum.to_list()
  end
end
defimpl Rangex.Range, for: Any do
  @fallback_to_any true
  def from(range), do: range.from
  def to(range), do: range.to
  def new(_model,from,to) do
    # is it ok to use a tuple in  `Any`'s implementation?'
    %{from: from, to: to}
  end
  def overlaps?(first, second) do
    not disjunct?(first,second)
  end
  def disjunct?(first, second) do
    if from(first) > from(second) do
      disjunct?(second,first)
    else
      to(first) < from(second)
    end
  end
  def includes?(includes, included) do
    from(includes) <= from(included) and to(included) <= to(includes)
  end
  def adiacent?(range1,range2) do
    to(range1) == from(range2) || to(range2) == from(range1)
  end
  def mergeable?(range1, range2) do
    overlaps?(range1, range2) or adiacent?(range1, range2)
  end
  def merge(range1, range2) do
    if adiacent?(range1, range2) or overlaps?(range1, range2) do
      {:ok, new(range1,min( from(range1), from(range2) ), max(to(range1),to(range2) ) )}
    else
      :error
    end
  end
  def merge!(range1, range2) do
    {:ok,ret}=merge(range1,range2)
    ret
  end

end
defimpl Rangex.Range, for: Tuple do
  use Rangex.Range.Default
  def from({from,_to}), do: from
  def to({_from,to}), do: to
  def new(_model,from, to), do: {from,to}
end
defimpl Rangex.Range, for: Map do
  use Rangex.Range.Default
  def from(%{from: from}), do: from
  def from(%{from: to}), do: to
  def mergeable?(range1,range2) do
    if overlaps?(range1, range2) or adiacent?(range1, range2) do
      if Map.drop(range1, [:from,:to]) == Map.drop(range2, [:from,:to]) do
        #mergeable by limits and the other content matches
        true
      else
        # cannot match because of content mismatch
        false
      end
    else
      false
    end
  end
end