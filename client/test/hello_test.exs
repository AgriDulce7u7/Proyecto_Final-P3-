defmodule HelloTest do
  use ExUnit.Case
  import Hello

  test "hello world" do
    assert hello() == "Hello, world!"
  end
end