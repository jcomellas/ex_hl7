defmodule HL7.Composite do
  @moduledoc "Generic functions used by HL7 composite field macros"

  @type t          :: map
  @type descriptor :: {name :: atom, type :: atom}
  @type option     :: {:separators, [{key :: atom, separator :: byte}]} | {:trim, boolean}

  @spec id(t) :: HL7.Type.composite_id
  def id(composite) when is_map(composite), do: Map.get(composite, :__composite__)
  def id(_composite), do: nil

  @spec module(HL7.Type.composite_id) :: atom
  def module(id) when is_binary(id), do: Module.concat([HL7.Composite, id])

  @spec new(HL7.Type.composite_id) :: {module :: atom, t}
  def new(composite_id) do
    module = module(composite_id)
    {module, apply(module, :new, [])}
  end

  @doc """
  Checks if a composite field is empty. This function is implemented as a
  macro so that it can be used in guards.
  """
  # @spec empty?(HL7.value | t) :: boolean
  defmacro empty?(value) do
    quote do
      unquote(value) === "" or unquote(value) === nil
    end
  end

  @doc """
  Creates the map corresponding to the underlying struct in a composite field.
  """
  @spec decode(t, [descriptor], binary | tuple) :: t | no_return
  def decode(composite, descriptor, tuple) when is_tuple(tuple), do:
    decode_tuple(composite, descriptor, tuple, 0)
  def decode(composite, [{name, type} | _tail], value), do:
    Map.put(composite, name, maybe_decode_value(value, type))

  defp decode_tuple(composite, [{name, type} | tail], tuple, index) when index < tuple_size(tuple) do
    value = elem(tuple, index)
    composite = Map.put(composite, name, maybe_decode_value(value, type))
    decode_tuple(composite, tail, tuple, index + 1)
  end
  defp decode_tuple(composite, _descriptor, _tuple, _index) do
    composite
  end

  def maybe_decode_value(value, type) do
    case HL7.Codec.decode_value(value, type) do
      :nomatch ->
        # Do not create composite fields when they are null
        case value do
          ""     -> type.new()
          "\"\"" -> nil
          _      -> type.decode(value)
        end
      value ->
        value
    end
  end

  @doc """
  Converts the struct holding the composite field data into the tuple format
  accepted by the functions in `HL7.Writer`.
  """
  @spec encode(t, [descriptor]) :: HL7.Type.field | no_return
  def encode(composite, descriptor), do:
    encode(composite, descriptor, [])

  def encode(composite, [{name, type} | tail], acc) do
    value = maybe_encode_value(Map.get(composite, name), type)
    encode(composite, tail, [value | acc])
  end
  def encode(_composite, [], acc) do
    List.to_tuple(Enum.reverse(acc))
  end

  def maybe_encode_value(value, type) do
    case HL7.Codec.encode_value(value, type) do
      :nomatch -> apply(type, :encode, [value])
      value    -> value
    end
  end


  @doc """
  Converts a composite field into an iolist suitable to send over a socket or
  write to a file.
  """
  @spec to_iodata(t, [descriptor], [option]) :: iodata | no_return
  def to_iodata(composite, descriptor, options) do
    field = encode(composite, descriptor)
    separators = case Keyword.get(options, :separators) do
                   nil        -> HL7.Codec.separators()
                   separators -> separators
                 end
    trim = Keyword.get(options, :trim, true)
    HL7.Codec.encode_field(field, separators, trim)
  end
end

use HL7.Composite.Def

defmodule HL7.Composite.CE do
  @moduledoc """
  2.9.3 CE - coded element

  Components:

    * `identifier` (ST)
    * `text` (ST)
    * `coding_system` (IS)
    * `alt_id` (ST)
    * `alt_text` (ST)
    * `alt_coding_system` (IS)

  ## Examples

      |F-11380^CREATININE^I9^2148-5^CREATININE^LN|

  """
  composite do
    component :id,                             type: :string
    component :text,                           type: :string
    component :coding_system,                  type: :string
    component :alt_id,                         type: :string
    component :alt_text,                       type: :string
    component :alt_coding_system,              type: :string
  end
end

defmodule HL7.Composite.CM_ERR_1 do
  @moduledoc """
  2.16.5.1 ERR-1 Error code and location (CM) 00024

  Components:

    - `segment_id` (ST)
    - `sequence` (NM)
    - `field_pos` (NM)
    - `error` (CE)

  """
  alias HL7.Composite.CE

  composite do
    component :segment_id,                     type: :string
    component :sequence,                       type: :integer
    component :field_pos,                      type: :integer
    component :error,                          type: CE
  end
end

defmodule HL7.Composite.CM_IN1_14 do
  @moduledoc """
  6.5.6.14 IN1-14 Authorization information (CM) 00439

  Components:

    - `number` (ST)
    - `date` (DT)
    - `source` (ST)

  """
  composite do
    component :number,                         type: :string
    component :date,                           type: :date
    component :source,                         type: :string
  end
end

defmodule HL7.Composite.CM_MSH_9 do
  @moduledoc """
  2.16.9.9 MSH-9 Message type (CM) 00009

  Components:

    - `id` (ID)
    - `trigger_event` (ID)
    - `structure` (ID)

  """
  composite do
    component :id,                             type: :string
    component :trigger_event,                  type: :string
    component :structure,                      type: :string
  end
end

defmodule HL7.Composite.CM_PRD_7_3 do
  @moduledoc """
  Custom composite type for PRD-7.3

  Components:

    - `license_type`
    - `province_id`
    - `specialty_id`

  """
  composite do
    component :license_type,                   type: :string
    component :province_id,                    type: :string
    component :specialty_id,                   type: :string
  end
end

defmodule HL7.Composite.CM_PRD_7 do
  @moduledoc """
  11.6.3.7 PRD-7 Provider identifiers (CM) 01162

  Components:

    - `id` (ST)
    - `id_type` (IS)
    - `other` (ST)

  Definition: This repeating field contains the provider's unique identifiers
  such as UPIN, Medicare and Medicaid numbers.

  """
  alias HL7.Composite.CM_PRD_7_3

  composite do
    component :id,                             type: :string
    component :id_type,                        type: :string
    component :other,                          type: CM_PRD_7_3
  end
end

defmodule HL7.Composite.CM_QPD_3 do
  @moduledoc """
  QPD_Q15-3 Provider ID number (CM)

  Components:

    - `id` (ID)
    - `id_type` (IS)

  """
  composite do
    component :id,                             type: :string
    component :id_type,                        type: :string
  end
end

defmodule HL7.Composite.MO do
  @moduledoc """
  2.9.26 MO - money

  Components:

    - `quantity` (NM)
    - `denomination` (ID)

  """
  composite do
    component :quantity,                       type: :float
    component :denomination,                   type: :string
  end
end

defmodule HL7.Composite.CP do
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
  alias HL7.Composite.CE
  alias HL7.Composite.MO

  composite do
    component :price,                          type: MO
    component :price_type,                     type: :string
    component :from_value,                     type: :float
    component :to_value,                       type: :float
    component :range_units,                    type: CE
    component :range_type,                     type: :string
  end
end

defmodule HL7.Composite.CQ do
  @moduledoc """
  2.9.10 CQ - composite quantity with units

  Components:

    - `quantity` (NM)
    - `units` (CE)

  """
  alias HL7.Composite.CE

  composite do
    component :quantity,                       type: :integer
    component :units,                          type: CE
  end
end

defmodule HL7.Composite.HD do
  @moduledoc """
  2.9.5.4 Assigning authority (HD)

  Components:

    - `namespace_id` (IS)
    - `universal_id` (ST)
    - `universal_id_type` (ID)

  """
  composite do
    component :namespace_id,                   type: :string
    component :universal_id,                   type: :string
    component :universal_id_type,              type: :string
  end
end

defmodule HL7.Composite.CX do
  @moduledoc """
  2.9.12 CX - extended composite ID with check digit

  Components:

    - `id` (ST)
    - `check_digit` (ST)
    - `check_digit_scheme` (ID)
    - `assigning_authority` (HD)
    - `id_type` (ID)
    - `assigning_facility` (HD)
    - `effective_date` (DT)
    - `expiration_date` (DT)

  ## Examples

      |1234567^4^M11^ADT01^MR^University Hospital|

  """
  alias HL7.Composite.HD

  composite do
    component :id,                             type: :string
    component :check_digit,                    type: :string
    component :check_digit_scheme,             type: :string
    component :assigning_authority,            type: HD
    component :id_type,                        type: :string
    component :assigning_facility,             type: HD
    component :effective_date,                 type: :date
    component :expiration_date,                type: :date
  end
end

defmodule HL7.Composite.DR do
  @moduledoc """
  2.9.54.10 Name validity range (DR)

  This component contains the start and end date/times which define the
  period during which this name was valid.

  Components:

    - `start_datetime` (DT)
    - `end_datetime` (DT)

  """
  composite do
    component :start_datetime,                 type: :datetime
    component :end_datetime,                   type: :datetime
  end
end

defmodule HL7.Composite.EI do
  @moduledoc """
  2.9.17 EI - entity identifier

  Components:

    - `id` (ST)
    - `namespace_id` (IS)
    - `universal_id` (ST)
    - `universal_id_type` (ID)

  """
  composite do
    component :id,                             type: :string
    component :namespace_id,                   type: :string
    component :universal_id,                   type: :string
    component :universal_id_type,              type: :string
  end
end

defmodule HL7.Composite.FN do
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
  composite do
    component :surname,                        type: :string
    component :own_surname_prefix,             type: :string
    component :own_surname,                    type: :string
    component :surname_prefix_from_partner,    type: :string
    component :surname_from_partner,           type: :string
  end
end

defmodule HL7.Composite.CN do
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
  alias HL7.Composite.FN
  alias HL7.Composite.HD

  composite do
    component :id_number,                      type: :string
    component :family_name,                    type: FN
    component :given_name,                     type: :string
    component :second_name,                    type: :string
    component :suffix,                         type: :string
    component :prefix,                         type: :string
    component :degree,                         type: :string
    component :source_table,                   type: :string
    component :assigning_authority,            type: HD
  end
end

defmodule HL7.Composite.PL do
  @moduledoc """
  2.9.29 PL - person location

  Components:

    - `point_of_care` (IS)
    - `room` (IS)
    - `bed` (IS)
    - `facility` (HD)
    - `location_status` (IS )
    - `person_location_type` (IS)
    - `building` (IS )
    - `floor` (IS)
    - `location_description` (ST)

  *Note*: This data type contains several location identifiers that should be
  thought of in the following order from the most general to the most
  specific: facility, building, floor, point of care, room, bed.

  Additional data about any location defined by these components can be added
  in the following components: person location type, location description and
  location status.

  This data type is used to specify a patient location within a healthcare
  institution. Which components are valued depends on the needs of the site.
  For example for a patient treated at home, only the person location type is
  valued. It is most commonly used for specifying patient locations, but may
  refer to other types of persons within a healthcare setting.

  Example: Nursing Unit
  A nursing unit at Community Hospital: 4 East, room 136, bed B

      4E^136^B^CommunityHospital^^N^^^

  Example: Clinic
  A clinic at University Hospitals: Internal Medicine Clinic located in the
  Briones building, 3rd floor.

      InternalMedicine^^^UniversityHospitals^^C^Briones^3^

  Example: Home
  The patient was treated at his home.

      ^^^^^H^^^

  """
  alias HL7.Composite.HD

  composite do
    component :point_of_care,                  type: :string
    component :room,                           type: :string
    component :bed,                            type: :string
    component :facility,                       type: HD
    component :location_status,                type: :string
    component :person_location_type,           type: :string
    component :building,                       type: :string
    component :floor,                          type: :string
    component :location_description,           type: :string
  end
end

defmodule HL7.Composite.CM_OBR_15 do
  @moduledoc """
  7.4.1.15 OBR-15 Specimen source (CM) 00249

  Components:

    - `code` (CE)
    - `additives` (TX)
    - `free_text` (TX)
    - `body_site` (CE)
    - `site_modifier` (CE)
    - `collection_method` (CE)

  """
  alias HL7.Composite.CE

  composite do
    component :code,                           type: CE
    component :additives,                      type: :string
    component :free_text,                      type: :string
    component :body_site,                      type: CE
    component :site_modifier,                  type: CE
    component :collection_method,              type: CE
  end
end

defmodule HL7.Composite.CM_OBR_23 do
  @moduledoc """
  7.4.1.23 OBR-23 Charge to practice (CM) 00256

  Components:

    - `amount` (MO)
    - `charge_code` (CE)

  """
  alias HL7.Composite.CE
  alias HL7.Composite.MO

  composite do
    component :amount,                         type: MO
    component :charge_code,                    type: CE
  end
end

defmodule HL7.Composite.CM_OBR_26 do
  @moduledoc """
  7.4.1.26 OBR-26 Parent result (CM) 00259

  Components:

    - `observation_id` (CE)
    - `observation_sub_id` (ST)
    - `observation_result` (TX)

  """
  alias HL7.Composite.CE

  composite do
    component :observation_id,                 type: CE
    component :observation_sub_id,             type: :string
    component :observation_result,             type: :string
  end
end

defmodule HL7.Composite.CM_OBR_29 do
  @moduledoc """
  7.4.1.29 OBR-29 Parent (CM) 00261

  Components:

    - `placer_order` (EI)
    - `filler_order` (EI)

  """
  alias HL7.Composite.EI

  composite do
    component :placer_order,                   type: EI
    component :filler_order,                   type: EI
  end
end

defmodule HL7.Composite.CM_OBR_32 do
  @moduledoc """
  7.4.1.32 OBR-32 Principal result interpreter (CM) 00264

  Components:

    - `name` (CN)
    - `start_datetime` (TS)
    - `end_datetime` (TS)
    - `point_of_care` (IS)
    - `room` (IS)
    - `bed` (IS)
    - `facility` (HD)
    - `location_status` (IS)
    - `patient_location_type` (IS)
    - `building` (IS)
    - `floor` (IS)

  """
  alias HL7.Composite.CN
  alias HL7.Composite.HD

  composite do
    component :name,                           type: CN
    component :start_datetime,                 type: :datetime
    component :end_datetime,                   type: :datetime
    component :point_of_care,                  type: :string
    component :room,                           type: :string
    component :bed,                            type: :string
    component :facility,                       type: HD
    component :location_status,                type: :string
    component :patient_location_type,          type: :string
    component :building,                       type: :string
    component :floor,                          type: :string
  end
end

defmodule HL7.Composite.CM_TQ_2 do
  @moduledoc """
  4.3.2 Interval component (CM)

  Subcomponents:

    - `repeat_pattern` (IS)
    - `explicit_interval` (ST)

  """
  composite do
    component :repeat_pattern,                 type: :string
    component :explicit_interval,              type: :string
  end
end

defmodule HL7.Composite.CM_TQ_10 do
  @moduledoc """
  4.3.10 Order sequencing component (CM)
  """
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

defmodule HL7.Composite.TQ do
  @moduledoc """
  4.3 Quantity/Timing (TQ) data type definition

  Components:

    - `quantity` (CQ)
    - `interval` (CM)
    - `duration` (ST)
    - `start_datetime` (TS)
    - `end_datetime` (TS)
    - `priority` (ST)
    - `condition` (ST)
    - `text` (TX)
    - `conjunction` (ID)
    - `order_sequencing` (CM)
    - `occurrence_duration` (CE)
    - `total_occurrences` (NM)

  """
  alias HL7.Composite.CE
  alias HL7.Composite.CQ
  alias HL7.Composite.CM_TQ_2
  alias HL7.Composite.CM_TQ_10
  alias HL7.Composite.HD

  composite do
    component :quantity,                       type: CQ
    component :interval,                       type: CM_TQ_2
    component :duration,                       type: :string
    component :start_datetime,                 type: :datetime
    component :end_datetime,                   type: :datetime
    component :priority,                       type: :string
    component :condition,                      type: :string
    component :text,                           type: :string
    component :conjunction,                    type: :string
    component :order_sequencing,               type: CM_TQ_10
    component :order_duration,                 type: CE
    component :total_occurrences,              type: :integer
  end
end

defmodule HL7.Composite.XAD do
  @moduledoc """
  2.9.51 XAD - extended address

  Components:

    - `street_address` (SAD)
    - `other_designation` (ST)
    - `city` (ST)
    - `state` (ST)
    - `postal_code` (ST)
    - `country` (ID)
    - `address_type` (ID)
    - `other_geo_designation` (ST)
    - `county` (IS)
    - `census_tract` (IS)
    - `address_representation` (ID)
    - `address_validity` (DR)

  Subcomponents of street address (SAD):

    - `mailing_address` (ST)
    - `street_name` (ST)
    - `dwelling_number` (ST)

  Subcomponents of address validity range (DR):

    - `start_datetime` (TS)
    - `end_datetime` (TS)

  Example of usage for US:

      |1234 Easy St.^Ste. 123^San Francisco^CA^95123^USA^B^^SF^|

  This would be formatted for postal purposes as

      1234 Easy St.
      Ste. 123
      San Francisco CA 95123

  Example of usage for Australia:

      |14th Floor^50 Paterson St^Coorparoo^QLD^4151|

  This would be formatted for postal purposes using the same rules as for the
  American example as

      14th Floor
      50 Paterson St
      Coorparoo QLD 4151

  """
  alias HL7.Composite.DR

  composite do
    component :street_address,                 type: :string
    component :other_designation,              type: :string
    component :city,                           type: :string
    component :state,                          type: :string
    component :postal_code,                    type: :string
    component :country,                        type: :string
    component :address_type,                   type: :string
    component :other_geo_designation,          type: :string
    component :county,                         type: :string
    component :census_tract,                   type: :string
    component :adrress_representation,         type: :string
    component :address_validity,               type: DR
  end
end

defmodule HL7.Composite.XCN do
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
  alias HL7.Composite.CE
  alias HL7.Composite.DR
  alias HL7.Composite.HD

  composite do
    component :id_number,                      type: :string
    component :family_name,                    type: :string
    component :given_name,                     type: :string
    component :second_name,                    type: :string
    component :suffix,                         type: :string
    component :prefix,                         type: :string
    component :degree,                         type: :string
    component :source_table,                   type: :string
    component :assigning_authority,            type: HD
    component :name_type_code,                 type: :string
    component :check_digit,                    type: :string
    component :check_digit_scheme,             type: :string
    component :id_type,                        type: :string
    component :assigning_facility,             type: HD
    component :name_representation_code,       type: :string
    component :name_context,                   type: CE
    component :name_validity,                  type: DR
    component :name_assembly_order,            type: :string
  end
end

defmodule HL7.Composite.XPN do
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
  alias HL7.Composite.CE
  alias HL7.Composite.DR
  alias HL7.Composite.FN

  composite do
    component :family_name,                    type: FN
    component :given_name,                     type: :string
    component :second_name,                    type: :string
    component :suffix,                         type: :string
    component :prefix,                         type: :string
    component :degree,                         type: :string
    component :name_type_code,                 type: :string
    component :name_representation_code,       type: :string
    component :name_context,                   type: CE
    component :name_validity,                  type: DR
    component :name_assembly_order,            type: :string
  end
end

defmodule HL7.Composite.XTN do
  @moduledoc """
  2.9.55 XTN - extended telecommunication number

  Components:

    - `formatted_phone_number` (ST): [NNN] [(999)]999-9999 [X99999] [B99999] [C any text]
    - `telecom_use_code` (ID)
    - `telecom_equipment_type` (ID)
    - `email` (ST)
    - `country_code` (NM)
    - `area_code` (NM)
    - `phone_number` (NM)
    - `extension` (NM)
    - `any_text` (ST)

  """
  composite do
    component :formatted_phone_number,         type: :string
    component :telecom_use_code,               type: :string
    component :telecom_equipment_type,         type: :string
    component :email,                          type: :string
    component :country_code,                   type: :integer
    component :area_code,                      type: :integer
    component :phone_number,                   type: :integer
    component :extension,                      type: :integer
    component :any_text,                       type: :string
  end
end
