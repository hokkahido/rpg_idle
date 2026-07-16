alias RpgIdle.Repo
alias RpgIdle.Character
alias RpgIdle.Item

if Repo.aggregate(Character, :count, :id) == 0 do
  %Character{}
  |> Character.changeset(%{
    name: "Hero",
    class: "Knight",
    level: 1,
    current_hp: 100,
    max_hp: 100,
    attack: 12,
    exp: 0,
    gold: 0
  })
  |> Repo.insert!()

  IO.puts("Default character 'Hero' (Knight) created!")
else
  IO.puts("Characters already exist, skipping seed.")
end

if Repo.aggregate(Item, :count, :id) == 0 do
  items = [
    # Common weapons (level 1+)
    %{name: "Rusty Sword", type: "weapon", attack_bonus: 2, hp_bonus: 0, description: "A worn-down blade, but still sharp", icon: "bi-sword", rarity: "common", drop_weight: 30},
    %{name: "Short Bow", type: "weapon", attack_bonus: 2, hp_bonus: 0, description: "Quick and light, perfect for beginners", icon: "bi-crosshair", rarity: "common", drop_weight: 30},
    %{name: "Wooden Staff", type: "weapon", attack_bonus: 1, hp_bonus: 0, description: "A simple staff imbued with minor magic", icon: "bi-magic", rarity: "common", drop_weight: 30},
    %{name: "Iron Axe", type: "weapon", attack_bonus: 3, hp_bonus: 0, description: "Heavy but effective", icon: "bi-shield", rarity: "common", drop_weight: 25},

    # Common armor
    %{name: "Leather Armor", type: "armor", attack_bonus: 0, hp_bonus: 10, description: "Basic protection made from tanned hide", icon: "bi-shield", rarity: "common", drop_weight: 30},
    %{name: "Cloth Robe", type: "armor", attack_bonus: 0, hp_bonus: 5, description: "Light robe with minor enchantments", icon: "bi-hdd-stack", rarity: "common", drop_weight: 30},

    # Uncommon weapons (level 3+)
    %{name: "Iron Sword", type: "weapon", attack_bonus: 5, hp_bonus: 0, description: "A reliable steel blade", icon: "bi-sword", rarity: "uncommon", drop_weight: 20},
    %{name: "War Axe", type: "weapon", attack_bonus: 6, hp_bonus: 0, description: "A formidable battle axe", icon: "bi-shield", rarity: "uncommon", drop_weight: 18},
    %{name: "Hunter's Bow", type: "weapon", attack_bonus: 4, hp_bonus: 0, description: "Precision crafted for hunting", icon: "bi-crosshair", rarity: "uncommon", drop_weight: 20},

    # Uncommon armor
    %{name: "Chainmail", type: "armor", attack_bonus: 0, hp_bonus: 25, description: "Interlocking rings provide solid defense", icon: "bi-shield", rarity: "uncommon", drop_weight: 20},
    %{name: "Enchanted Robe", type: "armor", attack_bonus: 0, hp_bonus: 20, description: "Robe woven with protective magic", icon: "bi-hdd-stack", rarity: "uncommon", drop_weight: 20},

    # Uncommon accessories
    %{name: "Silver Ring", type: "accessory", attack_bonus: 2, hp_bonus: 10, description: "A ring that boosts both strength and vitality", icon: "bi-gem", rarity: "uncommon", drop_weight: 15},
    %{name: "Gold Amulet", type: "accessory", attack_bonus: 1, hp_bonus: 20, description: "An amulet that enhances life force", icon: "bi-gem", rarity: "uncommon", drop_weight: 15},

    # Rare weapons (level 5+)
    %{name: "Mythril Blade", type: "weapon", attack_bonus: 10, hp_bonus: 0, description: "A legendary blade forged from mythril", icon: "bi-sword", rarity: "rare", drop_weight: 8},
    %{name: "Berserker Axe", type: "weapon", attack_bonus: 12, hp_bonus: -5, description: "Great power at a cost to vitality", icon: "bi-shield", rarity: "rare", drop_weight: 7},
    %{name: "Arcane Staff", type: "weapon", attack_bonus: 8, hp_bonus: 5, description: "A staff crackling with arcane energy", icon: "bi-magic", rarity: "rare", drop_weight: 8},

    # Rare armor
    %{name: "Steel Plate", type: "armor", attack_bonus: 0, hp_bonus: 50, description: "Full steel plate armor, nearly impenetrable", icon: "bi-shield", rarity: "rare", drop_weight: 8},
    %{name: "Dragon Scale", type: "armor", attack_bonus: 2, hp_bonus: 45, description: "Armor made from dragon scales", icon: "bi-hdd-stack", rarity: "rare", drop_weight: 6},

    # Rare accessories
    %{name: "Ruby Ring", type: "accessory", attack_bonus: 5, hp_bonus: 20, description: "A ring with a fiery ruby that boosts attack", icon: "bi-gem", rarity: "rare", drop_weight: 5},
    %{name: "Sapphire Amulet", type: "accessory", attack_bonus: 2, hp_bonus: 35, description: "An amulet that greatly enhances vitality", icon: "bi-gem", rarity: "rare", drop_weight: 5},

    # Epic weapons (level 8+)
    %{name: "Excalibur", type: "weapon", attack_bonus: 20, hp_bonus: 10, description: "The legendary sword of kings", icon: "bi-sword", rarity: "epic", drop_weight: 2},
    %{name: "Staff of Magnus", type: "weapon", attack_bonus: 18, hp_bonus: 15, description: "An ancient staff of immense power", icon: "bi-magic", rarity: "epic", drop_weight: 2},

    # Epic armor
    %{name: "Armor of the Gods", type: "armor", attack_bonus: 5, hp_bonus: 100, description: "Divine armor blessed by the gods", icon: "bi-shield", rarity: "epic", drop_weight: 1},

    # Epic accessories
    %{name: "Ring of Power", type: "accessory", attack_bonus: 10, hp_bonus: 50, description: "A ring of unimaginable power", icon: "bi-gem", rarity: "epic", drop_weight: 1}
  ]

  for attrs <- items do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert!()
  end

  IO.puts("#{length(items)} items created!")
else
  IO.puts("Items already exist, skipping seed.")
end
