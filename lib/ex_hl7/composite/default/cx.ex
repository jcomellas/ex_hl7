defmodule HL7.Composite.Default.CX do
  @moduledoc """
  2.9.12 CX - extended composite ID with check digit

  Components:

    - `id` (ST)
    - `check_digit` (ST)
    - `check_digit_scheme` (ID)
    - `assigning_authority` (HD)
    - `id_type` (ID)
    - `assigning_facility` (HD)
    - `effective_date` (DT)
    - `expiration_date` (DT)

  ## Examples

      |1234567^4^M11^ADT01^MR^University Hospital|

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.HD, as: HD

  composite do
    component :id,                  type: :string
    component :check_digit,         type: :string
    component :check_digit_scheme,  type: :string
    component :assigning_authority, type: HD
    component :id_type,             type: :string
    component :assigning_facility,  type: HD
    component :effective_date,      type: :date
    component :expiration_date,     type: :date
  end
end
