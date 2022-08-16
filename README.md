# autolist.nvim
Minimal automatic list continuation for ordered and unordered lists for neovim in lua


## Info
*Only works in insert mode, makes lists function similar to gui word processors.*

supports:
* ordered and unordered lists, continues the list when in insert mode and `Return` pressed
* autodeletes empty list entries with `Return` at the end of an empty entry
* indented lists with `<c-t>` and `<c-d>`
* creating new list entry with `o` key (newline key)
* enabling plugin for specific filetypes
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

## Installation
Using vim-plug:
```lua
Plug 'gaoDean/autolist.nvim'
```
and
```lua
lua require('autolist').setup({})
```

## Configuration
This is the default config:
```
require("autolist").setup({
	create_enter_mapping = true,
	-- for if you have something else that you want when you press enter
	-- with the create enter being false, you must create your own mapping
	new_entry_on_o = true,
	-- when key o pressed, new list entry
	override_fo_all_filetypes = false,
	-- override formatoptions for all filetypes
	-- what this does is au("Filetype", "*", "fo-=r") (same for fo-o)
	-- this means that if fo-r is enabled for current filetype, disable it
	-- if the current filetype is in the enabled filetypes list, enable the fo-r
	enabled_filetypes = { "markdown", "text" },
	-- filetypes that this plugin is enabled for
	-- must put file name, not the extension
	-- if you are not sure, just run :echo &filetype
})
```

## Credit

inspired by [my gist](https://gist.github.com/gaoDean/288d01dfe64da66569fb6615c767e081)
which is in turn inspired by [this gist](https://gist.github.com/sedm0784/dffda43bcfb4728f8e90)
