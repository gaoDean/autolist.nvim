# autolist.nvim
Minimal automatic list continuation for neovim, powered by lua

## Why autolist.nvim
This question can be interpreted in two ways. Why did I create autolist, and why you should use autolist.

<dl>
	<dt>Why did I create autolist?</dt>
	<dd>It sounds simple, but all I wanted was a minimal list continuation plugin in lua that makes lists function better. bullets.vim works, but it is written in vimscript and is more than a thousand lines long. Needless to say, I couldn't find one, so I decided to create my own.</dd>
	<dt>Why use autolist?</dt>
	<dd>autolist's main function file is less than 200 lines long, complete with comments and formatting. It strives to be as minimal as possible, while implementing basic functionality of automatic lists, to take your mind off the formatting, and have it work in the background while you write your thoughts.</dd>
</dl>


## Installation
Using vim-plug: (no vimscript, you should be using lua anyways :)
```lua
local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.config/nvim/plugged')
	Plug 'gaoDean/autolist.nvim'
vim.call('plug#end')
```
and
```lua
require('autolist').setup({})
```

## Configuration
This is the default config:
```lua
require('autolist.nvim').setup({
	create_enter_mapping = true,
	-- for if you have something else that you want to map when press return
	-- with the create enter being false, you must create your own mapping

	create_tab_mapping = true,
	-- creates mapping for <c-t> to renumber
	-- also allows you to disable renumbering for tab

	create_detab_mapping = true,
	-- creates mapping for <c-d> to use the same marker as other-
	-- entry with the same indent
	-- also allows you to disable renumbering for detab

	new_entry_on_o = true,
	-- when key o pressed, new list entry. Enables fo_o.
	-- see :h fo-table

	override_fo_r = true,
	-- if you don't use fo_r (or if you disable it), set this to true
	-- it will disable fo_r for all filetypes except for enabled types.
	-- perhaps grep for "formatoptions-=r" and "fo-=r"

	override_fo_o = true,
	-- if you don't use fo_o (or if you disable it), set this to true
	-- it will disable fo_o for all filetypes except for enabled types.
	-- perhaps grep for "formatoptions-=o" and "fo-=o"

	-- if you use any of the override options, you must remove any
	-- definitions of the overrided formatoptions, or you can
	-- define the options before sourcing the require setup for this
	-- plugin, so it can override it.

	enabled_filetypes = { "markdown", "text" },
	-- filetypes that this plugin is enabled for
	-- must put file name, not the extension
	-- if you are not sure of the name, just run :echo &filetype
})
```

## Credit

inspired by [my gist](https://gist.github.com/gaoDean/288d01dfe64da66569fb6615c767e081)
which is in turn inspired by [this gist](https://gist.github.com/sedm0784/dffda43bcfb4728f8e90)
