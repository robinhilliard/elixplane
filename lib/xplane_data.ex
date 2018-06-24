defmodule XPlane.Data do
  @moduledoc """
  Get and set X-Plane data references.
  """
  
  defstruct [
    instance: nil,
    next_code: 0, # Next unique code number
    values: %{},  # Just the raw message, do lazy decoding
    drefs: %{}    # map dref strings to codes
  ]
  
  
  @startup_grace_period 1000
  
  
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
  Values can then be retrieved using `XPlane.Data.get_latest_updates/2`. A small
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
  @spec request_updates(XPlane.Instance.t, list({atom, integer}))
  def request_updates(instance, dref_id_freq) do
    GenServer.cast(name(instance), {:request_updates, dref_id_freq})
    :timer.sleep(@startup_grace_period)  # Allow time for data ref values to be received
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
  @spec stop() :: :ok | {:error, any}
  def stop(instance) do
    GenServer.cast(name(instance), :stop)
  end
  
  
  # GensServer Callbacks
  
  
  def init({:ok, instance}) do
    {:ok, XPlane.DRef.load_version(instance.version_number)}
  end
  
  
  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end
  
  
  # Helpers
  
  
  defp name(instance) do
    "#{__MODULE__}_#{instance.addr}"
  end
  

end
