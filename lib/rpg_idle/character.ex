defmodule RpgIdle.Character do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "characters" do
    field :name, :string
    field :class, :string
    field :level, :integer
    field :current_hp, :integer
    field :max_hp, :integer
    field :attack, :integer
    field :exp, :integer
    field :gold, :integer

    has_many :character_items, RpgIdle.CharacterItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [:name, :class, :level, :current_hp, :max_hp, :attack, :exp, :gold])
    |> validate_required([:name, :class, :level, :current_hp, :max_hp, :attack, :exp, :gold])
  end

  def equipped_bonuses(character_id) do
    query =
      from ci in RpgIdle.CharacterItem,
        join: i in assoc(ci, :item),
        where: ci.character_id == ^character_id and ci.equipped == true,
        select: %{attack_bonus: i.attack_bonus, hp_bonus: i.hp_bonus}

    result = RpgIdle.Repo.all(query)

    %{
      attack_bonus: Enum.reduce(result, 0, &(&1.attack_bonus + &2)),
      hp_bonus: Enum.reduce(result, 0, &(&1.hp_bonus + &2))
    }
  end

  def total_attack(character) do
    bonuses = equipped_bonuses(character.id)
    character.attack + bonuses.attack_bonus
  end

  def total_max_hp(character) do
    bonuses = equipped_bonuses(character.id)
    character.max_hp + bonuses.hp_bonus
  end
end
