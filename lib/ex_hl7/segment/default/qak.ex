defmodule HL7.Segment.Default.QAK do
  @moduledoc "5.5.2 QAK - query acknowledgment segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE

  segment "QAK" do
    field :query_tag,             seq:  1, type: :string, len: 32
    field :query_response_status, seq:  2, type: :string, len: 4
    field :query_id,              seq:  3, type: {CE, :id}, len: 14
    field :query_name,            seq:  3, type: {CE, :text}, len: 30
  end
end
