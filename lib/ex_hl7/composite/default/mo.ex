defmodule HL7.Composite.Default.MO do
  @moduledoc """
  2.9.26 MO - money

  Components:

    - `quantity` (NM)
    - `denomination` (ID)

  """
  use HL7.Composite.Spec

  composite do
    component :quantity,     type: :float
    component :denomination, type: :string
  end
end
