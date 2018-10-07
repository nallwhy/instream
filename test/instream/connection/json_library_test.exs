defmodule Instream.Connection.JSONLibraryTest do
  use ExUnit.Case, async: true

  defmodule JSONConnection do
    alias Instream.Connection.JSONLibraryTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_library: JSONLibrary,
        loggers: []
      ]
  end

  defmodule JSONLibrary do
    alias Instream.Connection.JSONLibraryTest.JSONLogger

    def encode!(data) do
      JSONLogger.log({:encode, data})
      Poison.encode!(data)
    end

    def decode!(data, options) do
      JSONLogger.log({:decode, data})
      Poison.decode!(data, options)
    end
  end

  defmodule JSONLogger do
    def start_link(), do: Agent.start_link(fn -> [] end, name: __MODULE__)

    def log(action), do: Agent.update(__MODULE__, fn actions -> [action | actions] end)
    def get(), do: Agent.get(__MODULE__, & &1)
  end

  test "json runtime configuration" do
    {:ok, _} = JSONLogger.start_link()
    {:ok, _} = Supervisor.start_link([JSONConnection], strategy: :one_for_one)

    _ = JSONConnection.query("")

    assert [{:decode, _}] = JSONLogger.get()
  end
end
