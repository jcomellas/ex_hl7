defmodule HL7.Segment.Default.MSA do
  @moduledoc "2.16.8 MSA - message acknowledgment segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE

  segment "MSA" do
    field :ack_code,           seq:  1, type: :string, len: 2
    field :message_control_id, seq:  2, type: :string, len: 20
    field :text_message,       seq:  3, type: :string, len: 80
    field :error_code,         seq:  6, type: {CE, :id}, len: 10
    field :error_text,         seq:  6, type: {CE, :text}, len: 40
  end
end
