# Zhora Giveaway Script for FiveM

A powerful and easy-to-use giveaway script for FiveM servers running the ESX framework. This script allows administrators to create, manage, and announce giveaways for items, money, weapons, and vehicles through a modern and intuitive React-based UI.

## 📚 Disclaimer

This script is primarily a **learning project** that I've developed to improve my coding skills and understanding of FiveM development. I'm sharing it with the community to see if others find it useful and enjoyable to use. 

**Please note:**
- This is an educational resource created for learning purposes
- Feedback, suggestions, and constructive criticism are highly appreciated
- Feel free to use, modify, or learn from the code
- If you encounter any issues or have ideas for improvements, please let me know!

I hope this script can be helpful for your server or inspire you in your own FiveM development journey! 🚀

## 🎥 Preview & Demonstration

### 📋 Admin Panel Overview
[![Admin Panel Preview](https://streamable.com/j68w1x/mp4)](https://streamable.com/j68w1x)

*Click to watch the complete admin panel walkthrough*

### 🎮 Live Demonstration
[![Live Demo](https://streamable.com/xj7grw/mp4)](https://streamable.com/xj7grw)

*Click to see the giveaway system in action*

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
| `Config.AnnouncementSystem` | The announcement system to use. Options: `'ns_announce'`, `'chat'`, `'custom_event'`, `'custom_export'`. See [Customizing Announcements](#-customizing-announcements) for details |

## 📢 Customizing Announcements

The script supports multiple announcement systems to fit your server's setup. You can easily switch between them or add your own custom system.

### Available Systems

#### 🎯 ns_announce (Default)
Perfect for servers using the popular ns_announce script:

```lua
Config.AnnouncementSystem = 'ns_announce'
```

This system automatically uses the configured styles and sender names from your ns_announce setup.

#### 💬 Chat System
Simple fallback using standard chat messages with custom styling:

```lua
Config.AnnouncementSystem = 'chat'
```

Features:
- Custom HTML templates for styled messages
- Configurable prefixes
- Automatic fallback if other systems fail

#### ⚙️ Custom Event System
For servers with custom announcement scripts using events:

```lua
Config.AnnouncementSystem = 'custom_event'

-- Example configuration in Config.Announcements:
Config.Announcements.my_custom_system = {
    type = 'event',
    trigger = 'myServer:announce',  -- Your event name
    defaultTitle = "Server Announcement"
}
```

#### 📤 Custom Export System
For announcement scripts that use exports:

```lua
Config.AnnouncementSystem = 'custom_export'

-- Example configuration:
Config.Announcements.my_export_system = {
    type = 'export',
    resource = 'my_announce_script',     -- Resource name
    trigger = 'SendGlobalAnnouncement',  -- Export function name
    defaultTitle = "Important Notice"
}
```

### Adding Your Own System

1. **Define your system** in `Config.Announcements`:

```lua
Config.Announcements.my_system = {
    type = 'event',  -- or 'export'
    trigger = 'your_event_name',
    defaultTitle = "Custom Title",
    -- Add any custom parameters you need
}
```

2. **Set it as active**:

```lua
Config.AnnouncementSystem = 'my_system'
```

3. **Modify parameters** (if needed):
   - Edit the `SendAnnouncement` function in `server.lua`
   - Adjust parameter passing for your specific system's requirements

### Message Types

The system automatically handles different message types:
- **Info** - General giveaway announcements
- **Success** - Winner announcements  
- **Warning** - No participants notifications
- **Error** - Cancellation messages

Each type can have different styling based on your announcement system's capabilities.

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
