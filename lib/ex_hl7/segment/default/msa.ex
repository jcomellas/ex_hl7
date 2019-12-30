defmodule HL7.Segment.Default.MSA do
  @moduledoc "2.16.8 MSA - message acknowledgment segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE

  segment "MSA" do
    field :ack_code,           seq:  1, type: :string, length: 2
    field :message_control_id, seq:  2, type: :string, length: 20
    field :text_message,       seq:  3, type: :string, length: 80
    field :error_code,         seq:  6, type: {CE, :id}, length: 10
    field :error_text,         seq:  6, type: {CE, :text}, length: 40
  end
end
