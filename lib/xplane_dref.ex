defmodule XPlane.DRef do
  @moduledoc """
  Get and set X-Plane data references.
  """
  
  
  use GenServer
  
  
  # API
  
  
  def start(instance, opts \\ []) do
    GenServer.start(__MODULE__,
      :ok,
      [name: name(instance) ++ opts])
  end
  
  
  def request(instance, dref_freq) do
    GenServer.cast(name(instance), {:request, dref_freq})
  end

  
  def get(instance, dref_list) do
    GenServer.call(name(instance), {:get, dref_list})
  end
  
  
  def stop(instance) do
    GenServer.cast(name(instance), :stop)
  end
  
  
  # GensServer callbacks
  
  
  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end
  
  
  # Helpers
  
  
  defp name(instance) do
    "#{__MODULE__}_#{instance.addr}"
  end
  
  
  

end
