defmodule JohannaTest do
  use ExUnit.Case
  # import ExUnit.CaptureIO

  doctest Johanna

  # test "once(0) immediately produces an output" do
  #   assert capture_io(fn ->
  #     Johanna.once(0, fn -> IO.puts("¡Yay!") end)
  #   end) == "¡Yay!\n"
  # end
end
