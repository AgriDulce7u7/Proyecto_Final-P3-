defmodule ChatServer do
  use GenServer

  # Estructura de estado del servidor
  # - clients: Mapa de clientes conectados {client_pid => username}
  # - rooms: Mapa de salas disponibles {room_name => [client_pids]}
  # - messages: Mapa de mensajes por sala {room_name => [mensajes]}
  def start_link do
    GenServer.start_link(__MODULE__, %{clients: %{}, rooms: %{}, messages: %{}}, name: __MODULE__)
  end

  # Inicializa el servidor y crea la sala principal
  def init(state) do
    # Crear sala principal cuando inicia el servidor
    updated_state = put_in(state, [:rooms, "general"], [])
    updated_state = put_in(updated_state, [:messages, "general"], [])
    {:ok, updated_state}
  end

  # API pública del servidor

  # Cliente se conecta al servidor
  def connect(pid, username) do
    GenServer.call(__MODULE__, {:connect, pid, username})
  end

  # Cliente se desconecta
  def disconnect(pid) do
    GenServer.cast(__MODULE__, {:disconnect, pid})
  end

  # Listar usuarios conectados
  def list_users do
    GenServer.call(__MODULE__, :list_users)
  end

  # Crear nueva sala de chat
  def create_room(room_name) do
    GenServer.call(__MODULE__, {:create_room, room_name})
  end

  # Unirse a una sala existente
  def join_room(pid, room_name) do
    GenServer.call(__MODULE__, {:join_room, pid, room_name})
  end

  # Listar salas disponibles
  def list_rooms do
    GenServer.call(__MODULE__, :list_rooms)
  end

  # Enviar mensaje a una sala
  def send_message(pid, room_name, message) do
    GenServer.cast(__MODULE__, {:send_message, pid, room_name, message})
  end

  # Consultar historial de mensajes de una sala
  def get_history(room_name) do
    GenServer.call(__MODULE__, {:get_history, room_name})
  end

  # Guardar historial de mensajes en archivo
  def save_history(room_name, file_name) do
    GenServer.call(__MODULE__, {:save_history, room_name, file_name})
  end

  # Callbacks de GenServer

  # Maneja conexión de cliente
  def handle_call({:connect, pid, username}, _from, state) do
    Process.monitor(pid)
    updated_clients = Map.put(state.clients, pid, username)
    # Añadir automáticamente a la sala general
    general_room = Map.get(state.rooms, "general", [])
    updated_rooms = Map.put(state.rooms, "general", [pid | general_room])

    new_state = %{state | clients: updated_clients, rooms: updated_rooms}

    # Notificar a todos los usuarios que un nuevo usuario se ha conectado
    broadcast_system_message("general", "#{username} se ha conectado", new_state)

    {:reply, {:ok, "Te has conectado como #{username}"}, new_state}
  end

  # Listar usuarios conectados
  def handle_call(:list_users, _from, state) do
    users = Enum.map(state.clients, fn {_pid, username} -> username end)
    {:reply, {:ok, users}, state}
  end

  # Crear una nueva sala
  def handle_call({:create_room, room_name}, _from, state) do
    case Map.has_key?(state.rooms, room_name) do
      true ->
        {:reply, {:error, "La sala #{room_name} ya existe"}, state}
      false ->
        updated_rooms = Map.put(state.rooms, room_name, [])
        updated_messages = Map.put(state.messages, room_name, [])
        new_state = %{state | rooms: updated_rooms, messages: updated_messages}
        {:reply, {:ok, "Sala #{room_name} creada correctamente"}, new_state}
    end
  end

  # Unirse a una sala
  def handle_call({:join_room, pid, room_name}, _from, state) do
    case Map.has_key?(state.rooms, room_name) do
      false ->
        {:reply, {:error, "La sala #{room_name} no existe"}, state}
      true ->
        room_clients = Map.get(state.rooms, room_name, [])
        username = Map.get(state.clients, pid, "Anónimo")

        updated_rooms = Map.put(state.rooms, room_name, [pid | room_clients])
        new_state = %{state | rooms: updated_rooms}

        # Notificar a los usuarios de la sala que un nuevo usuario se ha unido
        broadcast_system_message(room_name, "#{username} se ha unido a la sala", new_state)

        {:reply, {:ok, "Te has unido a la sala #{room_name}"}, new_state}
    end
  end

  # Listar salas disponibles
  def handle_call(:list_rooms, _from, state) do
    rooms = Map.keys(state.rooms)
    {:reply, {:ok, rooms}, state}
  end

  # Obtener historial de mensajes
  def handle_call({:get_history, room_name}, _from, state) do
    case Map.has_key?(state.messages, room_name) do
      false ->
        {:reply, {:error, "La sala #{room_name} no existe"}, state}
      true ->
        messages = Map.get(state.messages, room_name, [])
        {:reply, {:ok, messages}, state}
    end
  end

  # Guardar historial en archivo
  def handle_call({:save_history, room_name, file_name}, _from, state) do
    case Map.has_key?(state.messages, room_name) do
      false ->
        {:reply, {:error, "La sala #{room_name} no existe"}, state}
      true ->
        messages = Map.get(state.messages, room_name, [])
        content = Enum.map(messages, fn msg -> "#{msg.timestamp} - #{msg.username}: #{msg.content}\n" end)
                  |> Enum.join("")

        case File.write(file_name, content) do
          :ok ->
            {:reply, {:ok, "Historial guardado en #{file_name}"}, state}
          {:error, reason} ->
            {:reply, {:error, "Error al guardar archivo: #{reason}"}, state}
        end
    end
  end

  # Manejar envío de mensajes
  def handle_cast({:send_message, pid, room_name, content}, state) do
    case Map.has_key?(state.rooms, room_name) do
      false ->
        {:noreply, state}
      true ->
        room_clients = Map.get(state.rooms, room_name, [])
        username = Map.get(state.clients, pid, "Anónimo")

        # Solo procesar el mensaje si el usuario está en la sala
        if pid in room_clients do
          timestamp = get_timestamp()
          message = %{username: username, content: content, timestamp: timestamp}

          # Añadir mensaje al historial
          room_messages = Map.get(state.messages, room_name, [])
          updated_messages = Map.put(state.messages, room_name, [message | room_messages])

          # Enviar mensaje a todos los clientes en la sala
          Enum.each(room_clients, fn client_pid ->
            send(client_pid, {:chat_message, room_name, username, content, timestamp})
          end)

          {:noreply, %{state | messages: updated_messages}}
        else
          {:noreply, state}
        end
    end
  end

  # Manejar desconexión de cliente
  def handle_cast({:disconnect, pid}, state) do
    case Map.has_key?(state.clients, pid) do
      false ->
        {:noreply, state}
      true ->
        username = Map.get(state.clients, pid)

        # Eliminar cliente de la lista de clientes
        updated_clients = Map.delete(state.clients, pid)

        # Eliminar cliente de todas las salas y notificar
        updated_rooms = Enum.map(state.rooms, fn {room_name, clients} ->
          if pid in clients do
            # Notificar a los demás usuarios que este usuario se ha desconectado
            broadcast_system_message(room_name, "#{username} se ha desconectado", state)
            {room_name, List.delete(clients, pid)}
          else
            {room_name, clients}
          end
        end)
        |> Enum.into(%{})

        {:noreply, %{state | clients: updated_clients, rooms: updated_rooms}}
    end
  end

  # Manejar cuando un proceso cliente se termina
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Usar la misma lógica que para disconnect
    handle_cast({:disconnect, pid}, state)
  end

  # Funciones auxiliares privadas

  # Obtiene timestamp actual en formato legible
  defp get_timestamp do
    {{year, month, day}, {hour, minute, second}} = :calendar.local_time()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}:#{pad(second)}"
  end

  # Añade un cero inicial si el número es menor que 10
  defp pad(num) when num < 10, do: "0#{num}"
  defp pad(num), do: "#{num}"

  # Envía un mensaje de sistema a todos los usuarios en una sala
  defp broadcast_system_message(room_name, message, state) do
    room_clients = Map.get(state.rooms, room_name, [])
    timestamp = get_timestamp()

    Enum.each(room_clients, fn client_pid ->
      send(client_pid, {:system_message, room_name, message, timestamp})
    end)
  end
end
