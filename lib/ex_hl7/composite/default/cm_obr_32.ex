defmodule HL7.Composite.Default.CM_OBR_32 do
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
  use HL7.Composite.Spec

  require HL7.Composite.Default.CN, as: CN
  require HL7.Composite.Default.HD, as: HD

  composite do
    component :name,                  type: CN
    component :start_datetime,        type: :datetime
    component :end_datetime,          type: :datetime
    component :point_of_care,         type: :string
    component :room,                  type: :string
    component :bed,                   type: :string
    component :facility,              type: HD
    component :location_status,       type: :string
    component :patient_location_type, type: :string
    component :building,              type: :string
    component :floor,                 type: :string
  end
end
