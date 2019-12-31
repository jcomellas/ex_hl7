defmodule HL7.Type do
  @moduledoc """
  Type specifications used by the library.
  """
  @type segment_id :: binary
  @type sequence :: pos_integer
  @type repetition :: pos_integer
  @type composite_id :: binary
  @type item_type :: :field | :component | :repetition | :subcomponent
  # Types used by the intermediate representation.
  @type subcomponent :: binary | tuple
  @type component :: binary | tuple
  @type field :: binary | component | [binary] | [component]
  # Types that can be used for HL7 fields.
  @type value_type :: :string | :integer | :float | :date | :datetime
  @type value :: binary | integer | float | Date.t() | NaiveDateTime.t()
  # Field specification that is used by the segment specification returned by `HL7.Segment.spec/0`.
  @type field_spec :: [{atom, tuple(), value_type(), integer | nil}]
  # For the configuration setting holding separators.
  @type separators :: tuple
end
