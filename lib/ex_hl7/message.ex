defmodule HL7.Message do
  @moduledoc """
  Module used to read, write and retrieve segments from an HL7 message.

  Each message is represented as a list of HL7 segments in the order in which
  they appeared in the original message.
  """
  alias HL7.Reader
  alias HL7.Writer

  @type t          :: [HL7.Segment.t]
  @type read_ret   :: {:ok, t} |
                      {:incomplete, {(binary -> read_ret), binary}} |
                      {:error, reason :: any}


  @spec segment(t, HL7.Type.segment_id, HL7.Type.repetition) :: HL7.Segment.t
  def segment(message, segment_id, repetition \\ 0)

  def segment(message, segment_id, repetition) do
    case tail_at_segment(message, segment_id, repetition) do
      {segment, _tail} -> segment
      nil              -> nil
    end
  end

  @spec paired_segments(t, [HL7.Type.segment_id], HL7.Type.repetition) :: [HL7.Segment.t]
  def paired_segments(message, segment_ids, repetition \\ 0)

  def paired_segments(message, [segment_id | tail2], repetition) do
    case tail_at_segment(message, segment_id, repetition) do
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

  defp tail_at_segment([segment | tail], segment_id, repetition) do
    case HL7.Segment.id(segment) do
      ^segment_id ->
        if repetition === 0 do
          {segment, tail}
        else
          tail_at_segment(tail, segment_id, repetition - 1)
        end
      _ ->
        tail_at_segment(tail, segment_id, repetition)
    end
  end
  defp tail_at_segment([], _segment_id, _repetition) do
    nil
  end

  @spec segment_count(t, HL7.Type.segment_id) :: non_neg_integer
  def segment_count(segments, segment_id)
   when is_list(segments) and is_binary(segment_id), do:
    segment_count(segments, segment_id, 0)

  defp segment_count([segment | tail], segment_id, count) do
    count = case HL7.Segment.id(segment) do
              ^segment_id -> count + 1
              _           -> count
            end
    segment_count(tail, segment_id, count)
  end
  defp segment_count([], _segment_id, count) do
    count
  end

  @spec delete(t, HL7.Type.segment_id, HL7.Type.repetition) :: t
  def delete(message, segment_id, repetition \\ 0) do
    case split_at_segment(message, segment_id, repetition, []) do
      {_segment, tail, acc} ->
        Enum.reverse(acc, tail)
      _acc ->
        message
    end
  end

  @spec insert_before(t, HL7.Type.segment_id, HL7.Segment.t | [HL7.Segment.t]) :: t
  def insert_before(message, segment_id, segment), do:
    insert_before(message, segment_id, 0, segment)

  @spec insert_before(t, HL7.Type.segment_id, HL7.Type.repetition,
                      HL7.Segment.t | [HL7.Segment.t]) :: t
  def insert_before(message, segment_id, repetition, new_segments)
   when is_list(message) and is_binary(segment_id) and is_integer(repetition) and
        is_list(new_segments) do
    case split_at_segment(message, segment_id, repetition, []) do
      {segment, tail, acc} ->
        Enum.reverse(acc, new_segments ++ [segment | tail])
      _acc ->
        message
    end
  end
  def insert_before(message, segment_id, repetition, new_segment)
   when is_map(new_segment) do
    insert_before(message, segment_id, repetition, [new_segment])
  end

  @spec insert_after(t, HL7.Type.segment_id, HL7.Segment.t | [HL7.Segment.t]) :: t
  def insert_after(message, segment_id, segment), do:
    insert_after(message, segment_id, 0, segment)

  @spec insert_after(t, HL7.Type.segment_id, HL7.Type.repetition,
                     HL7.Segment.t | [HL7.Segment.t]) :: t
  def insert_after(message, segment_id, repetition, new_segments)
   when is_list(message) and is_binary(segment_id) and is_integer(repetition) and
        is_list(new_segments) do
    case split_at_segment(message, segment_id, repetition, []) do
      {segment, tail, acc} ->
        Enum.reverse(acc, [segment | (new_segments ++ tail)])
      _acc ->
        message
    end
  end
  def insert_after(message, segment_id, repetition, new_segment)
   when is_map(new_segment) do
    insert_after(message, segment_id, repetition, [new_segment])
  end

  @spec replace(t, HL7.Type.segment_id, HL7.Segment.t | [HL7.Segment.t]) :: t
  def replace(message, segment_id, segment), do:
    replace(message, segment_id, 0, segment)

  @spec replace(t, HL7.Type.segment_id, HL7.Type.repetition,
                HL7.Segment.t | [HL7.Segment.t]) :: t
  def replace(message, segment_id, repetition, new_segments)
   when is_list(message) and is_binary(segment_id) and is_integer(repetition) and
        is_list(new_segments) do
    case split_at_segment(message, segment_id, repetition, []) do
      {_segment, tail, acc} ->
        Enum.reverse(acc, new_segments ++ tail)
      _acc ->
        message
    end
  end
  def replace(message, segment_id, repetition, new_segment)
   when is_map(new_segment) do
    replace(message, segment_id, repetition, [new_segment])
  end

  defp split_at_segment([segment | tail], segment_id, repetition, acc) do
    case HL7.Segment.id(segment) do
      ^segment_id ->
        if repetition === 0 do
          {segment, tail, acc}
        else
          split_at_segment(tail, segment_id, repetition - 1, [segment | acc])
        end
      _ ->
        split_at_segment(tail, segment_id, repetition, [segment | acc])
    end
  end
  defp split_at_segment([], _segment_id, _repetition, acc) do
    acc
  end

  @doc """
  Reads a binary containing an HL7 message converting it to a list of segments.

  ## Arguments

    * `reader`: a `HL7.Reader.t` that will hold the state of the HL7 parser.

    * `buffer`: a binary containing the HL7 message to be parsed (partial
      messages will raise an `HL7.ReadError` exception).

  ## Return value

  Returns the parsed message (i.e. list of segments) or raises an
  `HL7.ReadError` exception in case of error.

  ## Examples

  Given an HL7 message like the following bound to the `buffer` variable:

      "MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\\r" <>
      "PRD|PS~4600^^HL70454||^^^B||||30123456789^CU\\r" <>
      "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown\\r" <>
      "PR1|1||903401^^99DH\\r" <>
      "AUT||112233||||||1|0\\r" <>
      "PR1|2||904620^^99DH\\r" <>
      "AUT||112233||||||1|0\\r"

  You could read the message in the following way:

      iex> reader = HL7.Reader.new(input_format: :wire, trim: true)
      iex> message = HL7.Message.read!(reader, buffer)

  """
  @spec read!(HL7.Reader.t, buffer :: binary) :: t
  def read!(reader, buffer) do
    case read(reader, buffer) do
      {:ok, message}           -> message
      {:incomplete, _function} -> raise HL7.ReadError, :incomplete
      {:error, reason}         -> raise HL7.ReadError, reason
    end
  end

  @doc """
  Reads a binary containing an HL7 message converting it to a list of segments.

  ## Arguments

    * `reader`: a `HL7.Reader.t` that will hold the state of the HL7 parser.

    * `buffer`: a binary containing the HL7 message to be parsed (partial
      messages are allowed).

  ## Return value

    * `{:ok, HL7.Message.t}` if the buffer could be parsed successfully, then
      a message will be returned. This is actually a list of `HL7.Segment.t`
      structs (check the [segment.ex](lib/ex_hl7/segment.ex) file to see the
      list of included segment definitions).

    * `{:incomplete, {(binary -> read_ret), rest :: binary}}`: if the message
      in the string is not a complete HL7 message, then a function will be
      returned together with the part of the message that could not be parsed.
      You should acquire the remaining part of the message and concatenate it
      to the `rest` of the previous buffer. Finally, you have to call the
      function that was returned passing it the concatenated string.

    * `{:error, reason :: any}` if the contents of the buffer were malformed
      and could not be parsed correctly.

  ## Examples

  Given an HL7 message like the following bound to the `buffer` variable:

      "MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG\\r" <>
      "PRD|PS~4600^^HL70454||^^^B||||30123456789^CU\\r" <>
      "PID|0||1234567890ABC^^^&112233&IIN^HC||unknown\\r" <>
      "PR1|1||903401^^99DH\\r" <>
      "AUT||112233||||||1|0\\r" <>
      "PR1|2||904620^^99DH\\r" <>
      "AUT||112233||||||1|0\\r"

  You could read the message in the following way:

      iex> reader = HL7.Reader.new(input_format: :wire, trim: true)
      iex> {:ok, message} = HL7.Message.read(reader, buffer)

  """
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

  @doc """
  Writes a list of HL7 segments into an iolist.

  ## Arguments

    * `writer`: an `HL7.Writer.t` holding the state of the writer.

    * `message`: a list of HL7 segments to be written into the string.

  ## Return value

  iolist containing the message in the selected output format.

  ## Examples

  Given the `message` parsed in the `HL7.Message.read/2` example you could do:

      iex> writer = HL7.Writer.new(output_format: :text, trim: true)
      iex> buffer = HL7.Message.write(writer, message)
      iex> IO.puts(buffer)

      MSH|^~\\&|CLIENTHL7|CLI01020304|SERVHL7|PREPAGA^112233^IIN|20120201101155||ZQA^Z02^ZQA_Z02|00XX20120201101155|P|2.4|||ER|SU|ARG
      PRD|PS~4600^^HL70454||^^^B||||30123456789^CU
      PID|0||1234567890ABC^^^&112233&IIN^HC||unknown
      PR1|1||903401^^99DH
      AUT||112233||||||1|0
      PR1|2||904620^^99DH
      AUT||112233||||||1|0

  """
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
