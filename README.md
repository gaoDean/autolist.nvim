# autolist.nvim
Minimal automatic list continuing for ordered and unordered lists for neovim in lua

supports:
* ordered and unordered
* autodeletes empty list bullets
* indented lists with `<c-t>` and `<c-d>`
```
	1. content
	2. content
		1. content

	- content
		- content
		- content
	* content
	+ content
```

doesn't support:
* renumbering of lists
