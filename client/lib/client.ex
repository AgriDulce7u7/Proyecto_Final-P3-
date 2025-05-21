defmodule ChatClient do
  @moduledoc """
  Módulo principal del cliente de chat.
  Gestiona la conexión con el servidor y el procesamiento de mensajes.
  """
  use Application
  use GenServer
  require Logger

  # API de la aplicación

  @doc """
  Inicia la aplicación del cliente.
  """
  def start(_type, _args) do
    children = [
      # El cliente en sí mismo
      {__MODULE__, []}
    ]

    opts = [strategy: :one_for_one, name: ChatClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Inicia el proceso principal del cliente.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Conecta con un servidor de chat remoto.
  Se debe proporcionar el nombre completo del nodo, por ejemplo: server@192.168.1.100
  """
  def connect(server_node) do
    GenServer.call(__MODULE__, {:connect, server_node})
  end

  @doc """
  Inicia sesión en el servidor con un nombre de usuario.
  """
  def login(username) do
    GenServer.call(__MODULE__, {:login, username})
  end

  @doc """
  Cierra la sesión en el servidor.
  """
  def logout do
    GenServer.call(__MODULE__, :logout)
  end

  @doc """
  Lista los usuarios conectados al servidor.
  """
  def list_users do
    GenServer.call(__MODULE__, :list_users)
  end

  @doc """
  Lista las salas de chat disponibles en el servidor.
  """
  def list_rooms do
    GenServer.call(__MODULE__, :list_rooms)
  end

  @doc """
  Crea una nueva sala de chat.
  """
  def create_room(name) do
    GenServer.call(__MODULE__, {:create_room, name})
  end

  @doc """
  Se une a una sala de chat existente.
  """
  def join_room(name) do
    GenServer.call(__MODULE__, {:join_room, name})
  end

  @doc """
  Abandona la sala de chat actual.
  """
  def leave_room do
    GenServer.call(__MODULE__, :leave_room)
  end

  @doc """
  Envía un mensaje a la sala de chat actual.
  """
  def send_message(content) do
    GenServer.cast(__MODULE__, {:send_message, content})
  end

  @doc """
  Obtiene el historial de mensajes de la sala actual.
  """
  def get_history do
    GenServer.call(__MODULE__, :get_history)
  end

  @doc """
  Obtiene los participantes de la sala actual.
  """
  def get_participants do
    GenServer.call(__MODULE__, :get_participants)
  end

  # Callbacks del servidor

  @impl true
  def init(:ok) do
    # Configuramos el nodo para distribución si aún no está configurado
    unless Node.alive?() do
      # Si el nombre de nodo no está configurado, usamos uno por defecto
      node_name = :"client@#{get_local_ip()}"
      Node.start(node_name)
      Node.set_cookie(:chat_cookie) # Misma cookie que el servidor
    end

    Logger.info("Cliente de chat iniciado en #{Node.self()}")

    # Estado inicial del cliente
    state = %{
      connected: false,
      server_node: nil,
      user_id: nil,
      username: nil,
      current_room: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:connect, server_node}, _from, state) do
    server_node =
      if is_binary(server_node) do
        String.to_atom(server_node)
      else
        server_node
      end

    case Node.connect(server_node) do
      true ->
        Logger.info("Conectado al servidor: #{server_node}")
        {:reply, :ok, %{state | connected: true, server_node: server_node}}
      false ->
        Logger.error("Error al conectar con el servidor: #{server_node}")
        {:reply, {:error, :connection_failed}, state}
      :ignored ->
        Logger.error("Conexión ignorada: #{server_node}")
        {:reply, {:error, :connection_ignored}, state}
    end
  end

  @impl true
  def handle_call({:login, username}, _from, state) do
    if state.connected do
      # Enviamos la solicitud de registro al servidor
      result = :rpc.call(
        state.server_node,
        ChatServer.UserManager,
        :register_user,
        [username, self()]
      )

      case result do
        {:ok, user_id} ->
          Logger.info("Sesión iniciada como: #{username} (#{user_id})")
          {:reply, :ok, %{state | user_id: user_id, username: username}}
        {:error, reason} ->
          Logger.error("Error al iniciar sesión: #{reason}")
          {:reply, {:error, reason}, state}
        {:badrpc, reason} ->
          Logger.error("Error de RPC: #{inspect(reason)}")
          {:reply, {:error, :rpc_error}, state}
      end
    else
      {:reply, {:error, :not_connected}, state}
    end
  end

  @impl true
  def handle_call(:logout, _from, state) do
    if state.connected && state.user_id do
      # Si estamos en una sala, la abandonamos primero
      if state.current_room do
        :rpc.call(
          state.server_node,
          ChatServer.ChatRoom,
          :leave,
          [state.current_room, state.user_id]
        )
      end

      # Nos desregistramos del servidor
      :rpc.call(
        state.server_node,
        ChatServer.UserManager,
        :unregister_user,
        [state.user_id]
      )

      Logger.info("Sesión cerrada: #{state.username}")

      new_state = %{
        state |
        user_id: nil,
        username: nil,
        current_room: nil
      }

      {:reply, :ok, new_state}
    else
      {:reply, {:error, :not_logged_in}, state}
    end
  end

  @impl true
  def handle_call(:list_users, _from, state) do
    if state.connected do
      users = :rpc.call(
        state.server_node,
        ChatServer.UserManager,
        :get_users,
        []
      )

      {:reply, users, state}
    else
      {:reply, {:error, :not_connected}, state}
    end
  end

  @impl true
  def handle_call(:list_rooms, _from, state) do
    if state.connected do
      rooms = :rpc.call(
        state.server_node,
        ChatServer.ChatRoom.Supervisor,
        :list_rooms,
        []
      )

      {:reply, rooms, state}
    else
      {:reply, {:error, :not_connected}, state}
    end
  end

  @impl true
  def handle_call({:create_room, name}, _from, state) do
    if state.connected do
      result = :rpc.call(
        state.server_node,
        ChatServer.ChatRoom.Supervisor,
        :create_room,
        [name]
      )

      {:reply, result, state}
    else
      {:reply, {:error, :not_connected}, state}
    end
  end

  @impl true
  def handle_call({:join_room, name}, _from, state) do
    if state.connected && state.user_id do
      # Si ya estamos en una sala, la abandonamos primero
      if state.current_room do
        :rpc.call(
          state.server_node,
          ChatServer.ChatRoom,
          :leave,
          [state.current_room, state.user_id]
        )
      end

      # Verificamos que la sala existe
      room_exists = :rpc.call(
        state.server_node,
        ChatServer.ChatRoom.Supervisor,
        :room_exists?,
        [name]
      )

      if room_exists do
        # Nos unimos a la nueva sala
        result = :rpc.call(
          state.server_node,
          ChatServer.ChatRoom,
          :join,
          [name, state.user_id]
        )

        case result do
          :ok ->
            Logger.info("Unido a la sala: #{name}")
            {:reply, :ok, %{state | current_room: name}}
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
      else
        {:reply, {:error, :room_not_found}, state}
      end
    else
      {:reply, {:error, :not_logged_in}, state}
    end
  end

  @impl true
  def handle_call(:leave_room, _from, state) do
    if state.connected && state.user_id && state.current_room do
      # Abandonamos la sala actual
      :rpc.call(
        state.server_node,
        ChatServer.ChatRoom,
        :leave,
        [state.current_room, state.user_id]
      )

      Logger.info("Saliendo de la sala: #{state.current_room}")

      {:reply, :ok, %{state | current_room: nil}}
    else
      {:reply, {:error, :not_in_room}, state}
    end
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    if state.connected && state.current_room do
      # Obtenemos el historial de la sala
      messages = :rpc.call(
        state.server_node,
        ChatServer.ChatRoom,
        :get_history,
        [state.current_room]
      )

      {:reply, messages, state}
    else
      {:reply, {:error, :not_in_room}, state}
    end
  end

  @impl true
  def handle_call(:get_participants, _from, state) do
    if state.connected && state.current_room do
      # Obtenemos los participantes de la sala
      participants = :rpc.call(
        state.server_node,
        ChatServer.ChatRoom,
        :get_participants,
        [state.current_room]
      )

      {:reply, participants, state}
    else
      {:reply, {:error, :not_in_room}, state}
    end
  end

  @impl true
  def handle_cast({:send_message, content}, state) do
    if state.connected && state.user_id && state.current_room do
      # Enviamos el mensaje a la sala actual
      :rpc.call(
        state.server_node,
        ChatServer.ChatRoom,
        :send_message,
        [state.current_room, state.user_id, content]
      )
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:chat_message, room_name, message}, state) do
    # Procesamos el mensaje recibido de una sala
    # Notificamos a la CLI para que lo muestre al usuario
    ChatClient.CLI.display_message(room_name, message)

    {:noreply, state}
  end

  # Funciones auxiliares

  @doc """
  Obtiene la dirección IP local para configurar el nombre del nodo.
  """
  defp get_local_ip do
    # Por defecto, usamos localhost
    "127.0.0.1"
  end

  @doc """
  Inicia la interfaz de línea de comandos.
  """
  def main do
    ChatClient.CLI.start()
  end
end
