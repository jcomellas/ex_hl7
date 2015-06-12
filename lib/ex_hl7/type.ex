defmodule HL7.Type do
  @type segment_id     :: binary
  @type sequence       :: pos_integer
  @type item_type      :: :field | :component | :repetition | :subcomponent
  @type subcomponent   :: binary | tuple(binary)
  @type component      :: binary | tuple(binary) | tuple(subcomponent)
  @type field          :: binary | component | [binary] | [component]
  @type value_type     :: :string | :integer | :float | :date | :datetime
  @type value          :: binary | integer | float | :calendar.date | :calendar.datetime
  @type repetition     :: non_neg_integer
end
