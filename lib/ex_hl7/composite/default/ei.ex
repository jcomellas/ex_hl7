defmodule HL7.Composite.Default.EI do
  @moduledoc """
  2.9.17 EI - entity identifier

  Components:

    - `id` (ST)
    - `namespace_id` (IS)
    - `universal_id` (ST)
    - `universal_id_type` (ID)

  """
  use HL7.Composite.Spec

  composite do
    component :id,                type: :string
    component :namespace_id,      type: :string
    component :universal_id,      type: :string
    component :universal_id_type, type: :string
  end
end
