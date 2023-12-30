local utils = require("autolist.utils")
local config = require("autolist.config")

local fn = vim.fn
local pat_checkbox = "^%s*%S+%s%[.%]"
local pat_colon = ":%s*$"
local checkbox_filled_pat = config.checkbox.left
.. config.checkbox.fill
.. config.checkbox.right
local checkbox_empty_pat = config.checkbox.left .. " " .. config.checkbox.right
-- filter_pat() removes the % signs
local checkbox_filled = utils.get_percent_filtered(checkbox_filled_pat)
local checkbox_empty = utils.get_percent_filtered(checkbox_empty_pat)

local new_before_pressed = false
local next_keypress = ""
local edit_mode = "n"

local M = {}

local function press(key, mode)
  if not key or key == "" then return end
  local parsed_key = vim.api.nvim_replace_termcodes(key, true, true, true)
  if mode == "i" then
    -- Another option is `vim.cmd.normal({ "i" .. parsed_key, bang = true })`
    vim.api.nvim_feedkeys(parsed_key, 'n', true)
  else
    vim.cmd.normal({ parsed_key, bang = true })
  end
end

-- returns the correct lists for the current filetype
local function get_lists()
  -- each table in filetype lists has the key of a filetype
  -- each value has the tables (of lists) that it is assigned to
  return config.lists[vim.bo.filetype]
end

-- recalculates the current list scope
function M.recalculate(override_start_num)
  -- the var base names: list and line
  -- x is the actual line (fn.getline)
  -- x_num is the line number (fn.line)
  -- x_indent is the indent of the line (utils.get_indent_lvl)

  local types = get_lists()
  local list_start_num
  local reset_list
  if override_start_num then
    list_start_num = override_start_num
  else
    list_start_num = utils.get_list_start(fn.line("."), types)
    reset_list = 0
  end
  if not list_start_num then return end -- returns nil if not ordered list
  if reset_list then
    local next_num = list_start_num + reset_list
    local nxt = fn.getline(next_num)
    if utils.is_ordered(nxt) then
      fn.setline(next_num, utils.set_ordered_value(nxt, 1))
    end
  end
  local list_start = fn.getline(list_start_num)
  local list_indent = utils.get_indent_lvl(list_start)

  local target = utils.get_value_ordered(list_start) + 1 -- start plus one
  local linenum = list_start_num + 1
  local line = fn.getline(linenum)
  local line_indent = utils.get_indent_lvl(line)
  local prev_indent = -1

  while
    line_indent >= list_indent
    and linenum < list_start_num + config.list_cap
    do
    if utils.is_list(line, types) then
      if line_indent == list_indent then
        local val = utils.set_ordered_value(list_start, target)
        utils.set_line_marker(
          linenum,
          utils.get_marker(val, types),
          types
        )
        target = target + 1 -- only increase target if increased list
        prev_indent = -1 -- escaped the child list
      elseif
        line_indent ~= prev_indent -- small difference between var names
        and line_indent == list_indent + config.tabstop
      then
        -- this part recalculates a child list with recursion
        -- the prev_indent prevents it from recalculating multiple times.
        -- the first time this runs, linenum is the first entry in the list
        M.recalculate(linenum)
        prev_indent = line_indent -- so you don't repeat recalculate()
      end
    else
      return
    end
    -- do these at the end so it can check it at the start of the loop
    linenum = linenum + 1
    line = fn.getline(linenum)
    line_indent = utils.get_indent_lvl(line)
  end
end

function M.new_bullet_before()
  return M.new_bullet(true)
end

local function get_bullet_from(line, pattern)
  local matched_bare = line:match("^%s*"
    .. pattern
    .. "%s*") -- only bullet, no checkbox
  local matched_with_checkbox = line:match("^%s*"
    .. pattern
    .. "%s*"
    .. "%[.%]"
    .. "%s*") -- bullet and checkbox

  return matched_with_checkbox or matched_bare
end

local function is_in_code_fence()
  -- check if Treesitter parser is installed, and if so, check if we're in a markdown code fence
  local parser = require('autolist.treesitter')
    :new(vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win())
  return parser and parser:is_in_markdown_code_fence()
end

local function find_suitable_bullet(line, filetype_lists, del_above)
  -- ipairs is used to optimise list_types (and say who has priority)
  for i, filetype_specific_pattern in ipairs(filetype_lists) do
    local bullet = get_bullet_from(line, filetype_specific_pattern)

    if bullet then
      if string.len(line) == string.len(bullet) then
        -- empty bullet, delete it
        fn.setline(fn.line(".") - (del_above and 1 or -1), "")
        utils.reset_cursor_column()
        return nil
      end
      return bullet
    end
  end
end


function M.new_bullet(prev_line_override)
  local filetype_lists = get_lists()
  if not filetype_lists then return nil end
  if is_in_code_fence() then return nil end

  -- if new_bullet_before, prev_line should be the line below
  local prev_line = fn.getline(fn.line(".") + (prev_line_override and 1 or -1))
  local cur_line = fn.getline(".")
  local bullet = find_suitable_bullet(prev_line,
    filetype_lists,
    not prev_line_override)
  bullet = bullet and utils.get_ordered_add(bullet, 1) -- add 1 if ordered list

  if prev_line:match(pat_colon)
    and (config.colon.indent_raw
    or (bullet and config.colon.indent)) then
    bullet = config.tab .. prev_line:match("^%s*") .. config.colon.preferred .. " "
  end

  if bullet then -- insert bullet
    utils.set_current_line(bullet .. cur_line:gsub("^%s*", "", 1))
  end
end

-- othewise it runs too fast and feedkeys doesn't register commands
local function run_recalculate_after_delay()
  vim.loop.new_timer():start(0, 0, vim.schedule_wrap(function()
    M.recalculate()
  end))
end

local function handle_indent(before, after)
  local cur_line = fn.getline(".")
  local filetype_lists = get_lists()
  local in_list = utils.is_list(cur_line, filetype_lists)
  local at_line_end = fn.getpos(".")[3] - 1 == string.len(cur_line) -- cursor on last char of line

  if in_list and at_line_end then
    press(after, "i")
  else
    press(before, "i")
  end
end

function M.shift_tab()
  handle_indent("<s-tab>", "<c-d>")
end

function M.tab()
  handle_indent("<tab>", "<c-t>")
end

local function checkbox_is_filled(line)
  if line:match(checkbox_filled_pat) then
    return true
  elseif line:match(checkbox_empty_pat) then
    return false
  end
end

function M.toggle_checkbox()
  local cur_line = fn.getline(".")
  local filled = checkbox_is_filled(cur_line)
  if filled == true then
    -- replace current line's empty checkbox with filled checkbox
    fn.setline(".", (cur_line:gsub(checkbox_filled_pat, checkbox_empty, 1)))
    -- it is a checkbox, but not empty
  elseif filled == false then
    -- replace current line's filled checkbox with empty checkbox
    fn.setline(".", (cur_line:gsub(checkbox_empty_pat, checkbox_filled, 1)))
  end
end

local function index_of(str, list)
  for i, v in ipairs(list) do
    if v == str then
      return i
    end
  end
end

local function cycle(cycle_backward)
  local filetype_lists = get_lists()
  local list_start = utils.get_indent_list_start(fn.line("."), filetype_lists)

  if not list_start then return nil end

  local current_bullet_type = utils.get_marker(fn.getline(list_start), filetype_lists)
  local stripped_bullet = utils.get_whitespace_trimmed(current_bullet_type)
  local index_in_cycle = index_of(stripped_bullet, config.cycle)

  if not index_in_cycle then return nil end

  local target_index = index_in_cycle + (cycle_backward and -1 or 1)

  print(target_index)
  if target_index > #config.cycle then target_index = 1 end
  if target_index <= 0 then target_index = #config.cycle end

  local target_bullet = config.cycle[target_index]

  utils.set_line_marker(list_start, target_bullet, filetype_lists)
  M.recalculate()
end


-- with dotrepeat
function M.cycle_next_dr(motion)
  if motion == nil then
    vim.o.operatorfunc = "v:lua.require'autolist'.cycle_next_dr"
    return "g@l"
  end
  for i = 1, vim.v.count1 do
    M.cycle_next()
  end
end

-- with dotrepeat
function M.cycle_prev_dr(motion)
  if motion == nil then
    vim.o.operatorfunc = "v:lua.require'autolist'.cycle_prev_dr"
    return "g@l"
  end
  for i = 1, vim.v.count1 do
    M.cycle_prev()
  end
end

function M.cycle_prev()
  cycle(true)
end

function M.cycle_next()
  cycle()
end

return M
