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
```
Currently assumes that X-Plane and Elixir are running on platforms with the same endedness byte order.
