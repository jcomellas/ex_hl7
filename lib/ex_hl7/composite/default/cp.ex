defmodule HL7.Composite.Default.CP do
  @moduledoc """
  2.9.9 CP - composite price

  Components:

    - `price` (MO)
    - `price_type` (ID)
    - `from_value` (NM)
    - `to_value` (NM)
    - `range_units` (CE)
    - `range_type` (ID)

  Subcomponents of `price`:

    - `quantity` (NM)
    - `denomination` (ID)

  Example:

      |100.00&USD^UP^0^9^min^P~50.00&USD^UP^10^59^min^P~
       10.00&USD^UP^60^999^P~50.00&USD^AP~200.00&USD^PF~80.00&USD^DC|

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE
  require HL7.Composite.Default.MO, as: MO

  composite do
    component :price,       type: MO
    component :price_type,  type: :string
    component :from_value,  type: :float
    component :to_value,    type: :float
    component :range_units, type: CE
    component :range_type,  type: :string
  end
end

