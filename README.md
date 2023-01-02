<p align="center">
  <h2 align="center">autolist.nvim</h2>
</p>
<p align="center">
	Automatic list continuation and formatting for neovim, powered by lua
</p>
<p align="center">
	<a href="https://github.com/gaoDean/autolist.nvim/stargazers">
		<img alt="Stars" src="https://img.shields.io/github/stars/gaoDean/autolist.nvim?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=D9E0EE&labelColor=302D41"></a>
	<a href="https://github.com/gaoDean/autolist.nvim/issues">
		<img alt="Issues" src="https://img.shields.io/github/issues/gaoDean/autolist.nvim?style=for-the-badge&logo=bilibili&color=F5E0DC&logoColor=D9E0EE&labelColor=302D41"></a>
	<a href="https://github.com/gaoDean/autolist.nvim">
	<img alt="Code Size" src="https://img.shields.io/github/languages/code-size/gaoDean/autolist.nvim?color=%23DDB6F2&logo=hackthebox&style=for-the-badge&logoColor=D9E0EE&labelColor=302D41"/></a>
</p>

https://user-images.githubusercontent.com/97860672/193787598-56abba13-3710-43d1-b8b3-4fd81074dbd4.mp4

## Why autolist.nvim
This question can be interpreted in two ways. Why did I create autolist, and why you should use autolist.

<dl>
	<dt>Why did I create autolist?</dt>
	<dd>It sounds simple, but all I wanted was a list continuation plugin in lua that makes lists function better. Bullets.vim works, but it is written in vimscript and is more than a thousand lines long. Needless to say, I couldn't find a suitable one, so I decided to create my own.</dd>
	<dt>Why use autolist?</dt>
	<dd>Autolist's files are relatively small, with the files complete with comments and formatting. It strives to be as minimal as possible, while implementing basic functionality of automatic lists, and implements context aware renumbering/marking of list entries, to take your mind off the formatting, and have it work in the background while you write down your thoughts.</dd>
</dl>


## Installation
Using vim-plug:
```lua
-- lua
local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.config/nvim/plugged')
	Plug 'gaoDean/autolist.nvim'
vim.call('plug#end')
```
or Paq:
```lua
-- lua
require "paq" {
	"gaoDean/autolist.nvim"
}
```
and with both:
```lua
-- lua
require('autolist').setup({})

-- recommended keymaps
-- for better performance, move these into ftplugin files

function create_mapping_hook(mode, mapping, hook, alias)
  vim.keymap.set(
    mode,
    mapping,
    function(motion)
      local keys = hook(motion, alias or mapping)
      if not keys then keys = "" end
      return keys
    end,
    { expr = true}
  )
end

create_mapping_hook("i", "<cr>", require("autolist").new)
create_mapping_hook("i", "<tab>", require("autolist").indent)
create_mapping_hook("i", "<s-tab>", require("autolist").indent, "<c-d>")
create_mapping_hook("n", "dd", require("autolist").force_recalculate)
create_mapping_hook("n", "o", require("autolist").new)
create_mapping_hook("n", "O", require("autolist").new_before)
create_mapping_hook("n", ">>", require("autolist").indent)
create_mapping_hook("n", "<<", require("autolist").indent)
create_mapping_hook("n", "<c-r>", require("autolist").force_recalculate)
create_mapping_hook("n", "<leader>x", require("autolist").invert_entry)
```

## Features
- Automatic list continuation
- Automatic list formatting
- List recalculation/renumbering
- Supports checkboxes
- Set custom list markers

## Usage
See the [wiki](https://github.com/gaoDean/autolist.nvim/wiki) for information on supported list types and their [usage](https://github.com/gaoDean/autolist.nvim/wiki/Usage).

#### An intro to autolist
1. Type in a list marker (a list marker is just the delimiter used to start the list (`-|+|*` or `1.|2.|3.`)
2. Type in your content
3. When you're ready, press `enter`/`return` and a new list entry will be automatically created
4. Indent your list with tab and your *whole line* gets indented. When indenting, ordered lists will automatically be reset to one
5. Dedent your list with shift-tab and your *whole line* gets dedented. When dedenting, markers will automatically be changed through context awareness, to the correct marker such that the list continues logically
6. Lastly, when you're done, pressing `enter`/`return` on an empty list entry will delete it, leaving you with a fresh new sentence.

## Configuration
Please see the [wiki](https://github.com/gaoDean/autolist.nvim/wiki/Configuration) for instructions, the below config might be outdated, but the wiki is always up to date.

This is the default config:
```lua
local default_config = {
	enabled = true,
	list_cap = 50,
	colon = {
		indent_raw = true,
		indent = true,
		preferred = "-"
	},
	invert = {
		indent = false,
		toggles_checkbox = true,
		ul_marker = "-",
		ol_incrementable = "1",
		ol_delim = ".",
	},
	lists = {
		preloaded = {
			generic = {
				"unordered",
				"digit",
				"ascii",
			},
			latex = {
				"latex_item",
			},
		},
		filetypes = {
			generic = {
				"markdown",
				"text",
			},
			latex = {
				"tex",
				"plaintex",
			},
		},
	},
	recal_function_hooks = {
		"invert",
		"new",
	},
	checkbox = {
		left = "%[",
		right = "%]",
		fill = "x",
	},
}
```

## Credit

inspired by [my gist](https://gist.github.com/gaoDean/288d01dfe64da66569fb6615c767e081)
which is in turn inspired by [this gist](https://gist.github.com/sedm0784/dffda43bcfb4728f8e90)

## Other

> "All software adds features until it is annoyingly complicated. It is then replaced by a "simpler" solution which adds features until it is exactly as complicated."

looking for contributors because i have schoolwork which means i sometimes cant keep up with issues
