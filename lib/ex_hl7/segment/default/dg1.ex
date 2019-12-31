defmodule HL7.Segment.Default.DG1 do
  @moduledoc "6.5.2 DG1 - diagnosis segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE

  segment "DG1" do
    field :set_id,             seq:  1, type: :integer, len: 4
    field :coding_method,      seq:  2, type: :string, len: 2
    field :diagnosis_id,       seq:  3, type: {CE, :id}, len: 20
    field :description,        seq:  4, type: :string, len: 40
    field :diagnosis_datetime, seq:  5, type: :datetime, len: 40
    field :diagnosis_type,     seq:  6, type: :string, len: 2
    field :approval_indicator, seq:  9, type: :string, len: 1
  end
end
