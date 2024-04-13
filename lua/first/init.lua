local M = {}

local NEXT = "next"
local PREV = "prev"
local default_last_command = {
  row = nil,
  dir = nil,
  search = nil,
}
M.last_command = default_last_command

local function get_next_index(line, search_char, col_index)
  local right_line = line:sub(col_index + 1)
  local offset = #line - #right_line

  local index = nil
  for word in right_line:gmatch("%w+") do
    if word:sub(1, 1) == search_char then
      index = right_line:find(word)
      if index ~= nil then
        return offset + index
      end
    end
  end
end

local function get_prev_index(line, search_char, col_index)
  local left_line = line:sub(1, col_index - 1)
  local rev_left_line = left_line:reverse()

  for rev_word in rev_left_line:gmatch("%w+") do
    if rev_word:sub(#rev_word) == search_char then
      local index = rev_left_line:find(rev_word)
      if index ~= nil then
        local end_of_word = index + #rev_word - 1
        return #left_line - end_of_word + 1
      end
    end
  end
end

function M.jump_to_next()
  local search_key = vim.fn.getchar()
  local search_key_str = vim.fn.nr2char(search_key)
  local line = vim.fn.getline(".")
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
  local line = vim.fn.getline(".")
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

  local line = vim.fn.getline(".")
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

  local line = vim.fn.getline(".")
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

function M.setup(opts)
  opts = opts or {}

  if opts.use_default_keymap then
    vim.keymap.set("n", "f", "<cmd>lua require('first').jump_to_next()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", "F", "<cmd>lua require('first').jump_to_prev()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", ";", "<cmd>lua require('first').continue_jump_to_next()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", ",", "<cmd>lua require('first').continue_jump_to_prev()<cr>", { noremap = true, silent = true })
  end
end

return M
