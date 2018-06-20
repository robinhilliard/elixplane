eliXPLANE
======

An X-Plane network interface for Elixir. So far:

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
Currently assumes that X-Plane and Elixir are running on platforms with the same
endian byte order.

I'm working on the DREF module at the moment. This is another GenServer that will
load DREFs relevant to the XPlane version we're connecting to and allow a caller 
to subscribe to updates at a specified frequency or set writeable DREFs. Because
it's easy to mistype a DREF I'll validate DREFs against the file. With this in 
place users should be able to drive XPlane from their own hardware, write
autopilots etc.

Confirmed with X-Plane that it's ok to redistribute the DREF files:

https://forums.x-plane.org/index.php?/forums/topic/151455-redistributing-datarefs-files/