if exists("g:loaded_autolist")
    finish
endif
let g:loaded_autolist = 1

inoremap <cr> <cr>:lua require('autolist').list()<cr>
au FileType markdown setl comments=b:*,b:-,b:+,n:>
au Filetype markdown setl formatoptions+=r
