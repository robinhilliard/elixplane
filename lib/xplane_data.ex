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
    result = GenServer.call(name(instance), {:request_updates, dref_id_freq})
    :timer.sleep(@startup_grace_period)  # Allow time for data to be received
    result
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
  iex> latest_updates(master, [:flightmodel_position_indicated_airspeed])
  %{flightmodel_position_indicated_airspeed: ...}`
  ```
  """
  @spec latest_updates(XPlane.Instance.t, list(atom)) :: %{atom: XPlane.Data.t}
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
    {:ok, {XPlane.DRef.load_version(instance.version_number), %{}, instance}}
  end
  
  
  @impl true
  def handle_call({:request_updates, dref_id_freq}, _from, state={drefs, _, instance}) do
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
    
    errors = code_freq
             |> Enum.filter(&(match?({:error, _}, &1)))
    
    if Enum.empty?(errors) do
      {:ok, sock} = :gen_udp.open(@listen_port, [:binary, active: true])
      for {:ok, freq, code, name} <- code_freq do
        :ok = :gen_udp.send(
          sock,
          instance.ip,
          instance.port,
          <<"RREF\0",
            freq::native-integer-32,
            code::native-integer-32,
            name::binary,
            "\0">>
        )
      end
      :gen_udp.close(sock)
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
  
  
  @impl true
  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end
  
  
  @impl true
  def handle_info({:udp, _sock, sender_ip, _sender,
    <<code::native-integer-32,
      data::binary>>}, {drefs, values, instance}) do
      {
        drefs,
        values |> Map.put(code, data),
        instance
      }
      IO.inspect(code)
  end
  
  
  # Helpers
  
  
  defp name(instance) do
    String.to_atom("#{__MODULE__}_#{instance.addr}")
  end
  
  
  # Access behaviour for XPlane.Data struct
  
  @behaviour Access

  def fetch(%XPlane.Data{type: {:int, [dim]}, value: value}, index)
    when index in 0..(dim - 1) do
    {:ok, 0} # TODO decode int
  end
  
  # TODO other xtypes
  
  def fetch(%XPlane.Data{type: {xtype, [dim | inner_dims]}, value: value}, index)
    when index in 0..(dim - 1) do
  {:ok, %XPlane.Data{type: {xtype, [inner_dims]}, value: value}} # TODO munge value
  end
  
  
  def get(data=%XPlane.Data{type: {_, [dim | _]}, value: _}, index, _)
    when index in 0..(dim - 1) do
    fetch(data, index)
  end
    
  def get(_, _, default) do
    default
  end
  
  # Don't think we want to implement get_and_update() or pop()?
    

  # Enumerable protocol for XPlane.Data struct
  
  
  defimpl Enumerable do
    
    
    def count(%XPlane.Data{type: {:_, [dim | _]}, value: _}) do
      {:ok, dim}
    end
    
    
    def member?(%XPlane.Data{type: {:_, [dim | _]}, value: _}, index) do
      {:ok, index in 0..(dim - 1)}
    end
    
    # TODO alter reduce to work with XPlane.Data
    
    def reduce(_,       {:halt, acc}, _fun),   do: {:halted, acc}
    
    def reduce(list,    {:suspend, acc}, fun), do: {:suspended, acc, &reduce(list, &1, fun)}
    
    def reduce([],      {:cont, acc}, _fun),   do: {:done, acc}
    
    def reduce([h | t], {:cont, acc}, fun),    do: reduce(t, fun.(h, acc), fun)
    
  end
  

end
