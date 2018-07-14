defmodule ExBanking do
  use Application

  alias ExBanking.User
  alias ExBanking.BankingValidation

  @type banking_error :: {:error,
    :wrong_arguments                |
    :user_already_exists            |
    :user_does_not_exist            |
    :not_enough_money               |
    :sender_does_not_exist          |
    :receiver_does_not_exist        |
    :too_many_requests_to_user      |
    :too_many_requests_to_sender    |
    :too_many_requests_to_receiver
  }

  def start(_type, _args) do
    ExBanking.Supervisor.start_link([])
  end

  @spec create_user(user :: String.t) :: :ok | banking_error
  def create_user(user) do
    if BankingValidation.lookup_user(user) != [] do
      {:error, :user_already_exists}
    else
      {:via, Registry, {Registry.ExBanking, user}}
      |> User.start_link()
    end
  end

  @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    with [] <- BankingValidation.lookup_user(user) do
      {:error, :user_does_not_exist}
    else
      [{user_pid, _state}] ->
        GenServer.call(user_pid, {:get_balance, currency})
        |> fn balance -> {:ok, balance} end.()
    end
  end

  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    with [] <- BankingValidation.lookup_user(user) do
      {:error, :user_does_not_exist}
    else
      [{user_pid, _state}] ->
        GenServer.call(user_pid, {:deposit, amount, currency})
        |> BankingValidation.get_balance_from_reply(currency)
    end
  end

  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    with [] <- BankingValidation.lookup_user(user) do
      {:error, :user_does_not_exist}
    else
      [{user_pid, _state}] ->
        GenServer.call(user_pid, {:withdraw, amount, currency})
        |> BankingValidation.get_balance_from_reply(currency)
    end
  end

  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    from_user = BankingValidation.lookup_user(from_user)
    to_user = BankingValidation.lookup_user(to_user)

    cond do
      from_user == [] -> {:error, :sender_does_not_exist}
      to_user == [] -> {:error, :receiver_does_not_exist}
      true -> transfer_money(from_user, to_user, amount, currency)
    end
  end

  def transfer_money([{from_pid, _}], [{to_pid, _}], amount, currency) do
    {:ok, from_new_balance} =
      GenServer.call(from_pid, {:withdraw, amount, currency})
      |> BankingValidation.get_balance_from_reply(currency)

    {:ok, to_new_balance} =
      GenServer.call(to_pid, {:deposit, amount, currency})
      |> BankingValidation.get_balance_from_reply(currency)

    {:ok, from_new_balance, to_new_balance}
  end

end
