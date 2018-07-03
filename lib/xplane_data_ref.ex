defmodule XPlane.DataRef do
  @moduledoc """
  Represent an X-Plane Data Reference (DataRef) and provide helper methods
  to load the closest available set of DataRefs for a given X-Plane version
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
  @type t :: %XPlane.DataRef{
               name: String.t,
               id: atom,
               code: integer,
               type: XPlane.DataRef.xtype,
               writable: boolean,
               units: String.t,
               description: String.t}
  
  @doc """
  Load the closest list of DataRefs we have available for the specified X-Plane version.
  
  ## Parameters
  
  - version_number: X-Plane version number as returned by `XPlane.Instance.list/0`
  """
  @spec load_version(integer) :: %{atom: XPlane.DataRef.t}
  def load_version(version_number) do
    exact = "DataRefs#{version_number}.txt.gz"
    
    closest = "#{:code.priv_dir(:xplane)}/datarefs"
    |> File.ls!
    |> Enum.reverse
    |> Enum.filter(&(&1 <= exact))
    |> Enum.at(0)
    
    {:ok, file} = File.open("#{:code.priv_dir(:xplane)}/datarefs/#{closest}", [:read, :compressed])
    
    IO.stream(file, :line)
    |> Enum.with_index()
    |> Enum.flat_map(
      fn({line, code}) ->
        parse(line |> String.split("\t"), code)
      end)
    |> Map.new(
      fn  d = %XPlane.DataRef{} ->
        {d.id, d}
      end)
  
  end
  
  
  def describe(data_refs, pattern) do
    IO.puts("\n")
    data_refs
    |> Enum.filter(
      fn {id, _} -> Regex.match?(pattern, Atom.to_string(id)) end)
    |> Enum.sort
    |> Enum.map(
      fn {id, %XPlane.DataRef{description: d, units: u, writable: w}} ->
        wd = if w do ", writable" else "" end
        "#{Atom.to_string(id) |> String.pad_trailing(40)} #{d} (#{u}#{wd})"
      end)
    |> Enum.join("\n")
    |> IO.puts
    IO.puts("\n")
  end
  
  
  def withCode(data_refs, code_to_match) do
    [{_, matching_data_ref} | _] =
      Enum.filter(data_refs,
        fn {_, %XPlane.DataRef{code: code}} ->
          code == code_to_match
        end)
    matching_data_ref
  end
  
  
  @spec parse(list, integer) :: list(XPlane.DataRef.t)
  defp parse([name, type, writable, units, description], code) do
    [%XPlane.DataRef{
      parse([name, type, writable, units], code) |> Enum.at(0)
      | description: binary_part(description, 0, byte_size(description) - 1)
    }]
  end
  
  @spec parse(list, integer) :: list(XPlane.DataRef.t)
  defp parse([name, type, writable, units], code) do
    [%XPlane.DataRef{
      parse([name, type, writable], code) |> Enum.at(0)
      | units: units
    }]
  end
  
  @spec parse(list, integer) :: list(XPlane.DataRef.t)
  defp parse([name, type, writable], code) do
    [%XPlane.DataRef{
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
  
  
  @spec parse_type(String.t) :: XPlane.DataRef.xtype
  defp parse_type(type) do
    [type | dims] = type |> String.split(["[", "]"], trim: true)
    {String.to_atom(type), if Enum.empty?(dims) do [1] else dims |> Enum.map(&(String.to_integer(&1))) end}
  end

end
