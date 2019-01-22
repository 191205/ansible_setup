"      .-.     .-.     .-.     .-.     .-.     .-.     .-.
" `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'
"
"
" -----------------------------
" Nvim Command Mode: and related configs
" Created: 2019/01/17
" Last Change:
" -----------------------------
" vim:ft=vim:ts=2:sw=2:fdm=marker
"
"
"      .-.     .-.     .-.     .-.     .-.     .-.     .-.
" `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'

" Custom Commands: {{{
" ----------------
" Copy Path: ...................................
command! CpPath :let @+ = expand("%:p:h")
command! CpName :let @+ = expand("%:p")

" Reload Config:
command! Reload source ~/.config/nvim/init.vim
" vim: foldmethod=marker:
"

" }}}
" Abbreviations: {{{
cabbrev sord sort
cabbrev ram Reload
cabbrev ter terminal

cnoreabbrev <silent> ww wa
cnoreabbrev <silent> xx x!
cnoreabbrev <silent> qq q!

command! W :w
command! Q :q
command! Vspl :vsp
" }}}
" Mapping: {{{
" --------------

cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-d> <C-w>
cnoremap <C-l> <Right>
cnoremap <C-h> <Left>
cnoremap <C-f> <S-Right>
cnoremap <C-s> <S-Left>

" Insert The Directory Of Current:
" -------------------------------------
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:p:h') . '/' : '%%'

" Paste System Clipboard To Command Line:
" -------------------------------------
cnoremap π <C-R>*

" }}}
