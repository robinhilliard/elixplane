defmodule XPlane.Cmd do
  @moduledoc """
  Send X-Plane commands.
  """
  
  
  @listen_port 59001
  
  
  use GenServer
  
  
  # API
  
  @doc """
  Start GenServer controlling port used to send commands to a specific X-Plane instance.
  
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
  Start GenServer linked to current process controlling port used to send commands
  to a specific X-Plane instance.
  
  ## Parameters
  
  - instance: X-Plane instance from list returned by `XPlane.Instance.list/0`
  """
  @spec start_link(XPlane.Instance.t, list) :: {:ok, pid} | {:error, any} | :ignore
  def start_link(instance, opts \\ []) do
    GenServer.start_link(__MODULE__,
      {:ok, instance},
      [name: name(instance)] ++ opts)
  end
  
  
  @doc """
  Send a command to X-pLane
  
  ## Parameters
  - instance: X-Plane instance from list returned by `XPlane.Instance.list/0`
  - commands: List of command atoms - use `XPlane.CmdRef.describe()` to look
    these up.
    
  ## Example
  ```
  iex> XPlane.Cmd.send(master, [:engines_throttle_up])
  :ok
  ```
  """
  @spec send(XPlane.Instance.t, list(atom)) :: :ok | {:error, list}
  def send(instance, command_ids) do
    case GenServer.call(name(instance), {:send, command_ids}) do
      e = {:error, _} -> e
      r -> r
    end
  end
  
  
  @doc """
  Stop the GenServer controlling the port used to send commands.
  """
  @spec stop(XPlane.Instance.t) :: :ok | {:error, any}
  def stop(instance) do
    GenServer.cast(name(instance), :stop)
  end
  
  
  # GensServer Callbacks
  
  
  @impl true
  def init({:ok, instance}) do
    {:ok, sock} = :gen_udp.open(@listen_port, [:binary, active: false])
    {:ok, {XPlane.CmdRef.load_version(instance.version_number), instance, sock}}
  end
  
  
  @impl true
  def handle_call({:send, command_ids}, _from, state={cmd_refs, instance, sock}) do
    vetted_command_ids = for cmd_id <- command_ids do
      if cmd_refs |> Map.has_key?(cmd_id) do
        {:ok, cmd_refs[cmd_id].name}
      else
        {:error, cmd_id}
      end
    end
    
    errors = vetted_command_ids |> Enum.filter(&(match?({:error, _}, &1)))
    
    if Enum.empty?(errors) do
      for {:ok, name} <- vetted_command_ids do
        :ok = :gen_udp.send(
          sock,
          instance.ip,
          instance.port,
          <<"CMND\0",
            name::binary>>
        )
      end
      {:reply, :ok, state}
      
    else
      {:reply, {:error,
       for {:error, invalid_cmd_id} <- errors do
         "Invalid command id: #{Atom.to_string(invalid_cmd_id)}"
       end
      }, state}
    end
  end
  
  
  @impl true
  def handle_cast(:stop, {_,  _, sock}) do
    :gen_udp.close(sock)
    {:stop, :normal, nil}
  end
  
  
  # Helpers
  
  
  defp name(instance) do
    String.to_atom("#{__MODULE__}_#{instance.addr}")
  end

end
