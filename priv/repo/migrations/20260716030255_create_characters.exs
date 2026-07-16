defmodule RpgIdle.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :class, :string
      add :level, :integer
      add :current_hp, :integer
      add :max_hp, :integer
      add :attack, :integer
      add :exp, :integer
      add :gold, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
