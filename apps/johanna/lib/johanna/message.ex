defmodule Johanna.Message do
  @moduledoc """
  The message struct, `Johanna.Spy` is about to store and bulk-send to the devops.
  """

  @typedoc """
  The message.
  """
  @type t :: %__MODULE__{
    time: DateTime.t,

    caller: {Atom.t, Atom.t, List.t},

    message: String.t,
    error: Exception.t,

    type: {:retry, Integer.t} | :log,

    bag: List.t}

  @fields [
    :time,

    :caller,

    :message,
    :error,

    :type,

    :bag]

  @initial Enum.zip(@fields, [DateTime.utc_now(), {IO, :inspect, []}, nil, nil, :log, []])

  @doc false
  def fields, do: @fields
  defstruct @initial

end
