defmodule RangeListRemoveContradictingTest do

  # RangePayloadImpl
  use ExUnit.Case
  alias Rangex.{RangeList, Range}
  def new(from,to,payload) do
    %RangePayloadImpl{
      _payload: payload,
      from: from,
      to: to
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

  test "tests custom on_contradiction function" do
    list=[new(1,3,true),new(4,7,false),new(2,13,false)]
    on_contradiction = fn (left, right) ->
      if left._payload do
        case  Range.difference(right,left) do
          nil->left
          diff-> [left,diff]
        end
        else
        case  Range.difference(left, right) do
          nil ->right
          diff -> [diff,right]
        end
      end
    end
    assert RangeList.add_ranges([], list, sorted: true, on_contradiction: on_contradiction) == [new(1,3,true),new(3,13,false)]
  end
  test "insert order test" do
    input=[
      new( 8095,8705,true  ),
      new( 8705 ,10359,false),
      new( 8095,8705,true ),
      new( 8705,10360,false ),
      new( 6778, 7518,true ),
      new( 7519, 7520,false ),
      new( 6778, 7518,true )
    ]
    assert RangeList.add_ranges([], input, [sorted: true]) == [
      new( 6778, 7518,true ),
      new( 7519, 7520,false ),
      new( 8095,8705,true  ),
      new( 8705,10360,false )
    ]
  end
end