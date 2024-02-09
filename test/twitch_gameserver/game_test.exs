defmodule TwitchGameServer.GameTest do
  use TwitchGameServer.DataCase

  alias TwitchGameServer.Game

  describe "scores" do
    alias TwitchGameServer.Game.Score

    import TwitchGameServer.GameFixtures

    @invalid_attrs %{username: nil, total: nil}

    test "list_scores/0 returns all scores" do
      score = score_fixture()
      assert Game.leaderboard() == [{1, score.username, score.total}]
    end

    test "increment_score_by_username/1 adds new score if none exists" do
      assert {:ok, %Score{username: "some user", total: 2}} =
               Game.increment_score_by_username("some user", 2)
    end

    test "increment_score_by_username/1 increments a score" do
      score = score_fixture()
      expected = score.total + 2

      assert {:ok, %Score{username: "some user", total: ^expected}} =
               Game.increment_score_by_username(score.username, 2)
    end

    test "create_score/1 with valid data creates a score" do
      valid_attrs = %{username: "some user", total: 42}

      assert {:ok, %Score{} = score} = Game.create_score(valid_attrs)
      assert score.username == "some user"
      assert score.total == 42
    end

    test "create_score/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_score(@invalid_attrs)
    end

    test "update_score/2 with valid data updates the score" do
      score = score_fixture()
      update_attrs = %{username: "some updated user", total: 43}

      assert {:ok, %Score{} = score} = Game.update_score(score, update_attrs)
      assert score.username == "some updated user"
      assert score.total == 43
    end

    test "update_score/2 with invalid data returns error changeset" do
      score = score_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_score(score, @invalid_attrs)
      assert score == Game.get_score_by(id: score.id)
    end

    test "delete_score/1 deletes the score" do
      score = score_fixture()
      assert {:ok, %Score{}} = Game.delete_score(score)
      assert Game.get_score_by(id: score.id) == nil
    end
  end
end
