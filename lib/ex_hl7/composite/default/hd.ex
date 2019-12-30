defmodule HL7.Composite.Default.HD do
  @moduledoc """
  2.9.5.4 Assigning authority (HD)

  Components:

    - `namespace_id` (IS)
    - `universal_id` (ST)
    - `universal_id_type` (ID)

  """
  use HL7.Composite.Spec

  composite do
    component :namespace_id,      type: :string
    component :universal_id,      type: :string
    component :universal_id_type, type: :string
  end
end
