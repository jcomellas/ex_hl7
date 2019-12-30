defmodule HL7.Composite.Default.CM_IN1_14 do
  @moduledoc """
  6.5.6.14 IN1-14 Authorization information (CM) 00439

  Components:

    - `number` (ST)
    - `date` (DT)
    - `source` (ST)

  """
  use HL7.Composite.Spec

  composite do
    component :number, type: :string
    component :date,   type: :date
    component :source, type: :string
  end
end
