defmodule HL7.Segment.Default.DSC do
  @moduledoc "2.16.4 DSC - continuation pointer segment"
  use HL7.Segment.Spec

  segment "DSC" do
    field :continuation_pointer, seq:  1, type: :string, len: 15
  end
end
