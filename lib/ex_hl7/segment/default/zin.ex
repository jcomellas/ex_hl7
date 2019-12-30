defmodule HL7.Segment.Default.ZIN do
  @moduledoc "Additional insurance information"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CE, as: CE

  segment "ZIN" do
    field :eligibility_indicator,   seq:  1, type: :string, length: 1
    field :patient_vat_status,      seq:  2, type: {CE, :id}, length: 4
    field :patient_vat_status_text, seq:  2, type: {CE, :text}, length: 7
    # There might be a variable number of repetitions of the following two components.
    field :coverage_id_1,           seq:  3, rep: 1, type: {CE, :id}, length: 5
    field :coverage_text_1,         seq:  3, rep: 1, type: {CE, :text}, length: 40
    field :coverage_id_2,           seq:  3, rep: 2, type: {CE, :id}, length: 5
    field :coverage_text_2,         seq:  3, rep: 2, type: {CE, :text}, length: 40
    field :coverage_id_3,           seq:  3, rep: 3, type: {CE, :id}, length: 5
    field :coverage_text_3,         seq:  3, rep: 3, type: {CE, :text}, length: 40
    field :coverage_id_4,           seq:  3, rep: 4, type: {CE, :id}, length: 5
    field :coverage_text_4,         seq:  3, rep: 4, type: {CE, :text}, length: 40
  end
end
