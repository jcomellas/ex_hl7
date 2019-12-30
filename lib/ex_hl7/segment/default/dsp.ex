defmodule HL7.Segment.Default.DSP do
  @moduledoc "5.5.1 DSP - display data segment"
  use HL7.Segment.Spec

  segment "DSP" do
    field :set_id,        seq:  1, type: :integer, length: 4
    field :display_level, seq:  2, type: :string, length: 4
    field :data_line,     seq:  3, type: :string, length: 40
    field :break_point,   seq:  4, type: :string, length: 2
    field :result_id,     seq:  5, type: :string, length: 20
  end
end
