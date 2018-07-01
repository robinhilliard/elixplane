defmodule XPlane.Data do
  @moduledoc """
  Get and set X-Plane data.
  """
  
  defstruct [:type, :value]
  @type t :: %XPlane.Data{
              type: XPlane.DRef.xtype,
              value: binary}
  
  
  @startup_grace_period 2000
  @listen_port 59000
  
  
  use GenServer
  
  
  # API
  
  @doc """
  Start GenServer to exchange data references with a specific X-Plane
  instance.
  
  ## Parameters
  
  - instance: X-Plane instance from list returned by `XPlane.Instance.list/0`
  """
  @spec start(XPlane.Instance.t, list) :: {:ok, pid} | {:error, any} | :ignore
  def start(instance, opts \\ []) do
    GenServer.start(__MODULE__,
      {:ok, instance},
      [name: name(instance)] ++ opts)
  end
  
  
  @doc """
  Request updates of the specified data references at the corresponding frequency.
  Values can then be retrieved using `XPlane.Data.latest_updates/2`. A small
  delay occurs during the call to give the GenServer a chance to collect at least
  one value for each requested data reference.
  
  ## Parameters
  - instance: X-Plane instance from list returned by `XPlane.Instance.list/0`
  - dref_id_freq: Keyword list of data reference ids and integer updates
    per second
    
  ## Example
  ```
  iex> request_updates(master, [flightmodel_position_indicated_airspeed: 10])
  :ok
  ```
  """
  @spec request_updates(XPlane.Instance.t, list({atom, integer})) :: :ok | {:error, list}
  def request_updates(instance, dref_id_freq) do
    case GenServer.call(name(instance), {:request_updates, dref_id_freq}) do
      e = {:error, _} ->
        e
      r ->
        :timer.sleep(@startup_grace_period)  # Allow time for data to be received
        r
    end
  end

  
  @doc """
  Request latest values of the listed data reference ids. Values will not be
  available until you have called `XPlane.Data.request_updates/2`. If you request
  a data reference that we have not received a value for, an:
  
  ```
  {:error, {no_values, [list of requested data reference ids missing values]}}`
  ```
  
  message is returned. This seemed to be more a more useful way to handle missing
  values, because most clients will need all the requested values to do their work.
  
  ## Parameters
  - instance: X-Plane instance from list returned by `XPlane.Instance.list/0`
  - dref_ids:  List of data reference ids to return values for
    
  ## Example
  ```
  iex> master |> latest_updates([:flightmodel_position_elevation])
  %{flightmodel_position_elevation: ...}`
  ```
  """
  @spec latest_updates(XPlane.Instance.t, list(atom)) :: %{atom: float | nil}
  def latest_updates(instance, dref_id_list) do
    GenServer.call(name(instance), {:latest_updates, dref_id_list})
  end
  
  
  @doc """
  Stop the GenServer listening for data reference updates, and tell X-Plane to
  stop sending any we are currently subscribed to.
  """
  @spec stop(XPlane.Instance.t) :: :ok | {:error, any}
  def stop(instance) do
    GenServer.cast(name(instance), :stop)
  end
  
  
  # GensServer Callbacks
  
  
  @impl true
  def init({:ok, instance}) do
    {:ok, sock} = :gen_udp.open(@listen_port, [:binary, active: true])
    {:ok, {XPlane.DRef.load_version(instance.version_number), %{}, instance, sock}}
  end
  
  
  @impl true
  def handle_call({:request_updates, dref_id_freq}, _from, state={drefs, _, instance, sock}) do
    code_freq = for {dref_id, freq} <- dref_id_freq do
      if drefs |> Map.has_key?(dref_id) do
        if is_integer(freq) and freq in 0..400 do
          {:ok, freq, drefs[dref_id].code, drefs[dref_id].name}
        else
          {:error, {:freq, dref_id, freq}}
        end
      else
        {:error, {:dref_id, dref_id, freq}}
      end
    end
    
    errors = code_freq |> Enum.filter(&(match?({:error, _}, &1)))
    
    if Enum.empty?(errors) do
      for {:ok, freq, code, name} <- code_freq do
        padded_name = pad_with_trailing_zeros(name, 400)
        :ok = :gen_udp.send(
          sock,
          instance.ip,
          instance.port,
          <<"RREF\0",
            freq::native-integer-32,
            code::native-integer-32,
            padded_name::binary>>
        )
      end
      {:reply, :ok, state}
      
    else
      {:reply, {:error,
       for {_, {kind, dref_id, freq}} <- errors do
         case kind do
          :freq ->
            "Invalid frequency #{freq} for data reference #{dref_id}"
          :dref_id ->
            "Invalid data reference id: #{Atom.to_string(dref_id)}"
         end
       end
      }, state}
    end
  end
  
  def handle_call({:latest_updates, dref_ids}, _from, state={drefs, code_data, instance, sock}) do
    
    data = for dref_id <- dref_ids do
      {dref_id, if Map.has_key?(drefs, dref_id) do  code_data |> Map.get(drefs[dref_id].code, nil) else nil end}
    end |> Map.new
    {:reply, data, state}
  end
  
  
  @impl true
  def handle_cast(:stop, state={_, _, _, sock}) do
    # TODO send zero frequencies to X-Plane
    sock |> :gen_udp.close
    {:stop, :normal, state}
  end
  
  
  @impl true
  def handle_info({:udp, _sock, _ip, _port,
    <<"RREF",
      #  "O" for X-Plane 10
      #  "," for X-Plane 11
      #  neither match documentation...
      _::size(8),
      tail::binary>>},
    {drefs, code_data, instance, sock}) do
      {:noreply,
        {
          drefs,
          unpack_xdata(code_data, tail),
          instance,
          sock
        }
      }
  end
  
  def handle_info(msg, state) do
    IO.inspect({:unexpected_msg, msg})
    {:noreply, state}
  end
  
  
  # Helpers
  
  defp unpack_xdata(code_data, <<>>) do
    code_data
  end

  defp unpack_xdata(code_data, <<code::native-integer-32, data::native-float-32, tail::binary>>) do
    unpack_xdata(code_data |> Map.put(code, data), tail)
  end
  
  
  defp name(instance) do
    String.to_atom("#{__MODULE__}_#{instance.addr}")
  end
  
  
  defp pad_with_trailing_zeros(bin, len) do
    pad_len = 8 * (len - byte_size(bin))
    <<bin::binary, 0::size(pad_len)>>
  end

end
