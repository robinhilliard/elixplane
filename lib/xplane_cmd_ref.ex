defmodule XPlane.CmdRef do
  @moduledoc """
  Represent an X-Plane Command Reference and provide helper methods
  to load the closest available set of Command References for a given
  X-Plane version.
  
  Note the X-Plane config file these come from is Commands.txt, I've
  named this module CmdRef to mirror DataRef/Data distinction.
  """
  
  defstruct [
    name: "",
    description: "???"]
  @type t :: %XPlane.CmdRef{
               name: String.t,
               description: String.t}
  
  @doc """
  Load the closest list of CmdRefs we have available for the specified X-Plane version.
  
  ## Parameters
  
  - version_number: X-Plane version number as returned by `XPlane.Instance.list/0`
  """
  @spec load_version(integer) :: %{atom: XPlane.CmdRef.t}
  def load_version(version_number) do
    exact = "Commands#{version_number}.txt.gz"
    
    closest = "#{File.cwd!}/commands"
    |> File.ls!
    |> Enum.reverse
    |> Enum.filter(&(&1 <= exact))
    |> Enum.at(0)
    
    {:ok, file} = File.open("#{File.cwd!}/commands/#{closest}", [:read, :compressed])
    
    IO.stream(file, :line)
    |> Enum.map(
      fn(line) ->
        line
        |> String.split(~r{\s+}, parts: 2)
        |> List.to_tuple
      end)
    |> Map.new(
      fn {name, description} ->
        {
          name
          |> String.slice(4..400)
          |> String.replace("/", "_")
          |> String.to_atom,
          %XPlane.CmdRef{
            name: name,
            description: description}
        }
      end)
  end
  
  
  def describe(cmds, pattern) do
    IO.puts("\n")
    cmds
    |> Enum.filter(
      fn {id, _} -> Regex.match?(pattern, Atom.to_string(id)) end)
    |> Enum.sort
    |> Enum.map(
      fn {id, %XPlane.CmdRef{description: d}} ->
        "#{Atom.to_string(id) |> String.pad_trailing(40)} #{d}"
      end)
    |> Enum.join
    |> IO.puts
    IO.puts("\n")
  end

end
