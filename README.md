# discord.nvim

Event-driven Discord Rich Presence for Neovim with idle, viewing, and editing states.

## Features

- 🚀 **Zero Configuration** - Works out of the box with automatic binary downloads
- 🔄 **Multi-Instance Support** - Multiple Neovim instances work seamlessly
- 🎯 **Smart Detection** - Automatically detects file types and shows appropriate icons
- ⚡ **Fast & Lightweight** - Minimal performance impact
- 🛠️ **Cross-Platform** - Works on Linux, macOS, and Windows

## Installation

### Using Plugin Managers

**With lazy.nvim:**
```lua
{
  'himonshuuu/discord.nvim',
  -- No build step needed - binary downloads automatically!
}
```

**With packer.nvim:**
```lua
use 'himonshuuu/discord.nvim'
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

```lua
require('presence').setup({
  client_id = 'YOUR_DISCORD_CLIENT_ID',  -- Required: Your Discord Application ID
  idle_timeout_ms = 60000,               -- Optional: Time before showing idle (default: 60000)
  show_timer = true,                     -- Optional: Show elapsed time (default: true)
})
```

## Getting Your Discord Client ID

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application or select existing one
3. Copy the Application ID from the General Information tab
4. Use this ID in your configuration

## How It Works

1. **Automatic Binary Management**: The plugin automatically downloads the correct binary for your platform from GitHub releases
2. **Socket Communication**: Uses UNIX domain sockets for efficient communication between Neovim and the daemon
3. **Multi-Instance Support**: Multiple Neovim instances can run simultaneously without conflicts
4. **Smart Fallbacks**: If binary download fails, falls back to local build (requires Go)

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
- Discord desktop application
- Internet connection (for initial binary download)

## Troubleshooting

### Binary Download Issues

If automatic binary download fails:

1. **Check Internet Connection**: Ensure you have internet access
2. **Manual Download**: Download the binary manually from [GitHub Releases](https://github.com/himonshuuu/discord.nvim/releases)
3. **Build from Source**: Install Go and run `make build`

### Discord Not Showing Presence

1. **Check Client ID**: Ensure your Discord Application ID is correct
2. **Discord Desktop**: Make sure you're using Discord desktop app (not web version)
3. **Application Status**: Verify your Discord application is not in development mode

### Multiple Instances

The plugin automatically handles multiple Neovim instances. The last active instance will show its presence in Discord.

## License

MIT License - see LICENSE file for details.