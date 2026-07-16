defmodule RpgIdle.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :name, :string
    field :type, :string
    field :attack_bonus, :integer, default: 0
    field :hp_bonus, :integer, default: 0
    field :description, :string
    field :icon, :string, default: "bi-sword"
    field :rarity, :string, default: "common"
    field :drop_weight, :integer, default: 10

    has_many :character_items, RpgIdle.CharacterItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :type, :attack_bonus, :hp_bonus, :description, :icon, :rarity, :drop_weight])
    |> validate_required([:name, :type])
  end
end
