---@class AutolistTsParser
local M = {}

---@param buf number current buffer
---@param win number current window
---@return AutolistTsParser|nil
function M.new(buf, win)
  local ft = vim.bo[buf].filetype
  if not ft or ft == "" then return nil end

  -- Explicitly check if the parser for this language is installed
  local has_parser, _ = pcall(vim.treesitter.language.add, ft)
  if not has_parser then return nil end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, ft, {})
  if not ok or not parser or parser:lang() ~= ft then
    return nil
  end
  local instance = setmetatable({
    parser = parser,
    buf = buf,
    win = win,
  }, M)
  M.__index = M
  return instance
end

---Get TS Node under cursor
---@return TSNode
function M:node_under_cursor()
  local cursor = vim.api.nvim_win_get_cursor(self.win)
  local root = self.parser:parse()[1]:root()
  return root:named_descendant_for_range(cursor[1] - 1, cursor[2] - 1, cursor[1] - 1, cursor[2])
end

---Check if current TS node is within a Markdown code fence
---@return boolean
function M:is_in_markdown_code_fence()
  if vim.bo[self.buf].filetype ~= 'markdown' then
    return false
  end

  local ok, current_node = pcall(M.node_under_cursor, self)
  if not ok then
    return false
  end

  local node = current_node
  while node ~= nil and node:type() ~= 'code_fence_content' and node:type() ~= 'fenced_code_block' do
    node = node:parent()
  end

  return node ~= nil and (node:type() == 'code_fence_content' or node:type() == 'fenced_code_block')
end

return M
