defmodule HL7.Composite.Default.XAD do
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
  use HL7.Composite.Spec

  require HL7.Composite.Default.DR, as: DR

  composite do
    component :street_address,         type: :string
    component :other_designation,      type: :string
    component :city,                   type: :string
    component :state,                  type: :string
    component :postal_code,            type: :string
    component :country,                type: :string
    component :address_type,           type: :string
    component :other_geo_designation,  type: :string
    component :county,                 type: :string
    component :census_tract,           type: :string
    component :adrress_representation, type: :string
    component :address_validity,       type: DR
  end
end
