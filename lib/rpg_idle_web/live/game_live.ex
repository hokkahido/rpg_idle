defmodule RpgIdleWeb.GameLive do
  use RpgIdleWeb, :live_view
  import Ecto.Query
  alias RpgIdle.{Repo, Character, CharacterItem}

  @char_img_url "https://api.dicebear.com/9.x/pixel-art/svg?seed=Knight&scale=150"
  @monster_img_url "https://api.dicebear.com/9.x/pixel-art/svg?seed=Monster&scale=150"

  @impl true
  def mount(_params, _session, socket) do
    character = Repo.one(Character)

    socket =
      if character do
        start_dungeon_server(character.id)
        Phoenix.PubSub.subscribe(RpgIdle.PubSub, "dungeon:#{character.id}")

        assign(socket, %{
          character_id: character.id,
          character: character,
          total_atk: Character.total_attack(character),
          total_max_hp: Character.total_max_hp(character),
          monster: nil,
          monster_status: :idle,
          status: :idle,
          logs: [],
          dungeon_active: false,
          char_img: @char_img_url,
          monster_img: @monster_img_url,
          inventory: load_inventory(character.id)
        })
      else
        assign(socket, %{
          character_id: nil,
          character: nil,
          total_atk: 0,
          total_max_hp: 0,
          monster: nil,
          monster_status: :idle,
          status: :idle,
          logs: [],
          dungeon_active: false,
          char_img: @char_img_url,
          monster_img: @monster_img_url,
          form: %{name: "", class: "Knight"},
          inventory: []
        })
      end

    {:ok, socket}
  end

  @impl true
  def handle_info({:dungeon_update, state}, socket) do
    monster_status =
      case state.status do
        :attacking -> :hit
        :hit -> :attacking
        :idle -> :idle
      end

    inventory = load_inventory(socket.assigns.character_id)

    socket =
      assign(socket, %{
        character: state.character,
        total_atk: Map.get(state, :total_atk, state.character.attack),
        total_max_hp: Map.get(state, :total_max_hp, state.character.max_hp),
        monster: state.monster,
        status: state.status,
        monster_status: monster_status,
        logs: state.logs,
        dungeon_active: state.dungeon_active,
        inventory: inventory
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("enter_dungeon", _, socket) do
    start_dungeon_server(socket.assigns.character_id)
    RpgIdle.Game.DungeonServer.enter_dungeon(socket.assigns.character_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_dungeon", _, socket) do
    RpgIdle.Game.DungeonServer.leave_dungeon(socket.assigns.character_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("equip_item", %{"id" => item_id}, socket) do
    id = String.to_integer(item_id)
    RpgIdle.Game.DungeonServer.equip_item(socket.assigns.character_id, id)
    {:noreply, assign(socket, :inventory, load_inventory(socket.assigns.character_id))}
  end

  @impl true
  def handle_event("unequip_item", %{"id" => item_id}, socket) do
    id = String.to_integer(item_id)
    RpgIdle.Game.DungeonServer.unequip_item(socket.assigns.character_id, id)
    {:noreply, assign(socket, :inventory, load_inventory(socket.assigns.character_id))}
  end

  @impl true
  def handle_event("create_character", %{"name" => name, "class" => class}, socket) do
    attrs = %{
      name: name,
      class: class,
      level: 1,
      current_hp: 100,
      max_hp: 100,
      attack: 12,
      exp: 0,
      gold: 0
    }

    case %Character{}
         |> Character.changeset(attrs)
         |> Repo.insert() do
      {:ok, character} ->
        start_dungeon_server(character.id)
        Phoenix.PubSub.subscribe(RpgIdle.PubSub, "dungeon:#{character.id}")

        socket =
          assign(socket, %{
            character_id: character.id,
            character: character,
            total_atk: Character.total_attack(character),
            total_max_hp: Character.total_max_hp(character),
            monster: nil,
            monster_status: :idle,
            status: :idle,
            logs: [],
            dungeon_active: false,
            inventory: load_inventory(character.id)
          })

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp start_dungeon_server(character_id) do
    case RpgIdle.Game.DungeonServer.start_link(character_id) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  defp load_inventory(char_id) do
    Repo.all(
      from ci in CharacterItem,
        where: ci.character_id == ^char_id,
        preload: [:item],
        order_by: [desc: :equipped, desc: :inserted_at]
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen" style="background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);">
      <div class="container mx-auto px-4 py-6 max-w-5xl">
        <h1 class="text-4xl font-bold text-center mb-2" style="color: #ffd700; text-shadow: 0 0 10px rgba(255,215,0,0.5);">
          ⚔ Text-Based Idle RPG ⚔
        </h1>
        <p class="text-center text-gray-400 mb-6">Auto-Battler Dungeon Crawler</p>

        <%= if @character == nil do %>
          <div class="max-w-md mx-auto">
            <div class="card" style="background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1);">
              <div class="card-body">
                <h2 class="card-title text-xl text-center mb-4" style="color: #ffd700;">
                  <i class="bi bi-person-fill"></i> Buat Karakter Baru
                </h2>
                <form phx-submit="create_character">
                  <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-300 mb-1">
                      <i class="bi bi-person"></i> Nama Karakter
                    </label>
                    <input type="text" name="name" required class="input input-bordered w-full" placeholder="Hero" style="background: rgba(255,255,255,0.08);" />
                  </div>
                  <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-300 mb-1">
                      <i class="bi bi-shield"></i> Class
                    </label>
                    <select name="class" class="select select-bordered w-full" style="background: rgba(255,255,255,0.08);">
                      <option>Knight</option>
                      <option>Mage</option>
                      <option>Archer</option>
                      <option>Berserker</option>
                    </select>
                  </div>
                  <button type="submit" class="btn w-full" style="background: #ffd700; color: #1a1a2e; font-weight: bold;">
                    <i class="bi bi-play-fill"></i> Mulai Petualangan
                  </button>
                </form>
              </div>
            </div>
          </div>
        <% else %>
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="character-column">
              <div class="card h-full" style="background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); backdrop-filter: blur(10px);">
                <div class="card-body items-center text-center">
                  <div class={"character-container #{@status}"} style="width: 150px; height: 150px; margin: 0 auto; position: relative;">
                    <img src={@char_img} alt="Character" class="character-sprite w-full h-full" style="image-rendering: pixelated;" />
                  </div>

                  <h2 class="card-title text-2xl mt-2" style="color: #fff;">
                    <%= @character.name %>
                  </h2>
                  <div class="badge badge-lg mb-3" style="background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none;">
                    <i class="bi bi-shield"></i> <%= @character.class %>
                  </div>

                  <div class="w-full mb-2">
                    <div class="flex justify-between text-xs mb-1">
                      <span style="color: #4ade80;"><i class="bi bi-heart-pulse-fill"></i> HP</span>
                      <span style="color: #4ade80;">
                        <%= min(@character.current_hp, @total_max_hp) %> / <%= @total_max_hp %>
                      </span>
                    </div>
                    <div class="w-full bg-gray-700 rounded-full h-3 overflow-hidden">
                      <div class="h-full rounded-full transition-all duration-300 ease-out"
                           style={"width: #{percent(@character.current_hp, @total_max_hp)}%; background: linear-gradient(90deg, #22c55e, #4ade80);"}>
                      </div>
                    </div>
                  </div>

                  <div class="w-full mb-3">
                    <div class="flex justify-between text-xs mb-1">
                      <span style="color: #fb923c;"><i class="bi bi-star-fill"></i> EXP</span>
                      <span style="color: #fb923c;"><%= @character.exp %> / <%= @character.level * 100 %></span>
                    </div>
                    <div class="w-full bg-gray-700 rounded-full h-2 overflow-hidden">
                      <div class="h-full rounded-full transition-all duration-300 ease-out"
                           style={"width: #{percent(@character.exp, @character.level * 100)}%; background: linear-gradient(90deg, #fb923c, #fbbf24);"}>
                      </div>
                    </div>
                  </div>

                  <div class="grid grid-cols-3 gap-3 w-full mb-3">
                    <div class="text-center p-2 rounded-lg" style="background: rgba(255,255,255,0.05);">
                      <div class="text-xs text-gray-400"><i class="bi bi-arrow-up-circle"></i> Level</div>
                      <div class="text-xl font-bold" style="color: #a78bfa;"><%= @character.level %></div>
                    </div>
                    <div class="text-center p-2 rounded-lg" style="background: rgba(255,255,255,0.05);">
                      <div class="text-xs text-gray-400"><i class="bi bi-sword"></i> ATK</div>
                      <div class="text-xl font-bold" style="color: #f87171;">
                        <%= @total_atk %>
                        <%= if @total_atk > @character.attack do %>
                          <span class="text-xs text-green-400">(+<%= @total_atk - @character.attack %>)</span>
                        <% end %>
                      </div>
                    </div>
                    <div class="text-center p-2 rounded-lg" style="background: rgba(255,255,255,0.05);">
                      <div class="text-xs text-gray-400"><i class="bi bi-coin"></i> Gold</div>
                      <div class="text-xl font-bold" style="color: #fbbf24;"><%= @character.gold %></div>
                    </div>
                  </div>

                  <div class="w-full mt-2">
                    <h4 class="text-sm font-semibold text-left mb-2" style="color: #94a3b8;">
                      <i class="bi bi-backpack-fill"></i> Inventory
                    </h4>
                    <div class="space-y-1 max-h-40 overflow-y-auto">
                      <%= if Enum.empty?(@inventory) do %>
                        <div class="text-xs text-gray-500 italic">Belum ada item...</div>
                      <% else %>
                        <%= for ci <- @inventory do %>
                          <div class={"flex items-center justify-between px-2 py-1 rounded text-xs #{if ci.equipped, do: "bg-white/10", else: "bg-white/5"}"}
                               style={if ci.equipped, do: "border: 1px solid rgba(74,222,128,0.3);", else: ""}>
                            <span>
                              <i class={"bi #{ci.item.icon}"} style={"color: #{rarity_color(ci.item.rarity)}"}></i>
                              <%= ci.item.name %>
                            </span>
                            <button phx-click={if ci.equipped, do: "unequip_item", else: "equip_item"}
                                    phx-value-id={ci.item_id}
                                    class={"btn btn-xs #{if ci.equipped, do: "btn-warning", else: "btn-ghost"}"}
                                    style={if !ci.equipped, do: "color: #94a3b8;", else: ""}>
                              <%= if ci.equipped, do: "Lepas", else: "Pakai" %>
                            </button>
                          </div>
                        <% end %>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="monster-column">
              <div class="card h-full" style="background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); backdrop-filter: blur(10px);">
                <div class="card-body items-center text-center justify-center">
                  <%= if @monster do %>
                    <div class={"monster-container #{@monster_status}"} style="width: 150px; height: 150px; margin: 0 auto; position: relative;">
                      <img src={@monster_img} alt="Monster" class="monster-sprite w-full h-full" style="image-rendering: pixelated;" />
                    </div>
                    <h2 class="card-title text-2xl mt-2" style="color: #fca5a5;">
                      <%= @monster.name %>
                    </h2>
                    <div class="badge badge-lg mb-3" style="background: linear-gradient(135deg, #dc2626, #991b1b); color: white; border: none;">
                      <i class="bi bi-bug"></i> Lv. <%= @monster.level %>
                    </div>

                    <div class="w-full">
                      <div class="flex justify-between text-xs mb-1">
                        <span style="color: #ef4444;"><i class="bi bi-heart-pulse-fill"></i> HP</span>
                        <span style="color: #ef4444;"><%= @monster.current_hp %> / <%= @monster.max_hp %></span>
                      </div>
                      <div class="w-full bg-gray-700 rounded-full h-3 overflow-hidden">
                        <div class="h-full rounded-full transition-all duration-300 ease-out"
                             style={"width: #{percent(@monster.current_hp, @monster.max_hp)}%; background: linear-gradient(90deg, #dc2626, #ef4444);"}>
                        </div>
                      </div>
                    </div>

                    <div class="mt-3 text-center p-2 rounded-lg" style="background: rgba(255,255,255,0.05);">
                      <div class="text-xs text-gray-400"><i class="bi bi-sword"></i> Monster ATK</div>
                      <div class="text-lg font-bold" style="color: #f87171;"><%= @monster.attack %></div>
                    </div>
                  <% else %>
                    <div class="text-center py-8">
                      <i class="bi bi-shield-slash" style="font-size: 4rem; color: rgba(255,255,255,0.15);"></i>
                      <p class="mt-4 text-gray-500">Belum ada monster</p>
                      <p class="text-sm text-gray-600">Masuk dungeon untuk bertarung!</p>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-6">
            <div class="card" style="background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1);">
              <div class="card-body">
                <h3 class="card-title text-sm" style="color: #94a3b8;">
                  <i class="bi bi-chat-dots-fill"></i> Combat Log
                </h3>
                <div class="h-44 overflow-y-auto space-y-1" id="combat-log">
                  <%= for log <- Enum.reverse(@logs) do %>
                    <div class="text-sm py-1 px-2 rounded" style="color: #cbd5e1;">
                      <%= log %>
                    </div>
                  <% end %>
                  <%= if Enum.empty?(@logs) do %>
                    <div class="text-sm text-gray-500 italic">Belum ada aktivitas pertarungan...</div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <div class="text-center mt-6">
            <%= if @dungeon_active do %>
              <button phx-click="leave_dungeon"
                      class="btn btn-lg px-8"
                      style="background: linear-gradient(135deg, #dc2626, #991b1b); color: white; border: none; box-shadow: 0 0 20px rgba(220,38,38,0.3);">
                <i class="bi bi-door-open-fill"></i> Keluar Dungeon
              </button>
            <% else %>
              <button phx-click="enter_dungeon"
                      class="btn btn-lg px-8"
                      style="background: linear-gradient(135deg, #22c55e, #16a34a); color: white; border: none; box-shadow: 0 0 20px rgba(34,197,94,0.3);">
                <i class="bi bi-sword"></i> Masuk Dungeon
              </button>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp percent(0, _), do: 0
  defp percent(current, max) when max > 0, do: min(100, round(current / max * 100))
  defp percent(_, _), do: 0

  defp rarity_color("common"), do: "#94a3b8"
  defp rarity_color("uncommon"), do: "#22c55e"
  defp rarity_color("rare"), do: "#3b82f6"
  defp rarity_color("epic"), do: "#a855f7"
  defp rarity_color(_), do: "#94a3b8"
end
