local M = {}
local configured = false

function M.setup()
  if configured then
    return
  end

  local image = require "image"
  local from_file = image.from_file
  local wrapped = setmetatable({}, { __mode = "k" })

  image.from_file = function(path, opts)
    local item = from_file(path, opts)
    if item and opts and opts.namespace == "markdown" and opts.with_virtual_padding and not wrapped[item] then
      local render = item.render
      item.render = function(self, geometry)
        local position = geometry or self.geometry
        self.render_offset_top = 1
        if vim.api.nvim_win_is_valid(self.window) and vim.api.nvim_buf_is_valid(self.buffer) then
          local row = position.y + 1
          local line = vim.api.nvim_buf_get_lines(self.buffer, row - 1, row, false)[1]
          if line then
            local first = vim.fn.screenpos(self.window, row, position.x + 1)
            local last = vim.fn.screenpos(self.window, row, #line)
            if first.row > 0 and last.row > 0 then
              -- Keep wrapped link text and one blank row above the image.
              self.render_offset_top = math.max(1, last.row - first.row + 1)
            end
          end
        end
        return render(self, geometry)
      end
      wrapped[item] = true
    end
    return item
  end

  configured = true
end

return M
