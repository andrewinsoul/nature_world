defmodule NatureWorld.Message do
  @enforce_keys [
    :id,
    :from,
    :to,
    :started_at
  ]

  defstruct [
    :id,
    :from,
    :to,
    :started_at
  ]
end
