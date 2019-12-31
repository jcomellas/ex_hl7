defmodule HL7.Segment.Default.ZAU do
  @moduledoc "Procedure authorization information"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE
  require HL7.Composite.Default.CP, as: CP
  require HL7.Composite.Default.EI, as: EI

  segment "ZAU" do
    field :prev_authorization_id,     seq:  1, type: {EI, :id}, len: 15
    field :payor_control_id,          seq:  2, type: {EI, :id}, len: 15
    field :authorization_status,      seq:  3, type: {CE, :id}, len: 4
    field :authorization_status_text, seq:  3, type: {CE, :text}, len: 15
    field :pre_authorization_id,      seq:  4, type: {EI, :id}, len: 15
    field :pre_authorization_date,    seq:  5, type: :date, len: 8
    field :copay,                     seq:  6, type: {CP, :price, :quantity}, len: 10
    field :copay_currency,            seq:  6, type: {CP, :price, :denomination}, len: 10
  end
end
