defmodule HL7.Segment.Default.EVN do
  @moduledoc "3.4.1 EVN - event type segment"
  use HL7.Segment.Spec

  segment "EVN" do
    field :recorded_datetime,      seq:  2, type: :datetime, len: 14
    field :planned_event_datetime, seq:  3, type: :datetime, len: 14
    field :event_reason_code,      seq:  4, type: :string, len: 3
  end
end
