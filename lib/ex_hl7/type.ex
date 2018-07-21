defmodule HL7.Type do
  @moduledoc """
  Type specifications used by the library.
  """
  @type segment_id     :: binary
  @type sequence       :: pos_integer
  @type repetition     :: pos_integer
  @type composite_id   :: binary
  @type item_type      :: :field | :component | :repetition | :subcomponent
  @type subcomponent   :: binary | tuple
  @type component      :: binary | tuple
  @type field          :: binary | component | [binary] | [component]
  @type value_type     :: :string | :integer | :float | :date | :datetime
  @type value          :: binary | integer | float | Date.t | NaiveDateTime.t
end
