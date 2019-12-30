defmodule HL7.Composite.Default.FN do
  @moduledoc """
  2.9.19 FN - family name

  Components:

    - `surname` (ST)
    - `own_surname_prefix` (ST)
    - `own_surname` (ST)
    - `surname_prefix_from_partner` (ST)
    - `surname_from_partner` (ST)

  This data type allows full specification of the surname of a person. Where
  appropriate, it differentiates the person's own surname from that of the
  person's partner or spouse, in cases where the person's name may contain
  elements from either name. It also permits messages to distinguish the
  surname prefix (such as "van" or "de") from the surname root.
  """
  use HL7.Composite.Spec

  composite do
    component :surname,                     type: :string
    component :own_surname_prefix,          type: :string
    component :own_surname,                 type: :string
    component :surname_prefix_from_partner, type: :string
    component :surname_from_partner,        type: :string
  end
end
