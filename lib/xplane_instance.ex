defmodule XPlane.Instance do
  @moduledoc """
  Represent a running instance of X-Plane and provide a GenServer to monitor
  the local network for X-Plane multicast "beacon" messages and return them
  as a list.
  
  ## Example
  ```
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
  """
  
  
  defstruct [
    :ip,                  # IP Address of X-Plane instance
    :major_version,       # 1 at the time of X-Plane 10.40
    :minor_version,       # 1 at the time of X-Plane 10.40
    :version_number,      # 104103 for X-Plane 10.41r3
    :host,                # :xplane | :planemaker
    :role,                # :master | :extern_visual | :ios
    :port,                # Port number X-Plane is listening on, 49000 by default
    :computer_name,       # Hostname of the computer
    :seconds_since_seen]  # Time since last beacon multicast received in seconds


  @beacon_addr {239, 255, 1, 1}
  @beacon_port 49707
  @zeros_addr {0, 0, 0, 0}
  @startup_grace_period 2000


  use GenServer


  # API


  def start(opts \\ []) do
    result = GenServer.start(__MODULE__, :ok, [name: __MODULE__] ++ opts)
    :timer.sleep(@startup_grace_period) # Allow time for beacons to be picked up
    result
  end


  def list() do
    now = :erlang.system_time(:second)
    Enum.map(
      GenServer.call(__MODULE__, :list) |> Map.to_list,
      fn {ip, {major_version, minor_version, host, version_number,
        role, port, computer_name, last_seen}} ->
      
        %XPlane.Instance{
          ip: ip,
          major_version: major_version,
          minor_version: minor_version,
          version_number: version_number,
          host: [nil, :xplane, :planemaker] |> Enum.at(host),
          role: [nil, :master, :extern_visual, :ios] |> Enum.at(role),
          port: port,
          computer_name: binary_part(computer_name, 0, byte_size(computer_name) - 1),
          seconds_since_seen: now - last_seen
        }
      end
    )
    
    
  end


  def stop() do
    GenServer.cast(__MODULE__, :stop)
  end


  # GenServer callbacks


  def init(:ok) do
    udp_options = [
      :binary,
      active: true,
      add_membership: {@beacon_addr, @zeros_addr},
      multicast_if: @zeros_addr,
      multicast_loop: false,
      multicast_ttl: 4,
      reuseaddr: true
    ]

    {:ok, _sock} = :gen_udp.open(@beacon_port, udp_options)

    {:ok, %{}}
  end


  def handle_info({:udp, _sock, sender_ip, _sender,
    <<"BECN\0",
      major_version::unsigned,
      minor_version::unsigned,
      host::native-integer-32,
      version_number::native-integer-32,
      role::unsigned-native-32,
      port::unsigned-native-16,
      computer_name::binary>>}, state) do

    {
      :noreply,
      state
      |> Map.put(
          sender_ip, {
            major_version,
            minor_version,
            host,
            version_number,
            role,
            port,
            computer_name,
            :erlang.system_time(:second)
          }
      )
    }
  end


  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end
  

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end


end
