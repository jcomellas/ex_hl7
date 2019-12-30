defmodule HL7.Composite.Default.CM_TQ_10 do
  @moduledoc """
  4.3.10 Order sequencing component (CM)
  """
  use HL7.Composite.Spec

  composite do
    component :results_flag,                   type: :string
    component :placer_order_id,                type: :string
    component :placer_order_namespace_id,      type: :string
    component :filler_order_id,                type: :string
    component :filler_order_namespace_id,      type: :string
    component :condition,                      type: :string
    component :max_repeats,                    type: :integer
    component :placer_order_universal_id,      type: :string
    component :placer_order_universal_id_type, type: :string
    component :filler_order_universal_id,      type: :string
    component :filler_order_universal_id_type, type: :string
  end
end
