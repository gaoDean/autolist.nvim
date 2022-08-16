# autolist.nvim
Minimal automatic list continuing for ordered and unordered lists for neovim in lua

supports:
* ordered and unordered
* autodeletes empty list entries
* indented lists with `<c-t>` and `<c-d>`
```
1. it supports numbered
2. auto increments the number
	3. can indent, but won't renumber
	2. must do it manually
	3. might make a fork that does renumberings
	4. this repo is minimal version

- unordered
	- tab across with <c-t>
	- keeps the indent level
	- <c-t> and <c-d> indents whole line
* detab with <c-d>
+ supports syms "-+*"
+ pretend this text isn't here, if enter is pressed this line would be empty
```

doesn't support:
* renumbering of lists

side effects:
* overrides the comment variable

todo:
```lua
	if vim.bo.filetype ~= "markdown" and vim.bo.filetype ~= "txt" then
		return
	end
```
