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
  #def difference(x,y)
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
end
defmodule Rangex.Range.Default do
  defmacro __using__(_) do
    quote do
      def from(range), do: range.from
      def to(range), do: range.to
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
      defoverridable(from: 1, to: 1, new: 3, overlaps?: 2,disjunct?: 2, includes?: 2, adiacent?: 2, mergeable?: 2, merge!: 2, merge: 2  )
    end
  end

end
defimpl Rangex.Range, for: Any do
  @fallback_to_any true
  def from(range), do: range.from
  def to(range), do: range.to
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
  def from({from,_}), do: from
  def to({from,to}), do: to
  def new(model,from, to), do: {from,to}
end