defmodule HL7.Composite.Default.XPN do
  @moduledoc """
  2.9.54 XPN - extended person name

  Components:

    - `family_name` (FN)
    - `given_name` (ST)
    - `second_name` (ST)
    - `suffix` (ST)
    - `prefix` (ST)
    - `degree` (IS)
    - `name_type_code` (ID)
    - `name_representation_code` (ID)
    - `name_context` (CE)
    - `name_validity` (DR)
    - `name_assembly_order` (ID)

  Subcomponents of `family_name`:

    - `surname` (ST)
    - `own_surname_prefix` (ST)
    - `own_surname` (ST)
    - `surname_prefix_from_partner` (ST)
    - `surname_from_partner` (ST)

  Subcomponents of `name_context`:

    - `id` (ST)
    - `text` (ST)
    - `coding_system` (IS)
    - `alt_id` (ST)
    - `alt_text` (ST)
    - `alt_coding_system` (IS)

  Subcomponents of `name_validity`:

    - `start_datetime` (TS)
    - `end_datetime` (TS)

  ## Examples

      |Smith^John^J^III^DR^PHD^L|

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE
  require HL7.Composite.Default.DR, as: DR
  require HL7.Composite.Default.FN, as: FN

  composite do
    component :family_name,              type: FN
    component :given_name,               type: :string
    component :second_name,              type: :string
    component :suffix,                   type: :string
    component :prefix,                   type: :string
    component :degree,                   type: :string
    component :name_type_code,           type: :string
    component :name_representation_code, type: :string
    component :name_context,             type: CE
    component :name_validity,            type: DR
    component :name_assembly_order,      type: :string
  end
end
