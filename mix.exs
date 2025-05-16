defmodule ComnetChat.MixProject do
  use Mix.Project

  def project do
    [
      app: :comnet_chat,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuración de la aplicación
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {ComnetChat.Application, []}
    ]
  end

  # Dependencias
  defp deps do
    [
      {:jason, "~> 1.2"}  # Para manejo de JSON
    ]
  end
end
