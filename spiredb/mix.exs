defmodule Spiredb.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  defp releases do
    [
      spiredb: [
        applications: [
          spiredb_common: :permanent,
          spiredb_pd: :permanent,
          spiredb_store: :permanent
        ],
        include_executables_for: [:unix],
        steps: [:assemble, :tar],
        # Prevent cookie mismatch: use env var or fixed default
        # All nodes MUST use the same cookie for cluster communication
        cookie: String.to_atom(System.get_env("RELEASE_COOKIE", "spiredb_cluster_cookie"))
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
