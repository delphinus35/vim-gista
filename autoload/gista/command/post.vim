let s:save_cpo = &cpo
set cpo&vim

let s:V = gista#vital()
let s:A = s:V.import('ArgumentParser')

function! s:handle_exception(exception) abort " {{{
  redraw
  let canceled_by_user_patterns = [
        \ '^vim-gista: Login canceled',
        \ '^vim-gista: ValidationError: An API name cannot be empty',
        \ '^vim-gista: ValidationError: An API account username cannot be empty',
        \]
  for pattern in canceled_by_user_patterns
    if a:exception =~# pattern
      call gista#util#prompt#warn('Canceled')
      return
    endif
  endfor
  " else
  call gista#util#prompt#error(a:exception)
endfunction " }}}
function! gista#command#post#call(...) abort " {{{
  let options = get(a:000, 0, {})
  try
    let content = gista#api#call_post(options)
    let b:gista = {
          \ 'apiname': gista#api#get_current_apiname(),
          \ 'username': gista#api#get_current_username(),
          \ 'anonymous': gista#api#get_current_anonymous(),
          \ 'gistid': gista#api#post#get_current_gistid(),
          \}
    redraw
    call gista#util#prompt#info(printf(
          \ 'The content has posted to a gist "%s"',
          \ content.id,
          \))
    return content
  catch /^vim-gista:/
    call s:handle_exception(v:exception)
    return ''
  endtry
endfunction " }}}

function! s:get_parser() abort " {{{
  if !exists('s:parser')
    let s:parser = s:A.new({
          \ 'name': 'Gista post',
          \ 'description': 'Post contents into a new gist',
          \})
    call s:parser.add_argument(
          \ '--apiname',
          \ 'An API name', {
          \   'type': s:A.types.value,
          \   'complete': function('g:gista#api#complete_apiname'),
          \})
    call s:parser.add_argument(
          \ '--username',
          \ 'A username of an API account.', {
          \   'type': s:A.types.value,
          \   'complete': function('g:gista#api#complete_username'),
          \})
    call s:parser.add_argument(
          \ '--anonymous',
          \ 'Request gists as an anonymous user', {
          \   'deniable': 1,
          \})
    call s:parser.add_argument(
          \ '--description', '-d',
          \ 'A description of a gist', {
          \   'type': s:A.types.value,
          \})
    call s:parser.add_argument(
          \ '--public', '-p',
          \ 'Post a gist as a public gist', {
          \   'conflicts': ['private'],
          \})
    call s:parser.add_argument(
          \ '--private', '-P',
          \ 'Post a gist as a private gist', {
          \   'conflicts': ['public'],
          \})
    function! s:parser.hooks.post_validate(options) abort
      if has_key(a:options, 'private')
        let a:options.public = !a:options.private
        unlet a:options.private
      endif
    endfunction
  endif
  return s:parser
endfunction " }}}
function! gista#command#post#command(bang, range, ...) abort " {{{
  let options = s:get_parser().parse(a:bang, a:range, get(a:000, 0, ''))
  if empty(options)
    return
  endif
  " extend default options
  let options = extend(
        \ deepcopy(g:gista#command#post#default_options),
        \ options,
        \)
  " get filenames
  let filenames = filter(map(
        \ empty(options.__unknown__) ? ['%'] : options.__unknown__,
        \ 'expand(v:val)',
        \), 'bufexists(v:val) || filereadable(v:val)')
  let contents = map(
        \ copy(filenames),
        \ 'bufexists(v:val) ? getbufline(v:val, 1, "$") : readfile(v:val)',
        \)
  let options.filenames = map(filenames, 'fnamemodify(v:val, ":t")')
  let options.contents = contents
  call gista#command#post#call(options)
endfunction " }}}
function! gista#command#post#complete(arglead, cmdline, cursorpos) abort " {{{
  return s:get_parser().complete(a:arglead, a:cmdline, a:cursorpos)
endfunction " }}}

call gista#define_variables('command#post', {
      \ 'default_options': {},
      \})

let &cpo = s:save_cpo
unlet! s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
