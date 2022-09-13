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
		<img alt="Repo Size" src="https://img.shields.io/github/repo-size/gaoDean/autolist.nvim?color=%23DDB6F2&label=SIZE&logo=codesandbox&style=for-the-badge&logoColor=D9E0EE&labelColor=302D41"/></a>
</p>

https://user-images.githubusercontent.com/97860672/186395300-2225ce49-af81-45cc-8ec0-87f14fc80cd4.mp4

Note: this plugin is early in development, so expect breaking changes with updates. All breaking changes will be listed in the [releases](https://github.com/gaoDean/autolist.nvim/releases) page.

## Why autolist.nvim
This question can be interpreted in two ways. Why did I create autolist, and why you should use autolist.

<dl>
	<dt>Why did I create autolist?</dt>
	<dd>It sounds simple, but all I wanted was a list continuation plugin in lua that makes lists function better. Bullets.vim works, but it is written in vimscript and is more than a thousand lines long. Needless to say, I couldn't find a suitable one, so I decided to create my own.</dd>
	<dt>Why use autolist?</dt>
	<dd>Autolist's lua directory is 21K (according to <code>du -Ah</code>), with the files complete with comments and formatting. It strives to be as minimal as possible, while implementing basic functionality of automatic lists, and implements context aware renumbering/marking of list entries, to take your mind off the formatting, and have it work in the background while you write down your thoughts.</dd>
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
```

## Usage
See the [wiki](https://github.com/gaoDean/autolist.nvim/wiki) for information on supported list types and their [usage](https://github.com/gaoDean/autolist.nvim/wiki/Usage).

#### An intro to autolist
1. Type in a list marker (a list marker is just the delimiter used to start the list (`-|+|*` or `1.|2.|3.`)
2. Type in your content
3. When you're ready, press `enter`/`return` and a new list entry will be automatically created
4. Indent your list with `<c-t>` (**t**ab) and your *whole line* gets indented. When indenting, ordered lists will automatically be reset to one
5. Dedent your list with `<c-d>` (**d**edent) and your *whole line* gets dedented. When dedenting, markers will automatically be changed through context awareness, to the correct marker such that the list continues logically
6. Lastly, when you're done, pressing `enter`/`return` on an empty list entry will delete it, leaving you with a fresh new sentence.

## Configuration
See the [wiki](https://github.com/gaoDean/autolist.nvim/wiki/Configuration) for instructions.

This is the default config:
```lua
require('autolist').setup({
	enabled = true,
	create_enter_mapping = true,
	new_entry_on_o = true,
	list_cap = 50,
	colon = {
		indent_raw = true,
		indent = true,
		preferred = "-"
	},
	invert = {
		mapping = "<c-r>",
		normal_mapping = "",
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
	recal_hooks = {
		"invert",
		"new",
	},
	checkbox = {
		left = "%[",
		right = "%]",
		fill = "x",
	},
})
```

## Credit

inspired by [my gist](https://gist.github.com/gaoDean/288d01dfe64da66569fb6615c767e081)
which is in turn inspired by [this gist](https://gist.github.com/sedm0784/dffda43bcfb4728f8e90)

## Other
I started learning lua like a month ago, plus this is my first plugin, so there's probably a bunch of badly written code in there. Feel free to critique harshly and pull request.

If you submit a good enough pull request and show that you are trusted, you could perhaps become a contributor, as I have limited time cus you know *school*.

To get a overview of code, this removes all the comments and empty lines. Idk, I just like to do this to polish, might be useful to you.

	:%s/--.*//g | g/^\s*$/d
