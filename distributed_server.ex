defmodule DistributedServer do
  @moduledoc """
  Módulo para gestionar múltiples servidores de chat en una red distribuida.
  Permite escalar horizontalmente el sistema de chat.
  """

  # Registro donde guardar información de servidores
  @registry_name :distributed_chat_registry

  @doc """
  Inicia el módulo de servidor distribuido.
  """
  def start do
    # Crear un registro para mantener información sobre los servidores
    {:ok, _} = Registry.start_link(keys: :unique, name: @registry_name)
    :ok
  end

  @doc """
  Inicia un nuevo servidor de chat con un nombre específico.
  """
  def start_server(server_name) do
    # Convertir nombre a átomo
    name = String.to_atom("chat_server_#{server_name}")

    # Iniciar supervisor y servidor
    {:ok, sup_pid} = ChatSupervisor.start_link()

    # Registrar el servidor con su nombre
    Registry.register(@registry_name, server_name, sup_pid)

    {:ok, name}
  end

  @doc """
  Encuentra un servidor por su nombre.
  """
  def find_server(server_name) do
    case Registry.lookup(@registry_name, server_name) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Lista todos los servidores disponibles.
  """
  def list_servers do
    @registry_name
    |> Registry.select([{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """
  Distribuye la carga entre los servidores disponibles.
  Devuelve el servidor con menos carga.
  """
  def get_least_loaded_server do
    # Obtener todos los servidores
    servers = list_servers()

    # Si no hay servidores, devolver error
    if servers == [] do
      {:error, :no_servers}
    else
      # Algoritmo simple: elegir un servidor aleatorio
      # En una implementación real, se podría comprobar la carga actual
      server = servers |> Enum.random()
      {:ok, server}
    end
  end

  @doc """
  Replica un mensaje a todos los servidores conectados.
  """
  def broadcast_message(message) do
    servers = list_servers()

    # Enviar mensaje a todos los servidores
    Enum.each(servers, fn server_name ->
      with {:ok, pid} <- find_server(server_name) do
        send(pid, {:broadcast, message})
      end
    end)

    :ok
  end

  @doc """
  Sincroniza el estado entre servidores.
  """
  def sync_state(source_server, target_server) do
    with {:ok, source_pid} <- find_server(source_server),
         {:ok, target_pid} <- find_server(target_server) do

      # En una implementación real, aquí se transferiría el estado
      # de un servidor a otro para sincronizarlos

      # Ejemplo simplificado: enviar mensaje de sincronización
      send(target_pid, {:sync_from, source_pid})
      :ok
    else
      _ -> {:error, :server_not_found}
    end
  end

  @doc """
  Monitoriza la salud de los servidores y realiza failover si es necesario.
  """
  def monitor_servers do
    # Iniciar proceso de monitoreo
    spawn(fn ->
      monitor_loop()
    end)
  end

  # Bucle de monitoreo
  defp monitor_loop do
    # Comprobar todos los servidores
    list_servers()
    |> Enum.each(fn server_name ->
      case find_server(server_name) do
        {:ok, pid} ->
          # Comprobar si el servidor responde
          if not Process.alive?(pid) do
            # Log del fallo
            IO.puts("Servidor #{server_name} no responde, iniciando failover...")

            # Reiniciar servidor
            start_server(server_name)
          end
        _ ->
          :ok
      end
    end)

    # Esperar antes de la siguiente comprobación
    Process.sleep(5000)
    monitor_loop()
  end
end
