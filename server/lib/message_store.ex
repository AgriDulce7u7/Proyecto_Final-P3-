defmodule ChatServer.MessageStore do
  @moduledoc """
  Almacena y gestiona la persistencia de los mensajes.
  Proporciona funciones para guardar y recuperar mensajes de las salas de chat.
  """
  use GenServer
  require Logger

  # API del cliente

  @doc """
  Inicia el almacén de mensajes.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Guarda un mensaje en el historial de una sala.
  """
  def save_message(room_name, message) do
    GenServer.cast(__MODULE__, {:save_message, room_name, message})
  end

  @doc """
  Carga el historial de mensajes de una sala.
  """
  def load_history(room_name) do
    GenServer.call(__MODULE__, {:load_history, room_name})
  end

  # Callbacks del servidor

  @impl true
  def init(:ok) do
    Logger.info("Almacén de mensajes iniciado")

    # Creamos el directorio para el historial si no existe
    File.mkdir_p!("chat_history")

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:save_message, room_name, message}, state) do
    # Aseguramos que el directorio para la sala existe
    room_dir = "chat_history/#{room_name}"
    File.mkdir_p!(room_dir)

    # Formateamos el mensaje para guardarlo
    formatted_message = format_message(message)

    # Guardamos el mensaje en un archivo de registro
    file_path = "#{room_dir}/messages.log"
    File.write!(file_path, formatted_message, [:append])

    # También guardamos en un archivo JSON para facilitar la lectura
    json_path = "#{room_dir}/messages.json"

    # Leemos los mensajes existentes (si hay)
    existing_messages =
      case File.read(json_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, messages} -> messages
            _ -> []
          end
        _ ->
          []
      end

    # Añadimos el nuevo mensaje y guardamos
    updated_messages = [message | existing_messages]
    json_content = Jason.encode!(updated_messages, pretty: true)
    File.write!(json_path, json_content)

    {:noreply, state}
  end

  @impl true
  def handle_call({:load_history, room_name}, _from, state) do
    # Construimos la ruta del archivo JSON
    json_path = "chat_history/#{room_name}/messages.json"

    # Intentamos leer y decodificar el archivo
    messages =
      case File.read(json_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, messages} ->
              # Convertimos las claves de string a átomos
              Enum.map(messages, fn message ->
                message
                |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
              end)
            _ -> []
          end
        _ ->
          []
      end

    # Invertimos para tener orden cronológico (más antiguos primero)
    messages = Enum.reverse(messages)

    {:reply, messages, state}
  end

  # Funciones auxiliares

  @doc """
  Formatea un mensaje para guardarlo en el archivo de registro.
  """
  defp format_message(message) do
    timestamp = DateTime.to_string(message.timestamp)
    user_id = message.user_id || "system"
    username = message.username
    content = String.replace(message.content, "\n", "\\n")

    "#{timestamp}|#{user_id}|#{username}|#{content}\n"
  end
end
