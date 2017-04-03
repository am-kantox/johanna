defmodule Mix.Tasks.UnmbrellaHex do
  @shortdoc  "Builds the package for hex.pm from Umbrella project"
  @moduledoc @shortdoc

  @build_dir "_build_hex"

  use Mix.Task

  @doc false
  def run(argv) do
    File.rm_rf!(@build_dir)
    File.mkdir!(@build_dir)
    File.cp_r("apps/johanna/", @build_dir)

    erlcron = Path.join(@build_dir, "src")
    File.mkdir!(erlcron)
    File.cp_r("apps/erlcron/src", erlcron)

    mix_file = Path.join(@build_dir, "mix.exs")
    mix_content = mix_file
                  |> File.read!()
                  |> String.replace(
                      ~r|\[extra_applications: \[:logger, :erlcron\]\]|,
                      "[extra_applications: [:logger], mod: {:ecrn_app, []}]"
                  )
    File.write!(mix_file, mix_content)
    File.cd!(@build_dir, fn -> Mix.Tasks.Hex.Publish.run end)
  end
end
