defmodule Johanna.Spy do
  @moduledoc """
  The `GenServer` that holds all the messages to be bulk-send to the devops.

  ## Examples

  """

  use GenServer

  @doc """
  Bulk-sends the accumulated messages to devops and cleans up the cache.
  """
  @spec vomit :: :noreply
  def vomit(), do: GenServer.cast(__MODULE__, :vomit)

  @doc """
  Calls the given function back and cleans up the cache of messages.
  """
  @spec vomit(Function.t) :: :noreply
  def vomit(fun) when is_function(fun, 1), do: GenServer.cast(__MODULE__, {:vomit, fun})

  @doc """
  Retrieves the list of messages.
  """
  @spec spy() :: List.t
  def spy(), do: GenServer.call(__MODULE__, :spy)

  @doc """
  Calls the given function back with the list of messages as a parameter.
  """
  @spec spy(Function.t) :: List.t
  def spy(fun) when is_function(fun, 1), do: GenServer.cast(__MODULE__, {:spy, fun})

  @doc """
  Stores the message in the pool.
  """
  @spec push(Johanna.Message.t) :: :noreply
  def push(%Johanna.Message{} = message), do: GenServer.cast(__MODULE__, {:push, message})

  @doc """
  Stores the message in the pool synchronously.
  """
  @spec push!(Johanna.Message.t) :: :noreply
  def push!(%Johanna.Message{} = message), do: GenServer.call(__MODULE__, {:push, message})

  ##############################################################################
  ## Client API

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def stop(server), do: GenServer.call(server, :stop)

  ##############################################################################
  ## Server Callbacks

  @doc false
  def handle_call(:spy, _from, state), do: {:reply, state, state}

  @doc false
  def handle_call(:stop, _from, state), do: {:stop, :normal, :ok, state}

  @doc false
  def handle_call({:push, message}, _from, state) do
    state = [message | state]
    {:reply, state, state}
  end

  ##############################################################################

  @doc false
  def handle_cast(:vomit, state) do
    case Johanna.vomit[:to] do
      {mod, fun} -> apply(mod, fun, [state]) # FIXME catch/rescue
      _ -> :noop
    end
    {:noreply, []}
  end

  @doc false
  def handle_cast({:vomit, fun}, state) do
    fun.(state)
    {:noreply, []}
  end

  @doc false
  def handle_cast({:spy, fun}, state) do
    spawn(fn -> fun.(state) end)
    {:noreply, state}
  end

  @doc false
  def handle_cast({:push, message}, state) do
    {:noreply, [message | state]}
  end
end
