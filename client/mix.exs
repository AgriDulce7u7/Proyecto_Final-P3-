defmodule ChatClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_client,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ChatClient, []}
    ]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"} # Para manejar identificadores únicos
    ]
  end
end
