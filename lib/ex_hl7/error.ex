defmodule HL7.Error do
  defexception reason: nil, segment: nil, sequence: nil

  def message(exception) do
    "#{inspect exception.description} in #{inspect exception.segment}.#{inspect exception.sequence}: #{inspect exception.reason}"
  end
end
