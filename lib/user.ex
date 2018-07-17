defmodule ExBanking.User do
  use GenServer

  alias ExBanking.{BankingValidation, UserOperations}

  @operation_time 100

  def start_link(user_name) do
      GenServer.start_link(__MODULE__, %{"operation_count" => 0}, name: user_name)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:get_balance}, _from, state = %{"operation_count" => op_count}) when op_count < 10 do
    control_operation_time_and_count()
    new_state =
      state
      |> Map.update("operation_count", 0, fn count -> count + 1 end)
    {:reply, new_state, new_state}
  end

  def handle_call({:deposit, amount, currency}, _from, state = %{"operation_count" => op_count}) when op_count < 10 do
    control_operation_time_and_count()
    new_state =
      state
      |> Map.update("operation_count", 0, fn count -> count + 1 end)
      |> Map.update(currency, amount, fn balance -> UserOperations.add(balance, amount) end)

    {:reply, new_state, new_state}
  end

  def handle_call({:withdraw, amount, currency}, _from, state = %{"operation_count" => op_count}) when op_count < 10 do
    control_operation_time_and_count()
    with true <- BankingValidation.enough_balance_to_withdraw?(state, currency, amount) do
      new_state =
        state
        |> Map.update("operation_count", 0, fn count -> count + 1 end)
        |> Map.update(currency, amount, fn balance -> UserOperations.subtract(balance, amount) end)

    {:reply, new_state, new_state}
    else
      false -> {:reply, :not_enough_money, state}
    end
  end

  def handle_call(_args, _from, state) do
    {:reply, :too_many_requests_to_user, state}
  end

  def handle_info(:decrease_count, state) do
    new_state =
    Map.update(state, "operation_count", 0, fn count -> count - 1 end)

    {:noreply, new_state}
  end

  def control_operation_time_and_count() do
    Process.send_after(self(), :decrease_count, @operation_time)
  end
end
