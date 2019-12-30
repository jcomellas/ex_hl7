defmodule HL7.Composite.Default.CM_PRD_7_2 do
  @moduledoc """
  Custom composite type for PRD-7.2

  Components:

    - `license_type`
    - `province_id`

  """
  use HL7.Composite.Spec

  composite do
    component :license_type, type: :string
    component :province_id,  type: :string
  end
end
