defmodule HL7.Composite do
  @moduledoc "Generic functions used by HL7 composite field macros"

  @type spec :: {name :: atom, HL7.Type.value_type() | module}
  @type option ::
          {:separators, [{key :: atom, separator :: byte}]}
          | {:trim, boolean}

  @callback spec(atom) :: {index :: pos_integer, HL7.Type.value_type() | module}

  @doc """
  Given a tuple representing the declaration of a component or subcomponent of a field, return a
  tuple with the corresponding list of indexes (1-based) for the item in the composite and its type.

  The function will raise an exception if any of the passed component or subcomponent key names
  are invalid.

  ## Examples

      alias HL7.Composite.Default.{CE, CP, CX}
      alias HL7.Composite

      iex> Composite.spec!({CE, :text})
      {{2}, :string}
      iex> Composite.spec!({CX, :effective_date})
      {{7}, :date}
      iex> Composite.spec!({CP, :price, :quantity})
      {{1, 1}, :float}
      iex> Composite.spec!({CP, :price, :denomination})
      {{1, 2}, :string}

  """
  def spec!({component_mod, component_key})
      when is_atom(component_mod) and is_atom(component_key) do
    {component_index, type} =
      component_mod
      |> item_spec!(component_key)

    {{component_index}, type}
  end

  def spec!({component_mod, component_key, subcomponent_key})
      when is_atom(component_mod) and is_atom(component_key) and
             is_atom(subcomponent_key) do
    {component_index, subcomponent_mod} =
      component_mod
      |> item_spec!(component_key)

    {subcomponent_index, type} =
      subcomponent_mod
      |> item_spec!(subcomponent_key)

    {{component_index, subcomponent_index}, type}
  end

  defp item_spec!(composite_mod, item_key) do
    composite_mod
    |> apply(:spec, [])
    |> item_spec(item_key, 1)
    |> case do
      result = {_index, _type} ->
        result

      nil ->
        raise ArgumentError,
              "could not find element '#{inspect(item_key)}' in " <>
                "composite #{inspect(composite_mod)}"
    end
  end

  defp item_spec([{key, type} | tail], item_key, index) do
    case item_key do
      ^key -> {index, type}
      _ -> item_spec(tail, item_key, index + 1)
    end
  end

  defp item_spec([], _item_key, _index) do
    nil
  end
end
