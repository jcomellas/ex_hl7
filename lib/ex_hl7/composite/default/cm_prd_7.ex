defmodule HL7.Composite.Default.CM_PRD_7 do
  @moduledoc """
  11.6.3.7 PRD-7 Provider identifiers (CM) 01162

  Components:

    - `id` (ST)
    - `id_type` (IS)
    - `other` (ST)

  Definition: This repeating field contains the provider's unique identifiers
  such as UPIN, Medicare and Medicaid numbers.

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CM_PRD_7_2, as: CM_PRD_7_2

  composite do
    component :id,      type: :string
    component :id_type, type: CM_PRD_7_2
    component :other,   type: :string
  end
end
