defmodule HL7.Composite.Default.CN do
  @moduledoc """
  2.9.7 CN - composite ID number and name

  Components:

    - `id_number` (ST)
    - `family_name` (FN)
    - `given_name` (ST)
    - `second_name` (ST)
    - `suffix` (ST)
    - `prefix` (ST)
    - `degree` (IS)
    - `source_table` (IS)
    - `assigning_authority` (HD)

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.FN, as: FN
  require HL7.Composite.Default.HD, as: HD

  composite do
    component :id_number,           type: :string
    component :family_name,         type: FN
    component :given_name,          type: :string
    component :second_name,         type: :string
    component :suffix,              type: :string
    component :prefix,              type: :string
    component :degree,              type: :string
    component :source_table,        type: :string
    component :assigning_authority, type: HD
  end
end
