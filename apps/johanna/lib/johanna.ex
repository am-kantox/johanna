defmodule Johanna do
  @moduledoc """
  Simple wrapper for [`erlcron`](https://github.com/erlware/erlcron),
    the library providing testable cron like functionality for Erlang systems,
    with the ability to arbitrarily set the time and place along
    with fastforwarding through tests.

  ## Examples (gracefully copy-pasted from original `README`)

      {{once, {3, 30, pm}},
          {io, fwrite, ["Hello, world!~n"]}}

      {{once, {12, 23, 32}},
          {io, fwrite, ["Hello, world!~n"]}}

      {{once, 3600},
          {io, fwrite, ["Hello, world!~n"]}}

      {{daily, {every, {23, sec}, {between, {3, pm}, {3, 30, pm}}}},
          {io, fwrite, ["Hello, world!~n"]}}

      {{daily, {3, 30, pm}},
          fun() -> io:fwrite("It's three thirty~n") end}

      {{daily, [{1, 10, am}, {1, 07, 30, am}]},
          {io, fwrite, ["Bing~n"]}}

      {{weekly, thu, {2, am}},
          {io, fwrite, ["It's 2 Thursday morning~n"]}}

      {{weekly, wed, {2, am}},
          {fun() -> io:fwrite("It's 2 Wednesday morning~n") end}

      {{weekly, fri, {2, am}},
          {io, fwrite, ["It's 2 Friday morning~n"]}}

      {{monthly, 1, {2, am}},
          {io, fwrite, ["First of the month!~n"]}}

      {{monthly, 4, {2, am}},
          {io, fwrite, ["Fourth of the month!~n"]}}
  """

  @always {:between, {0, :am}, {11, 59, :pm}}

  @doc """
  Runs the given function recurrently at the time given.

  ## Examples

      ▶ Johanna.at({3, :pm}, fn -> IO.puts("¡Yay!") end)
      ▷ ... at 15:00, daily:
      ▷ "¡Yay!"

      ▶ Johanna.at({2, 45, :pm}, {IO, :puts, ["¡Yay!"]})
      ▷ ... at 14:45, daily:
      ▷ "¡Yay!"
  """
  @spec at(:erlcron.cron_time() | :erlcron.seconds() | Time.t, :erlcron.callable()) :: :erlcron.job_ref()
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

  @doc """
  Runs the given function once.

  ## Examples

      ▶ Johanna.once(10, fn -> IO.puts("¡Yay!") end)
      ▷ ... 10 sec pause
      ▷ "¡Yay!"
  """
  @spec once(:erlcron.cron_time() | :erlcron.seconds() | DateTime.t, :erlcron.callable()) :: :erlcron.job_ref()
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

  @doc """
  Runs the given function every `N` units (unit is `:hr`, `:min` or `:sec`).

  ## Examples

      ▶ Johanna.every(10, fn -> IO.puts("¡Yay!") end)
      ▷ ... every 10 secs
      ▷ "¡Yay!"

      ▶ Johanna.every({10, :sec}, fn -> IO.puts("¡Yay!") end)
      ▷ ... every 10 secs
      ▷ "¡Yay!"

      ▶ Johanna.every({1, :min}, {IO, :puts, ["¡Yay!"]})
      ▷ ... every 1 min
      ▷ "¡Yay!"

      ▶ Johanna.every(10, {:between, {1, :pm}, {4, :pm}}, fn -> IO.puts("¡Siesta!") end)
      ▷ ... every 10 secs from 1PM till 4PM
      ▷ "¡Siesta!"
  """
  @spec every(Integer.t | :erlcron.duration(), :erlcron.constraint() | nil, :erlcron.callable()) :: :erlcron.job_ref()
  def every(duration, constraint \\ nil, fun)
  def every(duration, constraint, fun) when is_integer(duration) do
    every({duration, :sec}, constraint, fun)
  end
  def every(duration, constraint, fun) when is_function(fun, 0) do
    cron({{:daily, {:every, duration, constraint || @always}}, fn _, _ -> fun.() end})
  end
  def every(duration, constraint, fun) when is_tuple(fun) do
    cron({{:daily, {:every, duration, constraint || @always}}, fun})
  end

  @doc """
  Runs the given function recurrently.

  ## Examples

      ▶ Johanna.cron({10, :am}, fn -> IO.puts("¡Yay!") end})
      ▷ ... at 10AM daily
      ▷ "¡Yay!"
  """
  @spec cron(:erlcron.job()) :: :erlcron.job_ref()
  def cron(job), do: erl_cron(job)

  @doc """
  Returns the `DateTime` instance, currently set for `erlcron`.

  ## Examples

      ▶ Johanna.datetime()
      ▷ %DateTime{calendar: Calendar.ISO, day: 30, hour: 14, microsecond: {0, 0},
      ▷     minute: 2, month: 3, second: 43, std_offset: 0, time_zone: "Etc/UTC",
      ▷     utc_offset: 0, year: 2017, zone_abbr: "UTC"}
  """
  @spec datetime() :: DateTime.t
  def datetime() do
    with {_, secs} <- erl_datetime(), do: DateTime.from_unix!(secs)
  end

  @doc """
  Sets the `DateTime` instance for `erlcron`. Useful in `Timecop`-like scenarios.
  """
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

  @doc """
  Sets the `DateTime` instance for `erlcron` on many nodes.
  """
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

  @doc """
  Cancels the job, previously started with `at`/`once`.
  """
  @spec cancel!(:erlcron.job_ref()) :: :ok | :undefined
  def cancel!(job_ref) do
    erl_cancel(job_ref)
  end

  @doc """
  Checks whether the job spec is valid.

  ## Examples

      ▶ Johanna.valid?({:once, {3, :pm}})
      ▷ true

      ▶ Johanna.valid?({:daily, {3, :pm}})
      ▷ true

      ▶ Johanna.valid?({3, :pm})
      ▷ false
  """
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
