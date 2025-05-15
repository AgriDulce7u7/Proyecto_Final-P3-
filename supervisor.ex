defmodule ChatSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Definir estrategia de supervisión: one_for_one significa que
    # si un proceso hijo falla, solo ese proceso será reiniciado
    children = [
      # El servidor de chat será supervisado
      {ChatServer, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Función para añadir un nuevo servidor de chat
  def add_server do
    Supervisor.start_child(__MODULE__, {ChatServer, []})
  end

  # Función para añadir un nuevo cliente
  def add_client(username) do
    {:ok, pid} = ChatClient.start_link(username)
    pid
  end
end
