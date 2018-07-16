defmodule ExBanking do
  use Application

  alias ExBanking.{User, UsersSupervisor, BankingValidation}

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
    with true <- BankingValidation.valid_arguments?(user),
      [] <- BankingValidation.lookup_user(user) do
      UsersSupervisor.start_child(user)
      :ok
    else
      false -> {:error, :wrong_arguments}
      [{_user_pid, _state}] -> {:error, :user_already_exists}
    end
  end

  @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    with true <- BankingValidation.valid_arguments?(user, currency),
    [{user_pid, _state}] <- BankingValidation.lookup_user(user),
    %{} = new_balance <- GenServer.call(user_pid, {:get_balance}) do
      BankingValidation.get_balance_from_reply(new_balance, currency)
    else
      false -> {:error, :wrong_arguments}
      [] -> {:error, :user_does_not_exist}
      :too_many_requests_to_user -> {:error, :too_many_requests_to_user}
    end
  end

  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    with true <- BankingValidation.valid_arguments?(user, amount, currency),
    [{user_pid, _state}] <- BankingValidation.lookup_user(user) do
      GenServer.call(user_pid, {:deposit, amount, currency})
      |> BankingValidation.get_balance_from_reply(currency)
    else
      false -> {:error, :wrong_arguments}
      [] -> {:error, :user_does_not_exist}
    end
  end

  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    with true <- BankingValidation.valid_arguments?(user, amount, currency),
    [{user_pid, _state}] <- BankingValidation.lookup_user(user),
    %{} = new_balance <- GenServer.call(user_pid, {:withdraw, amount, currency}) do

      BankingValidation.get_balance_from_reply(new_balance, currency)
    else
      false -> {:error, :wrong_arguments}
      [] -> {:error, :user_does_not_exist}
      :not_enough_money -> {:error, :not_enough_money}
    end
  end

  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    with true <- BankingValidation.valid_arguments?(from_user, to_user, amount, currency) do
      from_user = BankingValidation.lookup_user(from_user)
      to_user = BankingValidation.lookup_user(to_user)

      cond do
        from_user == [] -> {:error, :sender_does_not_exist}
        to_user == [] -> {:error, :receiver_does_not_exist}
        true -> User.transfer_money(from_user, to_user, amount, currency)
      end
    else
      false -> {:error, :wrong_arguments}
      new_balance -> BankingValidation.get_balance_from_reply(new_balance, currency)
    end
  end
end
