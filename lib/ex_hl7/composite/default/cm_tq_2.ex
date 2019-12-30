defmodule HL7.Composite.Default.CM_TQ_2 do
  @moduledoc """
  4.3.2 Interval component (CM)

  Subcomponents:

    - `repeat_pattern` (IS)
    - `explicit_interval` (ST)

  """
  use HL7.Composite.Spec

  composite do
    component :repeat_pattern,    type: :string
    component :explicit_interval, type: :string
  end
end
