defmodule XPLANE.Mixfile do
  use Mix.Project

  def project do
    [app: :xplane,
     version: "0.0.1",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.0",
     description: description(),
     package: package(),
     deps: deps()]
  end


  def application do
    []
  end


  defp deps do
    []
  end
  
  
  defp description() do
    "An X-Plane network interface for Elixir"
  end
  
  
  defp package() do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/robinhilliard/elixplane"},
      maintainers: ["Robin Hilliard"]
    ]
  end
end
