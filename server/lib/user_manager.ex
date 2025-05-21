defmodule ChatServer.UserManager do
  @moduledoc """
  Gestiona los usuarios conectados al servidor de chat.
  Mantiene un registro de los usuarios y sus sesiones.
  """
  use GenServer
  require Logger

  # API del cliente

  @doc """
  Inicia el proceso de gestión de usuarios.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Registra un nuevo usuario en el sistema.
  Devuelve {:ok, id_usuario} en caso de éxito.
  """
  def register_user(username, pid) do
    GenServer.call(__MODULE__, {:register_user, username, pid})
  end

  @doc """
  Elimina un usuario del sistema.
  """
  def unregister_user(user_id) do
    GenServer.cast(__MODULE__, {:unregister_user, user_id})
  end

  @doc """
  Obtiene la lista de usuarios conectados.
  """
  def get_users do
    GenServer.call(__MODULE__, :get_users)
  end

  @doc """
  Obtiene los datos de un usuario específico.
  """
  def get_user(user_id) do
    GenServer.call(__MODULE__, {:get_user, user_id})
  end

  # Callbacks del servidor

  @impl true
  def init(:ok) do
    Logger.info("Gestor de usuarios iniciado")
    # Inicializamos el estado con un mapa vacío de usuarios
    {:ok, %{users: %{}}}
  end

  @impl true
  def handle_call({:register_user, username, pid}, _from, state) do
    # Verificamos si el nombre de usuario ya está en uso
    if Enum.any?(state.users, fn {_id, user} -> user.username == username end) do
      {:reply, {:error, :username_taken}, state}
    else
      # Generamos un ID único para el usuario
      user_id = UUID.uuid4()

      # Creamos un monitor para detectar si el proceso del cliente termina
      ref = Process.monitor(pid)

      # Creamos la estructura del usuario
      user = %{
        id: user_id,
        username: username,
        pid: pid,
        monitor_ref: ref,
        connected_at: DateTime.utc_now()
      }

      Logger.info("Usuario registrado: #{username} (#{user_id})")

      # Actualizamos el estado con el nuevo usuario
      new_state = %{state | users: Map.put(state.users, user_id, user)}

      {:reply, {:ok, user_id}, new_state}
    end
  end

  @impl true
  def handle_call(:get_users, _from, state) do
    # Convertimos el mapa de usuarios en una lista para la API
    users =
      state.users
      |> Map.values()
      |> Enum.map(fn user ->
        Map.take(user, [:id, :username, :connected_at])
      end)

    {:reply, users, state}
  end

  @impl true
  def handle_call({:get_user, user_id}, _from, state) do
    case Map.get(state.users, user_id) do
      nil -> {:reply, {:error, :user_not_found}, state}
      user -> {:reply, {:ok, user}, state}
    end
  end

  @impl true
  def handle_cast({:unregister_user, user_id}, state) do
    case Map.get(state.users, user_id) do
      nil ->
        {:noreply, state}
      user ->
        # Desmontamos el monitor del proceso
        Process.demonitor(user.monitor_ref)

        Logger.info("Usuario eliminado: #{user.username} (#{user_id})")

        # Actualizamos el estado eliminando al usuario
        new_state = %{state | users: Map.delete(state.users, user_id)}

        # Notificamos a las salas de chat que el usuario se ha desconectado
        ChatServer.ChatRoom.Supervisor.user_disconnected(user_id)

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    # Buscamos el usuario asociado al monitor que se ha caído
    case Enum.find(state.users, fn {_id, user} -> user.monitor_ref == ref end) do
      nil ->
        {:noreply, state}
      {user_id, user} ->
        Logger.info("Cliente desconectado: #{user.username} (#{user_id})")

        # Actualizamos el estado eliminando al usuario
        new_state = %{state | users: Map.delete(state.users, user_id)}

        # Notificamos a las salas de chat que el usuario se ha desconectado
        ChatServer.ChatRoom.Supervisor.user_disconnected(user_id)

        {:noreply, new_state}
    end
  end
end
