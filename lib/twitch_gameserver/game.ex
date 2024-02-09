defmodule TwitchGameServer.Game do
  @moduledoc """
  The Game context.
  """

  import Ecto.Query

  alias TwitchGameServer.Game.Score
  alias TwitchGameServer.Repo

  # Broadcast successful actions.
  defp broadcast({:ok, %Score{} = score}, event) do
    TwitchGameServer.broadcast("scores", {event, score.id})
    {:ok, score}
  end

  defp broadcast({:error, _} = error, _event), do: error

  @doc """
  Get the top scores.
  """
  def leaderboard(opts \\ []) do
    count = Keyword.get(opts, :top, 20)
    filters = Keyword.get(opts, :filters, [])

    rank_query =
      from s in Score,
        select: %{
          rank: fragment("ROW_NUMBER() OVER (ORDER BY total DESC)"),
          id: s.id
        }

    initial_query =
      from s in Score,
        join: r in subquery(rank_query),
        on: r.id == s.id,
        select: {r.rank, s.username, s.total},
        order_by: [desc: s.total],
        limit: ^count

    query =
      Enum.reduce(filters, initial_query, fn
        {:username, username}, query ->
          from s in query, where: like(s.username, ^"%#{username}%")
      end)

    Repo.all(query)
  end

  @doc """
  Increments a score.

  ## Examples

      iex> increment_score_by_username(username, 10)
      {:ok, %Score{}}

      iex> increment_score_by_username(username, -1000)
      {:error, %Ecto.Changeset{}}

  """
  def increment_score_by_username(username, amount)
      when is_binary(username) and is_integer(amount) do
    case get_score_by(username: username) do
      nil -> create_score(%{username: username, total: amount})
      score -> update_score(score, %{total: score.total + amount})
    end
  end

  @doc """
  Gets a single score by keyword list.

  ## Examples

      iex> get_score_by(user: "foo")
      %Score{}

      iex> get_score_by(user: "notexists")
      nil

  """
  def get_score_by(by), do: Repo.get_by(Score, by)

  @doc """
  Creates a score.

  ## Examples

      iex> create_score(%{field: value})
      {:ok, %Score{}}

      iex> create_score(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_score(attrs \\ %{}) do
    %Score{}
    |> Score.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:score_updated)
  end

  @doc """
  Updates a score.

  ## Examples

      iex> update_score(score, %{field: new_value})
      {:ok, %Score{}}

      iex> update_score(score, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_score(%Score{} = score, attrs) do
    score
    |> Score.changeset(attrs)
    |> Repo.update()
    |> broadcast(:score_updated)
  end

  @doc """
  Deletes a score.

  ## Examples

      iex> delete_score(score)
      {:ok, %Score{}}

      iex> delete_score(score)
      {:error, %Ecto.Changeset{}}

  """
  def delete_score(%Score{} = score) do
    Repo.delete(score)
    |> broadcast(:score_updated)
  end
end
