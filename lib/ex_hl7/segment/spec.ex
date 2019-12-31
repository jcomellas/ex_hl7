defmodule HL7.Segment.Spec do
  @moduledoc "Macros and functions used to define HL7 segments"
  require HL7.Composite, as: Composite

  alias HL7.Type

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Macro that generates the code that allows a module to be used as an HL7 segment. A `segment`
  definition looks like the following block:

      defmodule HL7.Segment.Default.DG1 do
        require HL7.Composite.Default.CE, as: CE

        segment "DG1" do
          field :set_id,             seq:  1, type: :integer, length: 4
          field :coding_method,      seq:  2, type: :string, length: 2
          field :diagnosis_id,       seq:  3, type: {CE, :id}, length: 20
          field :description,        seq:  4, type: :string, length: 40
          field :diagnosis_datetime, seq:  5, type: :datetime, length: 40
          field :diagnosis_type,     seq:  6, type: :string, length: 2
          field :approval_indicator, seq:  9, type: :string, length: 1
        end
      end

  A `segment` has a name or segment ID, which is a binary that will be used to identify the
  segment when parsing an HL7 message or when converting the segment into its wire format.

  *Note*: when defining a segment, the fields with correlative sequence (`seq`) numbers need not be
  in order, but it is recommended that you do so.
  """
  defmacro segment(segment_id, do: fields) when is_binary(segment_id) do
    caller_module = __CALLER__.module

    quote do
      Module.register_attribute(unquote(caller_module), :segment_id, accumulate: false)
      Module.register_attribute(unquote(caller_module), :struct_fields, accumulate: true)
      Module.register_attribute(unquote(caller_module), :fields, accumulate: true)

      @before_compile unquote(__MODULE__)
      @segment_id unquote(segment_id)

      unquote(fields)
    end
  end

  @doc """
  Macro that injects the code used to represent a field within an HL7 segment block. Each `field`
  definition looks like the following one:

  ```elixir
  field :diagnosis_type, seq: 6, type: :binary, len: 2
  ```

  A `field` has a name that has to be an atom, a `seq` number (1-based) with the field's position
  in the segment, a `rep` indicating the repetition the field corresponds to (1-based), a `type`,
  a `len` and a `default` value. The default `type` is `:string` and the default `length` is `nil`.
  The supported types are:

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
  defmacro field(name, options) do
    seq = Keyword.get(options, :seq)
    rep = Keyword.get(options, :rep, 1)
    type = Keyword.get(options, :type, :string)
    len = Keyword.get(options, :len)
    default = Keyword.get(options, :default, "")

    quote bind_quoted: [
            name: name,
            seq: seq,
            rep: rep,
            type: type,
            len: len,
            default: default,
            caller_module: __CALLER__.module
          ] do
      check_field!(
        name,
        seq,
        rep,
        type,
        default,
        len,
        Module.get_attribute(caller_module, :segment_id),
        Module.get_attribute(caller_module, :fields)
      )

      @fields {name, seq, rep, type, len}
      @struct_fields {name, default}
    end
  end

  defmacro __before_compile__(_env) do
    segment_mod = __CALLER__.module
    segment_id = Module.get_attribute(segment_mod, :segment_id)
    fields = Module.get_attribute(segment_mod, :fields)
    spec = build_spec(fields, segment_id)
    # The sequence number is the key in the spec map.
    field_count = spec |> Map.keys() |> Enum.max()

    struct_fields =
      segment_mod
      |> Module.get_attribute(:struct_fields)
      |> Enum.reverse()

    struct_type_spec = quote_struct_type_spec(segment_mod, fields)

    # IO.puts("Generating spec for segment #{inspect(segment_id)}: #{inspect(spec)}\n")

    quote do
      defstruct unquote(Macro.escape([{:__segment__, segment_id} | struct_fields]))

      unquote(struct_type_spec)

      @doc "Return the segment's ID"
      @spec id() :: Type.segment_id()
      def id(), do: unquote(segment_id)

      @doc "Return the segment's specification"
      @spec spec() :: %{Type.seq() => Type.field_spec()}
      def spec(), do: unquote(Macro.escape(spec))

      @doc false
      @spec field_count() :: non_neg_integer
      def field_count(), do: unquote(field_count)

      @doc false
      @spec valid?(t) :: boolean
      def valid?(%unquote(segment_mod){}), do: true
      def valid?(_), do: false

      @doc "Create a new segment of this type"
      @spec new() :: t
      def new(), do: %unquote(segment_mod){}
    end
  end

  defp quote_struct_type_spec(module, fields) do
    field_specs =
      fields
      |> Enum.map(fn {name, _seq, _rep, type, _len} ->
        {name, Composite.Spec.quote_base_type(type)}
      end)

    struct_spec = quote_struct_type(module, field_specs)

    quote context: Elixir do
      @type t :: unquote(struct_spec)
    end
  end

  defp quote_struct_type(module, field_specs) do
    name_spec = quote do: unquote(module)
    {:%, [], [name_spec, {:%{}, [], field_specs}]}
  end

  def check_field!(name, seq, rep, type, default, len, segment_id, acc) do
    check_type!(name, seq, rep, type, segment_id)
    check_default!(name, seq, rep, type, default, segment_id)
    check_length!(name, seq, rep, type, len, segment_id)
    check_name_seq!(name, seq, rep, type, segment_id, acc)
  end

  @doc "Check that the type of a field in a segment is valid"
  def check_type!(name, seq, rep, type, segment_id) do
    unless Composite.Spec.check_type?(type) do
      raise ArgumentError,
            "invalid type #{inspect(type)} on field " <>
              "#{inspect(name)} from segment #{inspect(segment_id)} at sequence " <>
              "#{seq}, repetition #{rep}"
    end
  end

  @doc "Check that the type of a field in a segment is a base type"
  def check_base_type!(name, seq, rep, type, segment_id) do
    unless Composite.Spec.check_base_type?(type) do
      raise ArgumentError,
            "invalid type #{inspect(type)} on field " <>
              "#{inspect(name)} from segment #{inspect(segment_id)} at sequence " <>
              "#{seq}, repetition #{rep}"
    end
  end

  @doc "Check that the default value of a field in a segment is valid"
  def check_default!(name, seq, rep, type, default, segment_id) do
    unless Composite.Spec.check_default?(type, default) do
      raise ArgumentError,
            "invalid default value '#{inspect(default)}' for " <>
              "#{type} field #{inspect(name)} from segment #{inspect(segment_id)} at " <>
              "sequence #{seq}, repetition #{rep}"
    end
  end

  @doc "Check that the length of a field in a segment is valid"
  def check_length!(name, seq, rep, type, len, segment_id) do
    unless (is_integer(len) and len > 0) or len === nil do
      raise ArgumentError,
            "invalid length #{len} for #{type} field " <>
              "#{inspect(name)} from segment #{segment_id} at sequence #{seq}, " <>
              "repetition #{rep}"
    end
  end

  def check_name_seq!(name, seq, rep, type, segment_id, fields) do
    # IO.puts("check_name_seq!: #{name}, #{seq}, #{inspect segment_id}, #{inspect fields}")
    case List.keyfind(fields, name, 0) do
      {^name, seq1, rep1, _type1, _len1} ->
        raise ArgumentError,
              "field #{inspect(name)} from segment " <>
                "#{inspect(segment_id)} at sequence #{seq}, repetition #{rep}, was " <>
                "already defined on sequence #{seq1}, repetition #{rep1}"

      nil ->
        fields
        |> Enum.filter(fn {_name1, seq1, rep1, type1, _len1} ->
          seq === seq1 and rep === rep1 and (not is_tuple(type) or type === type1)
        end)
        |> case do
          [{name1, ^seq, ^rep, _type1, _len1} | _tail] ->
            raise ArgumentError,
                  "field #{inspect(name)} from segment " <>
                    "#{inspect(segment_id)} with sequence #{seq}, repetition #{rep} " <>
                    "refers to the same sequence, repetition and component as field " <>
                    inspect(name1)

          [] ->
            :ok
        end
    end
  end

  @doc """
  Builds a specification map based on the field descriptions that were accumulated by the use of
  the `field/2` macro. For a segment defined in the following way:

      require HL7.Composite.Default.CM_ERR_1, as: CM_ERR_1

      field :ack_code,           seq: 1, type: :string, length:  2
      field :message_control_id, seq: 2, type: :string, length: 20
      field :text_message,       seq: 3, type: :string, length: 80
      field :error_code,         seq: 6, type: {CM_ERR_1, :error, :id}, length: 10
      field :error_text,         seq: 6, type: {CM_ERR_1, :error, :text}, length: 61

  This function will end up generating the following segment specification map:

      %{
        1 => [{:ack_code, [1], :string, 2}],
        2 => [{:message_control_id, [1], :string, 20}],
        3 => [{:text_message, [1], :string, 80}],
        6 => [[{:error_text, [1, 2], :string, 61}, {:error_code, [1, 1], :string, 10}]]
      }

  The key in the map corresponds to the field sequence number in the segment,
  whereas the value is a list of tuples where each tuple has the following
  elements:

  1. Name: atom with the name of the field this value will be mapped to in the segment.

  2. Index: tuple of integers representing the nested indexes (1-based) where
     the item is located within the field. The number of elements in the tuple
     depends on whether the value corresponds to a:

     * field: one element with the field's repetition number (1-based);
       e.g. `{1}`.

     * component: two elements with the repetition number and the component
       index (1-based); e.g. for `{CE, :text}` you'd get `{1, 2}`.

     * subcomponent: three elements with the repetition number, the component
       index and the subcomponent index (1-based); e.g. for
       `{CX, :assigning_authority, :namespace_id}` you'd get {1, 4, 1}.

  3. Data type: one of the accepted basic data types (i.e. `:string`;
     `:integer`; `:float`; `:date`; `:datetime`).

  4. Maximum length of the value in bytes.

  The tuples in the item spec list will be sorted so that the items that are towards the end of the
  field end up at the beginning of the list (i.e. reversed). This order acts as an aid when writing
  the field from the segment map into a buffer.

  ## Examples

  A field with these definitions:

      field :id,      seq: 3, type: {CX, :id}, len: 6
      field :auth_id, seq: 3, type: {CX, :assigning_authority, :namespace_id}, len: 10,
      field :id_type, seq: 3, type: {CX, :id_type}, len: 10

  Would be expected to have a spec like the following one:

      [{:id,      [1, 1],    :string, 6},
       {:auth_id, [1, 4, 1], :string, 10},
       {:id_type, [1, 5],    :string, 10}]

  But given that the code that writes the field into a buffer requires this list to be reverse,
  what is actually returned is the following:

      [{:id_type, [1, 5],    :string, 10},
       {:auth_id, [1, 4, 1], :string, 10},
       {:id,      [1, 1],    :string, 6}]

  """
  @spec build_spec(
          [
            {name :: atom, seq :: pos_integer, rep :: pos_integer, type :: atom,
             len :: pos_integer}
          ],
          Type.segment_id()
        ) :: map
  def build_spec([_ | _] = fields, segment_id) do
    # We sort the fields in ascending order, convert them to the format returned
    # by the generated `spec/0` function, group them by sequence number and
    # finally sort each field specification according to the order expected by
    # the code that writes a field into a buffer.
    fields
    |> Enum.sort(&field_spec_order/2)
    |> Enum.map(&build_field_spec(&1, segment_id))
    |> Enum.group_by(fn {seq, _spec} -> seq end, fn {_seq, spec} -> spec end)
    |> Enum.into(%{}, &sort_field_spec/1)
  end

  def build_spec([]) do
    %{}
  end

  defp build_field_spec({name, seq, rep, type, len}, _segment_id)
       when type === :string or type === :integer or type === :float or
              type === :date or type === :datetime do
    # If the type is one of the supported basic data types, use its repetition
    # number as index.
    {seq, {name, {rep}, type, len}}
  end

  defp build_field_spec({name, seq, rep, type, len}, segment_id) when is_tuple(type) do
    # If the type is a component or subcomponent element, we delegate the index
    # calculation to the corresponding composite field module.
    {composite_index, composite_type} = Composite.spec!(type)
    # Verify that the expanded composite type corresponds to a base type.
    check_base_type!(name, seq, rep, composite_type, segment_id)
    {seq, {name, Tuple.insert_at(composite_index, 0, rep), composite_type, len}}
  end

  defp field_spec_order(
         {_name1, seq1, rep1, _type1, _len1},
         {_name2, seq2, rep2, _type2, _len2}
       ) do
    if seq1 == seq2, do: rep1 <= rep2, else: seq1 < seq2
  end

  defp sort_field_spec({seq, field_spec}) do
    {seq, Enum.sort(field_spec, &item_spec_order/2)}
  end

  defp item_spec_order({name_1, index_1, _type_1, _len_1}, {name_2, index_2, _type_2, _len_2}) do
    if index_1 !== index_2 do
      # We can't use the normal tuple comparison because we need the comparison to happen element
      # by element. The problem is that a tuple that has more elements is considered "bigger" even
      # if its elements are not bigger than those in the other tuple being compared. e.g.
      #
      #     iex> {1, 4, 3} > {2, 5}
      #     true
      #     iex> [1, 4, 3] > [2, 5]
      #     false
      #
      Tuple.to_list(index_1) > Tuple.to_list(index_2)
    else
      raise ArgumentError,
            "field #{inspect(name_1)} and field #{inspect(name_2)}" <>
              "have overlapping indexes #{inspect(index_1)}"
    end
  end
end
