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
  
  
  def load_compatible_drefs(version_number) do
    exact = "DataRefs#{version_number}.txt"
    
    closest = "#{File.cwd!}/datarefs"
    |> File.ls!
    |> Enum.reverse
    |> Enum.filter(&(&1 <= exact))
    |> Enum.at(0)
    
    {:ok, file} = File.open("#{File.cwd!}/datarefs/#{closest}", [:read])
    
    for line <- IO.stream(file, :line) do
      IO.inspect (line |> String.split("\t")) # TODO up to here
    end
  
  end

end
