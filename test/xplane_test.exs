defmodule XPLANETest do
  use ExUnit.Case, async: false
  
  
  test "At least one instance of X-Plane is visible" do
    {:ok, _pid} = XPlane.Instance.start
    instances = XPlane.Instance.list
    assert length(instances) > 0
    XPlane.Instance.stop
  end
  
  test "load compatible DataRefs" do
    data_refs = XPlane.DataRef.load_version(105000)
    data_refs |> XPlane.DataRef.describe(~r/flightmodel_position_l/)
  end
  
  test "load compatible CmdRefs" do
    cmd_refs = XPlane.CmdRef.load_version(105000)
    cmd_refs |> XPlane.CmdRef.describe(~r/throttle/)
  end
  
  test "Invalid DataRef update requested returns error" do
    XPlane.Instance.start
    [a | _] = XPlane.Instance.list
    a |> XPlane.Data.start
    assert {:error, ["Invalid data reference id: this_is_invalid"]} =
             a |> XPlane.Data.request_updates([this_is_invalid: -1])
    a |> XPlane.Data.stop
    XPlane.Instance.stop
  end
  
  test "Invalid DataRef update rate requested returns error" do
    XPlane.Instance.start
    [a | _] = XPlane.Instance.list
    a |> XPlane.Data.start
    assert {:error,
             ["Invalid frequency -1 for data reference flightmodel_position_longitude"]} =
             a |> XPlane.Data.request_updates(
                    [flightmodel_position_longitude: -1])
    a |> XPlane.Data.stop
    XPlane.Instance.stop
  end
  
  test "Valid DataRef with no updates requested" do
    XPlane.Instance.start
    
    [master] = XPlane.Instance.list
      |> Enum.filter(&(match?(%XPlane.Instance{role: :master}, &1)))
    
    master |> XPlane.Data.start
    assert :ok =
             master |> XPlane.Data.request_updates(
                    [flightmodel_position_longitude: 0])
    master |> XPlane.Data.stop
    XPlane.Instance.stop
  end
  
  test "Valid DataRef with updates requested" do
    XPlane.Instance.start
    
    [master] = XPlane.Instance.list
    |> Enum.filter(&(match?(%XPlane.Instance{role: :master}, &1)))
    
    master |> XPlane.Data.start
    
    assert :ok =
           master
           |> XPlane.Data.request_updates(
            [
              flightmodel_position_longitude: 2,
              flightmodel_position_latitude: 4,
              flightmodel_position_elevation: 8
            ])
           
    data = master
           |> XPlane.Data.latest_updates([
                :flightmodel_position_longitude,
                :flightmodel_position_latitude,
                :flightmodel_position_elevation
              ])
    
    data |> IO.inspect
    assert data |> Map.has_key?(:flightmodel_position_longitude)
    assert data |> Map.has_key?(:flightmodel_position_latitude)
    assert data |> Map.has_key?(:flightmodel_position_elevation)
    
    master
    |> XPlane.Data.request_updates(
         [
           flightmodel_position_longitude: 0,
           flightmodel_position_latitude: 0,
           flightmodel_position_elevation: 0
         ])
    
    master
    |> XPlane.Data.stop
    
    XPlane.Instance.stop
  end

end
