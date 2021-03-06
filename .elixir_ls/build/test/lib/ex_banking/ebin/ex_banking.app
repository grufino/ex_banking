{application,ex_banking,
             [{applications,[kernel,stdlib,elixir,logger]},
              {description,"ex_banking"},
              {modules,['Elixir.ExBanking',
                        'Elixir.ExBanking.BankingValidation',
                        'Elixir.ExBanking.Supervisor','Elixir.ExBanking.User',
                        'Elixir.ExBanking.UserOperations']},
              {registered,[]},
              {vsn,"0.1.0"},
              {extra_applications,[logger]},
              {mod,{'Elixir.ExBanking',[]}}]}.
