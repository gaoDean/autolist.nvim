.PHONY: test deps dev

test:
	nvim --headless --noplugin -u spec/minimal_init.lua -c "PlenaryBustedDirectory spec/ { minimal_init = 'spec/minimal_init.lua' }"

dev:
	nvim --clean --cmd "set rtp+=." \
		-c "lua require('autolist').setup()" \
		-c "lua vim.keymap.set('i', '<CR>', '<CR><cmd>AutolistNewBullet<cr>')" \
		-c "lua vim.keymap.set('i', '<S-Tab>', '<cmd>AutolistShiftTab<cr>')" \
		-c "lua vim.keymap.set('i', '<Tab>', '<cmd>AutolistTab<cr>')" \
		-c "lua vim.keymap.set('n', 'o', 'o<cmd>AutolistNewBullet<cr>')" \
		-c "lua vim.keymap.set('n', 'O', 'O<cmd>AutolistNewBulletBefore<cr>')" \
		dev.md

deps:
	@mkdir -p .tests
	@[ -d .tests/plenary.nvim ] || git clone --depth 1 https://github.com/nvim-lua/plenary.nvim .tests/plenary.nvim
