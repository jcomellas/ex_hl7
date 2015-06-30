defmodule HL7.Segment.Def do
  @moduledoc "Macros and functions used to define HL7 segments"
  require HL7.Composite

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Macro that generates the code that allows a module to be used as an HL7
  segment. A `segment` definition looks like the following block:

      segment "DG1" do
        field :set_id,                     seq:  1, type: :integer,  length:  4
        field :diagnosis,                  seq:  3, type: CE,        length: 64
        field :diagnosis_type,             seq:  6, type: :binary,   length:  2
      end

  A `segment` has a name or segment ID, which is a binary that will be used to
  identify the segment when parsing an HL7 message or when converting the
  segment into its wire format.

  *Note*: when defining a segment, the fields with correlative sequence (`seq`)
  numbers need not be in order, but it is recommended that you do so.
  """
  defmacro segment(segment_id, do: fields) when is_binary(segment_id) do
    quote do
      Module.register_attribute(unquote(__CALLER__.module), :segment_id, accumulate: false)
      Module.register_attribute(unquote(__CALLER__.module), :struct_fields, accumulate: true)
      Module.register_attribute(unquote(__CALLER__.module), :fields, accumulate: true)

      @before_compile unquote(__MODULE__)
      @segment_id unquote(segment_id)

      unquote(fields)
    end
  end

  @doc """
  Macro that injects the code used to represent a field within an HL7 segment
  block. Each `field` definition looks like the following one:

      field :diagnosis_type,             seq:  6, type: :binary,   length:  2

  A `field` has a name that has to be an atom, a `seq` number (1-based) with
  the field's position in the segment, a `type` and a `length`. The default
  `type` is `:string` and the default `length` is `nil`. The supported types
  are:

    * `:string`
    * `:integer`
    * `:float`
    * `:date`: a field containing a date as a `{year, month, day}` that is
      serialized using the YYYYMMDD format.
    * `:datetime`: a field containing a date/time tuple (i.e.
      `{{year, month, day}, {hour, min, sec}}`) that is serialized using the
      *YYYYMMDD[hhmm[ss]] format.
    * an atom corresponding to a composite field's module name. The module must
      have been built using the macros from the `HL7.Composite.Def` module or
      following the behaviour of an `HL7.Composite`. There are some sample
      composite field modules already defined in the `HL7.Composite` module.
  """
  defmacro field(name, options) do
    seq = Keyword.get(options, :seq)
    type = Keyword.get(options, :type, :binary)
    length = Keyword.get(options, :length)
    default = Keyword.get(options, :default, "")

    quote bind_quoted: [name: name, seq: seq, type: type, default: default,
                                 length: length, caller_module: __CALLER__.module] do
      check_field!(name, seq, type, default, length,
                   Module.get_attribute(caller_module, :segment_id),
                   Module.get_attribute(caller_module, :fields))

      @fields {name, seq, type, length}
      @struct_fields {name, default}
    end
  end

  defmacro __before_compile__(_env) do
    segment_module = __CALLER__.module
    segment_id = Module.get_attribute(segment_module, :segment_id)
    descriptor = build_descriptor(Module.get_attribute(segment_module, :fields))
    struct_fields = Enum.reverse(Module.get_attribute(segment_module, :struct_fields))

    quote do
      defstruct unquote(Macro.escape([{:__segment__, segment_id} | struct_fields]))

      # TODO: how do we inject a type spec into the generated code?
      @type t :: %unquote(segment_module){}
                 # unquote(Module.get_attribute(segment_module, :components)
                 #         |> Enum.map(fn {name, type} -> {name, type()} end)
                 #         |> Enum.reverse
                 #         |> Macro.escape)}

      @spec id() :: HL7.Type.segment_id
      def id(), do:
        unquote(segment_id)

      @spec descriptor() :: tuple
      def descriptor(), do:
        unquote(Macro.escape(descriptor))

      @spec field_count() :: non_neg_integer
      def field_count(), do:
        unquote(tuple_size(descriptor))

      @spec valid?(t) :: boolean
      def valid?(%unquote(segment_module){}), do: true
      def valid?(_), do: false

      @spec new() :: t
      def new(), do:
        %unquote(segment_module){}

      @spec get_field(t, HL7.Type.sequence) :: HL7.Type.field | no_return
      def get_field(segment, sequence) when is_integer(sequence), do:
        HL7.Segment.get_field(segment, descriptor(), sequence)

      @spec put_field(t, HL7.Type.sequence, HL7.Type.field) :: t | no_return
      def put_field(segment, sequence, value) when is_integer(sequence), do:
        HL7.Segment.put_field(segment, descriptor(), sequence, value)
    end
  end

  def check_field!(name, seq, type, default, length, segment_id, acc) do
    check_type!(name, seq, type)
    check_default!(name, seq, type, default)
    check_length!(name, seq, type, length)
    check_name_seq!(name, seq, segment_id, acc)
  end

  @doc "Check that the type of a field in a segment is valid"
  def check_type!(name, seq, type) do
    unless HL7.Composite.Def.check_type?(type) do
      raise ArgumentError, "invalid type #{inspect type} on field #{inspect name}, " <>
                           "sequence #{seq}"
    end
  end

  @doc "Check that the default value of a field in a segment is valid"
  def check_default!(name, seq, type, default) do
    unless HL7.Composite.Def.check_default?(type, default) do
      raise ArgumentError, "invalid default argument `#{inspect default}` for " <>
                           "#{type} field #{inspect name}, sequence #{seq}"
    end
  end

  @doc "Check that the length of a field in a segment is valid"
  def check_length!(name, seq, type, length) do
    unless (is_integer(length) and length > 0) or length === nil do
      raise ArgumentError, "invalid length #{length} for #{type} field #{inspect name}, "
                           "sequence #{seq}"
    end
  end

  def check_name_seq!(name, seq, segment_id, fields) do
    # IO.puts("check_name_seq!: #{name}, #{seq}, #{inspect segment_id}, #{inspect fields}")
    case List.keyfind(fields, name, 0) do
      {^name, seq1, _type1, _length1} ->
        raise ArgumentError, "field #{inspect name} (sequence #{seq}) was already " <>
                             "defined on segment #{inspect segment_id} with sequence #{seq1}"
      nil ->
        case List.keyfind(fields, seq, 1) do
          {name1, ^seq, _type1, _length1} ->
            raise ArgumentError, "sequence #{seq} for field #{name} was already " <>
                                 "defined on segment #{inspect segment_id} for field #{inspect name1}"
          nil ->
            nil
        end
    end
  end

  @spec build_descriptor([{name :: atom, seq :: pos_integer, type :: atom, length :: pos_integer}]) :: tuple
  def build_descriptor([_ | _] = fields) do
    # IO.puts("fields before sort: #{inspect fields}")
    # We sort the fields in descending order because we'll reverse the list as
    # we process it and end up leaving it in ascending order.
    fields = Enum.sort(fields,
                       fn {_name1, seq1, _type1, _length1},
                          {_name2, seq2, _type2, _length2} -> seq1 > seq2 end)
    [{_name, max_seq, _type, _length} | _tail] = fields
    # IO.puts("fields after sort: #{inspect fields}")
    _build_descriptor(fields, max_seq, [])
  end
  def build_descriptor([]) do
    {}
  end

  defp _build_descriptor([{_name, seq, _type, _length} = field | tail] = fields, last_seq, acc) do
    if seq === last_seq do
      _build_descriptor(tail, last_seq - 1, [field | acc])
    else
      # We use `nil` to represent missing descriptors.
      _build_descriptor(fields, last_seq - 1, [nil | acc])
    end
  end
  defp _build_descriptor([], last_seq, acc) when last_seq > 0 do
    # Add missing descriptors at the beginning of the segment.
    _build_descriptor([], last_seq - 1, [nil | acc])
  end
  defp _build_descriptor([], 0, acc) do
    # IO.puts("descriptor: #{inspect acc}\n")
    List.to_tuple(acc)
  end
end
