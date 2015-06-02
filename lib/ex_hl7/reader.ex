defmodule HL7.Reader do
  @moduledoc """
  Reader for the HL7 protocol. You can test its functionality with the following lines on `ìex`:

      r HL7.Lexer
      r HL7.Reader
      reader = HL7.Reader.new
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

      {:ok, {reader, token, rest}} = HL7.Reader.read(reader, buffer)
      token
      {:ok, {reader, token, rest}} = HL7.Reader.read(reader, rest); {reader.segment_id, reader.sequence, token}

      {:ok, msg} = HL7.read(buffer)
      buf2 = HL7.write(msg, format: :stdio)
      IO.puts(buf2)
  """
  alias HL7.Reader

  defstruct lexer: nil,
            segment_id: nil,
            sequence: 0,
            item_type: :segment,
            trim: true

  @type option     :: HL7.Lexer.option
  @type token      :: {:start_segment, HL7.Type.segment_id} |
                      {:end_segment, HL7.Type.segment_id} |
                      {:field, HL7.Type.field}
  @type t          :: %Reader{
                        lexer: HL7.Lexer.t,
                        segment_id: HL7.Type.segment_id,
                        sequence: non_neg_integer,
                        item_type: HL7.Type.item_type,
                        trim: boolean
                      }

  @doc "Create a new Reader instance"
  @spec new([option]) :: t
  def new(options \\ []) do
    %Reader{
      lexer: HL7.Lexer.new(options),
      segment_id: nil,
      sequence: 0,
      item_type: :segment,
      trim: Keyword.get(options, :trim, true)
    }
  end

  @doc "Return the segment ID of the segment that is being read by the `Reader`."
  @spec segment_id(t) :: HL7.Type.segment_id
  def segment_id(reader), do: reader.segment_id

  @doc "Return the sequence number of the last field that was read by the `Reader`."
  @spec sequence(t) :: 0 | HL7.Type.sequence
  def sequence(reader), do: reader.sequence

  @doc "Return the separators that were used in the message that was read by the `Reader`."
  @spec separators(t) :: binary
  def separators(%Reader{lexer: lexer}), do: lexer.separators

  @doc "Read a token from the reader."
  @spec read(t, binary) :: {:token, {t, token, binary}}
                         | {:incomplete, {t, binary}}
                         | {:complete, t}
                         | {:error, any}
  def read(%Reader{lexer: lexer, item_type: item_type} = reader, buffer) do
    case HL7.Lexer.read(lexer, buffer) do
      {:token, {lexer, token, buffer}} ->
        decode_token(reader, lexer, token, buffer)
      {:incomplete, {lexer, _buffer}} when item_type === :segment ->
        {:complete, %Reader{reader | lexer: lexer}}
      {:incomplete, {lexer, buffer}} ->
        {:incomplete, {%Reader{reader | lexer: lexer}, buffer}}
      {:error, _reason} = error ->
        error
    end
  end

  defp decode_token(%Reader{item_type: :segment} = reader, lexer, {token_type, segment_id}, buffer)
   when token_type === :literal or token_type === :value do
    reader = %Reader{reader | lexer: lexer, segment_id: segment_id, sequence: 0, item_type: :field}
    token = {:start_segment, segment_id}
    {:token, {reader, token, buffer}}
  end
  defp decode_token(%Reader{trim: trim} = reader, lexer, {token_type, value}, buffer)
   when token_type === :literal or token_type === :value do
    reader = %Reader{reader | lexer: lexer, sequence: reader.sequence + 1, item_type: :field}
    field = case token_type do
              :literal -> value
              :value   -> HL7.Codec.decode_field(value, lexer.separators, trim)
            end
    {:token, {reader, {:field, field}, buffer}}
  end
  defp decode_token(%Reader{segment_id: segment_id} = reader, lexer, {:separator, :segment}, buffer) do
    reader = %Reader{reader | lexer: lexer, segment_id: nil, sequence: 0, item_type: :segment}
    token = {:end_segment, segment_id}
    {:token, {reader, token, buffer}}
  end
  defp decode_token(reader, lexer, {:separator, :field}, buffer) do
    reader = %Reader{reader | lexer: lexer}
    read(reader, buffer)
  end
end
