defmodule FileManager do
  @moduledoc """
  Módulo para gestionar la persistencia de datos del chat en archivos.
  Proporciona funciones para guardar y cargar mensajes, configuraciones y logs.
  """

  @default_dir "chat_data"

  @doc """
  Inicializa las carpetas necesarias para almacenar datos.
  """
  def init do
    # Crear directorio base si no existe
    File.mkdir_p!(@default_dir)

    # Crear subdirectorios para diferentes tipos de datos
    File.mkdir_p!(Path.join(@default_dir, "messages"))
    File.mkdir_p!(Path.join(@default_dir, "logs"))
    File.mkdir_p!(Path.join(@default_dir, "config"))

    :ok
  end

  @doc """
  Guarda el historial de mensajes de una sala de chat en un archivo.

  ## Parámetros

  * `room_name` - Nombre de la sala
  * `messages` - Lista de mensajes a guardar
  * `format` - Formato de archivo (:txt o :json)

  ## Retorno

  * `{:ok, filename}` en caso de éxito
  * `{:error, reason}` en caso de error
  """
  def save_room_history(room_name, messages, format \\ :txt) do
    # Crear nombre de archivo con timestamp
    timestamp = DateTime.utc_now() |> DateTime.to_string() |> String.replace(~r/[^\w]/, "_")
    extension = if format == :json, do: "json", else: "txt"
    filename = "#{room_name}_#{timestamp}.#{extension}"
    filepath = Path.join([@default_dir, "messages", filename])

    # Convertir mensajes al formato especificado
    content = case format do
      :json -> Jason.encode!(messages, pretty: true)
      _ -> format_messages_text(messages)
    end

    # Guardar en archivo
    case File.write(filepath, content) do
      :ok -> {:ok, filename}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Carga el historial de mensajes desde un archivo.

  ## Parámetros

  * `filename` - Nombre del archivo a cargar

  ## Retorno

  * `{:ok, messages}` en caso de éxito
  * `{:error, reason}` en caso de error
  """
  def load_room_history(filename) do
    filepath = Path.join([@default_dir, "messages", filename])

    case File.read(filepath) do
      {:ok, content} ->
        # Determinar formato por extensión
        format = if String.ends_with?(filename, ".json"), do: :json, else: :txt

        messages = case format do
          :json -> Jason.decode!(content)
          _ -> parse_messages_text(content)
        end

        {:ok, messages}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Registra un evento en el archivo de log.

  ## Parámetros

  * `event_type` - Tipo de evento (átomo)
  * `details` - Detalles del evento (mapa o string)
  """
  def log_event(event_type, details) do
    # Crear nombre de archivo con fecha actual
    date = Date.utc_today() |> Date.to_string()
    filename = "chat_log_#{date}.log"
    filepath = Path.join([@default_dir, "logs", filename])

    # Formatear mensaje de log
    timestamp = DateTime.utc_now() |> DateTime.to_string()
    log_entry = "[#{timestamp}] [#{event_type}] #{inspect(details)}\n"

    # Añadir al archivo de log (append)
    File.write(filepath, log_entry, [:append])
  end

  @doc """
  Guarda configuración del sistema.

  ## Parámetros

  * `config` - Mapa con la configuración a guardar
  """
  def save_config(config) do
    filepath = Path.join([@default_dir, "config", "chat_config.json"])
    content = Jason.encode!(config, pretty: true)
    File.write(filepath, content)
  end

  @doc """
  Carga configuración del sistema.
  """
  def load_config do
    filepath = Path.join([@default_dir, "config", "chat_config.json"])

    case File.read(filepath) do
      {:ok, content} -> {:ok, Jason.decode!(content)}
      {:error, :enoent} -> {:ok, %{}} # Si no existe, devolver un mapa vacío
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Lista los archivos de historial disponibles.
  """
  def list_history_files do
    Path.join([@default_dir, "messages", "*"])
    |> Path.wildcard()
    |> Enum.map(&Path.basename/1)
  end

  # Funciones privadas auxiliares

  # Formatea mensajes para archivo de texto
  defp format_messages_text(messages) do
    Enum.map(messages, fn msg ->
      "[#{msg["timestamp"] || msg[:timestamp]}] #{msg["username"] || msg[:username]}: #{msg["content"] || msg[:content]}"
    end)
    |> Enum.join("\n")
  end

  # Parsea mensajes desde archivo de texto
  defp parse_messages_text(content) do
    String.split(content, "\n", trim: true)
    |> Enum.map(fn line ->
      case Regex.run(~r/\[(.*?)\] (.*?): (.*)/, line) do
        [_, timestamp, username, content] ->
          %{timestamp: timestamp, username: username, content: content}
        _ ->
          nil # Ignorar líneas con formato inválido
      end
    end)
    |> Enum.filter(&(&1 != nil))
  end
end
