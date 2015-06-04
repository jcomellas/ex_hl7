defmodule HL7 do
  @type message        :: HL7.Message.t
  @type segment        :: HL7.Segment.t
  @type segment_id     :: HL7.Type.segment_id
  @type sequence       :: HL7.Type.sequence
  @type field          :: HL7.Type.field
  @type item_type      :: HL7.Type.item_type
  @type value_type     :: HL7.Type.value_type
  @type value          :: HL7.Type.value
  @type read_option    :: HL7.Reader.option
  @type write_option   :: HL7.Writer.option
  @type read_ret       :: {:ok, HL7.Message.t} |
                          {:incomplete, {(binary -> read_ret), rest :: binary}} |
                          {:error, reason :: any}
  def read(buffer, options \\ []), do:
    HL7.Message.read(HL7.Reader.new(options), buffer)
	
  @spec write(message, [HL7.Writer.option]) :: iodata
  def write(message, options \\ []), do:
    HL7.Message.write(HL7.Writer.new(options), message)

  @spec segment_id(segment) :: segment_id
  defdelegate segment_id(segment), to: HL7.Segment, as: :id

  @spec segment(message, segment_id) :: segment | nil
  defdelegate segment(message, segment_id), to: HL7.Message

  @spec segment(message, segment_id, repetition :: non_neg_integer) :: segment | nil
  defdelegate segment(message, segment_id, repetition), to: HL7.Message

  @spec paired_segments(message, [segment_id]) :: [segment]
  defdelegate paired_segments(message, segment_ids), to: HL7.Message

  @spec paired_segments(message, [segment_id], repetition :: non_neg_integer) :: [segment]
  defdelegate paired_segments(message, segment_ids, repetition), to: HL7.Message

  @spec segment_count(message, segment_id) :: non_neg_integer
  defdelegate segment_count(message, segment_id), to: HL7.Message

  @doc """
  Escape a string that may contain separators using the HL7 escaping rules.

  ## Arguments

  * `value`: a string to escape; it may or may not contain separator
    characters.

  * `options`: keyword list with the escape options; these are:
    * `separators`: a binary containing the item separators to be used when
      generating the message as returned by `HL7.Codec.compile_separators/1`.
      Defaults to `HL7.Codec.separators`.
    * `escape_char`: character to be used as escape delimiter. Defaults to `?\\\\`.

  ## Examples

      iex> "ABCDEF" = HL7.escape("ABCDEF")
      iex> "ABC\\\\|\\\\DEF\\\\|\\\\GHI" = HL7.escape("ABC|DEF|GHI", separators: HL7.Codec.separators(), escape_char: ?\\\\)

  """
  def escape(value, options \\ []) do
    separators = Keyword.get(options, :separators, HL7.Codec.separators())
    escape_char = Keyword.get(options, :escape_char, ?\\)
    HL7.Codec.escape(value, separators, escape_char)
  end

  @doc """
  Convert an escaped string into its original value.

  ## Arguments

  * `value`: a string to unescape; it may or may not contain escaped characters.

  * `options`: keyword list with the unescape options; these are:
    * `escape_char`: character that was used as escape delimiter. Defaults to `?\\\\`.

  ## Examples

      iex> "ABCDEF" = HL7.unescape("ABCDEF")
      iex> "ABC|DEF|GHI" = HL7.unescape("ABC\\\\|\\\\DEF\\\\|\\\\GHI", escape_char: ?\\\\)

  """
  def unescape(value, options \\ []) do
    escape_char = Keyword.get(options, :escape_char, ?\\)
    HL7.Codec.unescape(value, escape_char)
  end

end
