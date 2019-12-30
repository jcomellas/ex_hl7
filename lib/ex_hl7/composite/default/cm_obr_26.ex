defmodule HL7.Composite.Default.CM_OBR_26 do
  @moduledoc """
  7.4.1.26 OBR-26 Parent result (CM) 00259

  Components:

    - `observation_id` (CE)
    - `observation_sub_id` (ST)
    - `observation_result` (TX)

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE

  composite do
    component :observation_id,     type: CE
    component :observation_sub_id, type: :string
    component :observation_result, type: :string
  end
end
