defmodule TwitchGameServer.GameTest do
  use TwitchGameServer.DataCase

  alias TwitchGameServer.Game

  describe "top_scores" do
    alias TwitchGameServer.Game.TopScore

    import TwitchGameServer.GameFixtures

    @invalid_attrs %{username: nil, score: nil}

    test "list_top_scores/0 returns all top_scores" do
      top_score = top_score_fixture()
      assert Game.leaderboard() == [top_score]
    end

    test "get_top_score_by/1 returns the top_score with given username" do
      top_score = top_score_fixture()
      assert Game.get_top_score_by(username: top_score.username) == top_score
    end

    test "create_top_score/1 with valid data creates a top_score" do
      valid_attrs = %{username: "some user", score: 42}

      assert {:ok, %TopScore{} = top_score} = Game.create_top_score(valid_attrs)
      assert top_score.username == "some user"
      assert top_score.score == 42
    end

    test "create_top_score/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Game.create_top_score(@invalid_attrs)
    end

    test "update_top_score/2 with valid data updates the top_score" do
      top_score = top_score_fixture()
      update_attrs = %{username: "some updated user", score: 43}

      assert {:ok, %TopScore{} = top_score} = Game.update_top_score(top_score, update_attrs)
      assert top_score.username == "some updated user"
      assert top_score.score == 43
    end

    test "update_top_score/2 with invalid data returns error changeset" do
      top_score = top_score_fixture()
      assert {:error, %Ecto.Changeset{}} = Game.update_top_score(top_score, @invalid_attrs)
      assert top_score == Game.get_top_score!(top_score.id)
    end

    test "delete_top_score/1 deletes the top_score" do
      top_score = top_score_fixture()
      assert {:ok, %TopScore{}} = Game.delete_top_score(top_score)
      assert_raise Ecto.NoResultsError, fn -> Game.get_top_score!(top_score.id) end
    end

    test "change_top_score/1 returns a top_score changeset" do
      top_score = top_score_fixture()
      assert %Ecto.Changeset{} = Game.change_top_score(top_score)
    end
  end
end
