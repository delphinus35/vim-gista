"******************************************************************************
" Gista utility
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

function! gista#util#call_on_buffer(expr, funcref, ...) abort " {{{
  let cbufnr = bufnr('%')
  let save_lazyredraw = &lazyredraw
  let &lazyredraw = 1
  if type(a:expr) == 0
    let tbufnr = a:expr
  else
    let tbufnr = bufnr(a:expr)
  endif
  if tbufnr == -1
    " no buffer is opened yet
    return 0
  endif
  let cwinnr = winnr()
  let twinnr = bufwinnr(tbufnr)
  if twinnr == -1
    " no window is opened
    execute tbufnr . 'buffer'
    call call(a:funcref, a:000)
    execute cbufnr . 'buffer'
  else
    execute twinnr . 'wincmd w'
    call call(a:funcref, a:000)
    execute cwinnr . 'wincmd w'
  endif
  let &lazyredraw = save_lazyredraw
  return 1
endfunction " }}}
function! gista#util#provide_filename(filename, filetype, ...) " {{{
  let magicnum = get(a:000, 0, 0)
  let filename = fnamemodify(a:filename, ':t')
  let default_filename = g:gista#gist_default_filename
  if empty(filename) && !empty(a:filetype)
    let ext = gista#utils#guess_extension(a:filetype)
    if !empty(ext)
      let filename = printf('%s%d%s', default_filename, magicnum, ext)
    endif
  endif
  if empty(filename)
    let filename = printf('%s%d.txt', default_filename, magicnum)
  endif
  return filename
endfunction " }}}
function! gista#util#guess_extension(filetype) " {{{
  if len(a:filetype) == 0
    return ''
  elseif has_key(s:consts.EXTMAP, a:filetype)
    return s:consts.EXTMAP[a:filetype]
  return '.' + a:filetype
endfunction " }}}
function! gista#util#input_yesno(message, ...) "{{{
  " forked from Shougo/unite.vim
  " AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
  " License: MIT license  {{{
  "     Permission is hereby granted, free of charge, to any person obtaining
  "     a copy of this software and associated documentation files (the
  "     "Software"), to deal in the Software without restriction, including
  "     without limitation the rights to use, copy, modify, merge, publish,
  "     distribute, sublicense, and/or sell copies of the Software, and to
  "     permit persons to whom the Software is furnished to do so, subject to
  "     the following conditions:
  "
  "     The above copyright notice and this permission notice shall be included
  "     in all copies or substantial portions of the Software.
  "
  "     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  "     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  "     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  "     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  "     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  "     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  "     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  " }}}
  let default = get(a:000, 0, '')
  let yesno = input(a:message . ' [yes/no]: ', default)
  while yesno !~? '^\%(y\%[es]\|n\%[o]\)$'
    redraw
    if yesno == ''
      echo 'Canceled.'
      break
    endif
    " Retry.
    call unite#print_error('Invalid input.')
    let yesno = input(a:message . ' [yes/no]: ')
  endwhile
  redraw
  return yesno =~? 'y\%[es]'
endfunction " }}}
function! gista#util#set_clipboard(content) abort " {{{
  if exists('g:gista#clip_command')
    call gista#vital#system(g:gista#clip_command, content)
  elseif has('unix') && !has('xterm_clipboard')
    let @" = content
  else
    let @+ = content
  endif
endfunction " }}}
function! gista#util#browse(url) abort " {{{
  try
    call openbrowser#open(a:url)
  catch /E117.*/
    " exists("*openbrowser#open") could not be used while this might be the
    " first time to call an autoload function.
    " Thus catch "E117: Unknown function" exception to check if there is a
    " newly implemented function or not.
    redraw
    echohl WarningMsg
    echo  'vim-gista require "tyru/open-browser.vim" plugin to oepn browsers. '
    echon 'It seems you have not installed that plugin yet. So ignore it.'
    echohl None
  endtry
endfunction " }}}


let s:consts = {}
let s:consts.EXTMAP = {
      \ "actionscript": ".as",
      \ "php": ".aw",
      \ "csharp": ".cs",
      \ "lisp": ".el",
      \ "erlang": ".erl",
      \ "haskell": ".hs",
      \ "javascript": ".js",
      \ "objc": ".m",
      \ "markdown": ".md",
      \ "perl": ".pl",
      \ "python": ".py",
      \ "ruby": ".rb",
      \ "scheme": ".scm",
      \ "smalltalk": ".st",
      \ "smarty": ".tpl",
      \ "verilog": ".v",
      \ "vbnet": ".vb",
      \ "xquery": ".xq",
      \ "yaml": ".yml",
      \}


let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
