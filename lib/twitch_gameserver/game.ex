defmodule TwitchGameServer.Game do
  @moduledoc """
  The Game context.
  """

  import Ecto.Query, warn: false
  alias TwitchGameServer.Repo

  alias TwitchGameServer.Game.TopScore

  # Broadcast successful actions.
  defp broadcast({:ok, top_score}, event) do
    TwitchGameServer.broadcast("top_scores", {event, top_score.id})
    {:ok, top_score}
  end

  defp broadcast({:error, _} = error, _event), do: error

  @doc """
  Get the top scores.
  """
  def leaderboard(top \\ 10) do
    Repo.all(
      from ts in TopScore,
        order_by: [desc: ts.score],
        limit: ^top
    )
  end

  @doc """
  Gets a single top_score by keyword list.

  ## Examples

      iex> get_top_score_by(user: "foo")
      %TopScore{}

      iex> get_top_score_by(user: "notexists")
      nil

  """
  def get_top_score_by(by), do: Repo.get_by(TopScore, by)

  @doc """
  Gets a single top_score.

  Raises `Ecto.NoResultsError` if the TopScore does not exist.

  ## Examples

      iex> get_top_score!(123)
      %TopScore{}

      iex> get_top_score!(456)
      ** (Ecto.NoResultsError)

  """
  def get_top_score!(id), do: Repo.get!(TopScore, id)

  @doc """
  Creates a top_score.

  ## Examples

      iex> create_top_score(%{field: value})
      {:ok, %TopScore{}}

      iex> create_top_score(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_top_score(attrs \\ %{}) do
    %TopScore{}
    |> TopScore.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:top_score_added)
  end

  @doc """
  Updates a top_score.

  ## Examples

      iex> update_top_score(top_score, %{field: new_value})
      {:ok, %TopScore{}}

      iex> update_top_score(top_score, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_top_score(%TopScore{} = top_score, attrs) do
    top_score
    |> TopScore.changeset(attrs)
    |> Repo.update()
    |> broadcast(:top_score_added)
  end

  @doc """
  Upserts a top_score for a user.

  ## Examples

      iex> upsert_top_score(username, %{field: new_value})
      {:ok, %TopScore{}}

      iex> upsert_top_score(username, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_top_score(username, attrs) do
    case get_top_score_by(username: username) do
      nil -> create_top_score(attrs)
      top_score -> update_top_score(top_score, attrs)
    end
  end

  @doc """
  Deletes a top_score.

  ## Examples

      iex> delete_top_score(top_score)
      {:ok, %TopScore{}}

      iex> delete_top_score(top_score)
      {:error, %Ecto.Changeset{}}

  """
  def delete_top_score(%TopScore{} = top_score) do
    Repo.delete(top_score)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking top_score changes.

  ## Examples

      iex> change_top_score(top_score)
      %Ecto.Changeset{data: %TopScore{}}

  """
  def change_top_score(%TopScore{} = top_score, attrs \\ %{}) do
    TopScore.changeset(top_score, attrs)
  end
end
