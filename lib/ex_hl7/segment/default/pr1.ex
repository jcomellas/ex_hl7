defmodule HL7.Segment.Default.PR1 do
  @moduledoc "6.5.4 PR1 - procedures segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE

  segment "PR1" do
    field :set_id,          seq:  1, type: :integer, len: 4
    field :coding_method,   seq:  2, type: :string, len: 3
    field :procedure_id,    seq:  3, type: {CE, :id}, len: 20
    field :procedure_name,  seq:  3, type: {CE, :text}, len: 30
    field :coding_system,   seq:  3, type: {CE, :coding_system}, len: 4
    field :description,     seq:  4, type: :string, len: 40
    field :datetime,        seq:  5, type: :datetime, len: 14
    field :functional_type, seq:  6, type: :string, len: 2
  end
end
