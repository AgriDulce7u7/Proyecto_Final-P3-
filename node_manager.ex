defmodule NodeManager do
  @moduledoc """
  Módulo para gestionar la comunicación distribuida entre nodos.
  """

  # Inicia un nodo con nombre específico
  def start_node(node_name) do
    # Convertir el nombre del nodo a átomo
    name = String.to_atom(node_name)

    # Iniciar el nodo
    Node.start(name)

    # Configurar cookie para todos los nodos
    # (debe ser la misma para permitir la comunicación entre ellos)
    Node.set_cookie(:comnet_chat_cookie)

    # Devolver el nombre del nodo
    name
  end

  # Conectarse a otro nodo
  def connect_to_node(node_name) do
    # Convertir el nombre del nodo a átomo
    name = String.to_atom(node_name)

    # Intentar conectarse al nodo
    case Node.connect(name) do
      true ->
        {:ok, "Conectado al nodo #{node_name}"}
      false ->
        {:error, "No se pudo conectar al nodo #{node_name}"}
    end
  end

  # Listar todos los nodos conectados
  def list_nodes do
    [Node.self() | Node.list()]
  end

  # Ejecutar una función en todos los nodos
  def run_on_nodes(module, function, args) do
    # Ejecutar en el nodo local primero
    local_result = apply(module, function, args)

    # Ejecutar en nodos remotos
    remote_results = Node.list() |> Enum.map(fn node ->
      {node, :rpc.call(node, module, function, args)}
    end)

    # Combinar resultados
    [local: local_result, remote: remote_results]
  end

  # Iniciar un nuevo servidor en un nodo remoto
  def start_server_on_node(node_name) do
    name = String.to_atom(node_name)
    :rpc.call(name, ChatServer, :start_link, [])
  end

  # Monitorear nodos para detectar desconexiones
  def monitor_nodes do
    :net_kernel.monitor_nodes(true)
    IO.puts("Monitoreo de nodos activado")
  end

  # Manejar eventos de conexión/desconexión de nodos
  def handle_node_event({:nodeup, node}) do
    IO.puts("Nodo conectado: #{node}")
  end

  def handle_node_event({:nodedown, node}) do
    IO.puts("Nodo desconectado: #{node}")
  end
end
