defmodule HL7.Composite.Default.TQ do
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
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE
  require HL7.Composite.Default.CM_TQ_2, as: CM_TQ_2
  require HL7.Composite.Default.CM_TQ_10, as: CM_TQ_10
  require HL7.Composite.Default.CQ, as: CQ

  composite do
    component :quantity,          type: CQ
    component :interval,          type: CM_TQ_2
    component :duration,          type: :string
    component :start_datetime,    type: :datetime
    component :end_datetime,      type: :datetime
    component :priority,          type: :string
    component :condition,         type: :string
    component :text,              type: :string
    component :conjunction,       type: :string
    component :order_sequencing,  type: CM_TQ_10
    component :order_duration,    type: CE
    component :total_occurrences, type: :integer
  end
end
