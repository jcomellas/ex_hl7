defmodule HL7.Message do
  @moduledoc """
  Module used to read, write and retrieve segments from an HL7 message.

  Each message is represented as a list of HL7 segments in the order in which
  they appeared in the original message.
  """
  alias HL7.Reader
  alias HL7.Writer

  @type option     :: {:format, :stdio | :wire}
  @type t          :: [HL7.Segment.t]
  @type read_ret   :: {:ok, t} |
                      {:incomplete, {(binary -> read_ret), binary}} |
                      {:error, reason :: any}


  @spec segment(t, HL7.Type.segment_id, repetition :: non_neg_integer) :: HL7.Segment.t
  def segment(message, segment_id, repetition \\ 0)

  def segment(message, segment_id, repetition) do
    case segment_tail(message, segment_id, repetition) do
      {segment, _tail} -> segment
      nil              -> nil
    end
  end

  @spec paired_segments(t, [HL7.Type.segment_id], repetition :: non_neg_integer) :: [HL7.Segment.t]
  def paired_segments(message, segment_ids, repetition \\ 0)

  def paired_segments(message, [segment_id | tail2], repetition) do
    case segment_tail(message, segment_id, repetition) do
      {segment, tail1} -> _paired_segments(tail1, tail2, [segment])
      nil              -> []
    end
  end
  def paired_segments(_message, [], _repetition) do
    []
  end

  defp _paired_segments([segment | tail1], [segment_id | tail2], acc) do
    case HL7.Segment.id(segment) do
      ^segment_id -> _paired_segments(tail1, tail2, [segment | acc])
      _           -> Enum.reverse(acc)
    end
  end
  defp _paired_segments(_message, _segment_ids, acc) do
    Enum.reverse(acc)
  end

  defp segment_tail([segment | tail], segment_id, repetition) do
    case HL7.Segment.id(segment) do
      ^segment_id ->
        if repetition === 0 do
          {segment, tail}
        else
          segment_tail(tail, segment_id, repetition - 1)
        end
      _ ->
        segment_tail(tail, segment_id, repetition)
    end
  end
  defp segment_tail([], _segment_id, _repetition) do
    nil
  end

  @spec segment_count(t, HL7.Type.segment_id) :: non_neg_integer
  def segment_count(segments, segment_id) when is_list(segments), do:
    _segment_count(segments, segment_id, 0)

  defp _segment_count([{segment_id, _fields} | tail], segment_id, count), do:
    _segment_count(tail, segment_id, count + 1)
  defp _segment_count([_segment | tail], segment_id, count), do:
    _segment_count(tail, segment_id, count)
  defp _segment_count([], _segment_id, count), do:
    count


  @spec read(HL7.Reader.t, buffer :: binary) :: read_ret
  def read(reader, buffer), do:
    read(reader, buffer, [])

  def read(reader, buffer, acc) do
    case Reader.read(reader, buffer) do
      {:token, {reader, {:start_segment, segment_id}, buffer}} ->
        module = HL7.Segment.module(segment_id)
        segment = apply(module, :new, [])
        case read_segment(reader, segment, module, buffer) do
          {:ok, {reader, segment, buffer}} ->
            read(reader, buffer, [segment | acc])
          {:incomplete, {reader, segment, module, buffer}} ->
            {:incomplete, {&complete_read(reader, segment, module, &1, acc), buffer}}
          {:error, _reason} = error ->
            error
        end
      {:complete, _reader} ->
        {:ok, Enum.reverse(acc)}
    end
  end

  def complete_read(reader, segment, module, buffer, acc) do
    case read_segment(reader, segment, module, buffer) do
      {:ok, {reader, segment, buffer}} ->
        read(reader, buffer, [segment | acc])
      result ->
        result
    end
  end

  def read_segment(reader, segment, module, buffer) do
    case Reader.read(reader, buffer) do
      {:token, {reader, {:field, field}, buffer}} ->
        segment = apply(module, :put_field, [segment, Reader.sequence(reader), field])
        read_segment(reader, segment, module, buffer)
      {:token, {reader, {:end_segment, _segment_id}, buffer}} ->
        {:ok, {reader, segment, buffer}}
      {:incomplete, {reader, buffer}} ->
        {:incomplete, {reader, segment, module, buffer}}
      {:error, _reason} = error ->
        # raise HL7.Error, reason: reason, segment: HL7.Reader.segment_id(reader),
        #       sequence: HL7.Reader.sequence(reader)
        error
    end
  end


  @spec write(HL7.Writer.t, t) :: iodata
  def write(writer, message) do
    writer
    |> Writer.start_message()
    |> write_segments(message)
    |> Writer.end_message()
    |> Writer.buffer
  end

  defp write_segments(writer, [segment | tail]) do
    segment_id = HL7.Segment.id(segment)
    module = HL7.Segment.module(segment_id)
    field_count = apply(module, :field_count, [])

    writer = writer
             |> Writer.start_segment(segment_id)
             |> write_fields(segment, module, field_count, 1)
             |> Writer.end_segment(segment_id)

    write_segments(writer, tail)
  end
  defp write_segments(writer, []) do
    writer
  end

  defp write_fields(writer, segment, module, field_count, seq)
   when seq <= field_count do
    field = apply(module, :get_field, [segment, seq])
    writer = Writer.put_field(writer, field)
    write_fields(writer, segment, module, field_count, seq + 1)
  end
  defp write_fields(writer, _segment, _module, _field_count, _seq) do
    writer
  end
end
