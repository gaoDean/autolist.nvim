if exists("g:loaded_autolist")
    finish
endif
let g:loaded_autolist = 1

lua vim.api.nvim_set_keymap('i', '<cr>', [[<cr>:lua require('autolist').list()<cr>]])
au FileType markdown setl comments=b:*,b:-,b:+,n:>
au Filetype markdown setl formatoptions+=r
