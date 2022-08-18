# autolist.nvim
Minimal automatic list continuation for neovim, powered by lua

## Why autolist
This question can be interpreted in two ways. Why did i create autolist, and why use autolist.

<dl>
	<dt>Why did I create autolist.nvim?</dt>
	<dd>It sounds simple, but all I wanted was a minimal list continuation plugin in lua that makes lists function better. bullets.vim works, but it is written in vimscript and is more than a thousand lines long. Needless to say, I couldn't find one, so I decided to create my own.</dd>
	<dt>Why use autolist?</dt>
	<dd>autolist's main function file is less than 200 lines long, complete with comments and formatting. It strives to be as minimal as possible, while implementing basic functionality of automatic lists, to take your mind off the formatting, and have it work in the background while you write your thoughts.</dd>
</dl>


## Installation
Using vim-plug:
```lua
local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.config/nvim/plugged')
	Plug 'gaoDean/autolist.nvim'
vim.call('plug#end')
```
and
```lua
lua require('autolist').setup({})
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
