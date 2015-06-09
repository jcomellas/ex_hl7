defmodule HL7.Codec do
  @moduledoc """
  Functions that decode and encode HL7 fields, repetitions, components and
  subcomponents.

  Each type of item has a canonical representation, that will vary depending
  on whether the `trim` option was used when decoding or encoding. If we set
  `trim` to `true`, some trailing optional items and separators will be omitted
  from the decoded or encoded result, as we can see in the following example:

      import HL7.Item

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
  and deal with it accordingly when performing lookups or comparisons,
  """

  @separators "|^&~"
  @null_value "\"\""

  @doc """
  Return the default separators used to encode HL7 messages in their compiled
  format. These are:

    * `|`: field separator
    * `^`: component separator
    * `&`: subcomponent separator
    * `~`: repetition separator

  To use custom separators in a message use `HL7.Codec.compile_separators/1`
  and pass the returned value as argument to the encoding functions.
  """
  def separators(), do:
    @separators

  def compile_separators(args) do
    field = Keyword.get(args, :field, ?|)
    component = Keyword.get(args, :component, ?^)
    subcomponent = Keyword.get(args, :subcomponent, ?&)
    repetition = Keyword.get(args, :repetition, ?~)
    # Based on the frequency at which each separator usually appears in a
    # message, the optimal layout to make comparisons more efficient is
    # field (59.2%), component (26.3%), subcomponent (3.5%), segment (8.9%), repetition (2.1%)
    <<field, component, subcomponent, repetition>>
  end

  @doc "Return the separator corresponding to an item type."
  @spec separator(HL7.Type.item_type, binary) :: byte
  def separator(item_type, separators \\ @separators)

  def separator(:field,        <<char, _, _, _>>), do: char
  def separator(:component,    <<_, char, _, _>>), do: char
  def separator(:subcomponent, <<_, _, char, _>>), do: char
  def separator(:repetition,   <<_, _, _, char>>), do: char

  def match_separator(char, <<char, _, _, _>>), do:
    {:match, :field}
  def match_separator(char, <<_, char, _, _>>), do:
    {:match, :component}
  def match_separator(char, <<_, _, char, _>>), do:
    {:match, :subcomponent}
  def match_separator(char, <<_, _, _, char>>), do:
    {:match, :repetition}
  def match_separator(_char, _separators), do:
    :nomatch

  @doc "Decode a binary holding an HL7 field into its canonical representation."
  @spec decode_field(binary, separators :: binary, trim :: boolean) :: HL7.Type.field
  def decode_field(field, separators \\ @separators, trim \\ true)

  def decode_field("", _separators, _trim) do
    ""
  end
  def decode_field(@null_value, _separators, _trim) do
    nil
  end
  def decode_field(value, separators, trim) when is_binary(value) do
    rep_sep = separator(:repetition, separators)
    case :binary.split(value, <<rep_sep>>, split_options(trim)) do
      [field] ->
        decode_components(field, separators, trim)
      repetitions ->
        for repetition <- repetitions, do:
          decode_components(repetition, separators, trim)
    end
  end

  @doc "Decode a binary holding one or more HL7 components into its canonical representation."
  def decode_components(components, separators \\ @separators, trim \\ true)

  def decode_components("", _separators, _trim) do
    ""
  end
  def decode_components(@null_value, _separators, _trim) do
    nil
  end
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
        components = for component <- components, do:
                       decode_subcomponents(component, separators, trim)
        case components do
          [] -> ""
          _  -> List.to_tuple(components)
        end
    end
  end

  @doc """
  Decode a binary holding one or more HL7 subcomponents into its canonical
  representation.
  """
  def decode_subcomponents(component, separators \\ @separators, trim \\ true)

  def decode_subcomponents("", _separators, _trim) do
    ""
  end
  def decode_subcomponents(@null_value, _separators, _trim) do
    nil
  end
  def decode_subcomponents(component, separators, trim) do
    subcomp_sep = separator(:subcomponent, separators)
    case :binary.split(component, <<subcomp_sep>>, split_options(trim)) do
      [subcomponent] ->
        subcomponent
      subcomponents ->
        subcomponents = for subcomponent <- subcomponents, do:
                          decode_value(subcomponent)
        case subcomponents do
          [] -> ""
          _  -> List.to_tuple(subcomponents)
        end
    end
  end

  @spec decode_value(HL7.Type.field, HL7.Type.value_type | module) :: HL7.Type.value | :nomatch
  def decode_value(value, type \\ :string)

  def decode_value(@null_value, _type), do:
    nil
  def decode_value(value, type)
   when type === :string or
        (value === "" and 
          (type === :string or type === :integer or type === :float or
           type === :date or type === :datetime or type === :datetime_compact)), do:
    # Empty fields have to be passed to the composite field module
    # to insert the corresponding struct in the corresponding field.
    value
  def decode_value(value, :integer), do:
    :erlang.binary_to_integer(value)
  def decode_value(value, :float), do:
    elem(Float.parse(value), 0)
  def decode_value(value, :date), do:
    binary_to_date(value)
  def decode_value(value, :datetime), do:
    binary_to_datetime(value)
  def decode_value(value, :datetime_compact), do:
    binary_to_datetime(value)
  def decode_value(_value, _type), do:
    :nomatch

  defp binary_to_date(<<y :: binary-size(4), m :: binary-size(2), d :: binary-size(2), _rest :: binary>> = value) do
    year = :erlang.binary_to_integer(y)
    month = :erlang.binary_to_integer(m)
    day = :erlang.binary_to_integer(d)
    date = {year, month, day}
    if valid_date?(date) do
      date
    else
      raise ArgumentError, "invalid date `#{value}`"
    end
  end
  defp binary_to_date(value) do
    raise ArgumentError, "invalid date `#{value}`"
  end

  defp binary_to_datetime(<<yyyymmdd :: binary-size(8), rest :: binary>> = value) do
    date = binary_to_date(yyyymmdd)
    case rest do
      <<h :: binary-size(2), mm :: binary-size(2), s :: binary>> = value ->
        hour = :erlang.binary_to_integer(h)
        min = :erlang.binary_to_integer(mm)
        sec = binary_to_seconds(s)
        time = {hour, min, sec}
        if valid_time?(time) do
          {date, time}
        else
          raise ArgumentError, "invalid datetime `#{value}`"
        end
      "" ->
        {date, {0, 0, 0}}
      _ ->
        raise ArgumentError, "invalid datetime `#{value}`"
    end
  end
  defp binary_to_datetime(value) do
    raise ArgumentError, "invalid datetime `#{value}`"
  end

  defp binary_to_seconds(<<_ :: binary-size(2)>> = value) do
    :erlang.binary_to_integer(value)
  end
  defp binary_to_seconds("") do
    0
  end
  defp binary_to_seconds(value) do
    raise ArgumentError, "invalid datetime `#{value}`"
  end


  def encode_field(field, separators \\ @separators, trim \\ true)

  def encode_field(field, _separators, _trim) when is_binary(field), do:
    field
  def encode_field(nil, _separators, _trim), do:
    @null_value
  def encode_field(repetitions, separators, trim) when is_list(repetitions), do:
    encode_repetitions(repetitions, separators, trim, [])
  def encode_field(components, separators, trim) when is_tuple(components) do
    encode_components(components, separators, trim)
  end

  defp encode_repetitions([repetition | tail], separators, trim, acc) when not is_list(repetition) do
    value = encode_field(repetition, separators, trim)
    acc = case acc do
            []      -> [value]
            [_ | _] -> [value, separator(:repetition, separators) | acc]
          end
    encode_repetitions(tail, separators, trim, acc)
  end
  defp encode_repetitions([], separators, trim, acc) do
    Enum.reverse(maybe_trim_item(acc, separator(:repetition, separators), trim))
  end


  def encode_components(components, separators \\ @separators, trim \\ true) do
    subencoder = &encode_subcomponents(&1, separators, trim)
    encode_subitems(components, subencoder, separator(:component, separators), trim)
  end


  def encode_subcomponents(subcomponents, separators \\ @separators, trim \\ true) do
    encode_subitems(subcomponents, &encode_value/1, separator(:subcomponent, separators), trim)
  end

  defp encode_subitems(item, _subencoder, _separator, _trim) when is_binary(item), do:
    item
  defp encode_subitems(nil, _subencoder, _separator, _trim), do:
    @null_value
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
    Enum.reverse(maybe_trim_item(acc, separator, trim))
  end

  @spec encode_value(HL7.Type.value | nil, HL7.Type.value_type) :: binary | :nomatch
  def encode_value(value, type \\ :string)
  
  def encode_value(nil, _type), do:
    @null_value
  def encode_value(value, type)
   when type === :string or value === "", do:
    value
  def encode_value(value, :integer) when is_integer(value), do:
    :erlang.integer_to_binary(value)
  def encode_value(value, :float) when is_float(value), do:
    Float.to_string(value, decimals: 4, compact: true)
  def encode_value(value, :date), do:
    format_date(value)
  def encode_value(value, :datetime), do:
    format_datetime(value, precision: :seconds)
  def encode_value(value, :datetime_compact), do:
    format_datetime(value, precision: :minutes)
  def encode_value(_value, _type), do:
    :nomatch

  def format_date({year, month, day} = date) do
    if valid_date?(date) do
      y = pad_integer(year, 4)
      m = pad_integer(month, 2)
      d = pad_integer(day, 2)
      <<y :: binary, m :: binary, d :: binary>>
    else
      raise ArgumentError, "invalid date `#{inspect date}`"
    end
  end
  def format_date({{_year, _month, _day} = date, _time}) do
    format_date(date)
  end
  def format_date(date) do
    raise ArgumentError, "invalid date `#{inspect date}`"
  end

  def format_datetime({{year, month, day}, {hour, min, sec}} = datetime, precision: precision) do
    if valid_datetime?(datetime) do
      y  = pad_integer(year, 4)
      m  = pad_integer(month, 2)
      d  = pad_integer(day, 2)
      h  = pad_integer(hour, 2)
      mm = pad_integer(min, 2)
      case precision do
        :seconds ->
          s = pad_integer(sec, 2)
          <<y :: binary, m :: binary, d :: binary, h :: binary, mm :: binary, s :: binary>>
        :minutes ->
          <<y :: binary, m :: binary, d :: binary, h :: binary, mm :: binary>>
        _ ->
          raise ArgumentError, "invalid precision `#{precision}` for datetime `#{inspect datetime}`"
      end
    else
      raise ArgumentError, "invalid datetime `#{inspect datetime}`"
    end
  end
  def format_datetime({_year, _month, _day} = date, options) do
    format_datetime({date, {0, 0, 0}}, options)
  end
  def format_datetime(datetime, _options) do
    raise ArgumentError, "invalid datetime `#{inspect datetime}`"
  end

  defp pad_integer(value, length), do:
    String.rjust(Integer.to_string(value), length, ?0)


  @doc """
  Escape a string that may contain separators using the HL7 escaping rules.

  ## Arguments

  * `value`: a string to escape; it may or may not contain separator
    characters.

  * `separators`: a binary containing the item separators to be used when
    generating the message as returned by `HL7.Codec.compile_separators/1`.
    Defaults to `HL7.Codec.separators`.

  * `escape_char`: character to be used as escape delimiter. Defaults to `?\\\\`.

  ## Examples

      iex> "ABCDEF" = HL7.Codec.escape("ABCDEF")
      iex> "ABC\\\\F\\\\DEF\\\\S\\\\GHI" = HL7.Codec.escape("ABC|DEF^GHI", separators: HL7.Codec.separators(), escape_char: ?\\\\)

  """
  def escape(value, separators \\ @separators, escape_char \\ ?\\)
   when is_binary(value) and is_binary(separators) and is_integer(escape_char) do
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

  defp escape_delimiter_type(:field),        do: ?F
  defp escape_delimiter_type(:component),    do: ?S
  defp escape_delimiter_type(:subcomponent), do: ?T
  defp escape_delimiter_type(:repetition),   do: ?R
  defp escape_delimiter_type(:escape),       do: ?E

  @doc """
  Convert an escaped string into its original value.

  ## Arguments

  * `value`: a string to unescape; it may or may not contain escaped characters.

  * `escape_char`: character that was used as escape delimiter. Defaults to `?\\\\`.

  ## Examples

      iex> "ABCDEF" = HL7.unescape("ABCDEF")
      iex> "ABC|DEF|GHI" = HL7.Codec.unescape("ABC\\\\F\\\\DEF\\\\F\\\\GHI", ?\\\\)

  """
  def unescape(value, separators \\ @separators, escape_char \\ ?\\)
   when is_binary(value) and is_binary(separators) and is_integer(escape_char) do
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

  defp valid_datetime?({date, time}), do:
    valid_date?(date) and valid_time?(time)

  defp valid_date?({year, month, day})
   when is_integer(year) and is_integer(month) and is_integer(day) do
    (month >= 1 and month <= 12) and
    (day >= 1 and day <= :calendar.last_day_of_the_month(year, month))
  end
  defp valid_date?(_date) do
    false
  end

  defp valid_time?({hour, min, sec})
   when is_integer(hour) and is_integer(min) and is_integer(sec) do
    (hour >= 0 and hour < 24) and
    (min >= 0 and min < 60) and
    (sec >= 0 and sec < 60)
  end
  defp valid_time?(_time) do
    false
  end

end
