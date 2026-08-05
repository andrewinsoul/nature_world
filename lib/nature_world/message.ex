defmodule NatureWorld.Message do
  @enforce_keys [
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
