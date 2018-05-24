defmodule RangeListTest do
  use ExUnit.Case
  doctest Rangex
  alias Rangex.RangeList, as: L
  test "insert in to empty range_list" do
    assert L.add_range([], {1,2}) == [{1,2}]
  end

  test "add_ranges" do
    assert L.add_ranges([] ,[{2,3},{2,4},{2,5}] ) == [{2,5}]
    assert L.add_ranges([{2,30},{2,10},{2,5}], [{2,7},{2,3}] ) == [{2,30}]
    assert L.add_ranges([{100,200},{2,30},{2,5},{2,10}], [{2,7},{2,3}], sorted: false) == [{2,30},{100,200}]
    assert L.add_ranges([{2,5},{100,200},{2,30},{2,10}], [{2,3},{2,7}], sorted: false) == [{2,30},{100,200}]
    assert L.add_ranges([{2,30},{2,5},{100,200},{2,10}], [{2,7},{2,3}], sorted: false ) == [{2,30},{100,200}]
    assert L.add_ranges([], [{100,200},{2,30},{2,30},{2,30}, {40,50}], sorted: false) == [{2,30},{40,50},{100,200}]
    
  end
  test "insert into front of empty range_list" do
    assert L.add_range([{1,2}], {5,6}) == [{1,2},{5,6}]
  end
  test "insert into end of empty range_list" do
    assert L.add_range([{5,6}], {1,2}) == [{1,2},{5,6}]
  end
  test "prepend the new range one with  merging" do
    assert L.add_range([{1,2},{3,4}], {-1,2}) == [{-1,2},{3,4}]
  end
  test "insert indentical range_list" do
    assert L.add_range([{1,2}], {1,2}) == [{1,2}]
  end
  test "insert empty range into range_list" do
    assert L.add_range([{1,2}], {1,1}) == [{1,2}]
  end
  test "insert into prepopulated list" do
    assert L.add_range([{-5,-7}, {8,10}], {1,2}) == [{-5,-7},{1,2},{8,10}]
  end
  test "test insert to join thhe new one and another one"  do
    assert L.add_range([{1,3}, {10,20}], {3,9}) == [{1,9},{10,20}]
  end
  test "test insert to join all ranges into one with one overlapping"  do
    assert L.add_range([{1,3}, {10,20},{30,40}], {3,31}) == [{1,40}]
  end
  test "test insert to join all ranges into one by inserting the middle"  do
    assert L.add_range([{1,3}, {10,20}], {3,10}) == [{1,20}]
  end
  test "test insert an unmergeable range between two other ranges"  do
    assert L.add_range([%{from: 1, to: 3, payload: :a}, %{from: 10,to: 20, payload: :a}], %{from: 3, to: 10, payload: :c}) == [
      %{from: 1, to: 3, payload: :a},
      %{from: 3, to: 10, payload: :c},
      %{from: 10,to: 20, payload: :a}
    ]
  end
  test "add_rabge merges" do
    assert L.add_range([{1,3},{1,4}, {1,5}], {1,5}, sorted: false) == [{1,5}]
  end
  test "cut_before and cut_after" do
    # cut with delimiter outside of ranges
    assert L.cut_before([{1,2}, {10,11}, {13,14}], 9) == [{10,11}, {13,14}]
    assert L.cut_after( [{1,2}, {10,11}, {13,14}], 9) == [{1,2}]

    #cut with delimiter inside of ranges
      assert L.cut_after([{1,3}, {10,12}, {13,15}], 11, [overlapping: :cut]) == [{1, 3}, {10, 11}]
      assert L.cut_before([{1,3}, {10,12}, {13,15}], 11, [overlapping: :cut]) == [{11,12}, {13,15}]

      assert L.cut_after([{1,3}, {10,12}, {13,15}], 11 ) == [{1, 3}, {10, 11}]
      assert L.cut_before([{1,3}, {10,12}, {13,15}], 11) == [{11,12}, {13,15}]

      #  [overlapping: false] is the same as [overlapping: :drop]
      assert L.cut_after([{1,3}, {10,12}, {13,15}], 11, [overlapping: false]) ==  [{1,3}]
      assert L.cut_before([{1,3}, {10,12}, {13,15}], 11, [overlapping: false]) == [ {13,15}]
      assert L.cut_after([{1,3}, {10,12}, {13,15}], 11, [overlapping: :drop]) ==  [{1,3}]
      assert L.cut_before([{1,3}, {10,12}, {13,15}], 11, [overlapping: :drop]) == [ {13,15}]

      assert L.cut_after([{1,3}, {10,12}, {13,15}], 11, [overlapping: :include]) == [{1,3}, {10,12}]
      assert L.cut_before([{1,3}, {10,12}, {13,15}], 11, [overlapping: :include]) == [ {10,12},{13,15}]


  end

  test "longest_gap without delimiting range" do
    assert L.longest_gap([{1,3}, {10,20},{30,40}]) == {20,30}
    assert L.longest_gap([{1,3}, {15,20},{30,40}], {0,100}) == {40,100}
    assert L.longest_gap([], {0,100}) == {0,100}
  end
  test "first_gap" do
    assert L.first_gap([{1,3}, {5,6}]) == {3,5}
    assert L.first_gap([{1,3}, {3,6}, {10,11}]) == {6,10}
    #now with encompassing range
    assert L.first_gap([{1,3}, {5,6}], {-3,100}) == {-3,1}
    assert L.first_gap([{-3,3}, {3,6}], {-3,100}) == {6,100}

    # now with a range cutting the first gap short
    assert L.first_gap([{1,3}, {5,6}], {-2,100}) == {-2,1}
    assert L.first_gap([{-3,3}, {3,6}, {500,1000}], {-3,100}) == {6,100}

    assert L.first_gap([],{1,2}) == {1,2}
  end
  test "gaps" do
    assert L.gaps([{1,3}, {4,5}]) == [{3,4}]
    assert L.gaps([{1,3}, {3,5}]) == []
    assert L.gaps([{1,3},{4,5}], {0,100}) == [{0,1},{3,4},{5,100}]
    assert L.gaps([{-10,3},{4,5}], {0,100}) == [{3,4},{5,100}]

    assert L.gaps([{1,3}, {4,5}], {10,20}) == [{10,20}]
    #special cases
    assert L.gaps([] ,{1,2}) ==[{1,2}]
    assert L.gaps([]) ==[]
    assert L.gaps([{1,3}],nil) ==[]
  end
  test "range_list ordering" do
     assert L.add_ranges([], [{1,2}, {1,5}, {1,3}, {6,8}]) == [{1,5}, {6,8}]

  end
end
