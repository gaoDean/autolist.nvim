# autolist.nvim
Minimal automatic list continuation for ordered and unordered lists for neovim in lua

This is quite a new plugin, so expect lots of :PlugUpdates.

## Info
*Only works in insert mode, makes lists function similar to gui word processors.*

supports:
* ordered and unordered lists
* autodelete empty list entries
* indented lists with `<c-t>` and `<c-d>`
* creating new list entry with `o` key (newline key)
* enabling continuation for specific filetypes

Start an unordered list with an optional space, a dash and a space. Write the list contents and when you're done, press enter and a new dash will be created with a (optional space then a ) dash and a space. If you don't write anything after the dash and the space, it will carrige return and the last empty dash will be deleted.

Indent lists with <c-t> (tab) and <c-d> (detab), which will indent the whole line, not just the text after the cursor. When you detab, the dash will not have the optional space before it, just a tab, or if it is aligned to the very left, nothing before the dash.

Start an ordered list with an number, a dot and space, with the contents after the space. The auto ending of the list works the same as unordered list, when the contents is empty and you press enter, there will be a carrige return and the last empty list entry will be deleted.

Indenting works the same way, with the exception that this *will not* renumber the lists, you must do it manually.

## Installation
Using vim-plug:
```lua
local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.config/nvim/plugged')
	Plug 'gaoDean/autolist.nvim'

	-- or if you want peak minimalism
	Plug('gaoDean/autolist.nvim', { branch = 'min' })
vim.call('plug#end')
```
and
```lua
lua require('autolist').setup({})
-- not required with min branch
```

## Configuration
This is the default config:
```lua
require('autolist.nvim').setup({
	create_enter_mapping = true,
	-- for if you have something else that you want to map when press return
	-- with the create enter being false, you must create your own mapping

	new_entry_on_o = true,
	-- when key o pressed, new list entry. Enables fo-o.

	override_fo_o = true,
	-- if you don't use formatoptions o, set this to true
	-- it will disable fo-o for all filetypes except for enabled types.

	-- if you use any of the override options, you must remove any
	-- definitions of the overrided formatoptions, or put the require setup after the formatoptions defintition.

	override_fo_r = true,
	-- if you don't use formatoptions r, set this to true
	-- it will disable fo-r for all filetypes except for enabled types.

	enabled_filetypes = { "markdown", "text" },
	-- filetypes that this plugin is enabled for
	-- must put file name, not the extension
	-- if you are not sure of the name, just run :echo &filetype
})
```

## Credit

inspired by [my gist](https://gist.github.com/gaoDean/288d01dfe64da66569fb6615c767e081)
which is in turn inspired by [this gist](https://gist.github.com/sedm0784/dffda43bcfb4728f8e90)
