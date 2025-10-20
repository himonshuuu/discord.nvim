# discord.nvim

**Discord Rich Presence for Neovim** - Show what you're coding in Discord!

Event-driven Discord Rich Presence for Neovim with idle, viewing, and editing states. Displays your current file, cursor position, and coding activity in your Discord status.

## Features

- Zero Configuration - Works out of the box with automatic binary downloads
- Multi-Instance Support - Multiple Neovim instances work seamlessly  
- Smart Detection - Automatically detects file types and shows appropriate icons
- Fast & Lightweight - Minimal performance impact with debounced updates
- Cross-Platform - Works on Linux, macOS, and Windows
- Customizable - Configure symbols, states, and appearance
- Rich Information - Shows file name, cursor position, diagnostics, and more

## Quick Start

1. Install the plugin using your preferred plugin manager
2. Get your Discord Client ID from the [Discord Developer Portal](https://discord.com/developers/applications)
3. Configure the plugin in your Neovim config:

```lua
require('discord').setup({
  client_id = 'YOUR_DISCORD_CLIENT_ID',
})
```

4. Restart Neovim and start coding! Your Discord status will automatically update.

## Installation

### Prerequisites

- Neovim 0.7+
- Discord Desktop App (not web version)
- Internet connection (for initial binary download)

### Using Plugin Managers

**With lazy.nvim:**
```lua
{
  'himonshuuu/discord.nvim',
  event = 'VeryLazy', -- Optional: load on first use
  config = function()
    require('discord').setup({
      client_id = 'YOUR_DISCORD_CLIENT_ID',
    })
  end,
}
```

**With packer.nvim:**
```lua
use {
  'himonshuuu/discord.nvim',
  config = function()
    require('discord').setup({
      client_id = 'YOUR_DISCORD_CLIENT_ID',
    })
  end,
}
```

**With vim-plug:**
```vim
Plug 'himonshuuu/discord.nvim'
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/himonshuuu/discord.nvim.git ~/.local/share/nvim/site/pack/packer/start/discord.nvim

# Binary will be downloaded automatically on first use
```

## Configuration

### Basic Setup

```lua
require('discord').setup({
  client_id = 'YOUR_DISCORD_CLIENT_ID',  -- Required: Your Discord Application ID
})
```

### Advanced Configuration

```lua
require('discord').setup({
  -- Basic settings
  client_id = 'YOUR_DISCORD_CLIENT_ID',
  idle_timeout_ms = 5000,                -- Time before showing idle (default: 5000)
  show_timer = true,                     -- Show elapsed time (default: true)
  debounce_timeout_ms = 500,             -- Debounce updates (default: 500)
  log_level = 'info',                    -- Log level: debug, info, warn, error
  
  -- Custom symbols (for different states)
  symbols = {
    editing = 'E',      -- Custom editing symbol
    viewing = 'V',      -- Custom viewing symbol  
    idle = 'Z',         -- Custom idle symbol
    folder = 'D',       -- Custom folder symbol
    tree = 'T',         -- Custom tree symbol
  },
  
  -- Custom state text (what appears in Discord presence)
  states = {
    browsing = 'Exploring files',     -- Custom browsing text
    idle = 'Having a break',          -- Custom idle text
    editing = 'Writing code',         -- Custom editing text
    viewing = 'Reading code',         -- Custom viewing text
  },
})
```

### Minimal Configuration

```lua
require('discord').setup({
  symbols = {
    editing = 'E',
    viewing = 'V', 
    idle = 'Z',
    folder = 'D',
    tree = 'T',
  },
  
  states = {
    browsing = 'Browsing',
    idle = 'Idle',
    editing = 'Editing',
    viewing = 'Viewing',
  },
})
```

## Getting Your Discord Client ID

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application or select existing one
3. Copy the Application ID from the General Information tab
4. Use this ID in your configuration

> Note: Make sure your Discord application is not in development mode for production use.

## Commands

The plugin provides several commands for manual control:

```vim
:DiscordStatus    " Check if Discord presence is running
:DiscordStart     " Manually start Discord presence  
:DiscordShutdown  " Stop Discord presence
```

## How It Works

1. Automatic Binary Management: Downloads the correct binary for your platform from GitHub releases
2. Stdio Communication: Uses stdio pipes for efficient communication between Neovim and the daemon
3. Multi-Instance Support: Multiple Neovim instances work seamlessly
4. Debounced Updates: Prevents excessive Discord API calls with smart debouncing
5. Smart Detection: Automatically detects file types, cursor position, and coding activity

## Acknowledgments

This project was inspired by and builds upon the work of:

- [presence.nvim](https://github.com/andweeb/presence.nvim) - Original Discord Rich Presence for Neovim
- [coc-discord-rpc](https://github.com/leonardssh/coc-discord-rpc) - Discord RPC for Coc.nvim
- [discord-vscode](https://github.com/iCrawl/discord-vscode) - Discord Rich Presence for VS Code

Thank you to the maintainers and contributors of these projects.

## Development

### Building from Source

```bash
# Install dependencies
make deps

# Build for current platform
make build

# Build for all platforms
make build-all

# Clean build artifacts
make clean
```

### Testing

```bash
# Test with multiple Neovim instances
nvim file1.txt &
nvim file2.txt &
```

## Requirements

- Neovim 0.7+
- Discord Desktop App (not web version)
- Internet connection (for initial binary download)

## Troubleshooting

### Binary Download Issues

If automatic binary download fails:

1. Check Internet Connection: Ensure you have internet access
2. Manual Download: Download the binary manually from [GitHub Releases](https://github.com/himonshuuu/discord.nvim/releases)
3. Build from Source: Install Go and run `make build`

### Discord Not Showing Presence

1. Check Client ID: Ensure your Discord Application ID is correct
2. Discord Desktop: Make sure you're using Discord desktop app (not web version)
3. Application Status: Verify your Discord application is not in development mode
4. Check Logs: Use `log_level = 'debug'` to see detailed logs

### Multiple Instances

The plugin automatically handles multiple Neovim instances. The last active instance will show its presence in Discord.

### Performance Issues

If you experience performance issues:

1. Increase Debounce: Set `debounce_timeout_ms = 1000` or higher
2. Disable Timer: Set `show_timer = false`
3. Reduce Logging: Set `log_level = 'warn'` or `'error'`

## License

MIT License - see LICENSE file for details.