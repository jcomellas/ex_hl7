defmodule HL7.Composite.Default.CM_MSH_9 do
  @moduledoc """
  2.16.9.9 MSH-9 Message type (CM) 00009

  Components:

    - `id` (ID)
    - `trigger_event` (ID)
    - `structure` (ID)

  """
  use HL7.Composite.Spec

  composite do
    component :id,            type: :string
    component :trigger_event, type: :string
    component :structure,     type: :string
  end
end
