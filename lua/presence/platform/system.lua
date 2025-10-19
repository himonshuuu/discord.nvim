local M = {}

-- Platform detection utilities
function M.get_os()
  local os_name = vim.loop.os_uname().sysname:lower()
  return os_name
end

function M.get_arch()
  local arch = vim.loop.os_uname().machine:lower()
  return arch
end

function M.get_platform()
  return M.get_os() .. "/" .. M.get_arch()
end

function M.is_linux()
  return M.get_os() == "linux"
end

function M.is_darwin()
  return M.get_os() == "darwin"
end

function M.is_windows()
  return M.get_os() == "windows"
end

function M.is_arm64()
  local arch = M.get_arch()
  return arch:match("aarch64") or arch:match("arm64")
end

function M.is_amd64()
  local arch = M.get_arch()
  return arch:match("amd64") or arch:match("x86_64")
end

return M
