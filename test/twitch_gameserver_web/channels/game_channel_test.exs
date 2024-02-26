defmodule TwitchGameServerWeb.GameChannelTest do
  use TwitchGameServerWeb.ChannelCase

  import TwitchGameServer.GameFixtures

  setup do
    {:ok, _, socket} =
      socket(TwitchGameServerWeb.NewGameSocket)
      |> subscribe_and_join(TwitchGameServerWeb.GameChannel, "game:123")

    %{socket: socket}
  end

  defp clear_filters(socket) do
    blank_filters = %{"set_filters" => %{"commands" => [], "matches" => []}}
    reply = push(socket, "run-commands", blank_filters)
    assert_reply reply, :ok, %{}
  end

  describe "set game config" do
    test "set_filters", %{socket: socket} do
      req = %{"set_filters" => %{"commands" => ["attack"], "matches" => ["abc"]}}

      expected = %{
        data: %{filters: %{commands: ["attack"], matches: ["abc"]}},
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected
      clear_filters(socket)
    end

    test "set_rate", %{socket: socket} do
      req = %{"set_rate" => 10_000}

      expected = %{
        data: %{rate: 10_000},
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected
      clear_filters(socket)
    end
  end

  describe "game config commands" do
    test "add_command_filter", %{socket: socket} do
      req = %{"add_command_filter" => "foo"}

      expected = %{
        data: %{filters: %{commands: ["foo"], matches: []}},
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected
      clear_filters(socket)
    end

    test "remove_command_filter", %{socket: socket} do
      req = %{"add_command_filter" => "foo"}

      expected = %{
        data: %{filters: %{commands: ["foo"], matches: []}},
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected

      req = %{"remove_command_filter" => "foo"}

      expected = %{
        data: %{filters: %{commands: [], matches: []}},
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected
      clear_filters(socket)
    end

    test "set_queue_limit", %{socket: socket} do
      req = %{"set_queue_limit" => 500}

      expected = %{
        data: %{queue_limit: 500},
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected
    end

    test "set_rate", %{socket: socket} do
      req = %{"set_rate" => 10_000}

      expected = %{
        data: %{rate: 10_000},
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected
    end
  end

  describe "leaderboard" do
    test "get_leaderboard", %{socket: socket} do
      score_fixture(username: "a", total: 1)
      score_fixture(username: "b", total: 100)
      score_fixture(username: "c", total: 50)

      req = %{"get_leaderboard" => 2}

      expected = %{
        data: %{
          leaderboard: [
            %{rank: 1, user: "b", total: 100},
            %{rank: 2, user: "c", total: 50}
          ]
        },
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected
    end

    test "increment_score", %{socket: socket} do
      score_fixture(username: "test_user_1", total: 1)

      req = %{"increment_score" => %{"user" => "test_user_1", "inc" => 1}}

      expected = %{
        data: %{score: %{user: "test_user_1", total: 2}},
        errors: []
      }

      reply = push(socket, "run-commands", req)
      assert_reply reply, :ok, ^expected
    end
  end
end
