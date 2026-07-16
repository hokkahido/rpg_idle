# ⚔ RpgIdle — Text-Based Idle RPG / Auto-Battler

Game bergenre *Text-Based Idle RPG / Auto-Battler* berbasis **Elixir + Phoenix LiveView** dengan visualisasi karakter dinamis di browser.

## ✨ Fitur

- **Database Permanen** (PostgreSQL + Ecto) — 4 tabel: characters, items, character_items. Auto-save saat masuk dungeon, keluar, atau mati
- **Combat Loop di Memori** (Elixir GenServer) — Setiap dungeon berjalan di proses independen, tick otomatis setiap 500ms
- **Real-time Animasi CSS** — Karakter bernafas (`:idle`), meluncur maju (`:attacking`), gempar merah (`:hit`)
- **Loot Drop & Equipment** — 24 item: senjata, armor, aksesoris. Rarity: common → uncommon → rare → epic
- **Inventory & Equip System** — Klik **Pakai** untuk equip, **Lepas** untuk ganti. Bonus stats langsung terlihat di ATK dan Max HP
- **Respawn Otomatis** — Hero mati? Tinggal klik **Masuk Dungeon** lagi, GenServer restart otomatis tanpa refresh
- **Total Stats Display** — ATK menampilkan total (base + equipment bonus) dengan indikator hijau
- **Dark Mode RPG** — Gradien gelap dengan aksen emas, pixel art via DiceBear, Bootstrap Icons

## 🚀 Cara Menjalankan

```bash
# 1. Masuk ke direktori proyek
cd C:/Coding/Elixir/rpg_idle

# 2. Install dependencies + setup database + seed karakter default
mix setup

# 3. Jalankan server
mix phx.server
```

Buka **http://localhost:4000/game** di browser.

> Jika port 4000 sudah dipakai, matikan proses lama:
> ```powershell
> Get-Process -Id (Get-NetTCPConnection -LocalPort 4000).OwningProcess | Stop-Process -Force
> ```

## 🎮 Cara Bermain

1. Buka halaman **/game** — karakter "Hero" (Knight) sudah tersedia
2. Klik **"Masuk Dungeon"** — GenServer menyala, combat loop berjalan otomatis
3. Karakter dan monster saling serang setiap 0.5 detik
4. Kalahkan monster → dapat EXP, Gold, dan **item drop** (senjata/armor/aksesoris)
5. Buka **Inventory** di kartu karakter → klik **"Pakai"** untuk equip item → ATK & Max HP naik
6. Level up (ATK +3, MaxHP +10) — stats base bertambah, equipment bonus tetap
7. Klik **"Keluar Dungeon"** atau mati → auto-save ke database. Bisa langsung masuk lagi tanpa refresh!

## 🏗️ Struktur Proyek

```
lib/
├── rpg_idle/
│   ├── character.ex              # Ecto schema + stat calculator
│   ├── character_item.ex         # Join table character ↔ item
│   ├── item.ex                   # Ecto schema item (senjata/armor/aksesoris)
│   ├── game/
│   │   └── dungeon_server.ex     # GenServer combat loop + loot drop
│   └── application.ex            # Supervisor tree + Registry
└── rpg_idle_web/
    ├── live/
    │   └── game_live.ex          # LiveView halaman game + inventory
    ├── router.ex                 # Route /game
    └── components/layouts/
        └── root.html.heex        # Layout + Bootstrap Icons
assets/css/app.css                # Animasi CSS RPG
priv/repo/
├── seeds.exs                     # Seed karakter + 24 items
└── migrations/                   # 4 migration files
```

## 🛠️ Teknologi

| Teknologi | Kegunaan |
|-----------|----------|
| **Elixir 1.20** | Bahasa pemrograman fungsional |
| **Phoenix 1.8** | Web framework |
| **Phoenix LiveView** | Real-time UI tanpa JavaScript |
| **Ecto + PostgreSQL** | Database ORM |
| **daisyUI 5 + Tailwind 4** | Komponen UI dark mode |
| **Bootstrap Icons** | Ikon game (sword, shield, coin, potion) |
| **DiceBear** | Pixel art avatar generator |
| **GenServer** | Combat loop di memori |

## 🧪 Development

```bash
mix compile --warnings-as-errors   # Cek kompilasi
mix test                           # Jalankan test
mix ecto.migrate                   # Jalankan migration
mix run priv/repo/seeds.exs        # Seed ulang data
```

## 📄 Lisensi

MIT
