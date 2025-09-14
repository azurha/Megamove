defmodule Megamove.Repo do
  use Ecto.Repo,
    otp_app: :megamove,
    adapter: Ecto.Adapters.Postgres
end
