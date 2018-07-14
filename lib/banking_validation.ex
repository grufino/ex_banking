defmodule ExBanking.BankingValidation do

  def lookup_user(user) do
      Registry.lookup(Registry.ExBanking, user)
  end

  def get_balance_from_reply(state, currency) do
    {:ok, Map.get(state, currency)}
  end
end
