defmodule MessageCrypto do
  @moduledoc """
  Módulo para cifrar y descifrar mensajes en el sistema de chat.
  Proporciona una capa de seguridad para la transmisión de mensajes.
  """

  # La clave debe ser de 32 bytes para AES-256
  @default_key :crypto.strong_rand_bytes(32)

  @doc """
  Cifra un mensaje de texto utilizando cifrado AES-256 con el modo CBC.

  ## Parámetros

  * `message` - Mensaje a cifrar (string)
  * `key` - Clave de cifrado (opcional, por defecto se usa una clave generada)

  ## Ejemplos

      iex> encrypted = MessageCrypto.encrypt("Hola mundo")
      iex> is_binary(encrypted)
      true

  """
  def encrypt(message, key \\ @default_key) do
    # Vector de inicialización (IV) aleatorio
    iv = :crypto.strong_rand_bytes(16)

    # Cifrar el mensaje
    encrypted = :crypto.crypto_one_time(:aes_256_cbc, key, iv, pad_message(message), true)

    # Concatenar IV y mensaje cifrado para almacenamiento/transmisión
    iv <> encrypted
  end

  @doc """
  Descifra un mensaje cifrado utilizando AES-256 con el modo CBC.

  ## Parámetros

  * `encrypted` - Mensaje cifrado (binario que incluye IV al inicio)
  * `key` - Clave de cifrado (debe ser la misma usada para cifrar)

  ## Ejemplos

      iex> encrypted = MessageCrypto.encrypt("Hola mundo")
      iex> MessageCrypto.decrypt(encrypted)
      "Hola mundo"

  """
  def decrypt(encrypted, key \\ @default_key) do
    # Extraer IV (los primeros 16 bytes)
    <<iv::binary-size(16), ciphertext::binary>> = encrypted

    # Descifrar el mensaje
    decrypted = :crypto.crypto_one_time(:aes_256_cbc, key, iv, ciphertext, false)

    # Eliminar el padding
    unpad_message(decrypted)
  end

  # Funciones auxiliares para agregar/quitar padding PKCS7

  defp pad_message(message) do
    # Tamaño del bloque AES = 16 bytes
    block_size = 16

    # Calcular cuántos bytes se necesitan añadir
    padding_size = block_size - rem(byte_size(message), block_size)

    # Añadir padding según PKCS7
    message <> :binary.copy(<<padding_size>>, padding_size)
  end

  defp unpad_message(padded_message) do
    # Obtener el último byte que indica el tamaño del padding
    padding_size = :binary.last(padded_message)

    # Eliminar el padding
    binary_part(padded_message, 0, byte_size(padded_message) - padding_size)
  end

  @doc """
  Genera una nueva clave de cifrado.

  ## Ejemplos

      iex> key = MessageCrypto.generate_key()
      iex> byte_size(key)
      32

  """
  def generate_key do
    :crypto.strong_rand_bytes(32)
  end

  @doc """
  Convierte una clave binaria a formato hexadecimal para almacenamiento.

  ## Ejemplos

      iex> key = MessageCrypto.generate_key()
      iex> hex = MessageCrypto.key_to_hex(key)
      iex> String.length(hex)
      64

  """
  def key_to_hex(key) do
    Base.encode16(key, case: :lower)
  end

  @doc """
  Convierte una clave hexadecimal a formato binario para uso.

  ## Ejemplos

      iex> key = MessageCrypto.generate_key()
      iex> hex = MessageCrypto.key_to_hex(key)
      iex> key2 = MessageCrypto.hex_to_key(hex)
      iex> key == key2
      true

  """
  def hex_to_key(hex) do
    Base.decode16!(hex, case: :mixed)
  end
end
