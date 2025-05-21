defmodule ChatServer do
  @moduledoc """
  Módulo principal del servidor de chat.
  Gestiona el inicio de la aplicación y coordina los diferentes componentes.
  """
  use Application
  require Logger

  @doc """
  Función de inicio de la aplicación del servidor.
  Configura y arranca los procesos necesarios.
  """
  def start(_type, _args) do
    # Configuramos el nodo para distribución si aún no está configurado
    unless Node.alive?() do
      # Si el nombre de nodo no está configurado, usamos uno por defecto
      node_name = :"server@#{get_local_ip()}"
      Node.start(node_name)
      Node.set_cookie(:chat_cookie) # Cookie para autenticación entre nodos
    end

    Logger.info("Servidor de chat iniciado en #{Node.self()}")
    Logger.info("Esperando conexiones...")

    # Iniciamos los componentes del servidor
    children = [
      # Supervisor para los procesos del servidor
      {ChatServer.UserManager, []},
      {ChatServer.MessageStore, []},
      {ChatServer.ChatRoom.Supervisor, []}
    ]

    # Configuración de la estrategia de supervisión
    opts = [strategy: :one_for_one, name: ChatServer.Supervisor]

    # Iniciamos el supervisor con los procesos hijos
    Supervisor.start_link(children, opts)
  end

  @doc """
  Obtiene la dirección IP local para configurar el nombre del nodo.
  """
  defp get_local_ip do
    # Por defecto, usamos localhost
    "127.0.0.1"
  end

  @doc """
  Inicia el servidor en modo interactivo.
  """
  def main do
    # Configuración de la distribución
    unless Node.alive?() do
      {ip, _} = System.cmd("hostname", ["-I"])
      ip = String.trim(ip)
      node_name = :"server@#{ip}"
      Node.start(node_name)
      Node.set_cookie(:chat_cookie)
    end

    Logger.info("Servidor de chat iniciado en #{Node.self()}")
    Logger.info("Esperando conexiones...")

    # Configuramos los procesos del servidor si no están en ejecución
    unless Process.whereis(ChatServer.Supervisor) do
      start(:normal, [])
    end

    # Mantenemos el proceso vivo
    Process.sleep(:infinity)
  end
end
