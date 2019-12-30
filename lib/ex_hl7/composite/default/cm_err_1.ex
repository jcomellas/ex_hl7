defmodule HL7.Composite.Default.CM_ERR_1 do
  @moduledoc """
  2.16.5.1 ERR-1 Error code and location (CM) 00024

  Components:

    - `segment_id` (ST)
    - `sequence` (NM)
    - `field_pos` (NM)
    - `error` (CE)

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE

  composite do
    component :segment_id, type: :string
    component :sequence,   type: :integer
    component :field_pos,  type: :integer
    component :error,      type: CE
  end
end
