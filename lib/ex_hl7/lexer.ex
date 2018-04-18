defmodule HL7.Lexer do
  @moduledoc """
  Lexer used by the HL7 parser to retrieve tokens from a buffer.
  """
  @segment_id_length 3

  defstruct state: :read_segment_id, separators: nil, escape_char: ?\\,
    terminator: ?\r, next_tokens: []

  alias HL7.Lexer

  @type option     :: {:input_format, :text | :wire}
  @type state      :: :read_segment_id
                    | :read_delimiters
                    | :read_separator
                    | :read_characters
  @type token      :: {:separator, HL7.Type.item_type | :segment} |
                      {:literal, binary} |
                      {:value, binary}
  @type t          :: %Lexer{
                        state: state,
                        separators: tuple,
                        escape_char: byte,
                        terminator: byte,
                        next_tokens: [token]
                      }

  @doc "Create a new Lexer instance"
  @spec new([option]) :: t
  def new(options \\ []) do
    %Lexer{
      state: :read_segment_id,
      separators: HL7.Codec.separators(),
      escape_char: ?\\,
      terminator: segment_terminator(Keyword.get(options, :input_format, :wire)),
      next_tokens: []
   }
  end

  @doc "Reads a token from a buffer containing an HL7 message"
  @spec read(t, binary) :: {:token, {t, token, binary}}
                         | {:incomplete, {t, binary}}
                         | {:error, any}
  def read(lexer = %Lexer{state: state, next_tokens: []}, buffer) do
    # case state do
    #   :read_segment_id -> read_segment_id(lexer, buffer)
    #   :read_delimiters -> read_delimiters(lexer, buffer)
    #   :read_separator  -> read_separator(lexer, buffer)
    #   :read_characters -> read_characters(lexer, buffer)
    # end
    apply(__MODULE__, state, [lexer, buffer])
  end
  def read(lexer = %Lexer{next_tokens: [token | tail]}, buffer) do
    lexer = %Lexer{lexer | next_tokens: tail}
    {:token, {lexer, token, buffer}}
  end

  @doc """
  Put back a token into the `lexer` so that it is the first one to be returned
  in the next call to `Lexer.read/2`
  """
  @spec unread(t, token) :: t
  def unread(lexer = %Lexer{next_tokens: next_tokens}, token), do:
    %Lexer{lexer | next_tokens: [token | next_tokens]}

  def read_segment_id(lexer, <<"MSH", rest :: binary>>) do
    token = {:literal, "MSH"}
    lexer = %Lexer{lexer | state: :read_delimiters}
    {:token, {lexer, token, rest}}
  end
  def read_segment_id(lexer, <<segment_id :: binary-size(@segment_id_length), rest :: binary>>) do
    if valid_segment_id?(segment_id) do
      token = {:literal, segment_id}
      lexer = %Lexer{lexer | state: :read_separator}
      {:token, {lexer, token, rest}}
    else
      {:error, {:bad_segment_id, segment_id}}
    end
  end
  def read_segment_id(lexer, <<>> = buffer) do
    {:incomplete, {lexer, buffer}}
  end

  def read_delimiters(lexer, <<delimiters :: binary-size(5), rest :: binary>>) do
    if valid_delimiters?(delimiters) do
      # The MSH segment must be handled as a special case because the 5
      # characters after the segment ID act both as separators and elements.
      # These 5 characters determine what separators will be used for the rest
      # of the message.
      <<field_sep, encoding_chars :: binary>> = delimiters
      <<comp_sep, rep_sep, escape_char, subcomp_sep>> = encoding_chars
      # Build a binary with the order required by the matching functions.
      separators = HL7.Codec.set_separators(field: field_sep, component: comp_sep,
                                            subcomponent: subcomp_sep, repetition: rep_sep)
      token = {:separator, :field}
      next_tokens = [{:literal, <<field_sep>>}, token, {:literal, encoding_chars}]
      # Set the lexer to the state to be used once all the buffered tokens are
      # retrieved.
      lexer = %Lexer{lexer | state: :read_separator, separators: separators,
                     escape_char: escape_char, next_tokens: next_tokens}
      {:token, {lexer, token, rest}}
    else
      {:error, {:bad_delimiters, delimiters}}
    end
  end
  def read_delimiters(lexer, buffer) do
    {:incomplete, {lexer, buffer}}
  end

  def read_separator(lexer = %Lexer{separators: separators, terminator: terminator},
                     <<char, rest :: binary>>) do
    case HL7.Codec.match_separator(char, separators) do
      {:match, :field} ->
        lexer = %Lexer{lexer | state: :read_characters}
        {:token, {lexer, {:separator, :field}, rest}}
      _ ->
        if char === terminator do
          lexer = %Lexer{lexer | state: :read_segment_id}
          {:token, {lexer, {:separator, :segment}, rest}}
        else
          {:error, {:bad_separator, <<char>>}}
        end
    end
  end
  def read_separator(lexer, <<>> = buffer) do
    {:incomplete, {lexer, buffer}}
  end

  def read_characters(lexer = %Lexer{separators: separators, terminator: terminator}, buffer)
   when buffer !== <<>> do
    case find_characters(buffer, HL7.Codec.separator(:field, separators), terminator, <<>>) do
      {:ok, {value, item_type, rest}} ->
        # Check that the contents of the field we just found are printable
        if printable?(value) do
          # Set the lexer to the state to be used once all the buffered tokens are retrieved.
          state = case item_type do
                    :segment -> :read_segment_id
                    _        -> :read_characters
                  end
          lexer = %Lexer{lexer | state: state, next_tokens: [{:separator, item_type}]}
          {:token, {lexer, {:value, value}, rest}}
        else
          {:error, {:bad_field, value}}
        end
      :incomplete ->
        {:incomplete, {lexer, buffer}}
    end
  end
  def read_characters(lexer, <<>> = buffer) do
    {:incomplete, {lexer, buffer}}
  end

  defp find_characters(<<char, rest :: binary>>, field_separator, terminator, acc) do
    case char do
      ^field_separator ->
        {:ok, {acc, :field, rest}}
      ^terminator ->
        {:ok, {acc, :segment, rest}}
      _ ->
        find_characters(rest, field_separator, terminator, <<acc :: binary, char>>)
    end
  end
  defp find_characters(<<>>, _field_separator, _terminator, _acc) do
    :incomplete
  end

  defp segment_terminator(input_format) do
      case input_format do
        :text -> ?\n
        _     -> ?\r
    end
  end

  @compile {:inline, printable?: 1}

  @doc """
  Checks that the characters in the string are printable ASCII and ISO-8859-1
  (Latin 1) characters.
  """
  @spec printable?(binary) :: boolean
  def printable?(<<char, rest :: binary>>)
   when (char >= 0x20 and char <= 0x7e) or (char >= 0xa0 and char <= 0xff), do:
    printable?(rest)
  def printable?(<<_char, _rest :: binary>>), do: false
  def printable?(<<>>), do: true

  @doc """
  Checks that the string is a valid segment ID.
  """
  @spec valid_segment_id?(binary) :: boolean
  def valid_segment_id?(<<s1, s2, s3>>) do
    uppercase_ascii_char?(s1) and
    (uppercase_ascii_char?(s2) or numeric_char?(s2)) and
    (uppercase_ascii_char?(s3) or numeric_char?(s3))
  end
  def valid_segment_id?(_str) do
    false
  end

  @compile {:inline, numeric_char?: 1}
  # Check if a character is a numeric digit.
  for char <- ?0..?9 do
    defp numeric_char?(unquote(char)), do: true
  end
  defp numeric_char?(_char), do: false

  @compile {:inline, uppercase_ascii_char?: 1}
  # Check if a character is an uppercase letter.
  for char <- ?A..?Z do
    defp uppercase_ascii_char?(unquote(char)), do: true
  end
  defp uppercase_ascii_char?(_char), do: false

  @compile {:inline, valid_delimiters?: 1}
  # Checks that the binary contains valid HL7 delimiters, as passed in the
  # MSH segment.
  @spec valid_delimiters?(binary) :: boolean
  defp valid_delimiters?(<<field_sep, comp_sep, rep_sep, escape_char, subcomp_sep>>) do
    delimiter_char?(field_sep) and
    delimiter_char?(comp_sep) and
    delimiter_char?(rep_sep) and
    delimiter_char?(escape_char) and
    delimiter_char?(subcomp_sep)
  end
  defp valid_delimiters?(_str), do: false

  @compile {:inline, delimiter_char?: 1}
  # Checks that the character is a valid HL7 delimiter.
  defp delimiter_char?(?|), do: true
  defp delimiter_char?(?^), do: true
  defp delimiter_char?(?&), do: true
  defp delimiter_char?(?~), do: true
  defp delimiter_char?(?\\), do: true
  defp delimiter_char?(?!), do: true
  defp delimiter_char?(?#), do: true
  defp delimiter_char?(?$), do: true
  defp delimiter_char?(?%), do: true
  defp delimiter_char?(?{), do: true
  defp delimiter_char?(?}), do: true
  defp delimiter_char?(?[), do: true
  defp delimiter_char?(?]), do: true
  defp delimiter_char?(_char), do: false
end
