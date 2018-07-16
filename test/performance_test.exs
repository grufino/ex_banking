defmodule PerformanceTest do
  use ExUnit.Case

  import ExBanking

  setup do
    Application.stop(:ex_banking)
    :ok = Application.start(:ex_banking)
  end

test "send 1" do
  create_user("user2")
  create_user("user3")
  deposit("user2", 5, "RMB")
  deposit("user3", 5, "RMB")
  assert send("user2", "user3", 2, "RMB") == {:ok, 3, 7}
  assert get_balance("user2", "RMB") == {:ok, 3}
  assert get_balance("user3", "RMB") == {:ok, 7}
  assert send("user3", "user2", 8, "RMB") == {:error, :not_enough_money}
  assert get_balance("user2", "RMB") == {:ok, 3}
  assert get_balance("user3", "RMB") == {:ok, 7}
end

test "send 2" do
  create_user("user2")
  assert send("user2", "user3", 2, "RMB") == {:error, :receiver_does_not_exist}
  create_user("user3")
  assert send("user999", "user3", 2, "RMB") == {:error, :sender_does_not_exist}
end

test "send 3" do
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

def loop1(n, m) do
  receive do
    {_, data} ->
      IO.inspect data
      cond do
        n < 6 ->
          assert data == {:error, :too_many_requests_to_user}
          loop1(n + 1, m)
        true ->
          balance = m + (n - 5)
          assert data == {:ok, balance}
          loop1(n + 1, balance)
      end
    after
      1000 ->
        :ok
  end
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

def loop4(n) do
  receive do
    {_, data} ->
      IO.inspect data
      cond do
        n < 4 ->
          assert data == {:error, :too_many_requests_to_user}
        n < 6 ->
          assert data == {:error, :too_many_requests_to_receiver}
        true ->
          assert data == {:ok, 40 - 2 * (n - 5)}
      end
      loop4(n + 1)
    after
      1000 ->
        :ok
      end
  end

end
