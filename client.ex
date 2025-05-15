defmodule ChatClient do
  use GenServer

  # Estado del cliente
  # - username: Nombre de usuario
  # - server: PID del servidor
  # - current_room: Sala actual en la que está el usuario

  def start_link(username) do
    GenServer.start_link(__MODULE__, %{username: username, server: nil, current_room: "general"})
  end

  def init(state) do
    {:ok, state}
  end

  # API pública del cliente

  # Conectarse al servidor
  def connect(pid, server_pid) do
    GenServer.call(pid, {:connect, server_pid})
  end

  # Desconectarse del servidor
  def disconnect(pid) do
    GenServer.cast(pid, :disconnect)
  end

  # Enviar mensaje en la sala actual
  def send_message(pid, message) do
    GenServer.cast(pid, {:send_message, message})
  end

  # Listar usuarios conectados
  def list_users(pid) do
    GenServer.call(pid, :list_users)
  end

  # Listar salas disponibles
  def list_rooms(pid) do
    GenServer.call(pid, :list_rooms)
  end

  # Crear una nueva sala
  def create_room(pid, room_name) do
    GenServer.call(pid, {:create_room, room_name})
  end

  # Unirse a una sala
  def join_room(pid, room_name) do
    GenServer.call(pid, {:join_room, room_name})
  end

  # Consultar historial de mensajes
  def get_history(pid) do
    GenServer.call(pid, :get_history)
  end

  # Guardar historial de mensajes
  def save_history(pid, file_name) do
    GenServer.call(pid, {:save_history, file_name})
  end

  # Obtener sala actual
  def get_current_room(pid) do
    GenServer.call(pid, :get_current_room)
  end

  # Callbacks de GenServer

  # Conexión al servidor
  def handle_call({:connect, server_pid}, _from, state) do
    case ChatServer.connect(self(), state.username) do
      {:ok, message} ->
        {:reply, {:ok, message}, %{state | server: server_pid}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  # Listar usuarios
  def handle_call(:list_users, _from, state) do
    case state.server do
      nil ->
        {:reply, {:error, "No estás conectado al servidor"}, state}
      server ->
        response = ChatServer.list_users()
        {:reply, response, state}
    end
  end

  # Listar salas
  def handle_call(:list_rooms, _from, state) do
    case state.server do
      nil ->
        {:reply, {:error, "No estás conectado al servidor"}, state}
      server ->
        response = ChatServer.list_rooms()
        {:reply, response, state}
    end
  end

  # Crear sala
  def handle_call({:create_room, room_name}, _from, state) do
    case state.server do
      nil ->
        {:reply, {:error, "No estás conectado al servidor"}, state}
      server ->
        response = ChatServer.create_room(room_name)
        {:reply, response, state}
    end
  end

  # Unirse a sala
  def handle_call({:join_room, room_name}, _from, state) do
    case state.server do
      nil ->
        {:reply, {:error, "No estás conectado al servidor"}, state}
      server ->
        case ChatServer.join_room(self(), room_name) do
          {:ok, message} ->
            {:reply, {:ok, message}, %{state | current_room: room_name}}
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  # Obtener historial
  def handle_call(:get_history, _from, state) do
    case state.server do
      nil ->
        {:reply, {:error, "No estás conectado al servidor"}, state}
      server ->
        response = ChatServer.get_history(state.current_room)
        {:reply, response, state}
    end
  end

  # Guardar historial
  def handle_call({:save_history, file_name}, _from, state) do
    case state.server do
      nil ->
        {:reply, {:error, "No estás conectado al servidor"}, state}
      server ->
        response = ChatServer.save_history(state.current_room, file_name)
        {:reply, response, state}
    end
  end

  # Obtener sala actual
  def handle_call(:get_current_room, _from, state) do
    {:reply, {:ok, state.current_room}, state}
  end

  # Desconexión
  def handle_cast(:disconnect, state) do
    case state.server do
      nil ->
        {:noreply, state}
      server ->
        ChatServer.disconnect(self())
        {:noreply, %{state | server: nil, current_room: nil}}
    end
  end

  # Enviar mensaje
  def handle_cast({:send_message, message}, state) do
    case state.server do
      nil ->
        {:noreply, state}
      server ->
        ChatServer.send_message(self(), state.current_room, message)
        {:noreply, state}
    end
  end

  # Recibir mensaje de chat
  def handle_info({:chat_message, room, username, content, timestamp}, state) do
    if room == state.current_room do
      IO.puts("\n[#{timestamp}] #{username}: #{content}")
    end
    {:noreply, state}
  end

  # Recibir mensaje del sistema
  def handle_info({:system_message, room, content, timestamp}, state) do
    if room == state.current_room do
      IO.puts("\n[#{timestamp}] SISTEMA: #{content}")
    end
    {:noreply, state}
  end
end
