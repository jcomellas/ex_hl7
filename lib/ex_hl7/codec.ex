defmodule HL7.Codec do
  @moduledoc """
  Functions that decode and encode HL7 fields, repetitions, components and
  subcomponents.

  Each type of item has a canonical representation, that will vary depending
  on whether the `trim` option was used when decoding or encoding. If we set
  `trim` to `true`, some trailing optional items and separators will be omitted
  from the decoded or encoded result, as we can see in the following example:

      import HL7.Codec

      decode_field("504599^223344&&IIN&^~", separators(), trim: true)

  Where the result is:

      {"504599", {"223344", "", "IIN"}}

  With `trim` set to `false` the result would be:

      [{"504599", {"223344", "", "IIN", ""}, ""}, ""]

  Both representations are correct, given that HL7 allows trailing items that
  are empty to be omitted. This causes an ambiguity because the same item can
  be interpreted in several ways when it is the first and only item present.

  For example, in the following HL7 segment the item in the third field
  (504599) might be the same in both cases (i.e. the first component of the
  second field):

    1. AUT||504599^^||||0000190447|^||
    2. AUT||504599||||0000190447|^||

  But for this module it has two different representations:

    1. First component of the second field
    2. Second field

  To resolve the ambiguity in the HL7 syntax, the code decoding and encoding
  HL7 segments using the functions in this module must be aware of this issue
  and deal with it accordingly when performing lookups or comparisons.
  """

  @separators          {?|, ?^, ?&, ?~}
  @null_value          "\"\""

  @doc """
  Return the default separators used to encode HL7 messages in their compiled
  format. These are:

    * `|`: field separator
    * `^`: component separator
    * `&`: subcomponent separator
    * `~`: repetition separator

  To use custom separators in a message use `HL7.Codec.set_separators/1`
  and pass the returned value as argument to the encoding functions.
  """
  def separators(), do: @separators

  def set_separators(args) do
    field = Keyword.get(args, :field, ?|)
    component = Keyword.get(args, :component, ?^)
    subcomponent = Keyword.get(args, :subcomponent, ?&)
    repetition = Keyword.get(args, :repetition, ?~)
    {field, component, subcomponent, repetition}
  end

  @compile {:inline, separator: 2}

  @doc "Return the separator corresponding to an item type."
  @spec separator(HL7.Type.item_type, tuple) :: byte
  def separator(item_type, separators \\ @separators)

  def separator(:field,        {char, _, _, _}), do: char
  def separator(:component,    {_, char, _, _}), do: char
  def separator(:subcomponent, {_, _, char, _}), do: char
  def separator(:repetition,   {_, _, _, char}), do: char

  @compile {:inline, match_separator: 2}

  def match_separator(char, separators \\ @separators)

  def match_separator(char, {char, _, _, _}), do:
    {:match, :field}
  def match_separator(char, {_, char, _, _}), do:
    {:match, :component}
  def match_separator(char, {_, _, char, _}), do:
    {:match, :subcomponent}
  def match_separator(char, {_, _, _, char}), do:
    {:match, :repetition}
  def match_separator(_char, _separators), do:
    :nomatch

  @doc """
  Decode a binary holding an HL7 field into its canonical representation.

  ## Examples

      iex> {"PREPAGA", "112233", "IIN"} = HL7.Codec.decode_field("PREPAGA^112233^IIN")
      iex> ["112233", "IIN"] = HL7.Codec.decode_field("112233~IIN")
      iex> nil = HL7.Codec.decode_field("\"\"")
      iex> "" = HL7.Codec.decode_field("")

  """
  @spec decode_field(binary, separators :: tuple, trim :: boolean) :: HL7.Type.field
  def decode_field(field, separators \\ @separators, trim \\ true)

  def decode_field("", _separators, _trim), do: ""
  def decode_field(@null_value, _separators, _trim), do: nil
  def decode_field(value, separators, trim) when is_binary(value) do
    rep_sep = separator(:repetition, separators)
    case :binary.split(value, <<rep_sep>>, split_options(trim)) do
      [field] ->
        decode_components(field, separators, trim)
      repetitions ->
        for repetition <- repetitions do
          decode_components(repetition, separators, trim)
        end
    end
  end

  @doc """
  Decode a binary holding one or more HL7 components into its canonical
  representation.
  """
  def decode_components(components, separators \\ @separators, trim \\ true)

  def decode_components("", _separators, _trim), do: ""
  def decode_components(@null_value, _separators, _trim), do: nil
  def decode_components(field, separators, trim) do
    comp_sep = separator(:component, separators)
    case :binary.split(field, <<comp_sep>>, split_options(trim)) do
      [component] ->
        case decode_subcomponents(component, separators, trim) do
          components when is_tuple(components) ->
            {components}
          components ->
            components
        end
      components ->
        for component <- components do
          decode_subcomponents(component, separators, trim)
        end
        |> case do
          [] -> ""
          components -> List.to_tuple(components)
        end
    end
  end

  @doc """
  Decode a binary holding one or more HL7 subcomponents into its canonical
  representation.
  """
  def decode_subcomponents(component, separators \\ @separators, trim \\ true)

  def decode_subcomponents("", _separators, _trim), do: ""
  def decode_subcomponents(@null_value, _separators, _trim), do: nil
  def decode_subcomponents(component, separators, trim) do
    subcomp_sep = separator(:subcomponent, separators)
    case :binary.split(component, <<subcomp_sep>>, split_options(trim)) do
      [subcomponent] ->
        subcomponent
      subcomponents ->
        for subcomponent <- subcomponents do
          decode_value(subcomponent)
        end
        |> case do
          [] -> ""
          subcomponents -> List.to_tuple(subcomponents)
        end
    end
  end

  @spec decode_value(HL7.Type.field, type :: atom) :: HL7.Type.value | :nomatch
  def decode_value(value, type \\ :string)

  def decode_value(@null_value, _type), do: nil
  def decode_value(value, type)
   when type === :string or
        (value === "" and
          (type === :string or type === :integer or type === :float or
           type === :date or type === :datetime)), do:
    # Empty fields have to be passed to the composite field module
    # to insert the corresponding struct in the corresponding field.
    value
  def decode_value(value, :integer), do:
    :erlang.binary_to_integer(value)
  def decode_value(value, :float), do:
    elem(Float.parse(value), 0)
  def decode_value(value, :date), do:
    binary_to_date!(value)
  def decode_value(value, :datetime), do:
    binary_to_datetime!(value)
  def decode_value(_value, _type), do:
    :nomatch

  defp binary_to_date!(<<y :: binary-size(4), m :: binary-size(2), d :: binary-size(2), _rest :: binary>> = value) do
    year = :erlang.binary_to_integer(y)
    month = :erlang.binary_to_integer(m)
    day = :erlang.binary_to_integer(d)
    case Date.new(year, month, day) do
      {:ok, date} -> date
      {:error, _reason} -> raise ArgumentError, "invalid date: #{value}"
    end
  end
  defp binary_to_date!(value) do
    raise ArgumentError, "invalid date: #{value}"
  end

  defp binary_to_datetime!(value) do
    case value do
      <<y :: binary-size(4), m :: binary-size(2), d :: binary-size(2), time :: binary>> ->
        year = :erlang.binary_to_integer(y)
        month = :erlang.binary_to_integer(m)
        day = :erlang.binary_to_integer(d)
        {hour, min, sec} =
          case time do
            <<h :: binary-size(2), mm :: binary-size(2), s :: binary-size(2)>> ->
              {:erlang.binary_to_integer(h), :erlang.binary_to_integer(mm),
               :erlang.binary_to_integer(s)}
            <<h :: binary-size(2), mm :: binary-size(2)>> ->
              {:erlang.binary_to_integer(h), :erlang.binary_to_integer(mm), 0}
            _ ->
              {0, 0, 0}
          end
        case NaiveDateTime.new(year, month, day, hour, min, sec) do
          {:ok, datetime} -> datetime
          {:error, _reason} -> raise ArgumentError, "invalid datetime: #{value}"
        end
      _ ->
        raise ArgumentError, "invalid datetime: #{value}"
    end
  end

  def encode_field(field, separators \\ @separators, trim \\ true)

  def encode_field(field, _separators, _trim) when is_binary(field), do: field
  def encode_field(nil, _separators, _trim), do: @null_value
  def encode_field(repetitions, separators, trim) when is_list(repetitions), do:
    encode_repetitions(repetitions, separators, trim, [])
  def encode_field(components, separators, trim) when is_tuple(components), do:
    encode_components(components, separators, trim)

  defp encode_repetitions([repetition | tail], separators, trim, acc)
   when not is_list(repetition) do
    value = encode_field(repetition, separators, trim)
    acc = case acc do
            []      -> [value]
            [_ | _] -> [value, separator(:repetition, separators) | acc]
          end
    encode_repetitions(tail, separators, trim, acc)
  end
  defp encode_repetitions([], separators, trim, acc) do
    acc
    |> maybe_trim_item(separator(:repetition, separators), trim)
    |> Enum.reverse()
  end

  def encode_components(components, separators \\ @separators, trim \\ true) do
    subencoder = &encode_subcomponents(&1, separators, trim)
    encode_subitems(components, subencoder, separator(:component, separators), trim)
  end

  def encode_subcomponents(subcomponents, separators \\ @separators, trim \\ true) do
    encode_subitems(subcomponents, &encode_value/1, separator(:subcomponent, separators), trim)
  end

  defp encode_subitems(item, _subencoder, _separator, _trim) when is_binary(item), do: item
  defp encode_subitems(nil, _subencoder, _separator, _trim), do: @null_value
  defp encode_subitems(items, subencoder, separator, trim) when is_tuple(items), do:
    _encode_subitems(items, subencoder, separator, trim, non_empty_tuple_size(items, trim), 0, [])

  defp _encode_subitems(items, subencoder, separator, trim, size, index, acc) when index < size do
    value = subencoder.(elem(items, index))
    acc = case acc do
            []      -> [value]
            [_ | _] -> [value, separator | acc]
          end
    _encode_subitems(items, subencoder, separator, trim, size, index + 1, acc)
  end
  defp _encode_subitems(_items, _subencoder, separator, trim, _size, _index, acc) do
    acc
    |> maybe_trim_item(separator, trim)
    |> Enum.reverse()
  end

  @spec encode_value(HL7.Type.value | nil, type :: atom) :: binary | :nomatch
  def encode_value(value, type \\ :string)

  def encode_value(nil, _type), do: @null_value
  def encode_value(value, type) when type === :string or value === "", do: value
  def encode_value(value, :integer) when is_integer(value), do:
    :erlang.integer_to_binary(value)
  def encode_value(value, :float) when is_float(value), do:
    Float.to_string(value)
  def encode_value(value, :date)when is_map(value), do:
    format_date!(value)
  def encode_value(value, :datetime) when is_map(value), do:
    format_datetime(value)
  def encode_value(_value, _type), do:
    :nomatch

  def format_date!(%Date{year: year, month: month, day: day}) do
    format_date(year, month, day)
  end
  def format_date!(%NaiveDateTime{year: year, month: month, day: day}) do
    format_date(year, month, day)
  end
  def format_date!(date) do
    raise ArgumentError, "invalid date: #{inspect date}"
  end

  defp format_date(year, month, day) do
    yyyy = zpad(year, 4)
    mm = zpad(month, 2)
    dd = zpad(day, 2)
    <<yyyy :: binary, mm :: binary, dd :: binary>>
  end

  def format_datetime(%NaiveDateTime{year: year, month: month, day: day,
                                     hour: hour, minute: min, second: sec}) do
    format_datetime(year, month, day, hour, min, sec)
  end
  def format_datetime(%Date{year: year, month: month, day: day}) do
    format_datetime(year, month, day, 0, 0, 0)
  end
  def format_datetime(datetime) do
    raise ArgumentError, "invalid datetime #{inspect datetime}"
  end

  defp format_datetime(year, month, day, hour, min, sec) do
    yyyy  = zpad(year, 4)
    m  = zpad(month, 2)
    dd  = zpad(day, 2)
    hh  = zpad(hour, 2)
    mm = zpad(min, 2)
    if sec === 0 do
      <<yyyy :: binary, m :: binary, dd :: binary, hh :: binary, mm :: binary>>
    else
      ss = zpad(sec, 2)
      <<yyyy :: binary, m :: binary, dd :: binary, hh :: binary, mm :: binary, ss :: binary>>
    end
  end

  defp zpad(value, length) do
    value
    |> Integer.to_string()
    |> String.pad_leading(length, "0")
  end

  @doc """
  Escape a string that may contain separators using the HL7 escaping rules.

  ## Arguments

  * `value`: a string to escape; it may or may not contain separator
    characters.

  * `separators`: a tuple containing the item separators to be used when
    generating the message as returned by `HL7.Codec.set_separators/1`.
    Defaults to `HL7.Codec.separators`.

  * `escape_char`: character to be used as escape delimiter. Defaults to `?\\\\ `.

  ## Examples

      iex> "ABCDEF" = HL7.Codec.escape("ABCDEF")
      iex> "ABC\\\\F\\\\DEF\\\\S\\\\GHI" = HL7.Codec.escape("ABC|DEF^GHI", separators: HL7.Codec.separators(), escape_char: ?\\\\)

  """
  def escape(value, separators \\ @separators, escape_char \\ ?\\)
   when is_binary(value) and is_tuple(separators) and is_integer(escape_char) do
    escape_no_copy(value, separators, escape_char, byte_size(value), 0)
  end

  defp escape_no_copy(value, separators, escape_char, size, index) when index < size do
    # As strings that need to be escaped are fairly rare, we try to avoid
    # generating unnecessary garbage by not copying the characters in the
    # string unless the string has to be escaped.
    <<head :: binary-size(index), char, rest :: binary>> = value
    case match_separator(char, separators) do
      {:match, item_type} ->
        acc = escape_acc(item_type, escape_char, head)
        escape_copy(rest, separators, escape_char, acc)
      :nomatch when char === escape_char ->
        acc = escape_acc(:escape, escape_char, head)
        escape_copy(rest, separators, escape_char, acc)
      :nomatch ->
        escape_no_copy(value, separators, escape_char, size, index + 1)
    end
  end
  defp escape_no_copy(value, _separators, _escape_char, _size, _index) do
    value
  end

  defp escape_copy(<<char, rest :: binary>>, separators, escape_char, acc) do
    acc = case match_separator(char, separators) do
            {:match, item_type}                -> escape_acc(item_type, escape_char, acc)
            :nomatch when char === escape_char -> escape_acc(:escape, escape_char, acc)
            :nomatch                           -> <<acc :: binary, char>>
          end
    escape_copy(rest, separators, escape_char, acc)
  end
  defp escape_copy(<<>>, _separators, _escape_char, acc) do
    acc
  end

  defp escape_acc(item_type, escape_char, acc) do
    char = escape_delimiter_type(item_type)
    <<acc :: binary, escape_char, char, escape_char>>
  end

  @compile {:inline, escape_delimiter_type: 1}

  defp escape_delimiter_type(:field),        do: ?F
  defp escape_delimiter_type(:component),    do: ?S
  defp escape_delimiter_type(:subcomponent), do: ?T
  defp escape_delimiter_type(:repetition),   do: ?R
  defp escape_delimiter_type(:escape),       do: ?E

  @doc """
  Convert an escaped string into its original value.

  ## Arguments

  * `value`: a string to unescape; it may or may not contain escaped characters.

  * `escape_char`: character that was used as escape delimiter. Defaults to `?\\\\ `.

  ## Examples

      iex> "ABCDEF" = HL7.unescape("ABCDEF")
      iex> "ABC|DEF|GHI" = HL7.Codec.unescape("ABC\\\\F\\\\DEF\\\\F\\\\GHI", ?\\\\)

  """
  def unescape(value, separators \\ @separators, escape_char \\ ?\\)
   when is_binary(value) and is_tuple(separators) and is_integer(escape_char) do
    unescape_no_copy(value, separators, escape_char, byte_size(value), 0)
  end

  defp unescape_no_copy(value, separators, escape_char, size, index) when index < size do
    # As strings that need to be unescaped are fairly rare, we try to avoid
    # generating unnecessary garbage by not copying the characters in the
    # string unless the string has to be unescaped.
    case value do
      <<head :: binary-size(index), ^escape_char, char, ^escape_char, rest :: binary>> ->
        char = unescape_delimiter(char, separators, escape_char)
        unescape_copy(rest, separators, escape_char, <<head :: binary, char>>)
      _ ->
        unescape_no_copy(value, separators, escape_char, size, index + 1)
    end
  end
  defp unescape_no_copy(value, _separators, _escape_char, _size, _index) do
    value
  end

  defp unescape_copy(value, separators, escape_char, acc) do
    case value do
      <<^escape_char, char, ^escape_char, rest :: binary>> ->
        char = unescape_delimiter(char, separators, escape_char)
        unescape_copy(rest, separators, escape_char, <<acc :: binary, char>>)
      <<char, rest :: binary>> ->
        unescape_copy(rest, separators, escape_char, <<acc :: binary, char>>)
      <<>> ->
        acc
    end
  end

  defp unescape_delimiter(?F, separators, _escape_char), do:
    separator(:field, separators)
  defp unescape_delimiter(?S, separators, _escape_char), do:
    separator(:component, separators)
  defp unescape_delimiter(?T, separators, _escape_char), do:
    separator(:subcomponent, separators)
  defp unescape_delimiter(?R, separators, _escape_char), do:
    separator(:repetition, separators)
  defp unescape_delimiter(?E, _separators, escape_char), do:
    escape_char

  defp split_options(true),  do: [:global, :trim]
  defp split_options(false), do: [:global]

  defp non_empty_tuple_size(tuple, false), do:
    tuple_size(tuple)
  defp non_empty_tuple_size(tuple, _trim), do:
    _non_empty_tuple_size(tuple, tuple_size(tuple))

  defp _non_empty_tuple_size(tuple, size) when size > 1 do
    case :erlang.element(size, tuple) do
      "" -> _non_empty_tuple_size(tuple, size - 1)
      _  -> size
    end
  end
  defp _non_empty_tuple_size(_tuple, size) do
    size
  end

  defp maybe_trim_item(data, char, true),   do: trim_item(data, char)
  defp maybe_trim_item(data, _char, false), do: data

  defp trim_item([value | tail], separator)
   when value === separator or value === "" or value === [], do:
    trim_item(tail, separator)
  defp trim_item(data, _separator), do:
    data
end
