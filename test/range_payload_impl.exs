
defmodule RangePayloadImpl do
  use Rangex.Range.Default
  defstruct from: nil,
            to: nil,
            _payload: nil

end
defimpl Rangex.Range , for: RangePayloadImpl do
  use Rangex.Range.Default
  def mergeable?(range1, range2) do
    if range1._payload == range2._payload do
      overlaps?(range1, range2) or adiacent?(range1, range2)
    else
      false
    end
  end
end