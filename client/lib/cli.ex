defmodule ChatClient.CLI do
  @moduledoc """
  Interfaz de línea de comandos para el cliente de chat.
  Proporciona una interfaz de usuario para interactuar con el servidor de chat.
  """
  require Logger

  @doc """
  Inicia la interfaz de línea de comandos.
  """
  def start do
    IO.puts("""
    ==============================
     Aplicación de Chat Distribuido
     ComNet Solutions
    ==============================
    """)

    IO.puts("Escribe /help para ver los comandos disponibles")
    IO.puts("Para chatear, simplemente escribe tu mensaje y presiona Enter")

    # Entramos en el bucle principal
    loop()
  end

  # Bucle principal de la CLI
  defp loop do
    prompt = get_prompt()
    input = IO.gets(prompt)

    # Procesamos el comando o mensaje
    case String.trim(input) do
      "/help" ->
        display_help()
      "/connect " <> server ->
        connect(server)
      "/login " <> username ->
        login(username)
      "/logout" ->
        logout()
      "/list" ->
        list_users()
      "/rooms" ->
        list_rooms()
      "/create " <> room_name ->
        create_room(room_name)
      "/join " <> room_name ->
        join_room(room_name)
      "/leave" ->
        leave_room()
      "/history" ->
        show_history()
      "/participants" ->
        show_participants()
      "/exit" ->
        IO.puts("Saliendo de la aplicación...")
        System.halt(0)
      message ->
        # Si no es un comando, lo tratamos como un mensaje
        send_message(message)
    end

    # Continuamos el bucle
    loop()
  end

  # Genera el prompt de la línea de comandos
  defp get_prompt do
    # Comprobamos el estado del cliente
    state = :sys.get_state(ChatClient)

    cond do
      state.current_room != nil ->
        "[#{state.current_room}] > "
      state.username != nil ->
        "[#{state.username}] > "
      state.connected ->
        "[Conectado] > "
      true ->
        "> "
    end
  end

  # Muestra la ayuda
  defp display_help do
    IO.puts("""

    Comandos disponibles:
    ---------------------
    /help                - Muestra este mensaje de ayuda
    /connect SERVIDOR    - Conecta con un servidor (ej: server@192.168.1.100)
    /login USUARIO       - Inicia sesión con un nombre de usuario
    /logout              - Cierra la sesión
    /list                - Lista los usuarios conectados
    /rooms               - Lista las salas de chat disponibles
    /create SALA         - Crea una nueva sala de chat
    /join SALA           - Entra en una sala de chat
    /leave               - Sale de la sala de chat actual
    /participants        - Muestra los participantes de la sala actual
    /history             - Muestra el historial de mensajes de la sala actual
    /exit                - Sale de la aplicación

    Para enviar un mensaje, simplemente escríbelo y presiona Enter

    """)
  end

  # Conecta con un servidor
  defp connect(server) do
    IO.puts("Conectando con el servidor: #{server}...")

    case ChatClient.connect(server) do
      :ok ->
        IO.puts("Conectado al servidor #{server} correctamente")
      {:error, reason} ->
        IO.puts("Error al conectar con el servidor: #{inspect(reason)}")
        IO.puts("Asegúrate de que el servidor está en ejecución y es accesible")
    end
  end

  # Inicia sesión
  defp login(username) do
    IO.puts("Iniciando sesión como #{username}...")

    case ChatClient.login(username) do
      :ok ->
        IO.puts("Sesión iniciada correctamente como #{username}")
      {:error, :username_taken} ->
        IO.puts("Error: El nombre de usuario ya está en uso")
      {:error, reason} ->
        IO.puts("Error al iniciar sesión: #{inspect(reason)}")
    end
  end

  # Cierra sesión
  defp logout do
    IO.puts("Cerrando sesión...")

    case ChatClient.logout() do
      :ok ->
        IO.puts("Sesión cerrada correctamente")
      {:error, reason} ->
        IO.puts("Error al cerrar sesión: #{inspect(reason)}")
    end
  end

  # Lista usuarios
  defp list_users do
    IO.puts("Obteniendo lista de usuarios...")

    case ChatClient.list_users() do
      users when is_list(users) ->
        IO.puts("\nUsuarios conectados (#{length(users)}):")
        Enum.each(users, fn user ->
          IO.puts("  - #{user.username}")
        end)
        IO.puts("")
      {:error, reason} ->
        IO.puts("Error al obtener la lista de usuarios: #{inspect(reason)}")
    end
  end

  # Lista salas
  defp list_rooms do
    IO.puts("Obteniendo lista de salas...")

    case ChatClient.list_rooms() do
      rooms when is_list(rooms) ->
        IO.puts("\nSalas disponibles (#{length(rooms)}):")
        Enum.each(rooms, fn room ->
          IO.puts("  - #{room}")
        end)
        IO.puts("")
      {:error, reason} ->
        IO.puts("Error al obtener la lista de salas: #{inspect(reason)}")
    end
  end

  # Crea una sala
  defp create_room(name) do
    IO.puts("Creando sala: #{name}...")

    case ChatClient.create_room(name) do
      {:ok, _} ->
        IO.puts("Sala creada correctamente: #{name}")
      {:error, :already_exists} ->
        IO.puts("Error: Ya existe una sala con ese nombre")
      {:error, reason} ->
        IO.puts("Error al crear la sala: #{inspect(reason)}")
    end
  end

  # Entra en una sala
  defp join_room(name) do
    IO.puts("Entrando en la sala: #{name}...")

    case ChatClient.join_room(name) do
      :ok ->
        IO.puts("Has entrado en la sala: #{name}")
      {:error, :room_not_found} ->
        IO.puts("Error: No se ha encontrado la sala")
      {:error, reason} ->
        IO.puts("Error al entrar en la sala: #{inspect(reason)}")
    end
  end

  # Sale de la sala actual
  defp leave_room do
    IO.puts("Saliendo de la sala actual...")

    case ChatClient.leave_room() do
      :ok ->
        IO.puts("Has salido de la sala")
      {:error, :not_in_room} ->
        IO.puts("Error: No estás en ninguna sala")
      {:error, reason} ->
        IO.puts("Error al salir de la sala: #{inspect(reason)}")
    end
  end

  # Muestra el historial de mensajes
  defp show_history do
    case ChatClient.get_history() do
      messages when is_list(messages) ->
        IO.puts("\nHistorial de mensajes:")

        if Enum.empty?(messages) do
          IO.puts("  No hay mensajes en esta sala")
        else
          Enum.each(messages, fn message ->
            format_message(message)
          end)
        end

        IO.puts("")
      {:error, :not_in_room} ->
        IO.puts("Error: No estás en ninguna sala")
      {:error, reason} ->
        IO.puts("Error al obtener el historial: #{inspect(reason)}")
    end
  end

  # Muestra los participantes de la sala
  defp show_participants do
    case ChatClient.get_participants() do
      participants when is_list(participants) ->
        IO.puts("\nParticipantes de la sala (#{length(participants)}):")

        if Enum.empty?(participants) do
          IO.puts("  No hay participantes en esta sala")
        else
          Enum.each(participants, fn participant ->
            IO.puts("  - #{participant.username}")
          end)
        end

        IO.puts("")
      {:error, :not_in_room} ->
        IO.puts("Error: No estás en ninguna sala")
      {:error, reason} ->
        IO.puts("Error al obtener los participantes: #{inspect(reason)}")
    end
  end

  # Envía un mensaje
  defp send_message(message) do
    # Solo enviamos si no está vacío
    message = String.trim(message)

    if message != "" do
      case ChatClient.send_message(message) do
        :ok ->
          # No hacemos nada, el mensaje se envió correctamente
          nil
        {:error, :not_in_room} ->
          IO.puts("Error: No estás en ninguna sala. Únete a una sala primero con /join NOMBRE_SALA")
        {:error, reason} ->
          IO.puts("Error al enviar el mensaje: #{inspect(reason)}")
      end
    end
  end

  @doc """
  Muestra un mensaje recibido en la consola.
  """
  def display_message(room_name, message) do
    # Formateamos y mostramos el mensaje
    IO.puts("[#{room_name}] #{format_message(message, false)}")
  end

  # Formatea un mensaje para mostrarlo
  defp format_message(message, with_newline \\ true) do
    # Construimos la cadena con formato de tiempo
    timestamp = format_timestamp(message.timestamp)

    # Construimos el mensaje formateado
    formatted = "[#{timestamp}] #{message.username}: #{message.content}"

    # Si se necesita un salto de línea, lo añadimos
    if with_newline do
      IO.puts(formatted)
    else
      formatted
    end
  end

  # Formatea una marca de tiempo
  defp format_timestamp(timestamp) do
    # Si es una cadena ISO, la convertimos a DateTime
    timestamp =
      if is_binary(timestamp) do
        {:ok, dt, _} = DateTime.from_iso8601(timestamp)
        dt
      else
        timestamp
      end

    # Formateamos la hora y minutos
    "#{timestamp.hour}:#{String.pad_leading("#{timestamp.minute}", 2, "0")}"
  end
end
