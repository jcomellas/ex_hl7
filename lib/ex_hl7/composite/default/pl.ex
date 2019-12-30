defmodule HL7.Composite.Default.PL do
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
  use HL7.Composite.Spec

  require HL7.Composite.Default.HD, as: HD

  composite do
    component :point_of_care,        type: :string
    component :room,                 type: :string
    component :bed,                  type: :string
    component :facility,             type: HD
    component :location_status,      type: :string
    component :person_location_type, type: :string
    component :building,             type: :string
    component :floor,                type: :string
    component :location_description, type: :string
  end
end
