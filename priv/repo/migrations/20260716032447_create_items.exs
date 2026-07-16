defmodule RpgIdle.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
    add :name, :string, null: false
    add :type, :string, null: false
    add :attack_bonus, :integer, default: 0
    add :hp_bonus, :integer, default: 0
    add :description, :string
    add :icon, :string, default: "bi-sword"
    add :rarity, :string, default: "common"
    add :drop_weight, :integer, default: 10

    timestamps(type: :utc_datetime)
  end

    create index(:items, [:type])
    create index(:items, [:rarity])
  end
end
