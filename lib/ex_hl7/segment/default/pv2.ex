defmodule HL7.Segment.Default.PV2 do
  @moduledoc "3.4.4 PV2 - patient visit - additional information segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE

  segment "PV2" do
    field :transfer_reason_id, seq: 4, type: {CE, :id}, len: 20
  end
end
