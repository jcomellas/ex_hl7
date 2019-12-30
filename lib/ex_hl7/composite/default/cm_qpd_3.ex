defmodule HL7.Composite.Default.CM_QPD_3 do
  @moduledoc """
  QPD_Q15-3 Provider ID number (CM)

  Components:

    - `id` (ID)
    - `id_type` (IS)

  """
  use HL7.Composite.Spec

  composite do
    component :id,      type: :string
    component :id_type, type: :string
  end
end
