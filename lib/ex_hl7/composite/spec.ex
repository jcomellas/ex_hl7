defmodule HL7.Composite.Spec do
  @moduledoc "Macros and functions used to define HL7 composite fields"
  @type option ::
          {:separators, [{key :: atom, separator :: byte}]}
          | {:trim, boolean}

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Macro that generates the code that allows a module to be used as a composite field for HL7
  segments. A `composite` field definition looks like the following block:

      composite do
        component :number, type: :string
        component :date,   type: :date
        component :source, type: :string
      end

  *Note*: when defining a composite, the fields have to be in the order they appear in the message.
  """
  defmacro composite(do: components) do
    caller_module = __CALLER__.module

    quote do
      Module.register_attribute(unquote(caller_module), :components, accumulate: true)
      @before_compile unquote(__MODULE__)

      unquote(components)
    end
  end

  @doc """
  Macro that generates the code for each individual component within an HL7 composite field.
  Each `component` definition looks like the following one:

      component :price, type: :float

  A `component` has a name that has to be an atom, a `type` and a `default` value. The default
  `type` is `:string` and the default `value` is `""` for basic types and an empty struct for
  composite types. The supported types are:

    * `:string`
    * `:integer`
    * `:float`
    * `:date`: a field containing a date as a `%Date{}` struct that is serialized using the
      `YYYYMMDD` format.
    * `:datetime`: a field containing a `%NaiveDateTime{}` struct that is serialized using the
      `YYYYMMDD[hhmm[ss]]` format.
    * an atom corresponding to a composite field's module name. The module must have been built
      using the macros from the `HL7.Composite.Spec` module or following the behaviour of an
      `HL7.Composite`.

  """
  defmacro component(name, args \\ []) do
    type = Keyword.get(args, :type, :string)
    default = default_for(type, Keyword.get(args, :default))

    quote bind_quoted: [name: name, type: type, default: default, module: __CALLER__.module] do
      check_component!(name, type, default, module, Module.get_attribute(module, :components))
      # Accumulate the components and fields of the struct that will be added to the module so
      # that the corresponding functions can be generated in the __before_compile__ function.
      @components {name, type}
    end
  end

  defmacro __before_compile__(_env) do
    composite_mod = __CALLER__.module

    spec =
      composite_mod
      |> Module.get_attribute(:components)
      |> Enum.reverse()

    quote do
      @doc "Return the specification for the composite type."
      @spec spec() :: [HL7.Composite.spec()]
      def spec(), do: unquote(Macro.escape(spec))
    end
  end

  def quote_base_type(:string), do: quote(context: Elixir, do: binary)
  def quote_base_type(:integer), do: quote(context: Elixir, do: integer)
  def quote_base_type(:float), do: quote(context: Elixir, do: float)
  def quote_base_type(:date), do: quote(context: Elixir, do: Date.t())
  def quote_base_type(:datetime), do: quote(context: Elixir, do: NaiveDateTime.t())
  def quote_base_type(composite), do: quote(context: Elixir, do: unquote(base_type!(composite)).t)

  @doc "Checks that a component definition is correct"
  @spec check_component!(
          name :: atom,
          type :: atom,
          default :: any,
          module,
          components :: [{name :: atom, type :: atom}]
        ) :: nil | no_return
  def check_component!(name, type, default, module, components) do
    check_type!(name, type)
    check_default!(name, type, default)

    unless List.keyfind(components, name, 0) === nil do
      raise ArgumentError,
            "component #{inspect(name)} is already present in composite '#{module}'"
    end
  end

  @doc "Checks that the type of a component inside a composite field is valid"
  def check_type!(name, type) do
    unless check_type?(type) do
      raise ArgumentError, "invalid type #{inspect(type)} in component #{inspect(name)}"
    end
  end

  def check_type?(composite_type) when is_tuple(composite_type) do
    composite_type
    |> base_type()
    |> check_type?()
  end

  def check_type?(type) do
    check_base_type?(type) or composite_module?(type)
  end

  def check_base_type?(:string), do: true
  def check_base_type?(:integer), do: true
  def check_base_type?(:float), do: true
  def check_base_type?(:date), do: true
  def check_base_type?(:datetime), do: true
  def check_base_type?(_type), do: false

  @doc """
  Function that receives the type used in a segment or composite field
  definition and returns its basic type. If a composite type is passed, it will
  navigate through its definition and return the basic type (i.e. `:string`;
  `:integer`, `:float`; `:date`; `:datetime`) of the corresponding field.

  It accepts both basic types and composite types, returning the atom
  corresponding to the type or `nil` if the type is invalid.

  ## Examples

      iex> alias HL7.Composite.Spec
      ...> alias HL7.Composite.Default.CX
      ...> Spec.base_type({CX, :assigning_authority, :universal_id})
      :string
      iex> Spec.base_type({CX, :effective_date})
      :date
      iex> Spec.base_type(:integer)
      :integer
      iex> Spec.base_type(:invalid_type)
      nil

  """
  def base_type(composite_type) when is_tuple(composite_type) do
    composite_mod = elem(composite_type, 0)

    if composite_module?(composite_mod) do
      key = elem(composite_type, 1)

      case List.keyfind(composite_mod.spec(), key, 0) do
        {^key, type} when tuple_size(composite_type) === 2 ->
          type

        {^key, subcomposite_mod} when tuple_size(composite_type) === 3 ->
          base_type({subcomposite_mod, elem(composite_type, 2)})

        nil ->
          nil
      end
    else
      nil
    end
  end

  def base_type(type)
      when type === :string or type === :integer or type === :float or
             type === :date or type === :datetime do
    type
  end

  def base_type(_type) do
    nil
  end

  def base_type!(type) do
    case base_type(type) do
      base_type when base_type !== nil ->
        base_type

      nil ->
        raise ArgumentError, "invalid type #{inspect(type)}"
    end
  end

  def composite_module?(module) do
    is_atom(module) and Code.ensure_compiled?(module) and function_exported?(module, :spec, 0)
  end

  @doc "Checks that the default value assigned to a component inside a composite field is valid"
  def check_default!(name, type, default) do
    if check_default?(type, default) do
      true
    else
      raise ArgumentError,
            "invalid default value #{inspect(default)} for " <>
              "#{type} component #{inspect(name)}"
    end
  end

  def check_default?(_type, ""), do: true
  def check_default?(:string, default), do: is_binary(default)
  def check_default?(:integer, default), do: is_integer(default)
  def check_default?(:float, default), do: is_float(default)
  def check_default?(:date, date), do: is_date(date)
  def check_default?(:datetime, datetime), do: is_datetime(datetime)
  def check_default?(_type, _default), do: false

  def default_for(_type, default) when is_nil(default) do
    quote do: unquote("")
  end

  def default_for(_type, default) do
    quote do: unquote(default)
  end

  def base_type?(:string), do: true
  def base_type?(:integer), do: true
  def base_type?(:float), do: true
  def base_type?(:date), do: true
  def base_type?(:datetime), do: true
  def base_type?(_type), do: false

  defp is_date(%Date{}), do: true
  defp is_date(_date), do: false

  defp is_datetime(%NaiveDateTime{}), do: true
  defp is_datetime(_datetime), do: false
end
