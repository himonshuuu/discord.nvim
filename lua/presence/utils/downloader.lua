local M = {}

local uv = vim.loop
local platform = require("presence.platform.system")

function M.get_binary_name()
  local os_name = platform.get_os()
  local arch = platform.get_arch()
  
  if os_name == "linux" then
    if platform.is_arm64() then
      return "presenced-linux-arm64"
    else
      return "presenced-linux-amd64"
    end
  elseif os_name == "darwin" then
    if platform.is_arm64() then
      return "presenced-darwin-arm64"
    else
      return "presenced-darwin-amd64"
    end
  elseif os_name == "windows" then
    return "presenced-windows-amd64.exe"
  end
  
  return "presenced-linux-amd64"
end

function M.get_binary_path()
  local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ":p:h:h:h:h")
  local bin_name = M.get_binary_name()
  return plugin_root .. "/bin/" .. bin_name
end

function M.get_plugin_root()
  return vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ":p:h:h:h:h")
end

function M.download_binary()
  local bin_name = M.get_binary_name()
  local bin_path = M.get_binary_path()
  local plugin_root = M.get_plugin_root()
  
  vim.fn.mkdir(plugin_root .. "/bin", "p")
  
  local url = "https://github.com/himonshuuu/presence.nvim/releases/latest/download/" .. bin_name
  
  vim.notify("presence.nvim: Downloading binary from GitHub releases...", vim.log.levels.INFO)
  
  local handle = uv.spawn("curl", {
    args = { "-L", "-o", bin_path, url },
    stdio = { nil, nil, nil }
  }, function(code)
    if code == 0 then
      uv.fs_chmod(bin_path, tonumber("755", 8), function(err)
        if err then
          vim.schedule(function()
            vim.notify("presence.nvim: Failed to make binary executable: " .. err, vim.log.levels.ERROR)
          end)
        else
          vim.schedule(function()
            vim.notify("presence.nvim: Binary downloaded successfully!", vim.log.levels.INFO)
          end)
        end
      end)
    else
      vim.schedule(function()
        vim.notify("presence.nvim: Failed to download binary. Falling back to local build.", vim.log.levels.WARN)
        M.build_binary_locally()
      end)
    end
  end)
end

function M.build_binary_locally()
  local plugin_root = M.get_plugin_root()
  
  local build_handle = uv.spawn("make", {
    args = { "build" },
    cwd = plugin_root,
    stdio = { nil, nil, nil }
  }, function(build_code)
    if build_code == 0 then
      vim.schedule(function()
        vim.notify("presence.nvim: Built binary locally successfully!", vim.log.levels.INFO)
      end)
    else
      vim.schedule(function()
        vim.notify("presence.nvim: Failed to build binary locally. Please install Go and run 'make build'.", vim.log.levels.ERROR)
      end)
    end
  end)
end

function M.ensure_binary_exists()
  local bin_path = M.get_binary_path()
  
  local stat = uv.fs_stat(bin_path)
  if not stat or stat.type ~= "file" then
    M.download_binary()
    return false
  end
  
  return true
end

return M
