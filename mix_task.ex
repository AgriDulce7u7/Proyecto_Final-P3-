defmodule Mix.Tasks.ComnetChat.Start do
  @moduledoc """
  Tarea de Mix para iniciar la aplicación de chat.

  ## Uso

      mix comnet_chat.start

  """
  use Mix.Task

  @shortdoc "Inicia la aplicación de chat de ComNet"
  def run(_) do
    IO.puts("Iniciando aplicación de chat ComNet...")

    # Inicializar aplicación
    Mix.Task.run("app.start")

    # Iniciar sistema principal
    Main.start()
  end
end
