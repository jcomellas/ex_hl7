defmodule HL7.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_hl7,
     version: "1.0.0",
     elixir: ">= 1.6.0",
     description: "HL7 Parser for Elixir",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     consolidate_protocols: Mix.env != :test]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev},
      {:rexbug, "~> 1.0.3", only: :dev}
    ]
  end

  defp package do
    [files: ["lib", "test", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Juan Jose Comellas"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/jcomellas/ex_hl7"}]
  end
end
