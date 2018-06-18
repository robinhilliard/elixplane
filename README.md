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
Currently assumes that X-Plane and Elixir are running on platforms with the same
endian byte order.

I'm working on the DREF module at the moment. This is another GenServer that will
load DREFs relevant to the XPlane version we're connecting to and allow a caller 
to subscribe to updates at a specified frequency or set writeable DREFs. Because
it's easy to mistype a DREF I'll validate DREFs against the file. With this in 
place users should be able to drive XPlane from their own hardware, write
autopilots etc.

I need to confirm with X-Plane that it's ok to redistribute the DREF files from
various X-Plane versions.