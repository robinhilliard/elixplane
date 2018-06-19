defmodule XPLANETest do
  use ExUnit.Case
  
  
  test "instance genserver doesn't crash" do
    {:ok, _pid} = XPlane.Instance.start
    IO.inspect XPlane.Instance.list
    XPlane.Instance.stop
  end
  
  test "load compatible drefs doesn't crash" do
    XPlane.DRef.load_version(105000)
  end
  

end
