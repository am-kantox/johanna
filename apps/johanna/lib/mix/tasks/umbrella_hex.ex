defmodule Mix.Tasks.UmbrellaHex do
  @shortdoc  "Builds the package for hex.pm from Umbrella project"
  @moduledoc @shortdoc

  @build_dir "_build_hex"

  use Mix.Task

  @doc false
  def run(_argv) do
    File.rm_rf!(@build_dir)
    File.mkdir!(@build_dir)
    File.cp_r!("apps/johanna/", @build_dir)

    erlcron = Path.join(@build_dir, "src")
    File.mkdir!(erlcron)
    File.cp_r!("apps/erlcron/src", erlcron)
    # File.cd!("apps/erlcron", fn -> System.cmd("make", []) end)
    # File.cp!("apps/erlcron/ebin/erlcron.app", @build_dir <> "/erlcron.app")

    mix_file = Path.join(@build_dir, "mix.exs")
    mix_content = mix_file
                  |> File.read!()
                  |> String.replace(
                      ~r|\[extra_applications: \[:logger, :erlcron\]\]|,
                      "[extra_applications: [:logger], mod: {:ecrn_app, []}]"
                  )
                  |> String.replace(
                      ~r|\s*\w+\:\s*\"\.\.\/\.\.\/.*?\",\s*|,
                      ""
                  )
    File.write!(mix_file, mix_content)

    File.cd!(@build_dir, fn ->
      System.cmd("mix", ["deps.get"]) # Mix.Tasks.Deps.Get.run(argv)
      System.cmd("mix", ["deps.compile"]) # Mix.Tasks.Deps.Compile.run(argv)
      System.cmd("mix", ["compile"]) # Mix.Tasks.Compile.run(argv)
      System.cmd("mix", ["hex.build"]) # Mix.Tasks.Hex.Publish.run(argv)
      IO.puts "Check the errors above; if none, do ⇒ cd #{@build_dir} && mix hex.publish"
    end)
  end
end
