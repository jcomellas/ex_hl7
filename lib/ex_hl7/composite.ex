defmodule HL7.Composite do
  @moduledoc "HL7 Composite fields and components"
  use HL7.Composite.Def

  defmodule CE do
    @moduledoc """
    2.9.3 CE - coded element

    Components: <identifier (ST)> ^ <text (ST)> ^ <name of coding system (IS)> ^
                <alternate identifier (ST)> ^ <alternate text (ST)> ^
                <name of alternate coding system (IS)>

    Example: |F-11380^CREATININE^I9^2148-5^CREATININE^LN|
    """
    composite do
      component :id,                           type: :string
      component :text,                         type: :string
      component :coding_system,                type: :string
      component :alt_id,                       type: :string
      component :alt_text,                     type: :string
      component :alt_coding_system,            type: :string
    end
  end

  defmodule CM_ERR do
    @moduledoc """
    2.16.5.1 ERR-1 Error code and location (CM) 00024

    Components: <segment ID (ST)> ^ <sequence (NM)> ^ <field position (NM)> ^
                <code identifying error (CE)>
    """
    composite do
      component :segment_id,                   type: :string
      component :sequence,                     type: :integer
      component :field_pos,                    type: :integer
      component :error,                        type: CE,       default: %CE{}
    end
  end

  defmodule CM_IN1 do
    @moduledoc """
    6.5.6.14 IN1-14 Authorization information (CM) 00439

    Components: <authorization number (ST)> ^ <date (DT)> ^ <source (ST)>
    """
    composite do
      component :number,                       type: :string
      component :date,                         type: :date
      component :source,                       type: :string
    end
  end

  defmodule CM_PRD do
    @moduledoc """
    11.6.3.7 PRD-7 Provider identifiers (CM) 01162

    Components: <ID number (ST)> ^ <type of ID number (IS)> ^ <other qualifying info (ST)>

    Definition: This repeating field contains the provider's unique identifiers
    such as UPIN, Medicare and Medicaid numbers.
    """
    composite do
      component :id_number,                    type: :string
      component :id_number_type,               type: :string
      component :other_info,                   type: :string
    end
  end

  defmodule CM_MSH do
    @moduledoc """
    2.16.9.9 MSH-9 Message type (CM) 00009 

    Components: <message type (ID)> ^ <trigger event (ID)> ^ <message structure (ID)>
    """
    composite do
      component :id,                           type: :string
      component :trigger_event,                type: :string
      component :structure,                    type: :string
    end
  end

  defmodule CM_QPD do
    @moduledoc """
    QPD_Q15-3 Provider ID number (CM)

    Components: <ID number (ID)> ^ <type of ID number (IS)>
    """
    composite do
      component :id_number,                    type: :string
      component :id_number_type,               type: :string
    end
  end

  defmodule MO do
    @moduledoc """
    2.9.26 MO - money

    Components: <quantity (NM)> ^ <denomination (ID)>
    """
    composite do
      component :quantity,                     type: :float
      component :denomination,                 type: :string
    end
  end

  defmodule CP do
    @moduledoc """
    2.9.9 CP - composite price

    Components: <price (MO)> ^ <price type (ID)> ^ <from value (NM)> ^
                <to value (NM)> ^ <range units (CE)> ^ <range type (ID)>

    Subcomponents of price: <quantity (NM)> & <denomination (ID)>

    Example:

        |100.00&USD^UP^0^9^min^P~50.00&USD^UP^10^59^min^P~
         10.00&USD^UP^60^999^P~50.00&USD^AP~200.00&USD^PF~80.00&USD^DC|
    """
    composite do
      component :price,                        type: MO
      component :price_type,                   type: :string
      component :from_value,                   type: :float
      component :to_value,                     type: :float
      component :range_units,                  type: CE,       default: %CE{}
      component :range_type,                   type: :string
    end
  end

  defmodule CQ do
    @moduledoc """
    2.9.10 CQ - composite quantity with units

    Components: <quantity (NM)> ^ <units (CE)>
    """
    composite do
      component :quantity,                     type: :integer
      component :units,                        type: CE,       default: %CE{}
    end
  end

  defmodule HD do
    @moduledoc """
    2.9.5.4 Assigning authority (HD)

    Components: <namespace ID (IS)> ^ <universal ID (ST)> ^ <universal ID type (ID)>
    """
    composite do
      component :namespace_id,                 type: :string
      component :universal_id,                 type: :string
      component :universal_id_type,            type: :string
    end
  end

  defmodule CX do
    @moduledoc """
    2.9.12 CX - extended composite ID with check digit

    Components: <ID (ST)> ^ <check digit (ST)> ^
                <code identifying the check digit scheme employed (ID)> ^
                <assigning authority (HD)> ^ <identifier type code (ID)> ^
                <assigning facility (HD) ^ <effective date (DT)> ^
                <expiration date (DT)>

    Example:

        |1234567^4^M11^ADT01^MR^University Hospital|
    """
    composite do
      component :id,                           type: :string
      component :check_digit,                  type: :string
      component :check_digit_scheme,           type: :string
      component :assigning_authority,          type: HD,       default: %HD{}
      component :id_type,                      type: :string
      component :assigning_facility,           type: HD,       default: %HD{}
      component :effective_date,               type: :date
      component :expiration_date,              type: :date
    end
  end

  defmodule DR do
    @moduledoc """
    2.9.54.10 Name validity range (DR)

    This component contains the start and end date/times which define the
    period during which this name was valid.
    """
    composite do
      component :start_datetime,               type: :datetime
      component :end_datetime,                 type: :datetime
    end
  end

  defmodule EI do
    @moduledoc """
    2.9.17 EI - entity identifier

    Components: <entity identifier (ST)> ^ <namespace ID (IS)> ^
                <universal ID (ST)> ^ < universal ID type (ID)>
    """
    composite do
      component :id,                           type: :string
      component :namespace_id,                 type: :string
      component :universal_id,                 type: :string
      component :universal_id_type,            type: :string
    end
  end

  defmodule FN do
    @moduledoc """
    2.9.19 FN - family name

    Components: <surname (ST)> ^ <own surname prefix (ST)> ^ <own surname (ST)> ^
                <surname prefix from partner/spouse (ST)> ^
                <surname from partner/spouse (ST)>

    This data type allows full specification of the surname of a person. Where
    appropriate, it differentiates the person's own surname from that of the
    person's partner or spouse, in cases where the person's name may contain
    elements from either name. It also permits messages to distinguish the
    surname prefix (such as "van" or "de") from the surname root.
    """
    composite do
      component :surname,                      type: :string
      component :own_surname_prefix,           type: :string
      component :own_surname,                  type: :string
      component :surname_prefix_from_partner,  type: :string
      component :surname_from_partner,         type: :string
    end
  end

  defmodule PL do
    @moduledoc """
    2.9.29 PL - person location

    Components: <point of care (IS)> ^ <room (IS)> ^ <bed (IS)> ^
                <facility (HD)> ^ < location status (IS )> ^
                <person location type (IS)> ^ <building (IS )> ^
                <floor (IS)> ^ <location description (ST)>

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
    composite do
      component :point_of_care,                type: :string
      component :room,                         type: :string
      component :bed,                          type: :string
      component :facility,                     type: HD,       default: %HD{}
      component :location_status,              type: :string
      component :person_location_type,         type: :string
      component :building,                     type: :string
      component :floor,                        type: :string
      component :location_description,         type: :string
    end
  end

  defmodule XAD do
    @moduledoc """
    2.9.51 XAD - extended address

    Components: <street address (SAD)> ^ <other designation (ST)> ^
                <city (ST)> ^ <state or province (ST)> ^
                <zip or postal code (ST)> ^ <country (ID)> ^
                <address type (ID)> ^ <other geographic designation (ST)> ^
                <county/parish code (IS)> ^ <census tract (IS)> ^
                <address representation code (ID)> ^
                <address validity range (DR)>

    Subcomponents of street address (SAD): <street or mailing address (ST)> &
                                           <street name (ST)> & <dwelling number (ST)>

    Subcomponents of address validity range (DR): <date range start date/time (TS)> &
                                                  <date range end date/time (TS)>

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
    composite do
      component :street_address,               type: :string
      component :other_designation,            type: :string
      component :city,                         type: :string
      component :state,                        type: :string
      component :postal_code,                  type: :string
      component :country,                      type: :string
      component :address_type,                 type: :string
      component :other_geo_designation,        type: :string
      component :county,                       type: :string
      component :census_tract,                 type: :string
      component :adrress_representation,       type: :string
      component :address_validity,             type: DR,       default: %DR{}
    end    
  end

  defmodule XCN do
    @moduledoc """
    2.9.52 XCN - extended composite ID number and name for persons

    Components: <ID number (ST)> ^ <family name (FN)> ^ <given name (ST)> ^
                <second and further given names or initials thereof (ST)> ^
                <suffix (e.g., JR or III) (ST)> ^ <prefix (e.g., DR) (ST)> ^
                <degree (e.g., MD) (IS)> ^ <source table (IS)> ^
                <assigning authority (HD)> ^ <name type code (ID)> ^
                <identifier check digit (ST)> ^
                <code identifying the check digit scheme employed (ID)> ^
                <identifier type code (IS)> ^ <assigning facility (HD)> ^
                <name representation code (ID)> ^ <name context (CE)> ^
                <name validity range (DR)> ^ <name assembly order (ID)>

    Subcomponents of family name: <surname (ST)> & <own surname prefix (ST)> &
                                  <own surname (ST)> &
                                  <surname prefix from partner/spouse (ST)> &
                                  <surname from partner/spouse (ST)>

    Subcomponents of assigning authority: <namespace ID (IS)> & <universal ID (ST)> &
                                          <universal ID type (ID)>

    Subcomponents of assigning facility: <namespace ID (IS)> & <universal ID (ST)> &
                                         <universal ID type (ID)>

    Subcomponents of name context: <identifier (ST)> & <text (ST)> &
                                   <name of coding system (IS)> &
                                   <alternate identifier (ST)> & <alternate text (ST)> &
                                   <name of alternate coding system (IS)>

    Subcomponents of name validity range: <date range start date/time (TS)> &
                                          <date range end date/time (TS)>

    This data type is used extensively appearing in the PV1, ORC, RXO, RXE, OBR
    and SCH segments, as well as others, where there is a need to specify the
    ID number and name of a person.

    Example without assigning authority and assigning facility:

        |1234567^Smith^John^J^III^DR^PHD^ADT01^^L^4^M11^MR|
    """
    composite do
      component :id_number,                    type: :string
      component :family_name,                  type: :string
      component :given_name,                   type: :string
      component :second_name,                  type: :string
      component :suffix,                       type: :string
      component :prefix,                       type: :string
      component :degree,                       type: :string
      component :source_table,                 type: :string
      component :assigning_authority,          type: HD,       default: %HD{}
      component :name_type_code,               type: :string
      component :check_digit,                  type: :string
      component :check_digit_scheme,           type: :string
      component :id_type,                      type: :string
      component :assigning_facility,           type: HD,       default: %HD{}
      component :name_representation_code,     type: :string
      component :name_context,                 type: CE,       default: %CE{}
      component :name_validity,                type: DR,       default: %DR{}
      component :name_assembly_order,          type: :string
    end
  end

  defmodule XPN do
    @moduledoc """
    2.9.54 XPN - extended person name

    Components: <family name (FN)> ^ <given name (ST)> ^
                <second and further given names or initials thereof (ST)> ^
                <suffix (e.g., JR or III) (ST)> ^ <prefix (e.g., DR) (ST)> ^
                <degree (e.g., MD) (IS)> ^ <name type code (ID) > ^
                <name representation code (ID)> ^ <name context (CE)> ^
                <name validity range (DR)> ^ <name assembly order (ID)>

    Subcomponents of family name: <surname (ST)> ^ <own surname prefix (ST)> ^
                                  <own surname (ST)> ^ <surname prefix from partner/spouse (ST)> ^
                                  <surname from partner/spouse (ST)>

    Subcomponents of name context: <identifier (ST)> & <text (ST)> & <name of coding system (IS)> &
                                   <alternate identifier (ST)> & <alternate text (ST)> &
                                   <name of alternate coding system (IS)>

    Subcomponents of name validity range: <date range start date/time (TS)> & <date range end date/time (TS)>

    Example: `|Smith^John^J^III^DR^PHD^L|`
    """
    composite do
      component :family_name,                  type: :string
      component :given_name,                   type: :string
      component :second_name,                  type: :string
      component :suffix,                       type: :string
      component :prefix,                       type: :string
      component :degree,                       type: :string
      component :name_type_code,               type: :string
      component :name_representation_code,     type: :string
      component :name_context,                 type: CE,       default: %CE{}
      component :name_validity,                type: DR,       default: %DR{}
      component :name_assembly_order,          type: :string
    end
  end

end
