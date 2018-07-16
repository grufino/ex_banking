defmodule ExBanking.BankingValidation do

  def lookup_user(user) do
      Registry.lookup(Registry.ExBanking, user)
  end

  def get_balance_from_reply(state, _currency) when state == %{}, do: {:ok, 0}

  def get_balance_from_reply(state, currency) do
    {:ok, Map.get(state, currency)}
  end

  def enough_balance_to_withdraw?(state, currency, amount) do
    cur_balance = Map.get(state, currency)

    cur_balance != nil && cur_balance >= amount
  end

  def valid_arguments?(user) when is_bitstring(user) do
    true
  end

  def valid_arguments?(_user), do: false

  def valid_arguments?(user, currency) when is_bitstring(currency) do
    valid_arguments?(user)
  end

  def valid_arguments?(_user, _currency), do: false

  def valid_arguments?(user, amount, currency) when is_number(amount) and amount > 0 do
    valid_arguments?(user, currency)
  end

  def valid_arguments?(_user, _amount, _currency), do: false

  def valid_arguments?(from_user, to_user, amount, currency) when is_number(amount) and amount > 0 do
    valid_arguments?(from_user, amount, currency) && valid_arguments?(to_user)
  end

  def valid_arguments?(_from_user, _to_user, _amount, _currency), do: false
end
