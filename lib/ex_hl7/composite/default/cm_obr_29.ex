defmodule HL7.Composite.Default.CM_OBR_29 do
  @moduledoc """
  7.4.1.29 OBR-29 Parent (CM) 00261

  Components:

    - `placer_order` (EI)
    - `filler_order` (EI)

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.EI, as: EI

  composite do
    component :placer_order, type: EI
    component :filler_order, type: EI
  end
end
