defmodule HL7.Composite.Default.CM_OBR_23 do
  @moduledoc """
  7.4.1.23 OBR-23 Charge to practice (CM) 00256

  Components:

    - `amount` (MO)
    - `charge_code` (CE)

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE
  require HL7.Composite.Default.MO, as: MO

  composite do
    component :amount,      type: MO
    component :charge_code, type: CE
  end
end
