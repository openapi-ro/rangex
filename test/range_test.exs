defmodule RangeTest do
  use ExUnit.Case
  alias Rangex.Range
  doctest Rangex
  test "overlaps" do
    assert Range.overlaps?({1,3}, {2,3})
    assert Range.overlaps?({-1,3}, {2,5})
    assert not Range.overlaps?({1,2},{2,3})
    assert Range.disjunct?({1,2},{2,3})
  end
  test "merge" do
    assert Range.merge!({1,3}, {2,3})== {1,3}
    assert Range.merge!({1,2}, {2,3})== {1,3}
    assert Range.merge!({2,4}, {1,3})== {1,4}
  end
  test "length" do
    assert Range.length({1,1}) == 0
    assert Range.length({1,2}) == 1
    assert Range.length({1,3}) == 2
    assert Range.length({1,4}) == 3
    assert Range.length(nil) == 0
  end
  test "megeable" do
    assert Range.mergeable?({1,3},{1,5})
    assert Range.merge!({1,3},{1,5}) == {1,5}
  end
end