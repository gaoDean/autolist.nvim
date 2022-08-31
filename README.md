<p align="center">
  <h2 align="center">autolist.nvim</h2>
</p>
<p align="center">
	Automatic list continuation and formatting for neovim, powered by lua
</p>
<p align="center">
	<a href="https://github.com/gaoDean/autolist.nvim/stargazers">
		<img alt="Stars" src="https://img.shields.io/github/stars/gaoDean/autolist.nvim?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=D9E0EE&labelColor=302D41"></a>
	<a href="https://github.com/Pocco81/autolist.nvim/issues">
		<img alt="Issues" src="https://img.shields.io/github/issues/gaoDean/autolist.nvim?style=for-the-badge&logo=bilibili&color=F5E0DC&logoColor=D9E0EE&labelColor=302D41"></a>
	<a href="https://github.com/gaoDean/autolist.nvim">
		<img alt="Repo Size" src="https://img.shields.io/github/repo-size/gaoDean/autolist.nvim?color=%23DDB6F2&label=SIZE&logo=codesandbox&style=for-the-badge&logoColor=D9E0EE&labelColor=302D41"/></a>
</p>

https://user-images.githubusercontent.com/97860672/186395300-2225ce49-af81-45cc-8ec0-87f14fc80cd4.mp4

Note: this plugin is early in development, so expect breaking changes with updates. All breaking changes will be listed in [breaking changes](#breaking-changes).

Sorry for the delay in issue response and unsatisfactory patches, currently going through a rewrite so the patches won't matter.

## Why autolist.nvim
This question can be interpreted in two ways. Why did I create autolist, and why you should use autolist.

<dl>
	<dt>Why did I create autolist?</dt>
	<dd>It sounds simple, but all I wanted was a minimal list continuation plugin in lua that makes lists function better. bullets.vim works, but it is written in vimscript and is more than a thousand lines long. Needless to say, I couldn't find a suitable one, so I decided to create my own.</dd>
	<dt>Why use autolist?</dt>
	<dd>Autolist's main function file is less than 300 lines long, complete with comments and formatting. It strives to be as minimal as possible, while implementing basic functionality of automatic lists, and implements context aware renumbering/marking of list entries, to take your mind off the formatting, and have it work in the background while you write down your thoughts.</dd>
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
This is the default config:
```lua
require('autolist').setup({
	generic = {

		enabled = true,

		-- for if you have something else that you want to map when press return
		-- with the create enter being false, you must create your own mapping
		create_enter_mapping = true,

		-- the mapping to invert the list type e.g ol -> ul, ul -> ol
		-- set this to empty ("") to disable
		invert_mapping = "<c-r>",

		-- when there is a list like - [x] content, when invert mapping is
		-- pressed and below option is true the list will turn into
		-- - [ ] content, instead of 1. [x] content
		invert_toggles_checkbox = true,

		-- invert mapping in normal mode
		invert_normal_mapping = "",

		-- when pressing the relist mapping and current marker is ordered list,
		-- change to invert_ul_marker.
		invert_ul_marker = "-",

		-- This just allows the relisting function to use the current list
		-- formatting to search for the right list type.
		-- Important: if your markdown ordered lists are badly formatted e.g a one
		-- followed by a three, the relist cant find the right list. most of the
		-- time you'll have the correct formatting, and its not a big deal if you
		-- dont, the program wont throw an error, you just wont get a relist.
		context_optimisaton = true,

		-- when key o pressed, new list entry. Enables fo_o. see :h fo-table
		new_entry_on_o = true,

		-- filetypes that this plugin is enabled for.
		-- must put file name, not the extension.
		-- if you are not sure, just run :echo &filetype. or :set filetype?
		enabled_filetypes = { "markdown", "text" },
	},
})
```
The `config.lua` contains good information about the mappings and config that the docs are sometimes behind on.

## Breaking changes
2022 Aug 29: Large refactor coming up that will remove the generic part of the table as its useless (all other config options kept, so just do two `dd`s for the generic brackets), and add extra options to do your own markers.

## Credit

inspired by [my gist](https://gist.github.com/gaoDean/288d01dfe64da66569fb6615c767e081)
which is in turn inspired by [this gist](https://gist.github.com/sedm0784/dffda43bcfb4728f8e90)

## Other
I started learning lua like a month ago, plus this is my first plugin, so there's probably a bunch of badly written code in there. Feel free to critique harshly and pull request.

If you submit a good enough pull request and show that you are trusted, you could perhaps become a contributor, as I have limited time cus you know *school*.

To get a overview of code, this removes all the comments and empty lines. Idk, I just like to do this to polish, might be useful to you.

	:%s/--.*//g | g/^\s*$/d
