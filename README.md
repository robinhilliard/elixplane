![eliXPLANE logo](elixplane.png)

An X-Plane network client for Elixir [1]. So far you can

- Detect instances of X-Plane/ PlaneMaker running on the local network
- Load the closest available DataRef and Command definitions (included with the library [2]) for a specific X-Plane version.
- Request a list of DataRefs to be sent to you at specified frequencies
- Write to a writable DataRef
- Send a command to X-Plane

```$elixir
  iex> XPlane.Instance.start
  {:ok, #PID<0.154.0>} 
  iex> [xp] = XPlane.Instance.list
  [
    %XPlane.Instance{
      addr: "192.168.0.22",
      computer_name: "Similitude",
      host: :xplane,
      ip: {192, 168, 0, 22},
      major_version: 1,
      minor_version: 1,
      port: 49000,
      role: :master,
      seconds_since_seen: 1,
      version_number: 105101
    }
  ]
  iex> drefs = XPlane.DataRef.load_version(105000)
  ...
  iex> drefs |> XPlane.DataRef.describe(~r/flightmodel_position_l/)
  
  flightmodel_position_local_ax            The acceleration in local OGL coordinates (mtr/sec2, writable)
  flightmodel_position_latitude            The latitude of the aircraft (degrees)
  ... 
  flightmodel_position_longitude           The longitude of the aircraft (degrees)
  flightmodel_position_local_vx            The velocity in local OGL coordinates (mtr/sec, writable)
  flightmodel_position_local_ay            The acceleration in local OGL coordinates (mtr/sec2, writable)


  :ok
  iex> crefs = XPlane.CmdRef.load_version(105000)
  ...
  iex> crefs |> XPlane.CmdRef.describe(~r/lights/)
  lights_beacon_lights_off                 Beacon lights off.
  lights_beacon_lights_on                  Beacon lights on.
  lights_beacon_lights_toggle              Beacon lights toggle.
  lights_landing_lights_off                Landing lights off.
  lights_landing_lights_on                 Landing lights on.
  lights_landing_lights_toggle             Landing lights toggle.
  ...
  iex> XPlane.Cmd.send(xp, [:lights_landing_lights_toggle])
  :ok
  iex> XPlane.Data.start(xp)
  {:ok, #PID<0.157.0>} 
  iex> XPlane.Data.request_updates(xp, [
  ...> flightmodel_position_elevation: 1,
  ...> flightmodel_position_longitude: 1,
  ...> flightmodel_position_latitude: 1])
  :ok
  iex> XPlane.Data.latest_updates(xp, [
  ...> :flightmodel_position_elevation,
  ...> :flightmodel_position_longitude,
  ...> :flightmodel_position_latitude])
  %{
    flightmodel_position_elevation: 17.584819793701172,
    flightmodel_position_latitude: -31.069093704223633,
    flightmodel_position_longitude: 152.76556396484375
  }
  iex> XPlane.Data.set(xp, [flightmodel_position_local_y: 6000.0])
  :ok
  iex> XPlane.Data.stop(xp)
  :ok
  iex> XPlane.Instance.stop
  :ok
```
1. Currently assumes that X-Plane and Elixir are running on platforms with the same
endian byte order.

2. I confirmed with X-Plane that it's ok to redistribute the DataRef and Command files:
https://forums.x-plane.org/index.php?/forums/topic/151455-redistributing-datarefs-files/