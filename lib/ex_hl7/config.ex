defmodule HL7.Config do
  @moduledoc """
  Stores configuration variables for the HL7 parser.
  """

  @app :ex_hl7

  @doc """
  Returns the field separator used by default in the **MSH** HL7 segment.
  Set it in `mix.exs`:

      config :ex_hl7, field_sep: "|"
  """
  def field_sep, do: Application.get_env(@app, :field_sep) || "|"

  @doc """
  Returns the characters used to encode components, repetitions, escaped values
  and subcomponents within an HL7 field. Set it in `mix.exs`:

      config :ex_hl7, encoding_chars: "^~\\&"
  """
  def encoding_chars, do: Application.get_env(@app, :encoding_chars) || "^~\\&"

  @doc """
  Returns the processing ID used by default in the **MSH** HL7 segment.
  Set it in `mix.exs` as `P`for production and `D` for debugging:

      config :ex_hl7, processing_id: "P"
  """
  def processing_id, do: Application.get_env(@app, :processing_id) || "P"

  @doc """
  Returns the version used by default in the **MSH** HL7 segment.
  Set it in `mix.exs`:

      config :ex_hl7, version: "2.4"
  """
  def version, do: Application.get_env(@app, :version) || "2.4"

  @doc """
  Returns the country code used by default in the **MSH** HL7 segment.
  Set it in `mix.exs` as the corresponding 3-letter ISO code:

      config :ex_hl7, country_code: "ARG"
  """
  def country_code, do: Application.get_env(@app, :country_code) || "ARG"
end