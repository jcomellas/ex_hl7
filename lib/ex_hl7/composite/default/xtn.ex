defmodule HL7.Composite.Default.XTN do
  @moduledoc """
  2.9.55 XTN - extended telecommunication number

  Components:

    - `formatted_phone_number` (ST): [NNN] [(999)]999-9999 [X99999] [B99999] [C any text]
    - `telecom_use_code` (ID)
    - `telecom_equipment_type` (ID)
    - `email` (ST)
    - `country_code` (NM)
    - `area_code` (NM)
    - `phone_number` (NM)
    - `extension` (NM)
    - `any_text` (ST)

  """
  use HL7.Composite.Spec

  composite do
    component :formatted_phone_number, type: :string
    component :telecom_use_code,       type: :string
    component :telecom_equipment_type, type: :string
    component :email,                  type: :string
    component :country_code,           type: :integer
    component :area_code,              type: :integer
    component :phone_number,           type: :integer
    component :extension,              type: :integer
    component :any_text,               type: :string
  end
end
