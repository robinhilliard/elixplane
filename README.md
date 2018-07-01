![eliXPLANE logo](elixplane.png)

An X-Plane network client for Elixir [1]. So far you can

- Detect instances of X-Plane/ PlaneMaker running on the local network
- Load the closest available DataRef definitions included with the library [2] 
  for a specific X-Plane version.
- Request a list of DataRefs to be sent to you at specified frequencies

I'm continuing to work on the data module at the moment so that we can set writeable DREFs.
With this in place users should be able to drive X-Plane from their own hardware, write
autopilots etc.

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
  iex> drefs = XPlane.DRef.load_version(105000)
  ...
  iex> drefs |> XPlane.DRef.describe(~r/flightmodel_position_l/)
  
  flightmodel_position_local_ax            The acceleration in local OGL coordinates (mtr/sec2, writable)
  flightmodel_position_latitude            The latitude of the aircraft (degrees)
  ... 
  flightmodel_position_longitude           The longitude of the aircraft (degrees)
  flightmodel_position_local_vx            The velocity in local OGL coordinates (mtr/sec, writable)
  flightmodel_position_local_ay            The acceleration in local OGL coordinates (mtr/sec2, writable)


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
  iex> XPlane.Data.stop(xp)
  :ok
  iex> XPlane.Instance.stop
  :ok
```
1. Currently assumes that X-Plane and Elixir are running on platforms with the same
endian byte order.

2. I confirmed with X-Plane that it's ok to redistribute the DataRef files:
https://forums.x-plane.org/index.php?/forums/topic/151455-redistributing-datarefs-files/