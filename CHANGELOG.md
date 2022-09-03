# Changelog

## 2022-09-03 (Major)
Merged [this rewrite](https://github.com/gaoDean/autolist.nvim/pull/12) with multiple breaking changes in the configuration

### Configuration changes
- the `invert_.*` options have been divided into a table
	- added `invert.ol_incrementable` which allows you to configure your preferred incrementable prefix for an ordered list e.g `123` or `abc`
	- added `invert.ol_delim` which allows you to configure your preferred delimiter for an ordered list e.g `a.` or `a)`
- added the `lists` table which is all about configuring list types
	- added the `lists.preloaded` table which takes list "groups" and replaces their string values with preloaded patterns (of list types). For example, there is a preloaded option called `"digit"`, and it is replaced with `"%d+[.)]"`, taken from the preloaded options in the `config.lua` file.
	- added the `lists.filetypes` table which has a table corresponding with a table in `lists.preloaded`, and this just defines which filetypes the list types in the corresponding table are active for.
- added `recal_hooks` which is a table that defines what fucntions call the recalculate function after their execution.
- added `checkbox` which is a table that defines the checkbox delimiters and fillers (technically you can now have a checkbox that is `{x}` or even `(*)`.

### Raw file changes
Deleted the entire `generic.lua` file (this is a complete rewrite) and added `auto.lua` (which handles the bulk of the plugin) and `utils.lua` (which has some useful functions that are not dependent on `config.lua` and would be local functions inside `auto.lua`), also reworked `config.lua`.

Inside `auto.lua`, there are two major functions. There is the `new()` function which handles list autocompletion (pressing `<cr>` and such), and there is `recal()` which recalculates an ordered list, and is activated after the executions of the functions inside `config.recal_hooks`.

The changes in `config.lua` mostly are from the `config.lists` table.

### Todo
- recalculate unordered lists
