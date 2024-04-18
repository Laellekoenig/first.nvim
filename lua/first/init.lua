local M = {}

NEXT = "next"
local PREV = "prev"
local default_last_command = {
  row = nil,
  dir = nil,
  search = nil,
}
M.last_command = default_last_command

local function get_word_list(line, filter_fn)
  local words = {}
  local search_line = line

  for word in line:gmatch("%w+") do
    if filter_fn(word) then
      local index = string.find(search_line, word)
      if index ~= nil then
        index = index + #line - #search_line
        search_line = string.sub(search_line, index + #word, #line)
        table.insert(words, { word = word, index = index })
      end
    end
  end

  return words
end

local function get_next_index(line, search_char, col_index)
  local words = get_word_list(line, function(w) return string.sub(w, 1, 1) == search_char end)
  for _, word in ipairs(words) do
    if word.index > col_index then
      return word.index
    end
  end
end

local function get_prev_index(line, search_char, col_index)
  local words = get_word_list(line, function(w) return string.sub(w, 1, 1) == search_char end)
  local found = nil
  for _, word in ipairs(words) do
    if word.index >= col_index then
      break
    else
      found = word
    end
  end

  if found ~= nil then
    return found.index
  end
end

function M.jump_to_next()
  local search_key = vim.fn.getchar()
  local search_key_str = vim.fn.nr2char(search_key)
  local line = vim.api.nvim_get_current_line()
  local col_index = vim.fn.col(".")

  local new_index = get_next_index(line, search_key_str, col_index)
  if new_index ~= nil then
    vim.fn.cursor(vim.fn.line("."), new_index)
    M.last_command = {
      row = vim.fn.line("."),
      dir = NEXT,
      search = search_key_str,
    }
  end
end

function M.jump_to_prev()
  local search_key = vim.fn.getchar()
  local search_key_str = vim.fn.nr2char(search_key)
  local line = vim.api.nvim_get_current_line()
  local col_index = vim.fn.col(".")

  local new_index = get_prev_index(line, search_key_str, col_index)
  if new_index ~= nil then
    vim.fn.cursor(vim.fn.line("."), new_index)
    M.last_command = {
      row = vim.fn.line("."),
      dir = PREV,
      search = search_key_str,
    }
  end
end

function M.continue_jump_to_next()
  if vim.fn.line(".") ~= M.last_command.row then
    M.last_command = default_last_command
    return
  end

  local line = vim.api.nvim_get_current_line()
  local col_index = vim.fn.col(".")

  local new_index = nil
  if M.last_command.dir == NEXT then
    new_index = get_next_index(line, M.last_command.search, col_index)
  elseif M.last_command.dir == PREV then
    new_index = get_prev_index(line, M.last_command.search, col_index)
  else
    M.last_command = default_last_command
  end

  if new_index ~= nil then
    vim.fn.cursor(vim.fn.line("."), new_index)
  end
end

function M.continue_jump_to_prev()
  if vim.fn.line(".") ~= M.last_command.row then
    M.last_command = default_last_command
    return
  end

  local line = vim.api.nvim_get_current_line()
  local col_index = vim.fn.col(".")

  local new_index = nil
  if M.last_command.dir == NEXT then
    new_index = get_prev_index(line, M.last_command.search, col_index)
  elseif M.last_command.dir == PREV then
    new_index = get_next_index(line, M.last_command.search, col_index)
  else
    M.last_command = default_last_command
  end

  if new_index ~= nil then
    vim.fn.cursor(vim.fn.line("."), new_index)
  end
end

function M.delete_until(m)
  local motion = m or vim.fn.nr2char(vim.fn.getchar())

  if motion == "f" then
    local target = vim.fn.nr2char(vim.fn.getchar())
    local line = vim.api.nvim_get_current_line()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local to_delete = get_next_index(line, target, cursor[2] + 1)

    if to_delete == nil then
      return
    end

    local new_line = string.sub(line, 1, cursor[2]) .. string.sub(line, to_delete + M._forward_delete_offset)
    vim.api.nvim_set_current_line(new_line)
    return
  end

  if motion == "F" then
    local target = vim.fn.nr2char(vim.fn.getchar())
    local line = vim.api.nvim_get_current_line()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local to_delete = get_prev_index(line, target, cursor[2] - 1)

    if to_delete == nil then
      return
    end

    local new_line = nil
    if to_delete == 1 then
      new_line = string.sub(line, cursor[2] + 1)
    else
      new_line = string.sub(line, 1, to_delete - M._backward_delete_offset - 1) .. string.sub(line, cursor[2] + 1)
    end

    local diff = #line - #new_line
    vim.api.nvim_set_current_line(new_line)
    vim.api.nvim_win_set_cursor(0, { cursor[1], cursor[2] - diff })

    return
  end

  if motion == "i" or motion == "t" or motion == "a" or motion == "g" then
    local target = vim.fn.nr2char(vim.fn.getchar())
    vim.keymap.del("n", "d", {})
    vim.api.nvim_feedkeys("d" .. motion .. target, "nx", true)
    vim.keymap.set("n", "d", "<cmd>lua require('first').delete_until()<cr>", { noremap = true, silent = true })
    return
  end

  vim.keymap.del("n", "d", {})
  vim.api.nvim_feedkeys("d" .. motion, "nx", true)
  vim.keymap.set("n", "d", "<cmd>lua require('first').delete_until()<cr>", { noremap = true, silent = true })
end

function M.change_until()
  local motion = vim.fn.nr2char(vim.fn.getchar())

  if motion == "c" then
    vim.keymap.del("n", "c", {})
    vim.api.nvim_feedkeys("cc", "nx", true)
    vim.keymap.set("n", "c", "<cmd>lua require('first').change_until()<cr>", { noremap = true, silent = true })
  end

  M.delete_until(motion)
  vim.cmd.startinsert()
end

function M.setup(opts)
  M.opts = opts or {
    use_default_keymap = true,
    use_delete_and_change = true,
    inclusive_forward_delete = false,
    inclusive_backward_delete = true,
  }

  if M.opts.inclusive_forward_delete then
    M._forward_delete_offset = 1
  else
    M._forward_delete_offset = 0
  end

  if not M.opts.inclusive_backward_delete then
    M._backward_delete_offset = 0
  else
    M._backward_delete_offset = 1
  end

  if M.opts.use_default_keymap then
    vim.keymap.set("n", "f", "<cmd>lua require('first').jump_to_next()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", "F", "<cmd>lua require('first').jump_to_prev()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", ";", "<cmd>lua require('first').continue_jump_to_next()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", ",", "<cmd>lua require('first').continue_jump_to_prev()<cr>", { noremap = true, silent = true })
    if M.opts.use_delete_and_change then
      vim.keymap.set("n", "d", "<cmd>lua require('first').delete_until()<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "c", "<cmd>lua require('first').change_until()<cr>", { noremap = true, silent = true })
    end
  end
end

return M
