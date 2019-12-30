defmodule HL7.Segment.Default.RF1 do
  @moduledoc "11.6.1 RF1 - referral information segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE
  require HL7.Composite.Default.EI, as: EI

  segment "RF1" do
    field :referral_status_id,          seq:  1, type: {CE, :id}, length: 5
    field :referral_status_description, seq:  1, type: {CE, :text}, length: 15
    field :referral_type_id,            seq:  3, type: {CE, :id}, length: 5
    field :referral_type_description,   seq:  3, type: {CE, :text}, length: 15
    field :originating_referral_id,     seq:  6, type: {EI, :id}, length: 15
    field :effective_datetime,          seq:  7, type: :datetime, length: 12
    field :expiration_datetime,         seq:  8, type: :datetime, length: 12
    field :process_datetime,            seq:  9, type: :datetime, length: 12
    field :referral_reason_id,          seq: 10, type: {CE, :id}, length: 21
  end
end
