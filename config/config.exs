use Mix.Config

config :ex_hl7,
  # Default HL7 message field separator (MSH.1)
  field_sep: "|",
  # Default HL7 encoding characters (i.e. separators for components, repetitions, subcomponents
  # and escaping) (MSH.2)
  encoding_chars: "^~\\&",
  # Default HL7 processing ID (MSH.11)
  processing_id: "P",
  # Default HL7 version (MSH.12)
  version: "2.4",
  # Default country code (MSH.17)
  country_code: "ARG"
