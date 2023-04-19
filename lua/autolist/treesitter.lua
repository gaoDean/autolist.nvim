local M = {}

function M:new(buf, win)
  local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
  local ok, parser = pcall(vim.treesitter.get_parser, buf, ft, {})
  if not ok then
    return nil
  end
  local instance = {}
  setmetatable(instance, self)
  self.__index = self
  self.parser = parser ---@type LanguageTree
  self.buf = buf ---@type number
  self.win = win ---@type number
  return instance
end

function M:node_under_cursor()
  local cursor = vim.api.nvim_win_get_cursor(self.win)
  local root = self.parser:parse()[1]:root()
  return root:named_descendant_for_range(cursor[1] - 1, cursor[2] - 1, cursor[1] - 1, cursor[2])
end

function M:is_in_markdown_code_fence()
  local ok, current_node = pcall(M.node_under_cursor, self)
  if not ok then
    return nil
  end

  local node = current_node
  while node ~= nil and node:type() ~= 'code_fence_content' and node:type() ~= 'fenced_code_block' do
    node = node:parent()
  end

  return node ~= nil and (node:type() == 'code_fence_content' or node:type() == 'fenced_code_block')
end

return M
