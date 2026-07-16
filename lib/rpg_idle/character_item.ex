defmodule RpgIdle.CharacterItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "character_items" do
    belongs_to :character, RpgIdle.Character
    belongs_to :item, RpgIdle.Item
    field :equipped, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_item, attrs) do
    character_item
    |> cast(attrs, [:character_id, :item_id, :equipped])
    |> validate_required([:character_id, :item_id])
  end
end
