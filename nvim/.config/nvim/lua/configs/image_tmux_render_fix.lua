-- Workaround: snacks.nvim image rendering inside tmux.
--
-- Why this exists:
--   Snacks renders images with the Kitty Graphics Protocol, tunneled through
--   tmux via passthrough sequences. The images are associated with Unicode
--   placeholder cells on the (outer) terminal's screen.
--
--   Whenever Neovim redraws the whole screen — switching tab pages,
--   switching buffers, layout changes — tmux repaints the pane content
--   asynchronously, which wipes those cell<->image associations. Snacks only
--   re-places an image when its internal state changed
--   (`vim.deep_equal(state, self._state)` early-return in
--   `placement:update()`), so after a tab/buffer switch the image stays
--   broken until some unrelated event forces a state change.
--
--   Without tmux this never happens, because Neovim writes the cells and the
--   placement request in one ordered flush. tmux breaks that ordering.
--
-- Fix:
--   After every update of a visible placement, (re)arm a short-delay timer
--   that re-sends the tiny `a=p,U=1` placement request (no image data
--   re-transmit). By the time it fires, tmux has finished repainting the
--   pane, so the outer terminal re-associates the placeholder cells with the
--   image and it displays again.
--
--   Only active when nvim runs inside tmux and the terminal supports the
--   unicode-placeholder mode (kitty/ghostty).
local M = {}

local uv = vim.uv or vim.loop

local RE_PLACE_DELAY_MS = 200 -- tmux pane repaint is typically <16ms; be generous

local function patch()
  local ok, placement = pcall(require, "snacks.image.placement")
  if not ok then
    return false
  end
  if placement.__tmux_render_fix then
    return true -- already patched
  end

  local orig_update = placement.update

  function placement.update(self)
    orig_update(self)

    if not vim.env.TMUX then
      return
    end
    if self.hidden or not self:ready() or not self.img or not self.img.sent then
      return
    end
    local ok_term, terminal = pcall(require, "snacks.image.terminal")
    if not ok_term or not terminal.env() or not terminal.env().placeholders then
      return -- fallback (overlay) mode: nothing to re-associate
    end

    local state = self:state()
    if not state or #state.wins == 0 then
      return
    end

    -- (re)arm the delayed re-placement
    local timer = self._tmux_render_timer
    if timer and not timer:is_closing() then
      timer:stop()
    end
    timer = timer or uv.new_timer()
    self._tmux_render_timer = timer
    timer:start(RE_PLACE_DELAY_MS, 0, vim.schedule_wrap(function()
      if self:ready() and not self.hidden and vim.api.nvim_buf_is_valid(self.buf) then
        local st = self:state()
        if st and #st.wins > 0 then
          terminal.request({
            a = "p",
            U = 1,
            i = self.img.id,
            p = self.id,
            C = 1,
            c = st.loc.width,
            r = st.loc.height,
          })
        end
      else
        -- placement gone or hidden: release the timer
        if not timer:is_closing() then
          timer:close()
        end
        self._tmux_render_timer = nil
      end
    end))
  end

  placement.__tmux_render_fix = true
  return true
end

---@return boolean true if the patch is active
function M.setup()
  if patch() then
    return true
  end
  -- snacks.image.placement not loadable yet; retry once everything is loaded
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    once = true,
    callback = patch,
  })
  return false
end

return M
