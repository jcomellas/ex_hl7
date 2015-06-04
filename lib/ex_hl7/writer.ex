defmodule HL7.Writer do
  @moduledoc """
  Writer for the HL7 protocol that converts a message into its wire format.
  """
  defstruct state: :start, separators: nil, trim: true, output_format: :wire, buffer: []

  alias HL7.Writer

  @type option         :: {:separators, binary} | {:trim, boolean} | {:output_format, :wire | :text}

  @opaque state        :: :normal | :field_separator | :encoding_chars
  @opaque t            :: %Writer{state: state, separators: binary, trim: boolean, buffer: iodata}

  @spec new([option]) :: t
  def new(options \\ []) do
    separators = Keyword.get(options, :separators, HL7.Codec.separators())
    trim = Keyword.get(options, :trim, true)
    output_format = Keyword.get(options, :output_format, :wire)
    %Writer{state: :start, separators: separators, trim: trim, output_format: output_format, buffer: []}
  end

  @spec buffer(t) :: iodata
  def buffer(%Writer{buffer: buffer}), do:
    Enum.reverse(buffer)

  @spec start_message(t) :: t
  def start_message(writer), do:
    %Writer{writer | state: :normal, buffer: []}

  @spec end_message(t) :: t
  def end_message(writer), do:
    %Writer{writer | state: :normal}

  @spec start_segment(t, HL7.Type.segment_id) :: t
  def start_segment(%Writer{buffer: buffer} = writer, "MSH" = segment_id), do:
    %Writer{writer | state: :field_separator, buffer: [segment_id | buffer]}
  def start_segment(%Writer{buffer: buffer} = writer, segment_id), do:
    %Writer{writer | buffer: [segment_id | buffer]}

  @spec end_segment(t, HL7.Type.segment_id) :: t
  def end_segment(%Writer{buffer: buffer, separators: separators, trim: trim,
                          output_format: output_format} = writer, _segment_id) do
    eos = case output_format do
            :text -> ?\n
            _     -> ?\r
          end
    %Writer{writer | buffer: [eos | maybe_trim_buffer(buffer, separators, trim)]}
  end

  @spec put_field(t, HL7.Type.field) :: t
  def put_field(%Writer{state: :normal, buffer: buffer, separators: separators} = writer, "") do
    # Avoid adding unnecessary empty fields
    %Writer{writer | buffer: [HL7.Codec.separator(:field, separators) | buffer]}
  end
  def put_field(%Writer{state: :normal, buffer: buffer, separators: separators, trim: trim} = writer, field) do
    %Writer{writer | buffer: [HL7.Codec.encode_field(field, separators, trim),
                              HL7.Codec.separator(:field, separators) | buffer]}
  end
  def put_field(%Writer{state: :field_separator, buffer: buffer} = writer, <<separator>>) do
    %Writer{writer | state: :encoding_chars, buffer: [separator | buffer]}
  end
  def put_field(%Writer{state: :encoding_chars, buffer: buffer} = writer, field) do
    %Writer{writer | state: :normal, buffer: [field | buffer]}
  end

  defp maybe_trim_buffer(buffer, separators, true),   do: trim_buffer(buffer, separators)
  defp maybe_trim_buffer(buffer, _separators, false), do: buffer

  defp trim_buffer([char | tail] = buffer, separators) when is_integer(char) do
    case HL7.Codec.match_separator?(char, separators) do
      {:match, _item_type} -> trim_buffer(tail, separators)
      :nomatch             -> buffer
    end
  end
  defp trim_buffer(buffer, _separators) do
    buffer
  end

end
