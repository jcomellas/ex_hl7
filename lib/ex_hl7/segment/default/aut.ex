defmodule HL7.Segment.Default.AUT do
  @moduledoc "11.6.2 AUT - authorization information segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE
  require HL7.Composite.Default.CP, as: CP
  require HL7.Composite.Default.EI, as: EI

  segment "AUT" do
    field :plan_id,               seq:  1, type: {CE, :id}, len: 10
    field :plan_name,             seq:  1, type: {CE, :text}, len: 20
    field :company_id,            seq:  2, type: {CE, :id}, len: 6
    field :company_name,          seq:  3, type: :string, len: 30
    field :effective_date,        seq:  4, type: :datetime, len: 14
    field :expiration_date,       seq:  5, type: :datetime, len: 14
    field :authorization_id,      seq:  6, type: {EI, :id}, len: 20
    field :reimbursement_limit,   seq:  7, type: {CP, :price, :quantity}, len: 25
    field :requested_treatments,  seq:  8, type: :integer, len: 2
    field :authorized_treatments, seq:  9, type: :integer, len: 2
    field :process_date,          seq: 10, type: :date, len: 8
  end
end
