defmodule Johanna.Spy.Test do
  use ExUnit.Case

  doctest Johanna.Spy

  defp push(), do: Johanna.Spy.push! %Johanna.Message{message: "¡Yay!"}
  defp spy_checker(messages) do
    case messages do
      [%Johanna.Message{} = msg | _] -> assert msg.message == "¡Yay!"
      other ->
        IO.inspect(other, label: "Johanna.Spy#checker")
        assert false
    end
  end

  setup do
    spy = Process.whereis Johanna.Spy
    push()
    {:ok, spy: spy}
  end

  describe "Johanna.Spy.vomit/0" do
    test "empties the state" do
      assert Johanna.Spy.spy() != []
      Johanna.Spy.vomit()
      assert Johanna.Spy.spy() == []
    end
  end

  describe "Johanna.Spy.vomit/1" do
    test "calls a callback", %{spy: spy} do
      Process.monitor(spy)
      assert Johanna.Spy.spy() != []
      Johanna.Spy.vomit(fn messages -> spy_checker(messages) end)
      assert Johanna.Spy.spy() == []
      push()
      assert Johanna.Spy.spy() != []
      Johanna.Spy.vomit(&spy_checker(&1))
      assert Johanna.Spy.spy() == []
    end
  end

  describe "Johanna.Spy.spy/0" do
    test "retrieves the messages synchronously" do
      spy_checker Johanna.Spy.spy()
    end
    test "leaves the spy bucket untouched" do
      Johanna.Spy.spy() # should not clean the store up
      spy_checker Johanna.Spy.spy()
    end
  end

  describe "Johanna.Spy.spy/1" do
    test "retrieves the messages synchronously" do
      Johanna.Spy.spy(fn messages -> spy_checker(messages) end)
    end
    test "leaves the spy bucket untouched" do
      Johanna.Spy.spy(fn _ -> :ok end) # should not clean the store up
      spy_checker Johanna.Spy.spy()
    end
  end
end
