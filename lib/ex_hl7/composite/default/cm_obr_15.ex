defmodule HL7.Composite.Default.CM_OBR_15 do
  @moduledoc """
  7.4.1.15 OBR-15 Specimen source (CM) 00249

  Components:

    - `code` (CE)
    - `additives` (TX)
    - `free_text` (TX)
    - `body_site` (CE)
    - `site_modifier` (CE)
    - `collection_method` (CE)

  """
  use HL7.Composite.Spec

  require HL7.Composite.Default.CE, as: CE

  composite do
    component :code,              type: CE
    component :additives,         type: :string
    component :free_text,         type: :string
    component :body_site,         type: CE
    component :site_modifier,     type: CE
    component :collection_method, type: CE
  end
end
