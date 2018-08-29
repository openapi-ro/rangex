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
  test "difference" do
    #BEGIN Complete case test
    # 1  2  3  4
    # ax ay bx by
    assert Range.difference({1,2},{3,4}) == [{1,2}]
    # ax bx ay by
    assert Range.difference({1,3},{2,4}) == [{1,2}]
    # ax bx by ay
    assert Range.difference({1,4},{2,3}) == [{1,2},{3,4}]
    # bx ax ay by
    assert Range.difference({2,3},{1,4}) == []
    # bx ax by ay
    assert Range.difference({2,4},{1,3}) == [{3,4}]
    # bx by ax ay
    assert Range.difference({3,4},{1,2}) == [{3,4}]
    #END Complete case test


    #old tests
    assert Range.difference({8,13},{2,11}) == [{11,13}]
    assert Range.difference({1,10}, {2,50}) == [{1,2}]
    assert Range.difference({1,10}, {2,5}) == [{1,2},{5,10}]
    assert Range.difference({5,10}, {2,50}) == []
  end
  test "intersect" do
    assert Range.intersect({1,10}, {1,3}) == {1,3}
    assert Range.intersect({2,10}, {1,3}) == {2,3}
    assert Range.intersect({4,10}, {1,3}) == nil
    assert Range.intersect({1,10}, {8,13}) == {8,10}
    assert Range.intersect({1,10}, {8,9}) == {8,9}
    assert Range.intersect({1,10}, {8,10}) == {8,10}
    assert Range.intersect({1,10}, {10,13}) == nil
  end
end