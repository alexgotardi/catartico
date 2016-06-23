defmodule Catartico.Rdstation do
  require Logger
  require Poison
  require HTTPoison

  @base_url "https://www.rdstation.com.br/api/1.3"
  @conversions_endpoint "#{@base_url}/conversions"
  @token System.get_env("RD_TOKEN")

  @moduledoc """
  Handles payload from catartico_conversions channel
  """

  @doc """
  Handles with transformation of payload and sent to rdstation conversions api
  """
  def process(_, payload) do
    Task.start_link(
      fn ->
        Logger.info "[RD] Received payload #{payload}"
        payload |> _transform |> _sent
      end
    )
  end

  defp _transform payload do
    Logger.info "[RD] Transforming payload -> #{payload}"
    d = Poison.decode!(payload)
    %{
      identificador: d["event_name"],
      email: d["email"],
      nome: d["name"],
      value: d["value"],
      token_rdstation: @token
    } |> Poison.encode!
  end

  defp _sent encoded do
    if is_nil(@token) do
      Logger.warn "[RD] MISSING ENV RD_TOKEN!!!"
    else
      Logger.info "[RD] sending enconded event json to rdstation -> #{encoded}"
      HTTPoison.post(
        @conversions_endpoint,
        encoded,
        [{"Content-Type", "application/json"}])
    end
  end
end
