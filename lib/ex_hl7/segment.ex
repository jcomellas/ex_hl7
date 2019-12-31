defmodule HL7.Segment do
  @moduledoc """
  Generic functions used by HL7 segment macros
  """
  require Logger

  alias HL7.Codec
  alias HL7.Type

  @type t :: map
  @type spec :: {name :: atom, seq :: Type.sequence(), type :: atom, len :: pos_integer}

  @default_value ""

  @doc """
  Return the ID of a segment.

  ## Examples

      iex> alias HL7.Segment.Default.Builder
      ...> {:ok, {segment, segment_spec}} = Builder.new("MSH")
      ...> id(segment)
      "MSH"

  """
  @spec id(t) :: Type.segment_id()
  def id(segment) when is_map(segment), do: Map.get(segment, :__segment__)
  def id(_segment), do: nil

  @doc """
  Return the module corresponding to a segment.

  ## Examples

      iex> alias HL7.Segment.Default.Builder
      ...> {:ok, {segment, segment_spec}} = Builder.new("MSH")
      ...> module(segment)
      HL7.Segment.Default.MSH

  """
  @spec module(t) :: module
  def module(%{__struct__: module}), do: module
  def module(_segment), do: nil

  @doc """
  Given a field specification, generate the intermediate representation for the field using the
  data present in a segment map.

  A field that has the following definition in a segment:

      alias HL7.Composite.Default.CX

      field :patient_id,               seq:  3, rep: 1, type: {CX, :id}, len: 20
      field :auth_id,                  seq:  3, rep: 1, type: {CX, :assigning_authority, :namespace_id}, len: 6
      field :auth_universal_id,        seq:  3, rep: 1, type: {CX, :assigning_authority, :universal_id}, len: 6
      field :auth_universal_id_type,   seq:  3, rep: 1, type: {CX, :assigning_authority, :universal_id_type}, len: 10
      field :id_type,                  seq:  3, rep: 1, type: {CX, :id_type}, len: 2
      field :patient_document_id,      seq:  3, rep: 2, type: {CX, :id}, len: 20
      field :patient_document_id_type, seq:  3, rep: 2, type: {CX, :id_type}, len: 2

  Will have the following field specification (note that the specifications of each item in the
  field are sorted based on their coordinate in descending order):

      field_spec = [
        {:patient_document_id_type,    {2, 4},    :string, 2},
        {:patient_document_id,         {2, 1},    :string, 20},
        {:id_type,                     {1, 5},    :string, 2},
        {:authority_universal_id_type, {1, 4, 3}, :string, 10},
        {:authority_universal_id,      {1, 4, 2}, :string, 6},
        {:authority_id,                {1, 4, 1}, :string, 6},
        {:patient_id,                  {1, 1},    :string, 20}
      ]

  The coordinate of an item is a tuple (with a maximum of 3 elements) representing their position
  in the field. Each element of the coordinate tuple is an index with the following meaning.

    1. repetition index
    2. component index
    3. subcomponent index

  ## Examples

      iex> field_spec = [
        {:patient_document_id_type,    {2, 4},    :string, 2},
        {:patient_document_id,         {2, 1},    :string, 20},
        {:id_type,                     {1, 5},    :string, 2},
        {:authority_universal_id_type, {1, 4, 3}, :string, 10},
        {:authority_universal_id,      {1, 4, 2}, :string, 6},
        {:authority_id,                {1, 4, 1}, :string, 6},
        {:patient_id,                  {1, 1},    :string, 20}
      ]
      ...> segment = %{
        patient_id: "Juan Perez",
        authority_id: "XYZ123",
        authority_universal_id: "808818",
        authority_universal_id_type: "IIN",
        id_type: "CU",
        patient_document_id: "12345678",
        patient_document_id_type: "DNI"
      }
      ...> get_field_ir(segment, field_spec)
      [
        {"Juan Perez", "", "", {"XYZ123", "808818", "IIN"}, "CU"},
        {"12345678", "", "", "DNI"}
      ]

  """
  def get_field_ir(segment, [{_name, _coord, _type, _len} | _spec_tail] = field_spec) do
    # If there is only a single repetition, there's no need to expose it.
    case build_item_ir(segment, field_spec, 1, {}, 1, []) do
      [item] -> item
      item -> item
    end
  end

  defp build_item_ir(
         segment,
         [{name, coord, type, _len} | spec_tail] = spec,
         cur_depth,
         parent_coord,
         prev_index,
         acc
       ) do
    max_depth = tuple_size(coord)

    # Check if the item being evaluated is a sibling or child of the previous one.
    if max_depth >= cur_depth and match_base_coord(parent_coord, coord, cur_depth - 1) do
      cur_index = coord_index(coord, cur_depth)
      acc = append_missing_empty_items(acc, prev_index, cur_index)

      cond do
        max_depth > cur_depth ->
          # If the current item spec corresponds to a child item, then we recurse to build it.
          child_depth = cur_depth + 1
          child_index = coord_index(coord, child_depth)

          {value, spec_tail} = build_item_ir(segment, spec, child_depth, coord, child_index, [])

          build_item_ir(segment, spec_tail, cur_depth, parent_coord, cur_index, [value | acc])

        true ->
          value =
            case Map.get(segment, name) do
              nil -> @default_value
              value_1 -> Codec.encode_value!(value_1, type)
            end

          build_item_ir(segment, spec_tail, cur_depth, parent_coord, cur_index, [
            value | acc
          ])
      end
    else
      {List.to_tuple(acc), spec}
    end
  end

  defp build_item_ir(
         _segment,
         [] = spec,
         cur_depth,
         _parent_coord,
         prev_index,
         acc
       ) do
    # If there are any items at the beginning of the field that are not in the field spec, we
    # add an empty value for each of them them.
    acc = prepend_missing_empty_items(acc, prev_index, 1)
    # The last recursive call will have the current item's depth set to 1. We use that condition
    # to return the result to the caller.
    if cur_depth > 1 do
      {List.to_tuple(acc), spec}
    else
      acc
    end
  end

  def match_base_coord(_coord_1, _coord_2, 0), do: true

  def match_base_coord(coord_1, coord_2, depth)
      when tuple_size(coord_1) >= depth and tuple_size(coord_2) >= depth do
    Enum.reduce_while(1..depth, true, fn index, _status ->
      if coord_index(coord_1, index) === coord_index(coord_2, index) do
        {:cont, true}
      else
        {:halt, false}
      end
    end)
  end

  def match_base_coord(_coord_1, _coord_2, _depth), do: false

  defp coord_index(_coord, 0), do: 1
  defp coord_index(coord, depth), do: :erlang.element(depth, coord)

  defp append_missing_empty_items(acc, prev_index, cur_index) do
    prev_index = prev_index - 1

    if prev_index > cur_index do
      append_missing_empty_items(["" | acc], prev_index, cur_index)
    else
      acc
    end
  end

  defp prepend_missing_empty_items(acc, prev_index, cur_index) do
    if prev_index > cur_index do
      prepend_missing_empty_items(["" | acc], prev_index - 1, cur_index)
    else
      acc
    end
  end

  def put_field_ir(segment, [{name, coord, type, _len} | spec_tail], value) do
    encoded_value =
      value
      |> get_item_from_ir(coord)
      |> Codec.decode_value!(type)

    segment
    |> Map.put(name, encoded_value)
    |> put_field_ir(spec_tail, value)
  end

  def put_field_ir(segment, [], _value) do
    segment
  end

  defp get_item_from_ir(value, coord) do
    index = coord_index(coord, 1)

    if is_list(value) do
      case Enum.at(value, index - 1) do
        nil -> @default_value
        item -> get_item_from_ir(item, coord, 2)
      end
    else
      if index === 1 do
        get_item_from_ir(value, coord, 2)
      else
        @default_value
      end
    end
  end

  defp get_item_from_ir(value, coord, depth) when depth > tuple_size(coord) do
    value
  end

  defp get_item_from_ir(tuple, coord, depth) when is_tuple(tuple) do
    index = coord_index(coord, depth)

    if index <= tuple_size(tuple) do
      index
      |> :erlang.element(tuple)
      |> get_item_from_ir(coord, depth + 1)
    else
      @default_value
    end
  end

  defp get_item_from_ir(value, coord, depth) do
    case coord_index(coord, depth) do
      1 -> get_item_from_ir(value, coord, depth + 1)
      _ -> @default_value
    end
  end
end
