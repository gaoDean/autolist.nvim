# autolist.nvim
Minimal automatic list continuation for ordered and unordered lists for neovim in lua

## Installation
Using vim-plug:
```
Plug 'gaoDean/autolist.nvim'
```

## Info
*Only works in insert mode, makes lists function similar to gui word processors.*

supports:
* ordered and unordered lists, continues the list when in insert mode and `Return` pressed
* autodeletes empty list entries with `Return` at the end of an empty entry
* indented lists with `<c-t>` and `<c-d>`
```
1. it supports numbered lists
2. auto increments the number on carrige return
	3. can indent, but won't renumber
	2. must do it manually
	3. might make a fork that does renumberings
	4. this repo is minimal version

- unordered
	- tab across with <c-t>
	- keeps the indent level on enter
	- <c-t> and <c-d> indents whole line, not just the text after the cursor
* detab with <c-d>
+ supports syms all markdown list markers (-+*)
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

inspired by [my gist](https://gist.github.com/gaoDean/288d01dfe64da66569fb6615c767e081)
which is in turn inspired by [this gist](https://gist.github.com/sedm0784/dffda43bcfb4728f8e90)
