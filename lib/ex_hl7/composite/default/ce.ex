defmodule HL7.Composite.Default.CE do
  @moduledoc """
  2.9.3 CE - coded element

  Components:

    * `identifier` (ST)
    * `text` (ST)
    * `coding_system` (IS)
    * `alt_id` (ST)
    * `alt_text` (ST)
    * `alt_coding_system` (IS)

  ## Examples

      |F-11380^CREATININE^I9^2148-5^CREATININE^LN|

  """
  use HL7.Composite.Spec

  composite do
    component :id,                type: :string
    component :text,              type: :string
    component :coding_system,     type: :string
    component :alt_id,            type: :string
    component :alt_text,          type: :string
    component :alt_coding_system, type: :string
  end
end
