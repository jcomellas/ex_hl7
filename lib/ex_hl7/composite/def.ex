defmodule HL7.Composite.Def do
  @moduledoc "Macros and functions used to define HL7 composite fields"
  @type option :: {:separators, [{key :: atom, separator :: byte}]} | {:trim, boolean}


  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Macro that generates the code that allows a module to be used as a composite
  field in HL7 segments. A `composite` field definition looks like the
  following block:

      composite do
        component :number,                       type: :string
        component :date,                         type: :date
        component :source,                       type: :string
      end

  *Note*: when defining a composite, the fields have to be in the order they
  in the message.
  """
  defmacro composite([do: components]) do
    quote do
      Module.register_attribute(unquote(__CALLER__.module), :struct_fields, accumulate: true)
      Module.register_attribute(unquote(__CALLER__.module), :components, accumulate: true)
      @before_compile unquote(__MODULE__)

      unquote(components)
    end
  end


  @doc """
  Macro that generates the code for each individual component within an
  HL7 composite field. Each `component` definition looks like the following
  one:

      component :price,                        type: :float

  A `component` has a name that has to be an atom, a `type` and a `default`
  value. The default `type` is `:string` and the default `value` is `""`.
  The supported types are:

    * `:string`
    * `:integer`
    * `:float`
    * `:date`: a field containing a date as a `{year, month, day}` that is
      serialized using the YYYYMMDD format (must be of `length` 8).
    * `:datetime`: a field containing a date/time tuple (i.e.
      `{{year, month, day}, {hour, min, sec}}`) that is serialized using the
      *YYYYMMDDhhmmss* format (must be of `length` 14).
    * `:datetime_compact`: equivalent to the `:datetime` type, but serialized
      using the *YYYYMMDDhhmm* format (must be of `length` 12).
    * an atom corresponding to a composite field's module name. The module must
      have been built using the macros from the `HL7.Composite.Def` module or
      following the behaviour of an `HL7.Composite`. There are some sample
      composite field modules already defined in the `HL7.Composite` module.
  """
  defmacro component(name, args \\ [type: :binary, default: ""]) do
    type = Keyword.get(args, :type, :binary)
    default = Keyword.get(args, :default, "")

    quote bind_quoted: [name: name, type: type, default: default, module: __CALLER__.module] do
      check_component!(name, type, default, module, Module.get_attribute(module, :components))
      # Accumulate the components and fields of the struct that will be added
      # to the module so that the corresponding functions can be generated in
      # the __before_compile__ function.
      @components {name, type}
      @struct_fields {name, default}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defstruct unquote(Module.get_attribute(__CALLER__.module, :struct_fields)
                        |> Enum.reverse
                        |> Macro.escape)

      # TODO: how do we inject a type spec in the generated code?
      @type t :: %unquote(__CALLER__.module){}
                 # unquote(Module.get_attribute(__CALLER__.module, :components)
                 #         |> Enum.map(fn {name, type} -> {name, type()} end)
                 #         |> Enum.reverse
                 #         |> Macro.escape)}

      def descriptor(), do:
        unquote(Module.get_attribute(__CALLER__.module, :components)
                |> Enum.reverse
                |> Macro.escape)

      @spec valid?(t) :: boolean
      def valid?(%unquote(__CALLER__.module){}), do: true
      def valid?(_), do: false

      @spec new() :: t
      def new(), do:
        %unquote(__CALLER__.module){}

      @spec decode(HL7.Type.field) :: t
      def decode(value), do:
        unquote(__MODULE__).decode_composite(%unquote(__CALLER__.module){}, descriptor(), value)

      @spec encode(t) :: HL7.Type.field
      def encode(map), do:
        unquote(__MODULE__).encode_composite(map, descriptor())

      @spec to_iodata(t, [unquote(__MODULE__).option]) :: iodata
      def to_iodata(map, options), do:
        unquote(__MODULE__).to_iodata(map, descriptor(), options)

    end
  end

  @doc "Check that a component definition is correct"
  @spec check_component!(name :: atom, type :: atom, default :: any, composite :: atom,
                         components :: [{name :: atom, type :: atom}]) :: boolean | no_return
  def check_component!(name, type, default, composite, components) do
    check_type!(name, type)
    check_default!(name, type, default)

    unless List.keyfind(components, name, 0) === nil do
      raise ArgumentError, "component #{inspect name} is already set on composite `#{composite}`"
    end
  end

  @doc "Check that the type of a component inside a composite field is valid"
  def check_type!(name, type) do
    unless check_type?(type) do
      raise ArgumentError, "invalid type #{inspect type} on component `#{inspect name}`"
    end
  end

  def check_type?(type) do
    cond do
      type === :string or type === :integer or type === :float or
      type === :date or type === :datetime or type === :datetime_compact ->
        true
      composite_type?(type) ->
        true
      true ->
        false
    end
  end

  def composite_type?(module), do:
    is_atom(module) and Code.ensure_compiled?(module) and function_exported?(module, :valid?, 1)

  @doc "Check that the default value assigned to a component inside a composite field is valid"
  def check_default!(name, type, default) do
    if check_default?(type, default) do
      true
    else
      raise ArgumentError, "invalid default argument `#{inspect default}` for " <>
                           "#{type} component #{inspect name}"
    end
  end

  def check_default?(_type, ""), do:
    true
  def check_default?(:string, default), do:
    is_binary(default)
  def check_default?(:integer, default), do:
    is_integer(default)
  def check_default?(:float, default), do:
    is_float(default)
  def check_default?(:date, date), do:
    is_date(date)
  def check_default?(type, datetime) when type === :datetime or type === :datetime_compact, do:
    is_datetime(datetime)
  def check_default?(type, default) when is_atom(type), do:
    apply(type, :valid?, [default])
  def check_default?(_type, _default), do:
    false

  defp is_date({day, month, year}) 
   when is_integer(day) and is_integer(month) and is_integer(year) do
    (day in 1..31) and (month in 1..12)
  end
  defp is_date(_date) do
    false
  end

  defp is_datetime({{day, month, year}, {hour, min, sec}})
   when is_integer(day) and is_integer(month) and is_integer(year) and
        is_integer(hour) and is_integer(min) and is_integer(sec) do
    (day in 1..31) and (month in 1..12) and
    (hour in 0..23) and (min in 0..59) and (sec in 0..59)
  end
  defp is_datetime(_datetime) do
    false
  end


  @doc """
  Function used to create the map corresponding to the underlying struct in a
  composite field.
  """
  @spec decode_composite(map, descriptor :: [{name :: atom, type :: atom}], binary | tuple) :: map
  def decode_composite(map, descriptor, tuple) when is_tuple(tuple), do:
    decode_tuple_composite(map, descriptor, tuple, 0)
  def decode_composite(map, [{name, type} | _tail], value), do:
    Map.put(map, name, decode_maybe_composite_value(value, type))

  defp decode_tuple_composite(map, [{name, type} | tail], tuple, index) when index < tuple_size(tuple) do
    value = elem(tuple, index)
    map = Map.put(map, name, decode_maybe_composite_value(value, type))
    decode_tuple_composite(map, tail, tuple, index + 1)
  end
  defp decode_tuple_composite(map, _descriptor, _tuple, _index) do
    map
  end

  def decode_maybe_composite_value(value, type) do
    case HL7.Codec.decode_value(value, type) do
      :nomatch -> apply(type, :decode, [value])
      value    -> value
    end
  end


  @spec encode_composite(composite :: any, descriptor :: [{name :: atom, type :: atom}]) :: any
  def encode_composite(composite, descriptor), do:
    encode_composite(composite, descriptor, [])

  def encode_composite(composite, [{name, type} | tail], acc) do
    value = encode_maybe_composite_value(Map.get(composite, name), type)
    encode_composite(composite, tail, [value | acc])
  end
  def encode_composite(_composite, [], acc) do
    List.to_tuple(Enum.reverse(acc))
  end

  def encode_maybe_composite_value(value, type) do
    case HL7.Codec.encode_value(value, type) do
      :nomatch -> apply(type, :encode, [value])
      value    -> value
    end
  end



  @doc """
  Function that converts a composite field into an iolist suitable to send over
  a socket or write to a file.
  """
  @spec to_iodata(map, [{name :: atom, type :: atom}], [option]) :: iodata
  def to_iodata(map, descriptor, options) do
    field = encode_composite(map, descriptor)
    separators = case Keyword.get(:separators, options) do
                   nil        -> HL7.Codec.separators()
                   separators -> separators
                 end
    trim = Keyword.get(:trime, true)
    HL7.Codec.encode_field(field, separators, trim)
  end
end
