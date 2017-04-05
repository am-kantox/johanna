# Johanna

[![Johanna Build Status](https://travis-ci.org/am-kantox/johanna.svg?branch=master)](https://travis-ci.org/am-kantox/johanna) ⇒ This project, orchestrating the processes and performing all the routine tasks to keep the environment clean and robust, is named after and dedicated to **Johanna**, to honor the best office manager I ever worked with.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `johanna` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:johanna, "~> 0.1"}]
end
```
Wrapper for [`erlcron`](https://github.com/erlware/erlcron) with some smartness and goodness.

## Using

### Simple `cron`-like behaviour

```elixir
Johanna.at({3, :pm}, fn -> IO.puts "Fridge cleaning time!" end)

Johanna.once(10, fn -> IO.puts "New sushi menu!" end)

Johanna.every(10, fn -> IO.puts("¡Yay!") end)
Johanna.every({10, :sec}, fn -> IO.puts("¡Yay!") end) # same as above
Johanna.every({1, :min}, {IO, :puts, ["¡Yay!"]}) # `apply` notation
Johanna.every({1, :hr}, {:between, {1, :pm}, {4, :pm}}, fn -> IO.puts("¡Siesta!") end)

### Experimental:
ref = Johanna.at {7, :pm}, {IO, :puts, ["Yay"]}
#⇒ #Reference<0.0.5.28>
Johanna.replace ref, {{:daily, {7, :pm}}, {IO, :puts, ["Yay"]}}
#⇒ #Reference<0.0.5.28>
```

### Make the task to retry until succeded

It’s easier to see by example. Here we declare a contrived function, that
fails for 100 seconds approx and then succeeds:

```elixir
defmodule Test do
  @now NaiveDateTime.utc_now

  def test do
    # make it succeed 100 seconds later
    case NaiveDateTime.compare(NaiveDateTime.utc_now, NaiveDateTime.add(@now, 100)) do
      :lt -> {:error, ":-("}
      _ -> {:ok, ":-)"}
    end
  end
end
Johanna.start(nil, nil)
Johanna.Service.care %Johanna.Message{caller: {Test, :test, []}}
Johanna.Service.jobs
#⇒ %{#Reference<0.0.4.45> => %Johanna.Message{attempts: [{%DateTime{calendar: Calendar.ISO,
#      day: 5, hour: 16, microsecond: {799580, 6}, minute: 12, month: 4,
#      second: 28, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0,
#      year: 2017, zone_abbr: "UTC"},
#     %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []},
#      message: ":-("}}], bag: [], caller: {Test, :test, []}, error: nil,
#   message: nil, result: nil,
#   time: %DateTime{calendar: Calendar.ISO, day: 5, hour: 13,
#    microsecond: {245363, 6}, minute: 31, month: 4, second: 26, std_offset: 0,
#    time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#   type: {:retry, 3}}}

# PAUSE FOR ≈60 SECONDS

Johanna.Service.jobs
#⇒ %{#Reference<0.0.4.45> => %Johanna.Message{attempts: [{%DateTime{calendar: Calendar.ISO,
#      day: 5, hour: 16, microsecond: {808563, 6}, minute: 13, month: 4,
#      second: 13, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0,
#      year: 2017, zone_abbr: "UTC"},
#     %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#    {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#      microsecond: {807548, 6}, minute: 12, month: 4, second: 49, std_offset: 0,
#      time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#     %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#    {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#      microsecond: {807267, 6}, minute: 12, month: 4, second: 37, std_offset: 0,
#      time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#     %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#    {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#      microsecond: {800534, 6}, minute: 12, month: 4, second: 31, std_offset: 0,
#      time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#     %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#    {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#      microsecond: {799580, 6}, minute: 12, month: 4, second: 28, std_offset: 0,
#      time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#     %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []},
#      message: ":-("}}], bag: [], caller: {Test, :test, []}, error: nil,
#   message: nil, result: nil,
#   time: %DateTime{calendar: Calendar.ISO, day: 5, hour: 13,
#    microsecond: {245363, 6}, minute: 31, month: 4, second: 26, std_offset: 0,
#    time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#   type: {:retry, 48}}}

# PAUSE FOR ≈100 SECONDS
Johanna.Service.jobs
#⇒ %{}

Johanna.Spy.spy
#⇒ [%Johanna.Message{attempts: [{%DateTime{calendar: Calendar.ISO, day: 5,
#     hour: 16, microsecond: {885986, 6}, minute: 19, month: 4, second: 35,
#     std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017,
#     zone_abbr: "UTC"},
#    %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#   {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#     microsecond: {884950, 6}, minute: 18, month: 4, second: 47, std_offset: 0,
#     time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#    %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#   {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#     microsecond: {883940, 6}, minute: 18, month: 4, second: 23, std_offset: 0,
#     time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#    %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#   {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#     microsecond: {882947, 6}, minute: 18, month: 4, second: 11, std_offset: 0,
#     time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#    %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#   {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#     microsecond: {882001, 6}, minute: 18, month: 4, second: 5, std_offset: 0,
#     time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#    %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}},
#   {%DateTime{calendar: Calendar.ISO, day: 5, hour: 16,
#     microsecond: {881281, 6}, minute: 18, month: 4, second: 2, std_offset: 0,
#     time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#    %Johanna.Service.ExecutedNotOk{caller: {Test, :test, []}, message: ":-("}}],
#  bag: [], caller: {Test, :test, []}, error: nil, message: nil,
#  result: {:ok, ":-)"},
#  time: %DateTime{calendar: Calendar.ISO, day: 5, hour: 13,
#   microsecond: {245363, 6}, minute: 31, month: 4, second: 26, std_offset: 0,
#   time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
#  type: {:retry, 96}}]

```

Upon successful execution, the `Johanna.Message` is being moved to `Johanna.Spy`
store to be reported on demand. Note, that the result `result: {:ok, ":-)"}` is
also stored in `Johanna.Spy` storage.

### Changelog

#### 0.2.0 — added `Johanna.Spy` and `Johanna.Service`


### [Documentation](https://hexdocs.pm/johanna).
