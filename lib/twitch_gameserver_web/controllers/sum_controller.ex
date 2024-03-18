defmodule TwitchGameServerWeb.SumController do
 use TwitchGameServerWeb, :controller

 def show(conn, _params) do
    # Load the Wasm module
    wasm_path = Path.join(:code.priv_dir(:twitch_gameserver), "game.wasm")
    bytes = File.read!(wasm_path)
    {:ok, pid} = Wasmex.start_link(%{bytes: bytes})

    # Call the exported function
    {:ok, [result]} = Wasmex.call_function(pid, "game_sum", [50, 8])

    # Use the result in your response
    json(conn, %{sum: result})
 end
end

