defmodule XPLANETest do
  use ExUnit.Case
  
  
  test "instance genserver doesn't crash" do
    {:ok, _pid} = XPlane.Instance.start
    IO.inspect XPlane.Instance.list
    XPlane.Instance.stop
  end
  

end
