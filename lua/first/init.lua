local M = {}

NEXT = "next"
local PREV = "prev"
local default_last_command = {
  row = nil,
  dir = nil,
  search = nil,
}
M.last_command = default_last_command

local function get_next_index(line, search_char, col_index)
  local adj_index = col_index
  while adj_index > 1 and line:sub(adj_index, adj_index) ~= " " do
    adj_index = adj_index - 1
  end

  local right_line = line:sub(adj_index)
  local offset = #line - #right_line

  local index = nil
  for word in right_line:gmatch("%w+") do
    if word:sub(1, 1) == search_char then
      local offset2 = 0
      if #word == 1 then
        word = " " .. word
        offset2 = 1
      end
      index = right_line:find(word)
      if index ~= nil and index > col_index then
        return offset + index + offset2
      end
    end
  end
end

local function get_prev_index(line, search_char, col_index)
  local adj_index = col_index
  while adj_index < #line and line:sub(adj_index, adj_index) ~= " " do
    adj_index = adj_index + 1
  end

  local left_line = line:sub(1, adj_index)
  local rev_left_line = left_line:reverse()

  for rev_word in rev_left_line:gmatch("%w+") do
    if rev_word:sub(#rev_word) == search_char then
      if #rev_word == 1 then
        rev_word = " " .. rev_word
      end
      local index = rev_left_line:find(rev_word)
      if index ~= nil then
        local end_of_word = index + #rev_word - 1
        local jump_index = #left_line - end_of_word + 1
        if jump_index < col_index then
          return jump_index
        end
      end
    end
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

function M.delete_until()
  local motion = vim.fn.nr2char(vim.fn.getchar())

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
  M.delete_until()
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
