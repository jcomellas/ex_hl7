defmodule HL7.Writer do
  @moduledoc """
  Writer for the HL7 protocol that converts a message into its wire format.
  """
  defstruct state: :start,
            separators: nil,
            trim: true,
            output_format: :wire,
            buffer: [],
            builder: nil

  alias HL7.{Codec, Segment, Type, Writer}

  @type output_format :: :wire | :text
  @type option ::
          {:separators, tuple}
          | {:trim, boolean}
          | {:output_format, output_format()}
  @opaque state :: :normal | :field_separator | :encoding_chars
  @opaque t :: %Writer{
            state: state,
            separators: tuple,
            trim: boolean,
            output_format: output_format(),
            buffer: iolist,
            builder: module
          }

  @spec new([option]) :: t
  def new(options \\ []) do
    %Writer{
      state: :start,
      separators: Keyword.get(options, :separators, Codec.separators()),
      trim: Keyword.get(options, :trim, true),
      output_format: Keyword.get(options, :output_format, :wire),
      buffer: [],
      builder: Keyword.get(options, :builder, Segment.Default.Builder)
    }
  end

  @spec buffer(t) :: iodata
  def buffer(%Writer{buffer: buffer}), do: Enum.reverse(buffer)

  @spec builder(t) :: atom
  def builder(%Writer{builder: builder}), do: builder

  @spec start_message(t) :: t
  def start_message(writer), do: %Writer{writer | state: :normal, buffer: []}

  @spec end_message(t) :: t
  def end_message(writer), do: %Writer{writer | state: :normal}

  @spec start_segment(t, Type.segment_id()) :: t
  def start_segment(%Writer{buffer: buffer} = writer, segment_id = "MSH"),
    do: %Writer{writer | state: :field_separator, buffer: [segment_id | buffer]}

  def start_segment(%Writer{buffer: buffer} = writer, segment_id),
    do: %Writer{writer | buffer: [segment_id | buffer]}

  @spec end_segment(t, Type.segment_id()) :: t
  def end_segment(
        %Writer{buffer: buffer, separators: separators, trim: trim} = writer,
        _segment_id
      ) do
    eos = if writer.output_format === :text, do: ?\n, else: ?\r
    %Writer{writer | buffer: [eos | maybe_trim_buffer(buffer, separators, trim)]}
  end

  @spec put_field(t, Type.field()) :: t
  def put_field(%Writer{state: :normal, buffer: buffer, separators: separators} = writer, field) do
    separator = Codec.separator(:field, separators)

    buffer =
      if field === "" do
        # Avoid adding unnecessary empty fields
        [separator | buffer]
      else
        case Codec.encode_field!(field, separators, writer.trim) do
          [] -> [separator | buffer]
          value -> [value, separator | buffer]
        end
      end

    %Writer{writer | buffer: buffer}
  end

  def put_field(%Writer{state: :field_separator, buffer: buffer} = writer, <<separator>>) do
    %Writer{writer | state: :encoding_chars, buffer: [separator | buffer]}
  end

  def put_field(%Writer{state: :encoding_chars, buffer: buffer} = writer, field) do
    %Writer{writer | state: :normal, buffer: [field | buffer]}
  end

  defp maybe_trim_buffer(buffer, separators, true), do: trim_buffer(buffer, separators)
  defp maybe_trim_buffer(buffer, _separators, false), do: buffer

  defp trim_buffer([char | tail] = buffer, separators) when is_integer(char) do
    case Codec.match_separator(char, separators) do
      {:match, _item_type} -> trim_buffer(tail, separators)
      :nomatch -> buffer
    end
  end

  defp trim_buffer(buffer, _separators) do
    buffer
  end
end
