defmodule HL7.Segment.Default.NTE do
  @moduledoc "2.16.10 NTE - notes and comments segment"
  use HL7.Segment.Spec

  segment "NTE" do
    field :set_id,  seq:  1, type: :integer, length: 4
    field :comment, seq:  3, type: :string, length: 512
  end
end
