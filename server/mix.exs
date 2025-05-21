defmodule ChatServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_server,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ChatServer, []}
    ]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"} # Para generar identificadores únicos
    ]
  end
end
