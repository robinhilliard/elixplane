![eliXPLANE logo](elixplane.png)

An X-Plane network client for Elixir [1]. So far you can detect instances of X-Plane/
PlaneMaker running on the local network and load closest available DataRef definitions 
included with the library [2] for a specific X-Plane version.

I'm working on the data module at the moment. This is another GenServer that will
allow a caller to subscribe to updates at a specified frequency or set writeable DREFs.
With this in place users should be able to drive X-Plane from their own hardware, write
autopilots etc.

```$elixir
  iex> XPlane.Instance.start
  {:ok, #PID<0.138.0>}
  iex> XPlane.Instance.list
  [
    %XPlane.Instance{
      computer_name: "Starboard",
      host: :xplane,
      ip: {192, 168, 0, 58},
      major_version: 1,
      minor_version: 1,
      port: 49000,
      role: :extern_visual,
      seconds_since_seen: 0,
      version_number: 105101
    }
  ]
  iex> XPlane.Instance.stop
  :ok
  iex> XPlane.DRef.load_version(105101) |> Enum.filter(&(&1.code == 200)) 
  [
    %XPlane.DRef{
      code: 200,
      description: "area each ring of prop",
      name: "sim/aircraft/prop/acf_ringarea",
      type: {:float, [8, 10]},
      units: "???",
      writable: true
    }
  ]
```
1. Currently assumes that X-Plane and Elixir are running on platforms with the same
endian byte order.

2. I Confirmed with X-Plane that it's ok to redistribute the DataRef files:
https://forums.x-plane.org/index.php?/forums/topic/151455-redistributing-datarefs-files/