defmodule RpgIdle.Repo.Migrations.CreateCharacterItems do
  use Ecto.Migration

  def change do
    create table(:character_items) do
    add :equipped, :boolean, default: false, null: false
    add :character_id, references(:characters, on_delete: :delete_all), null: false
    add :item_id, references(:items, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

    create index(:character_items, [:character_id])
    create index(:character_items, [:item_id])
    create index(:character_items, [:character_id, :equipped])
  end
end
