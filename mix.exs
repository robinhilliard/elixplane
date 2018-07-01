defmodule XPLANE.Mixfile do
  use Mix.Project

  def project do
    [app: :xplane,
     version: "0.1.0",
     deps_path: "../deps",
     lockfile: "../mix.lock",
     elixir: "~> 1.0",
     description: description(),
     package: package(),
     deps: deps()]
  end


  def application do
    []
  end


  defp deps do
    [
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
  
  
  defp description() do
    "An X-Plane network interface for Elixir"
  end
  
  
  defp package() do
    [
      name: "elixplane",
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/robinhilliard/elixplane"},
      maintainers: ["Robin Hilliard"]
    ]
  end
end
