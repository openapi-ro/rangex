defmodule RangeListRemoveContradictingTest do

  # RangePayloadImpl
  use ExUnit.Case
  alias Rangex.{RangeList}
  def new(from,to,payload) do
    %RangePayloadImpl{
      from: from,
      to: to,
      payload: payload
    }
  end
  test "one overlapping" do
    add=[new(1,10,:a),new(5,15,:b)]
    assert RangeList.add_ranges([], add, sorted: false, remove_contradicting: true) == [new(1,5,:a),new(5,15,:b)]
  end
  test "remove multiple after insertion point" do
    list=[new(1,3,:a),new(4,7,:b), new(8,11,:c),  new(2,11,:d)]
    assert RangeList.add_ranges([], list, sorted: true, remove_contradicting: true) == [new(1,2,:a),new(2,11,:d)]
  end
  test "remove multiple after insertion point with last one trimmed" do
    list=[new(1,3,:a),new(4,7,:b), new(8,13,:c) , new(2,11,:d)]
    assert RangeList.add_ranges([], list, sorted: true, remove_contradicting: true) == [new(1,2,:a),new(2,11,:d), new(11,13,:c)]
  end
  test "cuts on both ands and continuation afterwards" do
    list=[new(1,3,:a),new(4,7,:b), new(8,13,:c), new(13,15,:e) , new(2,11,:d)]
    assert RangeList.add_ranges([], list, sorted: true, remove_contradicting: true) == [new(1,2,:a),new(2,11,:d), new(11,13,:c),new(13,15,:e)]
  end
end