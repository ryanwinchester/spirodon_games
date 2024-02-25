defmodule TwitchGameserverWeb.GameSocketTest do
  use TwitchGameServer.DataCase, async: false

  import TwitchGameServer.GameFixtures

  @socket_uri "ws://127.0.0.1:4002/gamesocket/websocket"

  # ----------------------------------------------------------------------------
  # Support Modules
  # ----------------------------------------------------------------------------

  defmodule TestClient do
    use WebSockex

    def start_link({url, from_pid}) do
      WebSockex.start_link(url, __MODULE__, %{from: from_pid})
    end

    def handle_frame({:text, data}, state) do
      send(state.from, {:received, Jason.decode!(data)})
      {:ok, state}
    end
  end

  # ----------------------------------------------------------------------------
  # Setup
  # ----------------------------------------------------------------------------

  setup do
    client = start_supervised!({TestClient, {@socket_uri, self()}})
    {:ok, client: client}
  end

  defp clear_filters(client) do
    blank_filters = %{"set_filters" => %{"commands" => [], "matches" => []}}
    assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(blank_filters)})
  end

  # ----------------------------------------------------------------------------
  # Tests
  # ----------------------------------------------------------------------------

  describe "text frames" do
    test "increment_score", %{client: client} do
      score_fixture(username: "test_user_1", total: 1)

      req = %{"increment_score" => %{"user" => "test_user_1", "inc" => 1}}

      expected = %{
        "data" => %{"score" => %{"user" => "test_user_1", "total" => 2}},
        "errors" => []
      }

      assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(req)})
      assert_receive {:received, ^expected}, 1000
    end

    test "leaderboard", %{client: client} do
      score_fixture(username: "a", total: 1)
      score_fixture(username: "b", total: 100)
      score_fixture(username: "c", total: 50)

      req = %{"get_leaderboard" => 2}

      expected = %{
        "data" => %{
          "leaderboard" => [
            %{"rank" => 1, "user" => "b", "total" => 100},
            %{"rank" => 2, "user" => "c", "total" => 50}
          ]
        },
        "errors" => []
      }

      assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(req)})
      assert_receive {:received, ^expected}, 1000
    end

    test "set_filters", %{client: client} do
      req = %{"set_filters" => %{"commands" => ["attack"], "matches" => ["abc"]}}

      expected = %{
        "data" => %{"filters" => %{"commands" => ["attack"], "matches" => ["abc"]}},
        "errors" => []
      }

      assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(req)})
      assert_receive {:received, ^expected}, 1000
      clear_filters(client)
    end

    test "add_command_filter", %{client: client} do
      req = %{"add_command_filter" => "foo"}

      expected = %{
        "data" => %{"filters" => %{"commands" => ["foo"], "matches" => []}},
        "errors" => []
      }

      assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(req)})
      assert_receive {:received, ^expected}, 1000
      clear_filters(client)
    end

    test "remove_command_filter", %{client: client} do
      req = %{"add_command_filter" => "foo"}

      expected = %{
        "data" => %{"filters" => %{"commands" => ["foo"], "matches" => []}},
        "errors" => []
      }

      assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(req)})
      assert_receive {:received, ^expected}, 1000

      req = %{"remove_command_filter" => "foo"}

      expected = %{
        "data" => %{"filters" => %{"commands" => [], "matches" => []}},
        "errors" => []
      }

      assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(req)})
      assert_receive {:received, ^expected}, 1000
      clear_filters(client)
    end

    test "set_queue_limit", %{client: client} do
      req = %{"set_queue_limit" => 500}

      expected = %{
        "data" => %{"queue_limit" => 500},
        "errors" => []
      }

      assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(req)})
      assert_receive {:received, ^expected}, 1000
    end

    test "set_rate", %{client: client} do
      req = %{"set_rate" => 10_000}

      expected = %{
        "data" => %{"rate" => 10_000},
        "errors" => []
      }

      assert :ok = WebSockex.send_frame(client, {:text, Jason.encode!(req)})
      assert_receive {:received, ^expected}, 1000
    end
  end
end
