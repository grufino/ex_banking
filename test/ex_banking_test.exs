defmodule ExBankingTest do
  use ExUnit.Case, async: true

  import ExBanking

  setup do
    Application.stop(:ex_banking)
    :ok = Application.start(:ex_banking)
  end

  test "create user test" do
    assert create_user("user1") == :ok
  end

  test "create user bad arguments test" do
    assert create_user("user1") == :ok
    assert create_user("user1") == {:error, :user_already_exists}
  end

  test "get balance user not exists test" do
    assert create_user("user1") == :ok
    assert get_balance("user2", "dollar") == {:error, :user_does_not_exist}
  end

  test "deposit bad arguments test" do
    create_user("user1")
    assert deposit("user1", "hello", "dollar") == {:error, :wrong_arguments}
    assert deposit("user1", -100, "dollar") == {:error, :wrong_arguments}
  end

  test "get balance ok test" do
    assert create_user("user1") == :ok
    assert get_balance("user1", "dollar") == {:ok, 0}
  end

  test "deposit ok test" do
    create_user("user1")
    assert deposit("user1", 100.12, "dollar") == {:ok, 100.12}
    assert get_balance("user1", "dollar") == {:ok, 100.12}
  end

  test "withdraw ok test" do
    create_user("user1")
    assert deposit("user1", 100.12, "dollar") == {:ok, 100.12}
    assert withdraw("user1", 100.12, "dollar") == {:ok, 0}
    assert get_balance("user1", "dollar") == {:ok, 0}
  end

  test "send ok test" do
    create_user("user1")
    create_user("user2")
    deposit("user1", 500, "dollar")


    assert send("user1", "user2", 100, "dollar") == {:ok, 400, 100}
  end
end
