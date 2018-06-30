defmodule XPlane.DRef do
  @moduledoc """
  Represent an X-Plane Data Reference (DREF) and provide helper methods
  to load the closest available set of DREFs for a given X-Plane version
  """
  
  @type xtype :: {:byte | :float | :int | :uint | :short | :ushort, list(integer)} | :void
  
  defstruct [
    name: "",
    id: :unknown,
    code: -1,
    type: :void,
    writable: false,
    units: "???",
    description: "???"]
  @type t :: %XPlane.DRef{
               name: String.t,
               id: atom,
               code: integer,
               type: XPlane.DRef.xtype,
               writable: boolean,
               units: String.t,
               description: String.t}
  
  @doc """
  Load the closest list of DataRefs we have available for the specified X-Plane version.
  
  ## Parameters
  
  - version_number: X-Plane version number as returned by `XPlane.Instance.list/0`
  """
  @spec load_version(integer) :: %{atom: XPlane.DRef.t}
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
      end)
    |> Map.new(
      fn  d = %XPlane.DRef{} ->
        {d.id, d}
      end)
  
  end
  
  @spec parse(list, integer) :: list(XPlane.DRef.t)
  defp parse([name, type, writable, units, description], code) do
    [%XPlane.DRef{
      parse([name, type, writable, units], code) |> Enum.at(0)
      | description: binary_part(description, 0, byte_size(description) - 1)
    }]
  end
  
  @spec parse(list, integer) :: list(XPlane.DRef.t)
  defp parse([name, type, writable, units], code) do
    [%XPlane.DRef{
      parse([name, type, writable], code) |> Enum.at(0)
      | units: units
    }]
  end
  
  @spec parse(list, integer) :: list(XPlane.DRef.t)
  defp parse([name, type, writable], code) do
    [%XPlane.DRef{
      name: name,
      id: String.to_atom(name
                         |> String.slice(4..400)
                         |> String.replace("/", "_")),
      code: code,
      type: parse_type(type),
      writable: (writable == "y")
    }]
  end
  
  defp parse(_, _) do
    []
  end
  
  
  @spec parse_type(String.t) :: XPlane.DRef.xtype
  defp parse_type(type) do
    [type | dims] = type |> String.split(["[", "]"], trim: true)
    {String.to_atom(type), if Enum.empty?(dims) do [1] else dims |> Enum.map(&(String.to_integer(&1))) end}
  end

end
