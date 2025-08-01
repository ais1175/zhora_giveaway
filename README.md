# Zhora Giveaway Script for ESX

A powerful and easy-to-use giveaway script for FiveM servers running the ESX framework. This script allows administrators to create, manage, and announce giveaways for items, money, weapons, and vehicles through a modern and intuitive React-based UI.

## 📚 Disclaimer

This script is primarily a **learning project** that I've developed to improve my coding skills and understanding of FiveM development. I'm sharing it with the community to see if others find it useful and enjoyable to use. 

**Please note:**
- This is an educational resource created for learning purposes
- Feedback, suggestions, and constructive criticism are highly appreciated
- Feel free to use, modify, or learn from the code
- If you encounter any issues or have ideas for improvements, please let me know!

I hope this script can be helpful for your server or inspire you in your own FiveM development journey! 🚀

## ✨ Features

### 🎁 Versatile Giveaways
Create giveaways for a wide range of items, including:
- **Standard Items** (requires ox_inventory or standard ESX)
- **Cash** (money)
- **Black Money** (black_money)
- **Player Licenses**
- **Vehicles** (spawned directly into the player's garage)

### 🔄 Dynamic Item List
The admin panel automatically fetches and populates the item list for giveaways directly from your configured inventory system. It seamlessly pulls from ox_inventory exports or your ESX items database table, ensuring all available items are ready to be gifted.

### 🖥️ Modern Admin Panel
A clean and responsive user interface built with React and Vite for easy management:
- Start new giveaways with customizable duration, winner count, and item quantity
- Manage a list of pre-configured giveaway items for quick and easy setup
- View a detailed history of past giveaways, including prizes and winners

### ⚙️ Flexible Configuration
- Easily configure admin roles, commands, and default giveaway settings
- Multi-language support (English and German included by default)
- Seamless integration with different announcement systems (ns_announce, chat, or custom events/exports)
- Customizable vehicle plate generation

### 🎮 Simple for Players
Players can join active giveaways with a single command (`/enter`).

### ⚡ Robust and Optimized
The script is designed for performance and reliability.

## 📋 Dependencies

- **ESX Framework** (tested with ESX Legacy)
- **oxmysql**
- **ox_inventory** (can be configured for standard ESX item handling)
- **Announcement script** like ns_announce is recommended for the best experience, but it can be configured to use the standard chat or other systems

## 🚀 Installation

1. **Download the Script**
   ```bash
   # Download the zhora_giveaway files and place them in your server's resources directory
   ```

2. **Edit config.lua**
   ```lua
   -- Open config.lua and adjust the settings to your liking
   -- Pay close attention to:
   -- Config.InventorySystem
   -- Config.AdminGroups
   -- Config.AnnouncementSystem
   ```

3. **Add to server.cfg**
   ```cfg
   ensure zhora_giveaway
   ```

4. **Restart Your Server**
   Restart your FiveM server for the changes to take effect.

## ⚙️ Configuration

The `config.lua` file is extensively commented to help you customize the script. Here are the key sections:

| Setting | Description |
|---------|-------------|
| `Config.Language` | Set the default language for the script (`'en'` or `'de'`) |
| `Config.InventorySystem` | Choose your inventory system. Supported: `'ox_inventory'`, `'esx'` |
| `Config.AdminGroups` | A list of ESX groups that are allowed to use the admin panel (e.g., `{'admin', 'superadmin'}`) |
| `Config.AdminCommand` | The command to open the giveaway admin panel (default: `'giveaway'`) |
| `Config.Prefix` | The prefix for generated vehicle license plates |
| `Config.DefaultGiveawayDurationMinutes` | The default duration for a giveaway in minutes |
| `Config.DefaultMaxWinners` | The default number of winners for a giveaway |
| `Config.AnnouncementSystem` | The announcement system to use. Options: `'ns_announce'`, `'chat'`, `'custom_event'`, `'custom_export'` |

## 🎮 Usage

### Player Commands
- `/enter` - Enters the currently active giveaway

### Admin Commands
- `/giveaway` (or your configured `Config.AdminCommand`) - Toggles the admin panel
- `/cancelgiveaway` - Cancels the currently active giveaway

## 🖥️ Admin Panel

The admin panel is divided into three tabs:

### 📝 Start Giveaway
- Select a pre-configured item from the dropdown
- Set the quantity (if applicable), duration, and number of winners
- Click "Start & Announce Giveaway" to begin

### 🔧 Manage Items
- Create new giveaway item templates for easy reuse
- Define the item type (item, money, vehicle, etc.), a display label, and the technical name/spawn code
- Edit or delete existing item definitions

### 📊 History
- View a log of all past giveaways
- See the prize, the date, and who won

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](../../issues).

## ⭐ Show your support

Give a ⭐️ if this project helped you!
