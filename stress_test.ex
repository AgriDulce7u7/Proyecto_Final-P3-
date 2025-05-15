defmodule StressTest do
  @moduledoc """
  Módulo para realizar pruebas de carga y rendimiento del sistema de chat.
  """

  @doc """
  Ejecuta una prueba simulando múltiples clientes conectados simultáneamente.

  ## Parámetros

  * `num_clients` - Número de clientes a simular.
  * `messages_per_client` - Número de mensajes que enviará cada cliente.
  * `delay_ms` - Retardo en milisegundos entre mensajes (para simular uso real).

  ## Ejemplos

      iex> StressTest.run(50, 10, 100)
      {:ok, %{avg_response_time: 45.3, success_rate: 0.98}}

  """
  def run(num_clients, messages_per_client, delay_ms \\ 0) do
    IO.puts("\n=== INICIANDO PRUEBA DE CARGA ===")
    IO.puts("Clientes: #{num_clients}")
    IO.puts("Mensajes por cliente: #{messages_per_client}")
    IO.puts("Retardo entre mensajes: #{delay_ms}ms")
    IO.puts("Creando clientes...")

    # Iniciar servidor si no está iniciado
    case Process.whereis(ChatServer) do
      nil -> ChatServer.start_link()
      _ -> :ok
    end

    # Crear sala de pruebas
    ChatServer.create_room("stress_test")

    # Crear clientes simulados
    clients = Enum.map(1..num_clients, fn i ->
      username = "user_#{i}"
      {:ok, pid} = ChatClient.start_link(username)
      ChatClient.connect(pid, ChatServer)
      ChatClient.join_room(pid, "stress_test")
      pid
    end)

    IO.puts("#{length(clients)} clientes creados y conectados")
    IO.puts("\nIniciando envío de mensajes...")

    # Registrar tiempo inicial
    start_time = :os.system_time(:milli_seconds)

    # Enviar mensajes
    tasks = Enum.map(clients, fn pid ->
      Task.async(fn ->
        send_messages(pid, messages_per_client, delay_ms)
      end)
    end)

    # Esperar a que todas las tareas terminen
    results = Task.await_many(tasks, 30_000)

    # Registrar tiempo final
    end_time = :os.system_time(:milli_seconds)
    total_time = end_time - start_time

    # Calcular estadísticas
    total_messages = num_clients * messages_per_client
    messages_per_second = total_messages / (total_time / 1000)

    # Mostrar resultados
    IO.puts("\n=== RESULTADOS DE LA PRUEBA ===")
    IO.puts("Tiempo total: #{total_time}ms")
    IO.puts("Mensajes totales: #{total_messages}")
    IO.puts("Mensajes por segundo: #{Float.round(messages_per_second, 2)}")

    # Limpiar clientes
    Enum.each(clients, fn pid -> Process.exit(pid, :normal) end)

    {:ok, %{
      time_ms: total_time,
      messages: total_messages,
      messages_per_second: messages_per_second
    }}
  end

  # Función auxiliar para enviar mensajes desde un cliente
  defp send_messages(client_pid, count, delay_ms) do
    Enum.map(1..count, fn i ->
      # Enviar mensaje
      message = "Test message #{i}"
      ChatClient.send_message(client_pid, message)

      # Esperar si hay delay configurado
      if delay_ms > 0 do
        Process.sleep(delay_ms)
      end

      :ok
    end)
  end
end
