defmodule HL7.Message do
  @moduledoc """
  Module used to read, write and retrieve segments from an HL7 message.

  Each message is represented as a list of HL7 segments in the order in which
  they appeared in the original message.
  """
  alias HL7.Reader
  alias HL7.Writer
  alias HL7.Segment
  alias HL7.Type

  @type t :: [Segment.t()]
  @type read_ret ::
          {:ok, t}
          | {:incomplete, {(binary -> read_ret), binary}}
          | {:error, reason :: any}

  @doc """
  Return the nth repetition (0-based) of a segment within a message.

  ## Return value

  If the corresponding `repetition` of a segment with the passed `segment_id`
  is present in the `message` then the function returns the segment; otherwise
  it returns `nil`.

  ## Examples

  iex> pr1 = HL7.Message.segment(message, "PR1", 0)
  iex> 1 = pr1.set_id
  iex> pr1 = HL7.Message.segment(message, "PR1", 1)
  iex> 2 = pr1.set_id

  """
  @spec segment(t, Type.segment_id(), Type.repetition()) :: Segment.t() | no_return
  def segment(message, segment_id, repetition \\ 0)

  def segment(message, segment_id, repetition) do
    case drop_until_segment(message, segment_id, repetition) do
      [segment | _tail] -> segment
      [] -> nil
    end
  end

  @doc """
  Return the nth (0-based) grouping of segments with the specified segment IDs.

  In HL7 messages sometimes some segments are immediately followed by other
  segments within the message. This function was created to help find those
  "grouped segments".

  For example, the `PR1` segment is sometimes followed by some other segments
  (e.g. `OBX`, `AUT`, etc.) to include observations and other related
  information for a practice. Note that there might be multiple segment
  groupings in a message.

  ## Return value

  A list of segments corresponding to the segment IDs that were passed. The
  list might not include all of the requested segments if they were not
  present in the message. The function will stop as soon as it finds a segment
  that does not belong to the passed sequence.

  ## Examples

      iex> [pr1, aut] = HL7.Message.paired_segments(message, ["PR1", "AUT"], 0)
      iex> [pr1, aut] = HL7.Message.paired_segments(message, ["PR1", "AUT"], 1)
      iex> [] = HL7.Message.paired_segments(message, ["PR1", "AUT"], 2)
      iex> [aut] = HL7.Message.paired_segments(message, ["PR1", "OBX"], 1)

  """
  @spec paired_segments(t, [Type.segment_id()], Type.repetition()) :: [Segment.t()]
  def paired_segments(message, segment_ids, repetition \\ 0)

  def paired_segments(message, [segment_id | _tail] = segment_ids, repetition) do
    {group, _message_tail} =
      message
      |> drop_until_segment(segment_id, repetition)
      |> segment_group(segment_ids, [])

    group
  end

  @doc """
  It skips over the first `repetition` groups of paired segment and invokes
  `fun` for each subsequent group of paired segments in the `message`. It
  passes the following arguments to `fun` on each call:

    - list of segments found that correspond to the group.
    - index of the group of segments in the `message` (0-based).
    - accumulator `acc` with the incremental results returned by `fun`.

  In HL7 messages sometimes some segments are immediately followed by other
  segments within the message. This function was created to easily process
  those "paired segments".

  For example, the `PR1` segment is sometimes followed by some other segments
  (e.g. `OBX`, `AUT`, etc.) to include observations and other related
  information for a procedure. Note that there might be multiple segment
  groupings in a message.

  ## Return value

  The accumulator returned by `fun` in its last invocation.

  ## Examples

      iex> HL7.Message.reduce_paired_segments(message, ["PR1", "AUT"], 0, [], fun segments, index, acc ->
        segment_ids = for segment <- segments, do: HL7.segment_id(segment)
        [{index, segment_ids} | acc]
      end
      [{0, ["PR1", "AUT"]}, {1, ["PR1", "AUT"]}]

  """
  @spec reduce_paired_segments(
          t,
          [Type.segment_id()],
          Type.repetition(),
          acc :: term,
          ([Segment.t()], Type.repetition(), acc :: term -> acc :: term)
        ) :: acc :: term
  def reduce_paired_segments(
        message,
        [segment_id | _segment_id_tail] = segment_ids,
        initial_repetition,
        acc,
        fun
      ) do
    # Skip all the segments before the segment ID that starts the group we're
    # interested in.
    message
    |> drop_until_segment(segment_id, initial_repetition)
    |> reduce_segment_groups(segment_ids, 0, acc, fun)
  end

  defp reduce_segment_groups(
         [_ | _] = message,
         [segment_id | _] = segment_ids,
         repetition,
         acc,
         fun
       ) do
    message = drop_until_segment(message, segment_id)

    case segment_group(message, segment_ids, []) do
      {[_ | _] = group, message_tail} ->
        acc = fun.(group, repetition, acc)
        reduce_segment_groups(message_tail, segment_ids, repetition + 1, acc, fun)

      {[], _message_tail} ->
        acc
    end
  end

  defp reduce_segment_groups([], _segment_ids, _repetition, acc, _fun) do
    acc
  end

  defp segment_group([segment | message_tail] = message, [segment_id | segment_id_tail], acc) do
    # If the segment ID does not match the next segment in the list, we skip
    # the segment ID and continue with the following segment ID. This behaviour
    # deals with scenarios where we're looking for the `["PR1", "OBX", "AUT"]`
    # group and the message only contains the `["PR1", "AUT"]` one because the
    # `OBX` segment is optional.
    case Segment.id(segment) do
      ^segment_id -> segment_group(message_tail, segment_id_tail, [segment | acc])
      _ -> segment_group(message, segment_id_tail, acc)
    end
  end

  defp segment_group(message, _segment_ids, acc) do
    {Enum.reverse(acc), message}
  end

  defp drop_until_segment(segments, segment_id, repetition \\ 0)

  defp drop_until_segment([segment | tail] = segments, segment_id, repetition) do
    case Segment.id(segment) do
      ^segment_id ->
        if repetition === 0 do
          segments
        else
          drop_until_segment(tail, segment_id, repetition - 1)
        end

      _ ->
        drop_until_segment(tail, segment_id, repetition)
    end
  end

  defp drop_until_segment([] = segments, _segment_id, _repetition) do
    segments
  end

  @doc """
  Return the number of segments with a specified segment ID in an HL7 message.

  ## Examples

  iex> 2 = HL7.Message.segment_count(message, "PR1")
  iex> 0 = HL7.Message.segment_count(message, "OBX")

  """
  @spec segment_count(t, Type.segment_id()) :: non_neg_integer
  def segment_count(segments, segment_id)
      when is_list(segments) and is_binary(segment_id),
      do: segment_count(segments, segment_id, 0)

  defp segment_count([segment | tail], segment_id, count) do
    count =
      case Segment.id(segment) do
        ^segment_id -> count + 1
        _ -> count
      end

    segment_count(tail, segment_id, count)
  end

  defp segment_count([], _segment_id, count) do
    count
  end

  @doc """
  Deletes the given repetition (0-based) of a segment in a message

  ## Examples

  iex> HL7.delete(message, "NTE", 0)

  """
  @spec delete(t, Type.segment_id(), Type.repetition()) :: t
  def delete(message, segment_id, repetition \\ 0) do
    case split_at_segment(message, segment_id, repetition, []) do
      {_segment, tail, acc} ->
        Enum.reverse(acc, tail)

      _acc ->
        message
    end
  end

  @doc """
  Inserts a segment or group of segments before the first repetition of an
  existing segment in a message.

  ## Arguments

  * `message`: the `HL7.message` where the segment/s will be inserted.

  * `segment_id`: the segment ID of a segment that should be present in the
  `message`.

  * `segment`: the segment or list of segments that will be inserted

  ## Return values

  If a segment with the `segment_id` was present, the function will return a
  new message with the inserted segments. If not, it will return the original
  message

  ## Examples

  iex> alias HL7.Segment.MSA
  iex> ack = %MSA{ack_code: "AA", message_control_id: "1234"}
  iex> HL7.insert_before(message, "ERR", msa)

  """
  @spec insert_before(t, Type.segment_id(), Segment.t() | [Segment.t()]) :: t
  def insert_before(message, segment_id, segment),
    do: insert_before(message, segment_id, 0, segment)

  @doc """
  Inserts a segment or group of segments before the given repetition of an
  existing segment in a message.

  ## Arguments

  * `message`: the `HL7.message` where the segment/s will be inserted.

  * `segment_id`: the segment ID of a segment that should be present in the
  `message`.

  * `repetition`: the repetition (0-based) of the `segment_id` in the `message`.

  * `segment`: the segment or list of segments that will be inserted

  ## Return values

  If a segment with the `segment_id` was present with the given `repetition`,
  the function will return a new message with the inserted segments. If not,
  it will return the original message

  ## Examples

  iex> alias HL7.Segment.MSA
  iex> ack = %MSA{ack_code: "AA", message_control_id: "1234"}
  iex> HL7.Message.insert_before(message, "ERR", 0, msa)

  """
  @spec insert_before(t, Type.segment_id(), Type.repetition(), Segment.t() | [Segment.t()]) :: t
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

  @doc """
  Inserts a segment or group of segments after the first repetition of an
  existing segment in a message.

  ## Arguments

  * `message`: the `HL7.message` where the segment/s will be inserted.

  * `segment_id`: the segment ID of a segment that should be present in the
  `message`.

  * `segment`: the segment or list of segments that will be inserted

  ## Return values

  If a segment with the `segment_id` was present, the function will return a
  new message with the inserted segments. If not, it will return the original
  message

  ## Examples

  iex> alias HL7.Segment.MSA
  iex> ack = %MSA{ack_code: "AA", message_control_id: "1234"}
  iex> HL7.Message.insert_after(message, "MSH", msa)

  """
  @spec insert_after(t, Type.segment_id(), Segment.t() | [Segment.t()]) :: t
  def insert_after(message, segment_id, segment),
    do: insert_after(message, segment_id, 0, segment)

  @doc """
  Inserts a segment or group of segments after the given repetition of an
  existing segment in a message.

  ## Arguments

  * `message`: the `HL7.message` where the segment/s will be inserted.

  * `segment_id`: the segment ID of a segment that should be present in the
  `message`.

  * `repetition`: the repetition (0-based) of the `segment_id` in the `message`.

  * `segment`: the segment or list of segments that will be inserted

  ## Return values

  If a segment with the `segment_id` was present with the given `repetition`,
  the function will return a new message with the inserted segments. If not,
  it will return the original message

  ## Examples

  iex> alias HL7.Segment.MSA
  iex> ack = %MSA{ack_code: "AA", message_control_id: "1234"}
  iex> HL7.Message.insert_after(message, "MSH", 0, msa)

  """
  @spec insert_after(t, Type.segment_id(), Type.repetition(), Segment.t() | [Segment.t()]) :: t
  def insert_after(message, segment_id, repetition, new_segments)
      when is_list(message) and is_binary(segment_id) and is_integer(repetition) and
             is_list(new_segments) do
    case split_at_segment(message, segment_id, repetition, []) do
      {segment, tail, acc} ->
        Enum.reverse(acc, [segment | new_segments ++ tail])

      _acc ->
        message
    end
  end

  def insert_after(message, segment_id, repetition, new_segment)
      when is_map(new_segment) do
    insert_after(message, segment_id, repetition, [new_segment])
  end

  @doc """
  Replaces the first repetition of an existing segment in a message.

  ## Arguments

  * `message`: the `HL7.message` where the segment/s will be inserted.

  * `segment_id`: the segment ID of a segment that should be present in the
  `message`.

  * `segment`: the segment or list of segments that will replace the existing
  one.

  ## Return values

  If a segment with the `segment_id` was present, the function will return a
  new message with the replaced segments. If not, it will return the original
  message

  ## Examples

  iex> alias HL7.Segment.MSA
  iex> ack = %MSA{ack_code: "AA", message_control_id: "1234"}
  iex> HL7.Message.replace(message, "MSA", msa)

  """
  @spec replace(t, Type.segment_id(), Segment.t() | [Segment.t()]) :: t
  def replace(message, segment_id, segment), do: replace(message, segment_id, 0, segment)

  @doc """
  Replaces the given repetition of an existing segment in a message.

  ## Arguments

  * `message`: the `HL7.message` where the segment/s will be inserted.

  * `segment_id`: the segment ID of a segment that should be present in the
  `message`.

  * `repetition`: the repetition (0-based) of the `segment_id` in the `message`.

  * `segment`: the segment or list of segments that will replace the existing
  one.

  ## Return values

  If a segment with the `segment_id` was present with the given `repetition`,
  the function will return a new message with the replaced segments. If not,
  it will return the original message

  ## Examples

  iex> alias HL7.Segment.MSA
  iex> ack = %MSA{ack_code: "AA", message_control_id: "1234"}
  iex> HL7.Message.replace(message, "MSA", 0, msa)

  """
  @spec replace(t, Type.segment_id(), Type.repetition(), Segment.t() | [Segment.t()]) :: t
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
    case Segment.id(segment) do
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
  @spec read!(Reader.t(), buffer :: binary) :: t | no_return
  def read!(reader, buffer) do
    case read(reader, buffer) do
      {:ok, message} -> message
      {:incomplete, _function} -> raise HL7.ReadError, :incomplete
      {:error, reason} -> raise HL7.ReadError, reason
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
  @spec read(Reader.t(), buffer :: binary) :: read_ret
  def read(reader, buffer), do: read(reader, buffer, [])

  def read(reader, buffer, acc) do
    case Reader.read(reader, buffer) do
      {:token, {reader, {:start_segment, segment_id}, buffer}} ->
        case Reader.create_segment(reader, segment_id) do
          {:ok, {segment, segment_spec}} ->
            case read_segment(reader, segment, segment_spec, buffer) do
              {:ok, {reader, segment, buffer}} ->
                read(reader, buffer, [segment | acc])

              {:incomplete, {reader, segment, segment_spec, buffer}} ->
                {:incomplete, {&complete_read(reader, segment, segment_spec, &1, acc), buffer}}

              error = {:error, _reason} ->
                error
            end

          error = {:error, _reason} ->
            error
        end

      {:complete, _reader} ->
        {:ok, Enum.reverse(acc)}
    end
  end

  def complete_read(reader, segment, segment_spec, buffer, acc) do
    case read_segment(reader, segment, segment_spec, buffer) do
      {:ok, {reader, segment, buffer}} ->
        read(reader, buffer, [segment | acc])

      result ->
        result
    end
  end

  def read_segment(reader, segment, segment_spec, buffer) do
    case Reader.read(reader, buffer) do
      {:token, {reader, {:field, field}, buffer}} ->
        segment = read_field(reader, segment, segment_spec, field)
        read_segment(reader, segment, segment_spec, buffer)

      {:token, {reader, {:end_segment, _segment_id}, buffer}} ->
        {:ok, {reader, segment, buffer}}

      {:incomplete, {reader, buffer}} ->
        {:incomplete, {reader, segment, segment_spec, buffer}}

      error = {:error, _reason} ->
        # raise HL7.Error, reason: reason, segment: HL7.Reader.segment_id(reader),
        #       sequence: HL7.Reader.sequence(reader)
        error
    end
  end

  defp read_field(reader, segment, segment_spec, field) do
    seq = Reader.sequence(reader)

    case Map.get(segment_spec, seq) do
      nil -> segment
      field_spec -> Segment.put_field_ir!(segment, field_spec, field)
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
  @spec write(Writer.t(), t) :: iodata
  def write(writer, message) do
    writer
    |> Writer.start_message()
    |> write_segments(message)
    |> Writer.end_message()
    |> Writer.buffer()
  end

  defp write_segments(writer, [segment | tail]) do
    segment_id = Segment.id(segment)

    writer
    |> Writer.start_segment(segment_id)
    |> write_segment(segment, segment_id)
    |> Writer.end_segment(segment_id)
    |> write_segments(tail)
  end

  defp write_segments(writer, []) do
    writer
  end

  defp write_segment(writer, segment, segment_id) do
    case Writer.builder(writer).segment_spec(segment_id) do
      {:ok, segment_spec} ->
        {writer, _last_seq} =
          Enum.reduce(segment_spec, {writer, 1}, fn {seq, field_spec}, {writer1, prev_seq} ->
            # Get the intermediate representation corresponding to the field.
            field = Segment.get_field_ir!(segment, field_spec)
            # If there are empty fields between the previous sequence and the current
            # one, write them before writing the field.
            writer1 =
              writer1
              |> write_empty_fields(prev_seq, seq - 1)
              |> Writer.put_field(field)

            {writer1, seq}
          end)

        writer

      :error ->
        raise ArgumentError, "invalid segment ID: #{inspect(segment_id)}"
    end
  end

  defp write_empty_fields(writer, prev_seq, seq) do
    if prev_seq < seq do
      writer
      |> Writer.put_field("")
      |> write_empty_fields(prev_seq + 1, seq)
    else
      writer
    end
  end
end
