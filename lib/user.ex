defmodule ExBanking.User do
  use GenServer

  def start_link(user_name) do
      GenServer.start_link(__MODULE__, %{}, name: user_name)
  end

  def init(state) do
      {:ok, state}
  end

  def handle_call({:get_balance, currency}, _from, state) do
    balance =
      Map.get(state, currency)

    {:reply, balance, balance}
  end

  def handle_call({:deposit, amount, currency}, _from, state) do
    new_state =
      Map.update(state, currency, amount, fn balance -> balance + amount end)

    {:reply, new_state, new_state}
  end

  def handle_call({:withdraw, amount, currency}, _from, state) do
    new_state =
      Map.update(state, currency, amount, fn balance -> balance - amount end)

    {:reply, new_state, new_state}
  end
end
