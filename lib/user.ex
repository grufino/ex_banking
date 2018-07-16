defmodule ExBanking.User do
  use GenServer

  alias ExBanking.BankingValidation

  def start_link(user_name) do
      GenServer.start_link(__MODULE__, %{}, name: user_name)
  end

  def init(state) do
      {:ok, state}
  end

  def handle_call({:get_balance}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:deposit, amount, currency}, _from, state) do
    new_state =
      Map.update(state, currency, amount, fn balance -> add(balance, amount) end)

    {:reply, new_state, new_state}
  end

  def handle_call({:withdraw, amount, currency}, _from, state) do
    with true <- BankingValidation.enough_balance_to_withdraw?(state, currency, amount) do
    new_state =
      Map.update(state, currency, amount, fn balance -> subtract(balance, amount) end)

    {:reply, new_state, new_state}
    else
      false -> {:reply, :not_enough_money, state}
    end
  end

  def transfer_money([{from_pid, _}], [{to_pid, _}], amount, currency) do
    with %{} = from_reply <- GenServer.call(from_pid, {:withdraw, amount, currency}),
        {:ok, from_new_balance} <- BankingValidation.get_balance_from_reply(from_reply, currency) do

          {:ok, to_new_balance} =
            GenServer.call(to_pid, {:deposit, amount, currency})
            |> BankingValidation.get_balance_from_reply(currency)

          {:ok, from_new_balance, to_new_balance}
    else
      :not_enough_money -> {:error, :not_enough_money}
    end
  end

  def add(element_1, element_2) when is_float(element_1) or is_float(element_2) do
    element_1 + element_2
    |> Float.round(2)
  end

  def add(element_1, element_2) do
    element_1 + element_2
  end


  def subtract(element_1, element_2) when is_float(element_1) or is_float(element_2) do
    element_1 - element_2
    |> Float.round(2)
  end

  def subtract(element_1, element_2) do
    element_1 - element_2
  end
end
