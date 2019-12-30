defmodule HL7.Segment.Builder do
  @moduledoc """
  Behavior representing a module used to build HL7 segments based on their segment ID.
  """
  alias HL7.Segment
  alias HL7.Type

  @callback segment_module(Type.segment_id()) :: {:ok, module} | :error
  @callback segment_spec(Type.segment_id()) :: {:ok, Segment.spec()} | :error
  @callback new(Type.segment_id()) :: {:ok, {Segment.t(), Segment.spec()}} | :error
  @callback new(Type.segment_id(), Keyword.t(Type.value())) ::
              {:ok, {Segment.t(), Segment.spec()}} | :error
end
