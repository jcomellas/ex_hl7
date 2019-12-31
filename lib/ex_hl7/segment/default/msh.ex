defmodule HL7.Segment.Default.MSH do
  @moduledoc "2.16.9 MSH - message header segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CM_MSH_9, as: CM_MSH_9
  require HL7.Composite.Default.HD, as: HD

  segment "MSH" do
    field :field_separator,                      seq:  1, type: :string, len: 1
    field :encoding_chars,                       seq:  2, type: :string, len: 4
    field :sending_app_id,                       seq:  3, type: {HD, :namespace_id}, len: 12
    field :sending_facility_id,                  seq:  4, type: {HD, :namespace_id}, len: 12
    field :sending_facility_universal_id,        seq:  4, type: {HD, :universal_id}, len: 20
    field :sending_facility_universal_id_type,   seq:  4, type: {HD, :universal_id_type}, len: 20
    field :receiving_app_id,                     seq:  5, type: {HD, :namespace_id}, len: 12
    field :receiving_facility_id,                seq:  6, type: {HD, :namespace_id}, len: 12
    field :receiving_facility_universal_id,      seq:  6, type: {HD, :universal_id}, len: 20
    field :receiving_facility_universal_id_type, seq:  6, type: {HD, :universal_id_type}, len: 20
    field :message_datetime,                     seq:  7, type: :datetime, len: 14
    field :security,                             seq:  8, type: :string, len: 40
    field :message_type,                         seq:  9, type: {CM_MSH_9, :id}, len: 3
    field :trigger_event,                        seq:  9, type: {CM_MSH_9, :trigger_event}, len: 3
    field :message_structure,                    seq:  9, type: {CM_MSH_9, :structure}, len: 7
    field :message_control_id,                   seq: 10, type: :string, len: 20
    field :processing_id,                        seq: 11, type: :string, len: 3, default: "P"
    field :version,                              seq: 12, type: :string, len: 8, default: "2.4"
    field :accept_ack_type,                      seq: 15, type: :string, len: 2
    field :app_ack_type,                         seq: 16, type: :string, len: 2
    field :country_code,                         seq: 17, type: :string, len: 3, default: "ARG"
    field :char_set,                             seq: 18, type: :string, len: 10
  end
end
