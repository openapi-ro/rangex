defmodule Rangex.MixProject do
  use Mix.Project

  def project do
    [
      app: :rangex,
      version: "0.1.1-dev",
      package: [
        maintainers: ["Paul Balomiri", "paul.balomiri@gmail.com"],
        description: "Range manipulation library",
        licenses: ["WTFPL"],
        links: %{"GitHub" => "https://github.com/openapi-ro/rangex"}
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      consolidate_protocols: Mix.env != :test,
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]

    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.8", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
