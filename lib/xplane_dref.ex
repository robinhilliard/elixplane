defmodule XPlane.DRef do
  @moduledoc """
  Represent an X-Plane Data Reference (DREF) and provide helper methods
  to load the closest available set of DREFs for a given X-Plane version
  """
  
  
  defstruct [
    name: "",
    code: -1,
    type: :void,
    writable: false,
    units: "???",
    description: "???"
  ]
  
  
  def load_version(version_number) do
    exact = "DataRefs#{version_number}.txt.gz"
    
    closest = "#{File.cwd!}/datarefs"
    |> File.ls!
    |> Enum.reverse
    |> Enum.filter(&(&1 <= exact))
    |> Enum.at(0)
    
    {:ok, file} = File.open("#{File.cwd!}/datarefs/#{closest}", [:read, :compressed])
    
    IO.stream(file, :line)
    |> Enum.with_index()
    |> Enum.flat_map(
      fn({line, code}) ->
        parse(line |> String.split("\t"), code)
      end
    )
  
  end
  
  
  defp parse([name, type, writable, units, description], code) do
    [%XPlane.DRef{
      parse([name, type, writable, units], code) |> Enum.at(0)
      | description: binary_part(description, 0, byte_size(description) - 1)
    }]
  end
  
  defp parse([name, type, writable, units], code) do
    [%XPlane.DRef{
      parse([name, type, writable], code) |> Enum.at(0)
      | units: units
    }]
  end
  
  defp parse([name, type, writable], code) do
    [%XPlane.DRef{
      name: name,
      code: code,
      type: parse_type(type),
      writable: (writable == "y")
    }]
  end
  
  defp parse(_, _) do
    []
  end
  
  
  defp parse_type(type) do
    [type | dims] = type |> String.split(["[", "]"], trim: true)
    {String.to_atom(type), if Enum.empty?(dims) do [1] else dims |> Enum.map(&(String.to_integer(&1))) end}
  end

end
