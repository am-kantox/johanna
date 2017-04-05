defmodule Johanna.Service do
  @moduledoc """
  Helpers to provide easy operation with delayed/async tasks.

  ## Examples

  """

  defmodule ExecutedNotOk do
    @moduledoc """
        case my_func.(my_params) do
          :ok -> :ok
          {:error, context} ->
            raise Johanna.Service.ExecutedNotOk, context: %Johanna.Message{message: context, ...}
        end
    """
    defexception [:caller, :message]

    def exception(message: message, caller: caller) do
      message = message || "The attempt to execute [#{inspect(caller)}] resulted in error"
      %Johanna.Service.ExecutedNotOk{caller: caller, message: message}
    end
    def exception(message: message, context: %Johanna.Message{caller: caller} = _context) do
      exception(caller: caller, message: message)
    end

    def throw(%Johanna.Message{caller: caller} = _context, message) do
      raise Johanna.Service.ExecutedNotOk, message: message, caller: caller
    end
  end

  use GenServer

  @retry_period Application.get_env(:johanna, :retry, 3)

  @doc """
  Returns a list of all jobs currently processing.
  """
  @spec jobs() :: :noreply
  def jobs(), do: GenServer.call(__MODULE__, :jobs)

  @doc """
  Places the job into service to be executed.
  """
  @spec care(Message.t) :: :noreply
  def care(%Johanna.Message{} = context), do: GenServer.cast(__MODULE__, {:care, context})

  @doc """
  Re-places the job, identified by a reference, into service to be executed.
  """
  @spec care(reference()) :: :noreply
  def care(ref) when is_reference(ref), do: GenServer.cast(__MODULE__, {:care, ref})

  ##############################################################################
  ## Client API

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc false
  def stop(server), do: GenServer.call(server, :stop)

  ##############################################################################
  ## Server Callbacks

  @doc false
  def handle_call(:jobs, _from, state), do: {:reply, state, state}

  @doc false
  def handle_call(:stop, _from, state), do: {:stop, :normal, :ok, state}

  ##############################################################################

  @doc false
  def handle_cast({:care, %Johanna.Message{} = context}, state) do
    ref = :erlang.make_ref()
    {:noreply, retry!(ref, Map.put(state, ref, context))}
  end

  @doc false
  def handle_cast({:care, ref}, state) when is_reference(ref) do
    {:noreply, retry!(ref, state)}
  end

  ##############################################################################

  defp retry!(reference, state) do
    context = Map.get(state, reference)
    try do
      {mod, fun, params} = context.caller
      case apply(mod, fun, params) do
        {:err, error} ->
          Johanna.Service.ExecutedNotOk.throw(context, error)
        {:error, error} ->
          Johanna.Service.ExecutedNotOk.throw(context, error)
        {:errors, error} ->
          Johanna.Service.ExecutedNotOk.throw(context, error)
        result -> %Johanna.Message{context | result: result}
      end
    rescue
      e ->
        next_try = case context.type do
                    {:retry, 0} -> 1
                    {:retry, n} -> n * 2
                    _ -> @retry_period
                   end
        updated = %Johanna.Message{context |
          attempts: [{DateTime.utc_now, e} | context.attempts],
          type: {:retry, next_try}}
        Johanna.once(next_try, {Johanna.Service, :care, [reference]})
        Map.update!(state, reference, fn _ -> updated end)
#    catch
#      value -> IO.puts "caught #{value}"
    else
      result ->
        Johanna.Spy.push(result)
        Map.delete(state, reference)
#    after
#      IO.puts "This is printed regardless if it failed or succeed"
    end
  end
end
