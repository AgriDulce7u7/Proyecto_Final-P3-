defmodule ChatServer.ChatRoom do
  @moduledoc """
  Gestiona una sala de chat individual.
  Maneja los mensajes y los participantes de la sala.
  """
  use GenServer
  require Logger

  # API del cliente

  @doc """
  Inicia una nueva sala de chat con el nombre especificado.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  @doc """
  Añade un usuario a la sala de chat.
  """
  def join(room_name, user_id) do
    GenServer.call(via_tuple(room_name), {:join, user_id})
  end

  @doc """
  Elimina un usuario de la sala de chat.
  """
  def leave(room_name, user_id) do
    GenServer.cast(via_tuple(room_name), {:leave, user_id})
  end

  @doc """
  Envía un mensaje a la sala de chat.
  """
  def send_message(room_name, user_id, content) do
    GenServer.cast(via_tuple(room_name), {:send_message, user_id, content})
  end

  @doc """
  Obtiene el historial de mensajes de la sala.
  """
  def get_history(room_name) do
    GenServer.call(via_tuple(room_name), :get_history)
  end

  @doc """
  Obtiene la lista de participantes de la sala.
  """
  def get_participants(room_name) do
    GenServer.call(via_tuple(room_name), :get_participants)
  end

  # Callbacks del servidor

  @impl true
  def init(name) do
    Logger.info("Sala de chat iniciada: #{name}")
    {:ok, %{
      name: name,
      participants: MapSet.new(),
      messages: []
    }}
  end

  @impl true
  def handle_call({:join, user_id}, _from, state) do
    # Verificamos si el usuario existe
    case ChatServer.UserManager.get_user(user_id) do
      {:ok, user} ->
        Logger.info("Usuario #{user.username} se unió a la sala #{state.name}")

        # Añadimos el usuario a los participantes
        new_participants = MapSet.put(state.participants, user_id)
        new_state = %{state | participants: new_participants}

        # Creamos un mensaje de sistema
        system_message = %{
          id: UUID.uuid4(),
          user_id: nil,
          username: "Sistema",
          content: "#{user.username} se unió a la sala",
          timestamp: DateTime.utc_now()
        }

        # Guardamos el mensaje en el historial
        new_messages = [system_message | state.messages]
        new_state = %{new_state | messages: new_messages}

        # Guardamos el mensaje en el almacén de mensajes
        ChatServer.MessageStore.save_message(state.name, system_message)

        # Difundimos el mensaje a todos los participantes
        broadcast_message(new_state, system_message)

        {:reply, :ok, new_state}

      {:error, _reason} ->
        {:reply, {:error, :user_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    # Devolvemos los mensajes en orden cronológico (más recientes al final)
    messages = Enum.reverse(state.messages)
    {:reply, messages, state}
  end

  @impl true
  def handle_call(:get_participants, _from, state) do
    # Obtenemos la información de los participantes
    participants =
      state.participants
      |> Enum.map(fn user_id ->
        case ChatServer.UserManager.get_user(user_id) do
          {:ok, user} -> Map.take(user, [:id, :username])
          {:error, _} -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))

    {:reply, participants, state}
  end

  @impl true
  def handle_cast({:leave, user_id}, state) do
    if MapSet.member?(state.participants, user_id) do
      case ChatServer.UserManager.get_user(user_id) do
        {:ok, user} ->
          Logger.info("Usuario #{user.username} abandonó la sala #{state.name}")

          # Eliminamos el usuario de los participantes
          new_participants = MapSet.delete(state.participants, user_id)
          new_state = %{state | participants: new_participants}

          # Creamos un mensaje de sistema
          system_message = %{
            id: UUID.uuid4(),
            user_id: nil,
            username: "Sistema",
            content: "#{user.username} abandonó la sala",
            timestamp: DateTime.utc_now()
          }

          # Guardamos el mensaje en el historial
          new_messages = [system_message | state.messages]
          new_state = %{new_state | messages: new_messages}

          # Guardamos el mensaje en el almacén de mensajes
          ChatServer.MessageStore.save_message(state.name, system_message)

          # Difundimos el mensaje a todos los participantes
          broadcast_message(new_state, system_message)

          {:noreply, new_state}

        {:error, _} ->
          # El usuario ya no existe, lo eliminamos de los participantes
          new_participants = MapSet.delete(state.participants, user_id)
          new_state = %{state | participants: new_participants}
          {:noreply, new_state}
      end
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:send_message, user_id, content}, state) do
    case ChatServer.UserManager.get_user(user_id) do
      {:ok, user} ->
        if MapSet.member?(state.participants, user_id) do
          # Creamos el mensaje
          message = %{
            id: UUID.uuid4(),
            user_id: user_id,
            username: user.username,
            content: content,
            timestamp: DateTime.utc_now()
          }

          # Guardamos el mensaje en el historial
          new_messages = [message | state.messages]
          new_state = %{state | messages: new_messages}

          # Guardamos el mensaje en el almacén de mensajes
          ChatServer.MessageStore.save_message(state.name, message)

          # Difundimos el mensaje a todos los participantes
          broadcast_message(new_state, message)

          {:noreply, new_state}
        else
          # El usuario no es participante de la sala
          {:noreply, state}
        end

      {:error, _} ->
        # El usuario no existe
        {:noreply, state}
    end
  end

  # Funciones auxiliares

  @doc """
  Genera una tupla para identificar el proceso de una sala de chat.
  """
  defp via_tuple(name) do
    {:via, Registry, {ChatServer.RoomRegistry, name}}
  end

  @doc """
  Difunde un mensaje a todos los participantes de la sala.
  """
  defp broadcast_message(state, message) do
    Enum.each(state.participants, fn user_id ->
      case ChatServer.UserManager.get_user(user_id) do
        {:ok, user} ->
          send(user.pid, {:chat_message, state.name, message})
        {:error, _} ->
          # El usuario ya no existe, debería ser eliminado de los participantes
          nil
      end
    end)
  end

  # Módulo de supervisión de salas de chat

  defmodule Supervisor do
    @moduledoc """
    Supervisa las salas de chat y gestiona su ciclo de vida.
    """
    use DynamicSupervisor
    require Logger

    # API del cliente

    @doc """
    Inicia el supervisor de salas de chat.
    """
    def start_link(_opts) do
      # Iniciamos también el registro para las salas
      Registry.start_link(keys: :unique, name: ChatServer.RoomRegistry)
      DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    @doc """
    Crea una nueva sala de chat.
    """
    def create_room(name) do
      case room_exists?(name) do
        true ->
          {:error, :already_exists}
        false ->
          DynamicSupervisor.start_child(__MODULE__, {ChatServer.ChatRoom, name})
          {:ok, name}
      end
    end

    @doc """
    Obtiene la lista de salas de chat disponibles.
    """
    def list_rooms do
      Registry.select(ChatServer.RoomRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    end

    @doc """
    Verifica si una sala de chat existe.
    """
    def room_exists?(name) do
      case Registry.lookup(ChatServer.RoomRegistry, name) do
        [] -> false
        [_] -> true
      end
    end

    @doc """
    Notifica a todas las salas que un usuario se ha desconectado.
    """
    def user_disconnected(user_id) do
      list_rooms()
      |> Enum.each(fn room_name ->
        ChatServer.ChatRoom.leave(room_name, user_id)
      end)
    end

    # Callbacks del supervisor

    @impl true
    def init(:ok) do
      Logger.info("Supervisor de salas de chat iniciado")
      DynamicSupervisor.init(strategy: :one_for_one)
    end
  end
end
