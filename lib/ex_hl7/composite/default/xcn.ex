defmodule HL7.Composite.Default.XCN do
  @moduledoc """
  2.9.52 XCN - extended composite ID number and name for persons

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
    - `name_type_code` (ID)
    - `check_digit` (ST)
    - `check_digit_scheme` (ID)
    - `id_type` (IS)
    - `assigning_facility` (HD)
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

  Subcomponents of `assigning_authority`:

    - `namespace_id` (IS)
    - `universal_id` (ST)
    - `universal_id_type` (ID)

  Subcomponents of `assigning_facility`:

    - `namespace_id` (IS)
    - `universal_id` (ST)
    - `universal_id_type` (ID)

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

  This data type is used extensively appearing in the PV1, ORC, RXO, RXE, OBR
  and SCH segments, as well as others, where there is a need to specify the
  ID number and name of a person.

  ## Examples

    Neither an assigning authority nor an assigning facility are present in the
    example:

      |1234567^Smith^John^J^III^DR^PHD^ADT01^^L^4^M11^MR|

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE
  require HL7.Composite.Default.DR, as: DR
  require HL7.Composite.Default.HD, as: HD

  composite do
    component :id_number,                type: :string
    component :family_name,              type: :string
    component :given_name,               type: :string
    component :second_name,              type: :string
    component :suffix,                   type: :string
    component :prefix,                   type: :string
    component :degree,                   type: :string
    component :source_table,             type: :string
    component :assigning_authority,      type: HD
    component :name_type_code,           type: :string
    component :check_digit,              type: :string
    component :check_digit_scheme,       type: :string
    component :id_type,                  type: :string
    component :assigning_facility,       type: HD
    component :name_representation_code, type: :string
    component :name_context,             type: CE
    component :name_validity,            type: DR
    component :name_assembly_order,      type: :string
  end
end
