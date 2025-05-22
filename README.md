# Proyecto_Final-P3-

# Aplicación de Chat Distribuido - Proyecto Final Programación III

Este proyecto implementa una aplicación de chat distribuido para ComNet Solutions, desarrollada como proyecto final del curso de Programación III en la Universidad del Quindío.

## Características

- Sistema de mensajería en tiempo real
- Soporte para múltiples usuarios conectados simultáneamente
- Creación y gestión de salas de chat
- Almacenamiento de conversaciones con historial consultable
- Comandos del sistema (/list, /join, /create, /history, /exit)
- Alta tolerancia a fallos mediante supervisores de Elixir
- Posibilidad de ejecución local y remota

## Requisitos

- Elixir 1.12 o superior
- Erlang/OTP 23 o superior

## Estructura del Proyecto

```
Proyecto_Final-P3-/
├── README.md                 # Documentación e instrucciones
├── server/                   # Aplicación del servidor
│   ├── lib/                  # Código del servidor
│   │   ├── server.ex         # Módulo principal del servidor
│   │   ├── chat_room.ex      # Gestión de salas de chat
│   │   ├── user_manager.ex   # Gestión de usuarios
│   │   └── message_store.ex  # Almacenamiento de mensajes
│   └── mix.exs               # Dependencias del proyecto
└── client/                   # Aplicación del cliente
    ├── lib/                  # Código del cliente
    │   ├── client.ex         # Módulo principal del cliente
    │   └── cli.ex            # Interfaz de línea de comandos
    └── mix.exs               # Dependencias del proyecto
```

## Instalación

1. Navega hacia la carpeta del proyecto:
   ```
   cd Proyecto_Final-P3-
   ```

2. Instala las dependencias del servidor:
   ```
   cd server
   mix deps.get
   ```

3. Instala las dependencias del cliente:
   ```
   cd ../client
   mix deps.get
   ```

## Ejecución

### Ejecución Local

Para ejecutar la aplicación en modo local (en la misma máquina):

0. Navega hacia la carpeta del proyecto:
   ```
   cd Proyecto_Final-P3-
   ```

1. Inicia el servidor:
   ```cmd
   cd server
   iex --name server@127.0.0.1 --cookie chat_cookie -S mix
   ```

2. En otra terminal, inicia el cliente:
   ```cmd
   cd client
   iex --name client@127.0.0.1 --cookie chat_cookie -S mix
   ```

3. En la consola IEx del cliente, ejecuta:
   ```elixir
   ChatClient.main()
   ```

4. Conéctate al servidor local:
   ```
   /connect server@127.0.0.1
   ```

### Ejecución Remota

Para ejecutar la aplicación en modo remoto (diferentes máquinas):

1. En la máquina servidor, ejecuta:
   ```cmd
   cd server
   iex --name server@IP_SERVIDOR --cookie chat_cookie -S mix
   ```
   (Reemplaza IP_SERVIDOR con la dirección IP de la máquina servidor)

2. En la máquina cliente, ejecuta:
   ```cmd
   cd client
   iex --name client@IP_CLIENTE --cookie chat_cookie -S mix
   ```
   (Reemplaza IP_CLIENTE con la dirección IP de la máquina cliente)

3. En la consola IEx del cliente, ejecuta:
   ```elixir
   ChatClient.main()
   ```

4. Conéctate al servidor remoto:
   ```
   /connect server@IP_SERVIDOR
   ```
   (Reemplaza IP_SERVIDOR con la dirección IP de la máquina servidor)

## Uso

Una vez conectado al servidor, puedes usar los siguientes comandos:

- `/help` - Muestra la ayuda
- `/login USUARIO` - Inicia sesión con un nombre de usuario
- `/logout` - Cierra la sesión
- `/list` - Lista los usuarios conectados
- `/rooms` - Lista las salas de chat disponibles
- `/create SALA` - Crea una nueva sala de chat
- `/join SALA` - Entra en una sala de chat
- `/leave` - Sale de la sala de chat actual
- `/participants` - Muestra los participantes de la sala actual
- `/history` - Muestra el historial de mensajes de la sala actual
- `/exit` - Sale de la aplicación

Para enviar un mensaje, simplemente escríbelo y presiona Enter.

## Detalles de Implementación

### Tolerancia a Fallos

La aplicación implementa varios mecanismos para garantizar la tolerancia a fallos:

1. **Supervisores**: Tanto el servidor como el cliente utilizan supervisores para reiniciar automáticamente los procesos que fallan.

2. **Monitoreo de procesos**: El servidor monitorea las conexiones de los clientes. Si un cliente se desconecta abruptamente, el servidor detecta la desconexión y limpia los recursos asociados.

3. **Persistencia de mensajes**: Los mensajes se almacenan en disco, lo que permite recuperar el historial de conversaciones incluso después de un reinicio del servidor.

### Distribución

La aplicación utiliza las capacidades de distribución de Erlang/OTP para permitir la comunicación entre nodos:

1. **Nodos distribuidos**: El servidor y los clientes se ejecutan como nodos Erlang independientes que pueden estar en la misma máquina o en máquinas diferentes.

2. **RPC (Remote Procedure Call)**: Los clientes utilizan llamadas RPC para invocar funciones en el servidor.

3. **Mensajes distribuidos**: El servidor envía mensajes de chat a los clientes utilizando el mecanismo de paso de mensajes de Erlang.

## Contribuciones

Este proyecto fue desarrollado como parte del curso de Programación III en la Universidad del Quindío. Si deseas contribuir, por favor, abre un issue o envía un pull request.

## Licencia

MIT