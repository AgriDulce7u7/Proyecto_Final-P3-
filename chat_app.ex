defmodule ChatApp do
  @moduledoc """
  Módulo principal que actúa como interfaz de usuario para la aplicación de chat.
  """

  def start do
    # Iniciar el servidor de chat
    {:ok, _} = ChatServer.start_link()

    # Bienvenida e instrucciones
    mostrar_bienvenida()

    # Solicitar nombre de usuario
    username = solicitar_nombre_usuario()

    # Iniciar cliente
    {:ok, client_pid} = ChatClient.start_link(username)

    # Conectar al servidor
    {:ok, mensaje} = ChatClient.connect(client_pid, ChatServer)
    IO.puts("\n#{mensaje}")
    IO.puts("Te has unido a la sala 'general' automáticamente.\n")

    # Bucle principal de la aplicación
    loop(client_pid)
  end

  # Bucle principal para procesar comandos del usuario
  defp loop(client_pid) do
    # Mostrar prompt con sala actual
    {:ok, current_room} = ChatClient.get_current_room(client_pid)
    IO.write("[#{current_room}]> ")

    # Leer entrada del usuario
    input = IO.gets("") |> String.trim()

    # Procesar comando o mensaje
    case input do
      "/exit" ->
        # Desconectar y finalizar
        ChatClient.disconnect(client_pid)
        IO.puts("\nGracias por usar el chat de ComNet Solutions. ¡Hasta pronto!")

      "/list" ->
        # Listar usuarios conectados
        case ChatClient.list_users(client_pid) do
          {:ok, users} ->
            IO.puts("\nUsuarios conectados:")
            Enum.each(users, fn user -> IO.puts("- #{user}") end)
            IO.puts("")
          {:error, reason} ->
            IO.puts("\nError: #{reason}\n")
        end
        loop(client_pid)

      "/rooms" ->
        # Listar salas disponibles
        case ChatClient.list_rooms(client_pid) do
          {:ok, rooms} ->
            IO.puts("\nSalas disponibles:")
            Enum.each(rooms, fn room -> IO.puts("- #{room}") end)
            IO.puts("")
          {:error, reason} ->
            IO.puts("\nError: #{reason}\n")
        end
        loop(client_pid)

      "/create " <> room_name ->
        # Crear nueva sala
        case ChatClient.create_room(client_pid, room_name) do
          {:ok, message} ->
            IO.puts("\n#{message}\n")
          {:error, reason} ->
            IO.puts("\nError: #{reason}\n")
        end
        loop(client_pid)

      "/join " <> room_name ->
        # Unirse a una sala
        case ChatClient.join_room(client_pid, room_name) do
          {:ok, message} ->
            IO.puts("\n#{message}\n")
          {:error, reason} ->
            IO.puts("\nError: #{reason}\n")
        end
        loop(client_pid)

      "/history" ->
        # Mostrar historial de mensajes
        case ChatClient.get_history(client_pid) do
          {:ok, messages} ->
            IO.puts("\nHistorial de mensajes:")
            messages
            |> Enum.reverse()
            |> Enum.each(fn msg ->
              IO.puts("[#{msg.timestamp}] #{msg.username}: #{msg.content}")
            end)
            IO.puts("")
          {:error, reason} ->
            IO.puts("\nError: #{reason}\n")
        end
        loop(client_pid)

      "/save " <> file_name ->
        # Guardar historial en archivo
        case ChatClient.save_history(client_pid, file_name) do
          {:ok, message} ->
            IO.puts("\n#{message}\n")
          {:error, reason} ->
            IO.puts("\nError: #{reason}\n")
        end
        loop(client_pid)

      "/help" ->
        # Mostrar ayuda
        mostrar_ayuda()
        loop(client_pid)

      _ ->
        # Enviar mensaje normal
        if String.length(input) > 0 do
          ChatClient.send_message(client_pid, input)
        end
        loop(client_pid)
    end
  end

  # Mostrar mensaje de bienvenida e instrucciones
  defp mostrar_bienvenida do
    IO.puts("\n=========================================")
    IO.puts("    CHAT DISTRIBUIDO - COMNET SOLUTIONS    ")
    IO.puts("=========================================")
    IO.puts("\nBienvenido al sistema de chat interno de ComNet Solutions.")
    IO.puts("Este sistema permite la comunicación en tiempo real entre empleados.")
    IO.puts("\nPara comenzar, por favor ingrese su nombre de usuario.")
    IO.puts("Escribe /help para ver la lista de comandos disponibles.\n")
  end

  # Solicitar nombre de usuario
  defp solicitar_nombre_usuario do
    IO.write("Nombre de usuario: ")
    username = IO.gets("") |> String.trim()

    if String.length(username) < 3 do
      IO.puts("El nombre de usuario debe tener al menos 3 caracteres.")
      solicitar_nombre_usuario()
    else
      username
    end
  end

  # Mostrar lista de comandos disponibles
  defp mostrar_ayuda do
    IO.puts("\nComandos disponibles:")
    IO.puts("  /list                - Mostrar usuarios conectados")
    IO.puts("  /rooms               - Mostrar salas disponibles")
    IO.puts("  /create nombre_sala  - Crear una nueva sala de chat")
    IO.puts("  /join nombre_sala    - Unirse a una sala de chat existente")
    IO.puts("  /history             - Consultar historial de mensajes de la sala actual")
    IO.puts("  /save nombre_archivo - Guardar historial de la sala en un archivo")
    IO.puts("  /help                - Mostrar esta ayuda")
    IO.puts("  /exit                - Salir del chat")
    IO.puts("\nCualquier otro texto será enviado como mensaje a la sala actual.\n")
  end
end
