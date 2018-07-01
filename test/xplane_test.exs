defmodule XPLANETest do
  use ExUnit.Case, async: false
  
  
  test "instance genserver doesn't crash" do
    {:ok, _pid} = XPlane.Instance.start
    IO.inspect XPlane.Instance.list
    XPlane.Instance.stop
  end
  
  test "load compatible drefs doesn't crash" do
    XPlane.DRef.load_version(105000)
  end
  
  test "Invalid dref update requested" do
    XPlane.Instance.start
    [a | _] = XPlane.Instance.list
    a |> XPlane.Data.start
    assert {:error, ["Invalid data reference id: this_is_invalid"]} =
             a |> XPlane.Data.request_updates([this_is_invalid: -1])
    a |> XPlane.Data.stop
    XPlane.Instance.stop
  end
  
  test "Invalid dref update rate requested" do
    XPlane.Instance.start
    [a | _] = XPlane.Instance.list
    a |> XPlane.Data.start
    assert {:error,
             ["Invalid frequency -1 for data reference flightmodel_position_indicated_airspeed"]} =
             a |> XPlane.Data.request_updates(
                    [flightmodel_position_indicated_airspeed: -1])
    a |> XPlane.Data.stop
    XPlane.Instance.stop
  end
  
  test "Valid dref update requested" do
    XPlane.Instance.start
    
    [master] = XPlane.Instance.list
      |> Enum.filter(&(match?(%XPlane.Instance{role: :master}, &1)))
    
    master |> XPlane.Data.start
    assert :ok =
             master |> XPlane.Data.request_updates(
                    [flightmodel_position_indicated_airspeed: 1])
    master |> XPlane.Data.stop
    XPlane.Instance.stop
  end

end
