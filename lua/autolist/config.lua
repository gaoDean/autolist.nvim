local config = {
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

	override_fo_o = true,
	-- if you don't use formatoptions o, set this to true
	-- it will disable fo_o for all filetypes except for enabled types.

	-- if you use any of the override options, you must remove any
	-- definitions of the overrided formatoptions.

	override_fo_r = true,
	-- if you don't use formatoptions r, set this to true
	-- it will disable fo_r for all filetypes except for enabled types.

	optimised_renum = true,
	-- use good formatting

	enabled_filetypes = { "markdown", "text" },
	-- filetypes that this plugin is enabled for
	-- must put file name, not the extension
	-- if you are not sure of the name, just run :echo &filetype
}

return config
