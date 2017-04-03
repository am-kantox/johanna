defmodule Johanna.Mixfile do
  use Mix.Project

  @app :johanna

  def project do
    [app: @app,
     version: "0.1.2",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  def application do
    [extra_applications: [:logger, :erlcron]]
  end

  defp description do
    """
    **The wrapper for `erlcron` to be used in Elixir projects.**

    Original erlang library: https://github.com/erlware/erlcron
    """
  end

  defp package do
    [
     name: @app,
     files: ~w|lib src config mix.exs README.md|,
     maintainers: ["Aleksei Matiushkin"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/am-kantox/johanna",
              "Docs" => "https://hexdocs.pm/johanna"}]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 0.5", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end
end
