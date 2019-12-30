defmodule HL7.Segment.Default.ERR do
  @moduledoc "2.16.5 ERR - error segment"
  use HL7.Segment.Spec

  require HL7.Composite.Default.CM_ERR_1, as: CM_ERR_1

  segment "ERR" do
    field :segment_id, seq:  1, type: {CM_ERR_1, :segment_id}, length: 3
    field :sequence,   seq:  1, type: {CM_ERR_1, :sequence}, length: 3
    field :field_pos,  seq:  1, type: {CM_ERR_1, :field_pos}, length: 3
    field :error_code, seq:  1, type: {CM_ERR_1, :error, :id}, length: 9
    field :error_text, seq:  1, type: {CM_ERR_1, :error, :text}, length: 61
  end
end
