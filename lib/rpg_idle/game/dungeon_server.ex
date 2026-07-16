defmodule RpgIdle.Game.DungeonServer do
  use GenServer
  import Ecto.Query
  alias RpgIdle.{Repo, Character, Item, CharacterItem}

  # Client API

  def start_link(character_id) do
    GenServer.start_link(__MODULE__, character_id, name: via_tuple(character_id))
  end

  defp via_tuple(character_id) do
    {:via, Registry, {RpgIdle.GameRegistry, character_id}}
  end

  def get_state(character_id) do
    case Registry.lookup(RpgIdle.GameRegistry, character_id) do
      [{pid, _}] -> GenServer.call(pid, :get_state)
      [] -> {:error, :not_found}
    end
  end

  def enter_dungeon(character_id) do
    case Registry.lookup(RpgIdle.GameRegistry, character_id) do
      [{pid, _}] ->
        if Process.alive?(pid) do
          GenServer.cast(pid, :enter_dungeon)
          {:ok, pid}
        else
          Registry.unregister(RpgIdle.GameRegistry, character_id)
          ensure_and_enter(character_id)
        end

      [] ->
        ensure_and_enter(character_id)
    end
  end

  defp ensure_and_enter(character_id) do
    case start_link(character_id) do
      {:ok, pid} ->
        GenServer.cast(pid, :enter_dungeon)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        GenServer.cast(pid, :enter_dungeon)
        {:ok, pid}

      error ->
        error
    end
  end

  def leave_dungeon(character_id) do
    case Registry.lookup(RpgIdle.GameRegistry, character_id) do
      [{pid, _}] -> GenServer.cast(pid, :leave_dungeon)
      [] -> :ok
    end
  end

  def equip_item(character_id, item_id) do
    case Registry.lookup(RpgIdle.GameRegistry, character_id) do
      [{pid, _}] -> GenServer.call(pid, {:equip_item, item_id})
      [] -> :ok
    end
  end

  def unequip_item(character_id, item_id) do
    case Registry.lookup(RpgIdle.GameRegistry, character_id) do
      [{pid, _}] -> GenServer.call(pid, {:unequip_item, item_id})
      [] -> :ok
    end
  end

  # Server callbacks

  @impl true
  def init(character_id) do
    character = Repo.get!(Character, character_id)
    state = %{
      character_id: character_id,
      character: character,
      total_atk: Character.total_attack(character),
      total_max_hp: Character.total_max_hp(character),
      monster: nil,
      status: :idle,
      logs: [],
      dungeon_active: false
    }

    {:ok, state}
  end

  @impl true
  def handle_cast(:enter_dungeon, state) do
    character = Repo.get!(Character, state.character_id)
    total_atk = Character.total_attack(character)
    total_max_hp = Character.total_max_hp(character)
    character = %{character | current_hp: total_max_hp}
    monster = generate_monster(character.level)
    logs = ["Memasuki dungeon...", "Seekor #{monster.name} level #{monster.level} muncul!"]

    new_state = %{
      state
      | character: character,
        total_atk: total_atk,
        total_max_hp: total_max_hp,
        monster: monster,
        status: :idle,
        logs: logs,
        dungeon_active: true
    }

    broadcast(new_state)
    Process.send_after(self(), :tick, 500)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:equip_item, item_id}, _from, state) do
    Repo.get_by!(CharacterItem, character_id: state.character_id, item_id: item_id)
    |> Ecto.Changeset.change(%{equipped: true})
    |> Repo.update!()

    {:reply, :ok, recalc_state(state, "Equipment telah dipasang!")}
  end

  @impl true
  def handle_call({:unequip_item, item_id}, _from, state) do
    Repo.get_by!(CharacterItem, character_id: state.character_id, item_id: item_id)
    |> Ecto.Changeset.change(%{equipped: false})
    |> Repo.update!()

    {:reply, :ok, recalc_state(state, "Equipment dilepas.")}
  end

  @impl true
  def handle_info(:tick, state) do
    char_dmg = calc_character_damage(state.total_atk)
    monster_hp = max(0, state.monster.current_hp - char_dmg)
    monster = %{state.monster | current_hp: monster_hp}
    log = "#{state.character.name} menyerang #{monster.name}: -#{char_dmg} HP"

    new_state = %{state | monster: monster, status: :attacking, logs: [log | state.logs]}
    broadcast(new_state)
    Process.send_after(self(), {:monster_turn, char_dmg}, 100)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:monster_turn, _char_dmg}, state) do
    if state.monster.current_hp <= 0 do
      process_monster_defeated(state)
    else
      monster_dmg = calc_monster_damage(state.monster.attack)
      char_hp = max(0, state.character.current_hp - monster_dmg)
      character = %{state.character | current_hp: char_hp}
      log = "#{state.monster.name} menyerang #{character.name}: -#{monster_dmg} HP"

      new_state = %{state | character: character, status: :hit, logs: [log | state.logs]}
      broadcast(new_state)

      if char_hp <= 0 do
        process_character_defeated(new_state)
      else
        Process.send_after(self(), :reset_status, 100)
        {:noreply, new_state}
      end
    end
  end

  @impl true
  def handle_info(:reset_status, state) do
    new_state = %{state | status: :idle}
    broadcast(new_state)
    Process.send_after(self(), :tick, 300)
    {:noreply, new_state}
  end

  defp recalc_state(state, msg) do
    total_atk = Character.total_attack(state.character)
    total_max_hp = Character.total_max_hp(state.character)
    logs = [msg | state.logs]
    new_state = %{state | total_atk: total_atk, total_max_hp: total_max_hp, logs: logs}
    broadcast(new_state)
    new_state
  end

  defp process_monster_defeated(state) do
    exp_gain = 10 + state.monster.level * 5
    gold_gain = 5 + state.monster.level * 3
    character = %{
      state.character
      | exp: state.character.exp + exp_gain,
        gold: state.character.gold + gold_gain
    }

    exp_needed = character.level * 100

    {character, lvl_log} =
      if character.exp >= exp_needed do
        max_hp = character.max_hp + 10
        new_char = %{
          character
          | level: character.level + 1,
            exp: character.exp - exp_needed,
            max_hp: max_hp,
            current_hp: max_hp,
            attack: character.attack + 3
        }

        {new_char, "LEVEL UP! Sekarang level #{new_char.level}!"}
      else
        {character, nil}
      end

    logs = [
      "#{state.monster.name} dikalahkan! +#{exp_gain} EXP, +#{gold_gain} Gold"
      | state.logs
    ]

    logs = if lvl_log, do: [lvl_log | logs], else: logs

    {logs, _dropped_item} = try_drop_loot(state.character_id, state.monster, logs)

    new_monster = generate_monster(character.level)
    logs = ["Monster baru muncul: #{new_monster.name} level #{new_monster.level}!" | logs]

    new_state = %{
      state
      | character: character,
        total_atk: Character.total_attack(character),
        total_max_hp: Character.total_max_hp(character),
        monster: new_monster,
        status: :idle,
        logs: logs
    }

    broadcast(new_state)
    Process.send_after(self(), :tick, 500)
    {:noreply, new_state}
  end

  defp process_character_defeated(state) do
    saved = save_character(%{state.character | current_hp: 0})
    logs = ["#{state.character.name} telah gugur di dungeon..." | state.logs]
    new_state = %{state | character: saved, status: :idle, logs: logs, dungeon_active: false}
    broadcast(new_state)
    {:stop, :normal, state}
  end

  defp try_drop_loot(cid, mon, logs) do
    roll = :rand.uniform(100)

    drop_spec =
      cond do
        roll <= 40 -> nil
        roll <= 60 -> {"weapon", "common"}
        roll <= 73 -> {"armor", "common"}
        roll <= 83 -> {"weapon", "uncommon"}
        roll <= 90 -> {"armor", "uncommon"}
        roll <= 94 -> {"accessory", "uncommon"}
        roll <= 97 -> {"weapon", "rare"}
        roll <= 99 -> {"armor", "rare"}
        true -> {"accessory", "epic"}
      end

    case drop_spec do
      {type, rarity} ->
        items_query =
          from(item in Item,
            where: item.type == ^type and item.rarity == ^rarity,
            order_by: fragment("RANDOM()"),
            limit: 1
          )

        case Repo.one(items_query) do
          nil ->
            {logs, nil}

          item ->
            %CharacterItem{}
            |> CharacterItem.changeset(%{
              character_id: cid,
              item_id: item.id,
              equipped: false
            })
            |> Repo.insert!()

            drop_msg = "#{mon.name} menjatuhkan: #{item.name} [#{item.rarity}]!"
            {[drop_msg | logs], item}
        end

      nil ->
        {logs, nil}
    end
  end

  defp broadcast(state) do
    trimmed = %{state | logs: Enum.take(state.logs, 30)}
    Phoenix.PubSub.broadcast(
      RpgIdle.PubSub,
      "dungeon:#{state.character_id}",
      {:dungeon_update, trimmed}
    )
  end

  defp save_character(character) do
    character
    |> Ecto.Changeset.change(%{
      current_hp: character.current_hp,
      max_hp: character.max_hp,
      level: character.level,
      attack: character.attack,
      exp: character.exp,
      gold: character.gold
    })
    |> Repo.update!()
  end

  defp generate_monster(level) do
    names = ["Goblin", "Slime", "Skeleton", "Wolf", "Bandit", "Dark Elf", "Orc", "Troll"]
    name = Enum.random(names)
    m_level = max(1, level + :rand.uniform(3) - 2)
    %{
      name: name,
      level: m_level,
      current_hp: 20 + m_level * 12,
      max_hp: 20 + m_level * 12,
      attack: 3 + m_level * 3
    }
  end

  defp calc_character_damage(atk) do
    max(1, atk + :rand.uniform(6) - 3)
  end

  defp calc_monster_damage(atk) do
    max(1, atk + :rand.uniform(4) - 2)
  end
end
