defmodule HL7.Lexer do
  @moduledoc """
  Lexer used by the HL7 parser to retrieve tokens from a buffer.
  """

  @segment_id_length 3

  defstruct state: :read_segment_id, separators: nil, escape_char: ?\\, terminator: ?\r, next_tokens: []

  alias HL7.Lexer

  @type option     :: {:input_format, :text | :wire}
  @type state      :: :read_segment_id | :read_delimiters | :read_separator | :read_characters
  @type token      :: {:separator, HL7.Type.item_type | :segment} |
                      {:literal, binary} |
                      {:value, binary}
  @type t          :: %Lexer{
                        state: state,
                        separators: binary,
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
  def read(%Lexer{state: state, next_tokens: []} = lexer, buffer) do
    # case state do
    #   :read_segment_id -> read_segment_id(lexer, buffer)
    #   :read_delimiters -> read_delimiters(lexer, buffer)
    #   :read_separator  -> read_separator(lexer, buffer)
    #   :read_characters -> read_characters(lexer, buffer)
    # end
    apply(__MODULE__, state, [lexer, buffer])
  end
  def read(%Lexer{next_tokens: [token | tail]} = lexer, buffer) do
    lexer = %Lexer{lexer | next_tokens: tail}
    {:token, {lexer, token, buffer}}
  end

  @doc """
  Put back a token into the `lexer` so that it is the first one to be returned
  in the next call to `Lexer.read/2`
  """
  @spec unread(t, token) :: t
  def unread(%Lexer{next_tokens: next_tokens} = lexer, token), do:
    %Lexer{lexer | next_tokens: [token | next_tokens]}

  def read_segment_id(lexer, <<"MSH", rest :: binary>>) do
    token = {:literal, "MSH"}
    lexer = %Lexer{lexer | state: :read_delimiters}
    {:token, {lexer, token, rest}}
  end
  def read_segment_id(lexer, <<segment_id :: binary-size(@segment_id_length), rest :: binary>>) do
    if ASCII.upper_alphanumeric?(segment_id) do
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
    if ASCII.printable?(delimiters) and not ASCII.alphanumeric?(delimiters) do
      # The MSH segment must be handled as a special case because the 5
      # characters after the segment ID act both as separators and elements.
      # These 5 characters determine what separators will be used for the rest
      # of the message.
      <<field_sep, comp_sep, rep_sep, escape_char, subcomp_sep>> = delimiters
      # Build a binary with the order required by the matching functions.
      separators = HL7.Codec.compile_separators(field: field_sep, component: comp_sep,
                                                subcomponent: subcomp_sep, repetition: rep_sep)
      encoding_chars = <<comp_sep, rep_sep, escape_char, subcomp_sep>>
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

  def read_separator(%Lexer{separators: separators, terminator: terminator} = lexer,
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

  def read_characters(%Lexer{separators: separators, terminator: terminator} = lexer, buffer)
   when buffer !== <<>> do
    case find_characters(buffer, HL7.Codec.separator(:field, separators), terminator, <<>>) do
      {:ok, {value, item_type, rest}} ->
        # Check that the contents of the field we just found are printable
        if ASCII.printable?(value) do
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
end
