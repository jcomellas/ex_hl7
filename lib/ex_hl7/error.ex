defmodule HL7.ReadError do
  defexception reason: nil, segment_id: nil, sequence: nil, value: nil

  @doc """
  Creates an `HL7.ReadError` exception based on the return value of
  `HL7.Reader.read/2`.
  """
  def exception({reason, data}) when is_atom(reason) and is_list(data),
    do: %HL7.ReadError{
      reason: reason,
      segment_id: Keyword.get(data, :segment_id),
      sequence: Keyword.get(data, :sequence),
      value: Keyword.get(data, :value)
    }

  def exception(reason) when is_atom(reason), do: %HL7.ReadError{reason: reason}
  def exception({:error, reason}), do: exception(reason)

  def message(%HL7.ReadError{reason: :incomplete}) do
    "incomplete HL7 message; please use HL7.read/2 to read partial messages"
  end

  def message(%HL7.ReadError{reason: :bad_segment_id, value: value}) do
    "unknown HL7 segment ID '#{value}'"
  end

  def message(%HL7.ReadError{
        reason: reason,
        segment_id: segment_id,
        sequence: sequence,
        value: value
      }) do
    case reason do
      :bad_delimiters ->
        "invalid HL7 delimiter definition '#{value}' in field #{segment_id}.#{sequence}"

      :bad_field ->
        "invalid value '#{value}' for HL7 field #{segment_id}.#{sequence}"

      :bad_separator ->
        "invalid HL7 separator '#{value}' after field #{segment_id}.#{sequence}"
    end
  end
end
