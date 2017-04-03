defmodule Johanna do
  @moduledoc """
  Simple wrapper for [`erlcron`](https://github.com/erlware/erlcron),
    the library providing testable cron like functionality for Erlang systems,
    with the ability to arbitrarily set the time and place along
    with fastforwarding through tests.
  """

  @doc """
  Runs the given function once.

  ## Examples

      ▶ Johanna.once(10, fn -> IO.puts("¡Yay!") end)
      ▷ ... 10 sec pause
      ▷ "¡Yay!"

      ▶ Johanna.datetime()
      ▷ %DateTime{calendar: Calendar.ISO, day: 30, hour: 14, microsecond: {0, 0},
      ▷     minute: 2, month: 3, second: 43, std_offset: 0, time_zone: "Etc/UTC",
      ▷     utc_offset: 0, year: 2017, zone_abbr: "UTC"}

  """

  @spec at(:erlcron.cron_time() | :erlcron.seconds() | Time.t, fun) :: :erlcron.job_ref()
  def at(%Time{} = time, fun) when is_function(fun, 0) do
    time
    |> Time.to_erl()
    |> at(fun)
  end
  def at(time, fun) when is_function(fun, 0) do
    erl_at(time, fn _, _ -> fun.() end)
  end
  def at(time, fun) when is_tuple(fun) do
    erl_at(time, fun)
  end

  @spec once(:erlcron.cron_time() | :erlcron.seconds() | DateTime.t, fun) :: :erlcron.job_ref()
  def once(%DateTime{} = time, fun) when is_function(fun, 0) do
    now = DateTime.to_unix(DateTime.utc_now)
    then = DateTime.to_unix(time)
    once(then - now, fun)
  end
  def once(time, fun) when is_function(fun, 0) do
    erl_once(time, fn _, _ -> fun.() end)
  end
  def once(time, fun) when is_tuple(fun) do
    erl_once(time, fun)
  end

  @spec datetime() :: DateTime.t
  def datetime() do
    with {_, secs} <- erl_datetime(), do: DateTime.from_unix!(secs)
  end

  @spec datetime!(DateTime.t | NaiveDateTime.t) :: :ok
  def datetime!(%NaiveDateTime{} = time) do
    time
    |> NaiveDateTime.to_erl()
    |> erl_set_datetime()
  end
  def datetime!(%DateTime{} = time) do
    time
    |> DateTime.to_naive
    |> datetime!()
  end

  @spec datetimes!(DateTime.t | NaiveDateTime.t) :: :ok
  def datetimes!(%NaiveDateTime{} = time) do
    time
    |> NaiveDateTime.to_erl()
    |> erl_multi_set_datetime()
  end
  def datetimes!(%DateTime{} = time) do
    time
    |> DateTime.to_naive
    |> datetimes!()
  end

  @spec datetimes!([node()], DateTime.t | NaiveDateTime.t) :: :ok
  def datetimes!(nodes, %NaiveDateTime{} = time) when is_list(nodes) do
    erl_multi_set_datetime(nodes, NaiveDateTime.to_erl(time))
  end
  def datetimes!(nodes, %DateTime{} = time) when is_list(nodes) do
    datetimes!(nodes, DateTime.to_naive(time))
  end

  @spec cancel!(:erlcron.job_ref()) :: :ok | :undefined
  def cancel!(job_ref) do
    erl_cancel(job_ref)
  end

  @spec valid?(:erlcron.run_when()) :: :valid | :invalid
  def valid?(spec) do
    erl_validate(spec)
  end

  ##############################################################################
  ##### wrapped erlang
  ##############################################################################

  Enum.each(~w|datetime|a, fn fun ->
    defp unquote(:"erl_#{fun}")() do
      apply(:erlcron, unquote(fun), [])
    end
  end)

  Enum.each(~w|validate cron cancel set_datetime multi_set_datetime|a, fn fun ->
    defp unquote(:"erl_#{fun}")(param) do
      apply(:erlcron, unquote(fun), [param])
    end
  end)

  Enum.each(~w|at once multi_set_datetime|a, fn fun ->
    defp unquote(:"erl_#{fun}")(param1, param2) do
      apply(:erlcron, unquote(fun), [param1, param2])
    end
  end)
end
