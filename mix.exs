defmodule DBI.PostgreSQL.Mixfile do
  use Mix.Project

  def project do
    [ app: :exdbi_pgsql,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [applications: ~w(exdbi epgsql)a]
  end

  defp deps do
    [
      {:exdbi,  github: "khia/exdbi"},
      {:epgsql, github: "epgsql/epgsql"},
    ]
  end
end
