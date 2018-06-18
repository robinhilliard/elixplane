defmodule XPLANETest do
  use ExUnit.Case
  
  
  test "instance genserver doesn't crash" do
    {:ok, _pid} = XPlane.Instance.start
    IO.inspect XPlane.Instance.list
    XPlane.Instance.stop
  end
  
  test "load compatible drefs" do
    XPlane.DRef.load_compatible_drefs(105000)
  end
  

end
