defmodule HL7.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_hl7,
     version: "0.3.0",
     elixir: "~> 1.0",
     description: "HL7 Parser for Elixir",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     consolidate_protocols: Mix.env != :test]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev}]
  end

  defp package do
    [files: ["lib", "test", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Juan Jose Comellas"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/jcomellas/ex_hl7"}]
  end
end
