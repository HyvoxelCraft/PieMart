# PieMart — Minetest Market Mod

A full-featured player economy mod for Minetest 5.x+ featuring hosted markets,
PieCoin currency, an item exchange shop, and admin controls.

---

## Installation

1. Copy the `piemart/` folder into your Minetest world's `mods/` directory.
2. Enable `piemart` in your world's settings or `world.mt`.
3. Make sure the `default` mod is available (included in Minetest Game).

---

## Player Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `/bal` | `/bal` | Open a GUI showing your PieCoin balance |
| `/market` | `/market <market_name>` | Open a specific market to browse/buy items |
| `/market_list` | `/market_list` | Browse all markets; includes live search |
| `/pm_i` | `/pm_i <account> <market_name>` | List the item you're **holding** in a market. Sale proceeds go to `<account>` (can be yourself) |
| `/host_market` | `/host_market <name> <description>` | Create and host your own market (costs PieCoins) |
| `/del_mar` | `/del_mar <market_name>` | Delete a market you own; all listings are returned to sellers |
| `/exchange` | `/exchange` | Open the Exchange Shop to convert PieCoins into items |

---

## Admin Commands

Requires the `piemart_admin` privilege.

| Command | Usage | Description |
|---------|-------|-------------|
| `/set_value` | `/set_value <coins> <item_name>` | Set exchange rate: `<coins>` PieCoins = 1× `<item_name>` |
| `/set_mar_op` | `/set_mar_op <amount>` | Set the PieCoin cost to open a new market |
| `/give_coins` | `/give_coins <player> <amount>` | Give PieCoins to a player |
| `/take_coins` | `/take_coins <player> <amount>` | Remove PieCoins from a player |
| `/pm_bal` | `/pm_bal <player>` | Check any player's balance |
| `/pm_info` | `/pm_info <market_name>` | Detailed info about a market |

---

## Limitations & Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Max markets per player | **5** | Applies to everyone including admins |
| Cost to open a market | **1,500 ¢** | Changeable with `/set_mar_op` |
| Default exchange rate | **10 ¢ = 1 diamond** | More rates added via `/set_value` |
| Starting balance | **500 ¢** | Given to new players on first join |

---

## How to Sell Items

1. Hold the item you want to sell in your **hand** (wield slot).
2. Type `/pm_i <your_name> <market_name>`.
3. PieMart will ask you to type the price in chat.
4. Type the price (e.g. `250`) and press Enter.
5. Your item is now listed!

---

## How to Buy Items

1. Type `/market_list` to browse markets or `/market <name>` for a specific one.
2. Click **Buy** next to any listing.
3. PieCoins are deducted and the item goes to your inventory.

---

## Exchange Shop

The exchange shop lets players convert PieCoins into physical items:

```
/exchange
```

Admins set rates with `/set_value`:
```
/set_value 10 default:diamond        → 10 coins = 1 diamond
/set_value 50 default:mese_crystal   → 50 coins = 1 mese crystal
/set_value 5  default:coal_lump      → 5 coins = 1 coal lump
```

---

## Privilege Setup

Grant admin access to a player:
```
/grant <playername> piemart_admin
```

In `singleplayer`, `piemart_admin` is granted automatically.

---

## File Structure

```
piemart/
├── init.lua        — Entry point, config, namespace, first-run setup
├── storage.lua     — Persistent data (balances, markets, rates)
├── economy.lua     — Transaction logic (buy, sell, exchange, host market)
├── gui.lua         — All formspec GUIs and field handlers
├── commands.lua    — All /command registrations
├── mod.conf        — Mod metadata and dependencies
└── README.md       — This file
```

---

## Dependencies

- `default` (required — for item definitions)
- `sfinv` or `unified_inventory` (optional — future inventory tab support)

---

## Notes

- All data is stored via `mod_storage` — it persists across server restarts.
- When a market is deleted, all listed items are returned to their original listers if they are online. Offline players' items are logged; consider extending with an unclaimed-items system.
- PieCoin amounts are always whole numbers (no fractions).

## credits 
- The mod is developed by under CodeX devlopment department ( multicraft and luanti )
- The creator of mod is Endvoxel 
- The mod tested by Mika's ( Our senior developer and tester ) , Endvoxel 

---
