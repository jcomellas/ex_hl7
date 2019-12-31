defmodule HL7.Reader do
  @moduledoc """
  Reader for the HL7 protocol. You can test its functionality with the following lines on `ìex`:

      alias HL7.Lexer
      reader = new()
      buffer =
      "MSH|^~\\&|SERV|223344^^II|POSM|CARRIER^CL9999^IP|20030127202538||RPA^I08|5307938|P|2.3|||NE|NE\r" <>
      "MSA|AA|CL999920030127203647||||B006^\r" <>
      "AUT|TESTPLAN|223344^^II||||5307938||0|0\r" <>
      "PRD|RT|NOMBRE PRESTADOR SALUD|||||99999999999^CU^GUARDIA\r" <>
      "PRD|RP||||||9^^N\r" <>
      "PID|||2233441000013527101=0000000000002|1|APELLIDO^NOMBRE\r" <>
      "PR1|1||420101^CONSULTA EN CONSULTORIO^NA^||20030127203642|Z\r" <>
      "AUT|PLANSALUD|||20030127|20030127|5307938|0.00^$|1|1\r" <>
      "NTE|1||SIN CARGO\r" <>
      "NTE|2||IVA: SI\r"

      b1 =
      MSH|^~\\&|SERV|223344^^II|POSM|CARRIER^CL9999^IP|20030127202538||RPA^I08|5307938|P|2.3|||NE|NE
      MSA|AA|CL999920030127203647||||B006
      AUT|TESTPLAN|223344^^II||||5307938||0|0
      PRD|RT|NOMBRE PRESTADOR SALUD|||||99999999999^CU^GUARDIA
      PRD|RP||||||9^^N
      PID|||2233441000013527101=0000000000002|1|APELLIDO^NOMBRE
      PR1|1||420101^CONSULTA EN CONSULTORIO^NA^||20030127203642|Z
      AUT|PLANSALUD|||20030127|20030127|5307938|0.00^$|1|1
      NTE|1||SIN CARGO
      NTE|2||IVA: SI

      {:token, {reader, token, rest}} = HL7.Reader.read(reader, buffer)
      token
      {:token, {reader, token, rest}} = HL7.Reader.read(reader, rest)
      {reader.segment_id, reader.sequence, token}

      {:ok, msg} = HL7.read(buffer)
      buf2 = HL7.write(msg, input_format: :text)
      IO.puts(buf2)
  """
  alias HL7.{Codec, Lexer, Reader, Segment, Type}

  defstruct lexer: nil,
            segment_id: nil,
            sequence: 0,
            item_type: :segment,
            trim: true,
            segment_builder: nil

  @type option ::
          {:segment_builder, module}
          | {:trim, boolean}
          | Lexer.option()
  @type token ::
          {:start_segment, Type.segment_id()}
          | {:end_segment, Type.segment_id()}
          | {:field, Type.field()}
  @type t :: %Reader{
          lexer: Lexer.t(),
          segment_id: Type.segment_id() | nil,
          sequence: non_neg_integer,
          item_type: :segment | Type.item_type(),
          trim: boolean,
          segment_builder: module
        }

  @doc "Create a new Reader instance"
  @spec new([option]) :: t
  def new(options \\ []) do
    %Reader{
      lexer: Lexer.new(options),
      segment_id: nil,
      sequence: 0,
      item_type: :segment,
      trim: Keyword.get(options, :trim, true),
      segment_builder: Keyword.get(options, :segment_builder, Segment.Default.Builder)
    }
  end

  @doc "Return the segment ID of the segment that is being read by the `Reader`."
  @spec segment_id(t) :: Type.segment_id()
  def segment_id(reader), do: reader.segment_id

  @doc "Return the sequence number of the last field that was read by the `Reader`."
  @spec sequence(t) :: 0 | Type.sequence()
  def sequence(reader), do: reader.sequence

  @spec create_segment(t, Type.segment_id()) ::
          {:ok, {Segment.t(), Segment.spec()}}
          | {:error, any}
  def create_segment(%Reader{segment_builder: segment_builder}, segment_id) do
    case segment_builder.new(segment_id) do
      result = {:ok, {_segment, _segment_spec}} -> result
      :error -> {:error, {:unknown_segment_id, [segment_id: segment_id]}}
    end
  end

  @doc "Return the separators that were used in the message that was read by the `Reader`."
  @spec separators(t) :: tuple
  def separators(%Reader{lexer: lexer}), do: lexer.separators

  @doc "Read a token from the reader."
  @spec read(t, binary) ::
          {:token, {t, token, binary}}
          | {:incomplete, {t, binary}}
          | {:complete, t}
          | {:error, any}
  def read(%Reader{lexer: lexer, item_type: item_type} = reader, buffer) do
    case Lexer.read(lexer, buffer) do
      {:token, {lexer, token, buffer}} ->
        decode_token(reader, lexer, token, buffer)

      {:incomplete, {lexer, _buffer}} when item_type === :segment ->
        {:complete, %Reader{reader | lexer: lexer}}

      {:incomplete, {lexer, buffer}} ->
        {:incomplete, {%Reader{reader | lexer: lexer}, buffer}}

      {:error, {reason, data}} ->
        {:error,
         {reason, [segment_id: reader.segment_id, sequence: reader.sequence, value: data]}}
    end
  end

  defp decode_token(
         %Reader{item_type: :segment} = reader,
         lexer,
         {token_type, segment_id},
         buffer
       )
       when token_type === :literal or token_type === :value do
    reader = %Reader{
      reader
      | lexer: lexer,
        segment_id: segment_id,
        sequence: 0,
        item_type: :field
    }

    token = {:start_segment, segment_id}
    {:token, {reader, token, buffer}}
  end

  defp decode_token(%Reader{trim: trim} = reader, lexer, {token_type, value}, buffer)
       when token_type === :literal or token_type === :value do
    reader = %Reader{reader | lexer: lexer, sequence: reader.sequence + 1, item_type: :field}

    field =
      case token_type do
        :literal -> value
        :value -> Codec.decode_field!(value, lexer.separators, trim)
      end

    {:token, {reader, {:field, field}, buffer}}
  end

  defp decode_token(%Reader{} = reader, lexer, {:separator, :segment}, buffer) do
    reader = %Reader{reader | lexer: lexer, segment_id: nil, sequence: 0, item_type: :segment}
    token = {:end_segment, reader.segment_id}
    {:token, {reader, token, buffer}}
  end

  defp decode_token(reader, lexer, {:separator, :field}, buffer) do
    reader = %Reader{reader | lexer: lexer}
    read(reader, buffer)
  end
end
