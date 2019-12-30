defmodule HL7.Composite.Default.DR do
  @moduledoc """
  2.9.54.10 Name validity range (DR)

  This component contains the start and end date/times which define the
  period during which this name was valid.

  Components:

    - `start_datetime` (DT)
    - `end_datetime` (DT)

  """
  use HL7.Composite.Spec

  composite do
    component :start_datetime, type: :datetime
    component :end_datetime,   type: :datetime
  end
end
