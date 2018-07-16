defmodule ExBankingTest do
  use ExUnit.Case

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

  test "too many requests test" do
    create_user("user4")
    create_user("user5")
    s = self()
    Enum.each(1..15, fn n -> spawn(fn ->
      data =
        case rem(n, 4) do
          0  -> send("user4", "user5", n, "RMB")
          _ -> deposit("user4", n, "RMB")
         end
      send s, {self(), data}
    end) end)
    loop2(1)
  end

  def loop2(n) do
    receive do
      {_, data} ->
        IO.inspect data
        cond do
          n < 6 ->
            assert (data == {:error, :too_many_requests_to_user} || data == {:error, :too_many_requests_to_sender})
            loop2(n + 1)
          true ->
            assert Enum.any?([
              {:ok, 1},
              {:ok, 3},
              {:ok, 6},
              {:ok, 7},
              {:ok, 2, 4},
              {:ok, 13},
              {:ok, 20},
              {:ok, 21},
              {:ok, 12, 12},
              {:ok, 31}
            ], fn x -> x == data end)
            loop2(n + 1)
        end
      after
        1000 ->
          :ok
    end
  end
end
