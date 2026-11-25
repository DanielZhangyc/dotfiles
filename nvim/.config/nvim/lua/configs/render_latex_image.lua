local M = {}
local configured = false

local function upvalue(fn, wanted)
  for index = 1, debug.getinfo(fn, "u").nups do
    local name, value = debug.getupvalue(fn, index)
    if name == wanted then
      return value
    end
  end
  error("image.nvim allocator changed: " .. wanted)
end

function M.setup()
  if configured then
    return
  end

  local image = require "image"
  local create_image = upvalue(require("image/image").from_file, "createImage")
  local Image = upvalue(create_image, "Image")
  local image_kitty = require "image/backends/kitty"
  local latex_kitty = require "render_latex.image_backends.kitty"
  local helpers = require "image/backends/kitty/helpers"
  local clear_image = image_kitty.clear
  local set_latex = latex_kitty.set
  local delete_latex = latex_kitty.del
  local latex_ids = {}
  local allocated = {}

  -- The pinned release has no allocator hook. Share image.nvim's allocator
  -- rather than letting the two Kitty backends reuse the same protocol IDs.
  local allocator_index
  for index = 1, debug.getinfo(set_latex, "u").nups do
    local name = debug.getupvalue(set_latex, index)
    if name == "generate_id" then
      allocator_index = index
      break
    end
  end
  assert(allocator_index, "render-latex Kitty allocator changed; review the pinned compatibility configuration")
  debug.setupvalue(set_latex, allocator_index, function()
    local id = Image.next_internal_id
    assert(id > 0 and id <= 4294967295, "Kitty image ID range exhausted")
    Image.next_internal_id = id + 1
    allocated[#allocated + 1] = id
    return id
  end)

  local function release(internal_id)
    helpers.write_graphics { action = "d", display_delete = "I", image_id = internal_id, quiet = 2 }
  end

  image_kitty.clear = function(id, shallow)
    if not id then
      for _, item in ipairs(image.get_images()) do
        image_kitty.clear(item.id, shallow)
      end
      return
    end

    local internal_id
    for _, item in ipairs(image.get_images()) do
      if item.id == id then
        internal_id = item.internal_id
        break
      end
    end
    clear_image(id, shallow)
    if internal_id and not shallow then
      release(internal_id)
    end
  end

  latex_kitty.set = function(data_or_id, opts)
    allocated = {}
    local id = set_latex(data_or_id, opts)
    if type(data_or_id) == "string" then
      assert(#allocated == 2, "render-latex Kitty allocation changed")
      latex_ids[id] = allocated[1]
    end
    return id
  end

  latex_kitty.del = function(id)
    if id == math.huge then
      local ids = vim.tbl_keys(latex_ids)
      for _, owned_id in ipairs(ids) do
        latex_kitty.del(owned_id)
      end
      return #ids > 0
    end

    local internal_id = latex_ids[id]
    local removed = delete_latex(id)
    if internal_id then
      release(internal_id)
      latex_ids[id] = nil
    end
    return removed or internal_id ~= nil
  end

  configured = true
end

return M
