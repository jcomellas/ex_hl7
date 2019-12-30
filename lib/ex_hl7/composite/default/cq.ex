defmodule HL7.Composite.Default.CQ do
  @moduledoc """
  2.9.10 CQ - composite quantity with units

  Components:

    - `quantity` (NM)
    - `units` (CE)

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE

  composite do
    component :quantity, type: :integer
    component :units,    type: CE
  end
end
