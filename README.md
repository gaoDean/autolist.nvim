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

## Features
- Automatic list continuation
- Automatic list formatting
- List recalculation/renumbering
- Supports checkboxes
- Set custom list markers

## Installation
This is using lazy.nvim, but you can adapt it to other package managers as well:
```lua
{
  "gaoDean/autolist.nvim",
  ft = {
    "markdown",
    "text",
    "tex",
    "plaintex",
  },
  config = function()
    local autolist = require("autolist")
    autolist.setup()

    local function mapping_hook(mode, mapping, hook, alias)
      vim.keymap.set(
        mode,
        mapping,
        function(motion)
          local keys = hook(motion, alias or mapping)
          if not keys then keys = '' end
          return keys
        end,
        { expr = true, buffer = true }
      )
    end

    mapping_hook("i", "<cr>", autolist.new)
    mapping_hook("i", "<tab>", autolist.indent)
    mapping_hook("i", "<s-tab>", autolist.indent, "<c-d>")
    mapping_hook("n", "dd", autolist.force_recalculate)
    mapping_hook("n", "o", autolist.new)
    mapping_hook("n", "O", autolist.new_before)
    mapping_hook("n", ">>", autolist.indent)
    mapping_hook("n", "<<", autolist.indent)
    mapping_hook("n", "<c-r>", autolist.force_recalculate)
    mapping_hook("n", "<leader>x", autolist.invert_entry, "")
  end,
},
```

## Usage
1. Type in a list marker (a list marker is just the delimiter used to start the list (`-|+|*` or `1.|2.|3.`)
2. Type in your content
3. When you're ready, press `enter`/`return` and a new list entry will be automatically created
4. If you're cursor is at the end of the line, you can indent your list with tab. When indenting, ordered lists will automatically be reset to one.
5. Similarly, dedent your list with shift-tab and your *whole line* gets dedented. When dedenting, markers will automatically be changed through context awareness, to the correct marker such that the list continues logically
6. Lastly, when you're done, pressing `enter`/`return` on an empty list entry will delete it, leaving you with a fresh new sentence.

- [x] checkboxes can be toggled with autolist.invert_entry, which is "<leader>x" if you used the default mappings

1. [x] these can also be numbered

a) [ ] or these can work too
b) [x] see?

- if the list type is not a checkbox, invert entry converts it from an ordered list to an unordered list (and vice versa)
- below is a copy of this list, but after inverting

1. if the list type is not a checkbox, invert entry converts it from an ordered list to an unordered list (and vice versa)
2. below is a copy of this list, but after inverting

## Mappings

Most of the mappings you'll create will look like this:
```lua
create_mapping_hook("i", "<cr>", require("autolist").new)
```
It starts with the helper function, then the mode, mapping and the hook function. With the above mapping, it runs `autolist.new` **after** `<cr>` is pressed.

The `alias` argument converts the `mapping` to `alias` when passing to the function, for example in the below mapping, `<s-tab>` is captured and converted to `<c-d>` to pass to the function.
```lua
create_mapping_hook("i", "<s-tab>", require("autolist").indent, "<c-d>")
```


## Configuration
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
		markdown = {
			"unordered",
			"digit",
			"ascii"
		},
		text = {
			"unordered",
			"digit",
			"ascii"
		},
		tex = { "latex_item" },
		plaintex = { "latex_item" },
	},
	checkbox = {
		left = "%[",
		right = "%]",
		fill = "x",
	},
}
```

## Options explanation
Misc:
- `enabled`: enables/disables the plugin
- `list_cap`: when recalculating an ordered list, this is the max number of entries it will calculate.

`colon`: If a line ends in a colon
- `indent`: if autolist creates a new indented list after the current line when the current line *is a list* and ends in a colon. Emphasis on the current line *is a list*.
- `indent_raw`: if autolist creates a new list after the current line when the current line ends in a colon. Works on non-list lines as well.
- `preferred`: the preferred list marker when creating a new list. Put `1.` or `a)` for an ordered list.

`invert`: Inverts the list type (`ol -> ul`, `ul -> ol`, `[ ] -> [x]`)
- `indent`: when on the top level list, pressing invert inverts the list and indents it. Think about it.
- Dot repeat is also available for inverting in normal mode

`lists`: Configures the list behaviors
- `preloaded`: This is a list of preloaded lua patterns.
	- `generic`: This is a *"list group"*, such is the `latex` table just below. Each "list group" corresponds to a "list group" in the `filetypes` table explained below.
	- Inside a "list group", there are definitions for what "list types" this "list group" supports. For the "list types", you can have either a preloaded option, which you can use by putting the key for a preloaded option into the *list group*, or a custom lua pattern, which you just type into the list group.
	- You can see a few preloaded options in the default configuration such as "unordered" and "digit", of which the full set you can find in the #preloaded-lists header.
- `filetypes`:
	- As explained before, each list group inside the `filetypes` table corresponds to a list group inside the `preloaded` table. For each list group in `filetypes`, you can put the filetypes that this list group is activated for. For example, in the default configuration, the `latex` list group is activated for `tex` files and `plaintex` files.
	- **IMPORTANT**: You must put the -file name- for the filetype, not the -file extension-. To get the "file name", it is just `:set filetype?` or `:se ft?`.

`recal_function_hooks`: Configures what functions recalculate the list at the end of their execution. In the default config, it will recalculate when it creates a new bullet, and also recalculate when you invert.

`checkbox`: Configures the options for checkboxes
- `left`: The pattern for the left checkbox delimiter.
- `right`: The pattern for the right checkbox delimiter.
- `fill`: The pattern for the checkbox fill.
- To make checkboxes look like `(-)`, make `left = "%("`, `right = "%)`, `fill = "%-"`. Search for lua patterns on how to configure the patterns.

### Preloaded lists
```lua
local preloaded_lists = {
	unordered = "[-+*]",
	digit = "%d+[.)]",
	ascii = "%a[.)]",
	latex_item = "\\item"
}
```

## Faq
#### On defining custom lists
In a nutshell, all you need to do is make a lua pattern match that allows autolist to find your new list marker.

[Here's](https://riptutorial.com/lua/example/20315/lua-pattern-matching) a not-bad article on lua patterns, but you can find examples for these patterns in the preloaded patterns section.

I'll walk you through step by step on how to define your custom list:

```lua
require('autolist').setup({
	lists = {
		preloaded = {
			custom = {
				"%a[.)]", // insert your custom lua pattern here
			}
		},
		filetypes = {
			custom = { // insert your filetypes here
				"markdown",
				"text"
			}
		},
	}
})
```

Now your lua pattern (in this case `%a[.)]` which matches ascii lists) will be applied to the filetypes `markdown` and `text`. Also note that the filetype is not the file extension, it is what you get when you run `:set filetype?`.

#### Frequently asked questions

Does it have a mapping for toggling a checkbox like bullets.vim has? Yes.

Does it support checkbox lists? Yes.


## Credit

inspired by [this gist](https://gist.github.com/sedm0784/dffda43bcfb4728f8e90)

## Other

> "All software adds features until it is annoyingly complicated. It is then replaced by a "simpler" solution which adds features until it is exactly as complicated."

looking for contributors because i have schoolwork which means i sometimes cant keep up with issues
