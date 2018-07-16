defmodule ExBanking.Supervisor do
  use Supervisor

    def start_link(_) do
        Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init(_) do
      children = [
          {Registry, keys: :unique, name: Registry.ExBanking},
          {DynamicSupervisor, name: ExBanking.UsersSupervisor, strategy: :one_for_one}
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
end
