defmodule HL7.Composite.Builder do
  @moduledoc """
  Behavior representing a module used to build HL7 composites based on their composite ID.
  """
  @callback module(HL7.Type.composite_id()) :: {:ok, module}
end
