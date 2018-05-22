
defmodule RangePayloadImpl do
  use Rangex.Range.Default
  defstruct from: nil,
            to: nil,
            payload: nil

end
defimpl Rangex.Range , for: RangePayloadImpl do
  use Rangex.Range.Default
  def mergeable?(range1, range2) do
    if range1.payload == range2.payload do
      Rangex.Range.Default.megeable?(range1,range2)
    else
      false
    end
  end
end