local M = {}

function M.setup()
  vim.api.nvim_create_user_command("DiscordStatus", function()
    local status = require("discord").get_status()
    print("Discord rich presence status: " .. status)
  end, { desc = "Get the status of the Discord rich presence" })

  vim.api.nvim_create_user_command("DiscordStart", function()
    require("discord").start()
    print("Discord rich presence started")
  end, { desc = "Start the Discord rich presence" })

  vim.api.nvim_create_user_command("DiscordShutdown", function()
    require("discord").shutdown()
    print("Discord rich presence shutdown")
  end, { desc = "Shutdown the Discord rich presence" })
end

return M