defmodule NatureWorld.Repo do
  use Ecto.Repo,
    otp_app: :nature_world,
    adapter: Ecto.Adapters.Postgres
end
