defmodule RpgIdle.Repo do
  use Ecto.Repo,
    otp_app: :rpg_idle,
    adapter: Ecto.Adapters.Postgres
end
