defmodule DocumentationHelper do
  @moduledoc """
  Este módulo genera documentación automática para el sistema de chat.
  """

  @doc """
  Genera un archivo README con documentación básica del proyecto.
  """
  def generate_readme do
    content = """
    # Sistema de Chat Distribuido - ComNet Solutions

    Este proyecto es un sistema de chat distribuido desarrollado para ComNet Solutions como parte
    del proyecto final de Programación III.

    ## Características

    - Sistema de mensajería en tiempo real
    - Soporte para salas de conversación
    - Gestión de usuarios
    - Historial de mensajes consultable
    - Sistema distribuido con múltiples nodos
    - Tolerancia a fallos
    - Seguridad mediante cifrado de mensajes

    ## Arquitectura del sistema

    El sistema está desarrollado en Elixir y utiliza su modelo de concurrencia para garantizar
    escalabilidad y tolerancia a fallos. La arquitectura se basa en el patrón cliente-servidor,
    con la capacidad de distribuir la carga entre múltiples nodos.

    ### Componentes principales

    - **ChatServer**: Servidor de chat que gestiona conexiones, salas y mensajes
    - **ChatClient**: Cliente que permite a los usuarios interactuar con el sistema
    - **ChatSupervisor**: Supervisor que garantiza la tolerancia a fallos
    - **NodeManager**: Gestor de nodos para la comunicación distribuida
    - **DistributedServer**: Sistema para escalar horizontalmente el servidor
    - **MessageCrypto**: Módulo de seguridad para cifrado de mensajes
    - **FileManager**: Gestión de persistencia de datos

    ## Requisitos

    - Elixir 1.12 o superior
    - Erlang OTP 24 o superior

    ## Instalación

    1. Asegúrate de tener Elixir y Erlang instalados
    2. Clona este repositorio
    3. Ejecuta `mix deps.get` para instalar dependencias

    ## Uso

    Para iniciar el sistema:

    ```bash
    iex -S mix
    ```

    Una vez dentro del intérprete de Elixir:

    ```elixir
    Main.start()
    ```

    ### Comandos disponibles

    - `/list` - Mostrar usuarios conectados
    - `/rooms` - Mostrar salas disponibles
    - `/create nombre_sala` - Crear una nueva sala de chat
    - `/join nombre_sala` - Unirse a una sala de chat existente
    - `/history` - Consultar historial de mensajes de la sala actual
    - `/save nombre_archivo` - Guardar historial de la sala en un archivo
    - `/help` - Mostrar ayuda con los comandos disponibles
    - `/exit` - Salir del chat

    ## Modo distribuido

    Para ejecutar en modo distribuido, sigue estos pasos:

    1. Inicia el primer nodo:

    ```bash
    iex --name nodo1@hostname -S mix
    ```

    2. Dentro del intérprete, inicia el sistema:

    ```elixir
    Main.start()
    ```

    3. Selecciona la opción 2 (Iniciar como nodo distribuido)

    4. En otra terminal, inicia el segundo nodo:

    ```bash
    iex --name nodo2@hostname -S mix
    ```

    5. Repite los pasos 2 y 3, y conecta al primer nodo

    ## Pruebas de carga

    El sistema incluye un módulo para realizar pruebas de carga:

    ```elixir
    StressTest.run(50, 10, 100)  # 50 clientes, 10 mensajes por cliente, 100ms de retardo
    ```

    ## Estructura del proyecto

    - `server.ex` - Implementación del servidor de chat
    - `client.ex` - Implementación del cliente de chat
    - `chat_app.ex` - Interfaz de usuario del chat
    - `supervisor.ex` - Supervisor para tolerancia a fallos
    - `node_manager.ex` - Gestión de nodos distribuidos
    - `distributed_server.ex` - Implementación de servidor distribuido
    - `message_crypto.ex` - Cifrado de mensajes
    - `file_manager.ex` - Persistencia de datos
    - `stress_test.ex` - Pruebas de carga
    - `main.ex` - Punto de entrada de la aplicación

    ## Autores

    Desarrollado como proyecto final de Programación III - Universidad del Quindío
    """

    # Guardar el README
    File.write("README.md", content)
  end

  @doc """
  Genera documentación de API en formato HTML.
  """
  def generate_api_docs do
    modules = [
      ChatServer,
      ChatClient,
      ChatApp,
      ChatSupervisor,
      NodeManager,
      DistributedServer,
      MessageCrypto,
      FileManager,
      StressTest,
      Main
    ]

    content = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Documentación API - Chat Distribuido</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 1000px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
        h2 { color: #0066cc; margin-top: 30px; border-bottom: 1px solid #ddd; padding-bottom: 10px; }
        h3 { color: #009900; }
        .function { background: #f5f5f5; padding: 10px; border-radius: 5px; margin-bottom: 15px; }
        .description { margin-left: 20px; }
      </style>
    </head>
    <body>
      <h1>API del Sistema de Chat Distribuido</h1>
      <p>Esta documentación describe los módulos y funciones disponibles en el sistema de chat distribuido.</p>
    """

    # Iterar sobre cada módulo
    Enum.each(modules, fn module ->
      mod_name = module |> to_string() |> String.replace("Elixir.", "")

      # Añadir sección para el módulo
      content = content <> """
        <h2>#{mod_name}</h2>
        <p class="description">#{module.__info__(:moduledoc) || "Sin documentación"}</p>
        <h3>Funciones</h3>
      """

      # Obtener funciones del módulo
      functions = module.__info__(:functions)

      # Iterar sobre cada función
      Enum.each(functions, fn {func_name, arity} ->
        content = content <> """
          <div class="function">
            <h4>#{func_name}/#{arity}</h4>
            <p class="description">Descripción de la función</p>
          </div>
        """
      end)
    end)

    # Cerrar el documento HTML
    content = content <> """
    </body>
    </html>
    """

    # Guardar la documentación
    File.write("api_docs.html", content)
  end

  @doc """
  Genera un manual de usuario en formato Markdown.
  """
  def generate_user_manual do
    content = """
    # Manual de Usuario - Sistema de Chat Distribuido

    ## Introducción

    Bienvenido al manual de usuario del sistema de chat distribuido de ComNet Solutions.
    Este sistema permite la comunicación en tiempo real entre múltiples usuarios,
    con soporte para salas de chat, almacenamiento de conversaciones y mecanismos de seguridad.

    ## Inicio del sistema

    Al iniciar el sistema, se mostrará un menú con las siguientes opciones:

    1. **Iniciar como servidor independiente**: Inicia un servidor de chat en modo local.
    2. **Iniciar como nodo distribuido**: Inicia un nodo que puede conectarse con otros
       para formar un sistema distribuido.
    3. **Iniciar como cliente**: Inicia el cliente de chat para conectarse a un servidor.
    4. **Ejecutar prueba de carga**: Realiza una prueba de rendimiento del sistema.
    5. **Salir**: Cierra la aplicación.

    ## Modo cliente

    Al iniciar como cliente, se solicitará un nombre de usuario. Una vez ingresado,
    se conectará automáticamente al servidor y se unirá a la sala 'general'.

    ### Interfaz de comandos

    La interfaz muestra un prompt con el nombre de la sala actual y permite ingresar
    mensajes o comandos.

    ```
    [general]>
    ```

    ### Comandos disponibles

    - `/list`: Muestra la lista de usuarios conectados actualmente.
    - `/rooms`: Muestra la lista de salas de chat disponibles.
    - `/create nombre_sala`: Crea una nueva sala con el nombre especificado.
    - `/join nombre_sala`: Permite unirse a una sala existente.
    - `/history`: Muestra el historial de mensajes de la sala actual.
    - `/save nombre_archivo`: Guarda el historial de la sala en un archivo.
    - `/help`: Muestra la lista de comandos disponibles.
    - `/exit`: Cierra la sesión y sale del chat.

    ### Envío de mensajes

    Para enviar un mensaje normal, simplemente escribe el texto y presiona Enter.
    El mensaje se enviará a todos los usuarios en la sala actual.

    ## Modo servidor distribuido

    Al iniciar como nodo distribuido, se solicitará un nombre para el nodo.
    Posteriormente, se preguntará si se desea conectar a otro nodo existente.

    Una vez iniciado, se mostrará información sobre:

    - Nodo actual
    - Nodos conectados
    - Servidores disponibles

    Esta información se actualiza al presionar Enter.

    ## Consideraciones de seguridad

    - Los mensajes se transmiten cifrados para mayor seguridad.
    - Cada usuario tiene un identificador único dentro del sistema.
    - El historial de mensajes se puede guardar localmente para su consulta posterior.

    ## Solución de problemas

    Si experimentas dificultades con la conexión:

    1. Verifica que el servidor esté en ejecución.
    2. Comprueba que los nombres de nodo sean correctos al conectar nodos distribuidos.
    3. Asegúrate de que los puertos necesarios estén abiertos si usas múltiples máquinas.

    ## Contacto

    Para soporte técnico, contacta a:
    soporte@comnetsolutions.com
    """

    # Guardar el manual
    File.write("user_manual.md", content)
  end

  @doc """
  Genera toda la documentación del proyecto.
  """
  def generate_all do
    generate_readme()
    generate_api_docs()
    generate_user_manual()

    IO.puts("Documentación generada correctamente.")
  end
end
