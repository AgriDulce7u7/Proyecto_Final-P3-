defmodule Main do
  @moduledoc """
  Módulo principal para iniciar la aplicación de chat.
  """

  def start do
    IO.puts("=== INICIANDO SISTEMA DE CHAT COMNET SOLUTIONS ===")

    # Inicializar sistema de archivos
    FileManager.init()

    # Opciones de inicio
    IO.puts("\nSeleccione modo de inicio:")
    IO.puts("1. Iniciar como servidor independiente")
    IO.puts("2. Iniciar como nodo distribuido")
    IO.puts("3. Iniciar como cliente")
    IO.puts("4. Ejecutar prueba de carga")
    IO.puts("5. Salir")

    # Leer opción
    IO.write("\nOpción: ")
    opcion = IO.gets("") |> String.trim() |> String.to_integer()

    case opcion do
      1 ->
        start_standalone_server()
      2 ->
        start_distributed_node()
      3 ->
        start_client()
      4 ->
        run_stress_test()
      5 ->
        IO.puts("Saliendo...")
      _ ->
        IO.puts("Opción no válida")
        start()
    end
  end

  # Iniciar como servidor independiente
  defp start_standalone_server do
    IO.puts("\n=== INICIANDO SERVIDOR INDEPENDIENTE ===")

    # Iniciar supervisor y servidor
    {:ok, _} = ChatSupervisor.start_link()

    IO.puts("Servidor iniciado correctamente")
    IO.puts("Presiona Enter para iniciar cliente de chat...")
    IO.gets("")

    # Iniciar cliente en el mismo proceso
    ChatApp.start()
  end

  # Iniciar como nodo distribuido
  defp start_distributed_node do
    IO.puts("\n=== INICIANDO NODO DISTRIBUIDO ===")

    # Solicitar nombre del nodo
    IO.write("Nombre del nodo: ")
    node_name = IO.gets("") |> String.trim()

    # Iniciar nodo
    node_atom = NodeManager.start_node(node_name)
    IO.puts("Nodo iniciado: #{node_atom}")

    # Preguntar si conectar a otro nodo
    IO.write("¿Conectar a otro nodo? (s/n): ")
    respuesta = IO.gets("") |> String.trim() |> String.downcase()

    if respuesta == "s" do
      IO.write("Nombre del nodo a conectar: ")
      target_node = IO.gets("") |> String.trim()

      case NodeManager.connect_to_node(target_node) do
        {:ok, message} -> IO.puts(message)
        {:error, reason} -> IO.puts("Error: #{reason}")
      end
    end

    # Iniciar servidor distribuido
    DistributedServer.start()
    DistributedServer.start_server(node_name)

    IO.puts("Servidor distribuido iniciado")

    # Iniciar monitoreo de nodos
    NodeManager.monitor_nodes()

    # Mantener el nodo vivo y mostrar información de nodos conectados
    node_info_loop()
  end

  # Bucle para mostrar información de nodos conectados
  defp node_info_loop do
    # Limpiar pantalla
    IO.puts("\n\n=== INFORMACIÓN DEL NODO ===")
    IO.puts("Nodo actual: #{Node.self()}")

    # Mostrar nodos conectados
    nodes = Node.list()
    IO.puts("Nodos conectados: #{length(nodes)}")
    Enum.each(nodes, fn node ->
      IO.puts("  - #{node}")
    end)

    # Mostrar servidores
    servers = DistributedServer.list_servers()
    IO.puts("\nServidores disponibles: #{length(servers)}")
    Enum.each(servers, fn server ->
      IO.puts("  - #{server}")
    end)

    # Esperar
    IO.puts("\nPresiona Enter para actualizar o 'q' para salir...")
    input = IO.gets("") |> String.trim()

    if input == "q" do
      IO.puts("Saliendo...")
    else
      node_info_loop()
    end
  end

  # Iniciar como cliente
  defp start_client do
    IO.puts("\n=== INICIANDO CLIENTE ===")

    # Si el servidor no está iniciado en este nodo, verificar si
    # se desea conectar a un servidor remoto
    if Process.whereis(ChatServer) == nil do
      IO.puts("No se detectó servidor local.")
      IO.write("¿Conectar a un nodo remoto? (s/n): ")

      respuesta = IO.gets("") |> String.trim() |> String.downcase()

      if respuesta == "s" do
        IO.write("Nombre del nodo a conectar: ")
        target_node = IO.gets("") |> String.trim()

        case NodeManager.connect_to_node(target_node) do
          {:ok, message} ->
            IO.puts(message)
            # Continuar con el cliente
            ChatApp.start()
          {:error, reason} ->
            IO.puts("Error: #{reason}")
            start() # Volver al menú principal
        end
      else
        # Iniciar servidor local para uso del cliente
        {:ok, _} = ChatSupervisor.start_link()
        ChatApp.start()
      end
    else
      # Si el servidor ya está iniciado, simplemente iniciar el cliente
      ChatApp.start()
    end
  end

  # Ejecutar prueba de carga
  defp run_stress_test do
    IO.puts("\n=== PRUEBA DE CARGA ===")

    # Solicitar parámetros de la prueba
    IO.write("Número de clientes: ")
    num_clients = IO.gets("") |> String.trim() |> String.to_integer()

    IO.write("Mensajes por cliente: ")
    messages_per_client = IO.gets("") |> String.trim() |> String.to_integer()

    IO.write("Retardo entre mensajes (ms): ")
    delay = IO.gets("") |> String.trim() |> String.to_integer()

    # Ejecutar prueba
    StressTest.run(num_clients, messages_per_client, delay)

    # Volver al menú principal
    IO.puts("\nPresiona Enter para volver al menú principal...")
    IO.gets("")
    start()
  end
end
