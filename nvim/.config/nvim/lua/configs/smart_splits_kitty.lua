local M = {}

function M.setup()
  local kitty = require "smart-splits.mux.kitty"
  local owner = tostring(vim.fn.getpid())
  local context
  local suspended = false
  local checking = false
  local tracked_once = false
  local inherited = { socket = vim.env.KITTY_LISTEN_ON, window = vim.env.KITTY_WINDOW_ID }

  local function mark(target, enabled)
    if not target then
      return
    end
    local match = "id:" .. target.window
    if not enabled then
      match = match .. " and var:IS_NVIM=^" .. owner .. "$"
    end
    vim.system({ "kitty", "@", "--to", target.socket, "set-user-vars", "--match", match,
      enabled and "IS_NVIM=" .. owner or "IS_NVIM" })
  end

  local function apply(current)
    if suspended then
      return
    end
    if context and (not current or context.socket ~= current.socket or context.window ~= current.window) then
      mark(context, false)
      context = nil
    end
    vim.env.KITTY_LISTEN_ON = current and current.socket or nil
    vim.env.KITTY_WINDOW_ID = current and current.window or nil
    if current and not context then
      context = current
      mark(context, true)
      kitty.update_mux_layout_details()
    end
  end

  local function refresh()
    if suspended or checking then
      return
    end
    if not vim.env.ZMX_SESSION then
      apply(inherited)
      return
    end
    checking = true
    vim.system({ "zmx", "print-env", vim.env.ZMX_SESSION }, { text = true }, vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        checking = false
        apply(nil)
        return
      end
      local tracked = {}
      for key, value in result.stdout:gmatch("([^=\n]+)=([^\n]*)") do
        tracked[key] = value
      end
      if tracked.KITTY_LISTEN_ON and tracked.KITTY_WINDOW_ID then
        tracked_once = true
        checking = false
        apply({ socket = tracked.KITTY_LISTEN_ON, window = tracked.KITTY_WINDOW_ID })
      elseif not tracked_once and inherited.socket and inherited.window then
        -- Older sessions may predate ZMX_TRACK_ENV. Only reuse inherited
        -- identity while that exact window still hosts this zmx client.
        vim.system({ "kitty", "@", "--to", inherited.socket, "ls", "--match", "id:" .. inherited.window },
          { text = true }, vim.schedule_wrap(function(list)
            checking = false
            local attached = false
            if list.code == 0 then
              for _, os_window in ipairs(vim.json.decode(list.stdout)) do
                for _, tab in ipairs(os_window.tabs) do
                  for _, window in ipairs(tab.windows) do
                    for _, process in ipairs(window.foreground_processes) do
                      local argv = process.cmdline
                      if argv[1] and vim.fs.basename(argv[1]) == "zmx" then
                        attached = vim.tbl_contains(argv, vim.env.ZMX_SESSION) or attached
                      end
                    end
                  end
                end
              end
            end
            apply(attached and inherited or nil)
          end))
      else
        checking = false
        apply(nil)
      end
    end))
  end

  kitty.is_in_session = function()
    refresh()
    return context ~= nil
  end
  kitty.on_init = function()
    suspended = false
    refresh()
  end
  kitty.on_exit = function()
    suspended = true
    mark(context, false)
    context = nil
  end
  -- Upstream's helper returns stdout first and the exit status second.
  kitty.resize_pane = function(direction, amount)
    if not kitty.is_in_session() then
      return false
    end
    local result = vim.system({ "kitty", "@", "--to", context.socket, "kitten",
      "--match", "id:" .. context.window, "relative_resize.py", direction, tostring(amount) }, { text = true }):wait()
    return result.code == 0
  end

  local group = vim.api.nvim_create_augroup("KittyAttachment", { clear = true })
  vim.api.nvim_create_autocmd({ "FocusGained", "VimResized" }, {
    group = group,
    callback = function()
      refresh()
    end,
  })
  if vim.env.ZMX_SESSION then
    -- Same-size reattachments do not necessarily generate a UI event.
    local timer = assert(vim.uv.new_timer())
    timer:start(1000, 1000, vim.schedule_wrap(refresh))
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = function()
        timer:stop()
        timer:close()
      end,
    })
  end
end

return M
