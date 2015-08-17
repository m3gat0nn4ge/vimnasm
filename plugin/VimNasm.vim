au BufRead,BufNewFile *.asm set filetype=nasm

function! VNGetBits()
  let s:target_line_num = search('\<BITS\>')
  let s:bits = matchstr(getline(s:target_line_num), '[0-9]\{2}')
  return s:bits
endfunction

function! VNSetObjectFormat()
" TODO: allow other formats than elf32|elf64
  let s:object_format = 'elf' . VNGetBits()
endfunction

let s:symbols_enabled = 0
let s:debug = ''
function! VNToggleSymbols()
  if s:symbols_enabled
    let s:debug = ''
    let s:symbols_enabled = 0
    call VNOff()
  else
    let s:debug = '-g'
    let s:symbols_enabled = 1
    call VNOn()
  endif
endfunction

function! VNSetLinkerEmulation()
  if VNGetBits() == 64
    let s:linker_emulation = 'elf_x86_64'
  else
    let s:linker_emulation = 'elf_i386'
  endif
endfunction

function! VNCompile()
  if !exists("s:object_format") 
    call VNSetObjectFormat()
  endif
  silent !clear
  silent execute '!nasm ' . s:debug .
          \ ' -f ' . s:object_format .
          \ ' -o ' . shellescape('%:r') . '.o ' .
          \ shellescape('%') . ' >/tmp/' . expand('%:t') . '.nasm_out 2>&1'
  if v:shell_error != 0
    execute '!cat /tmp/' . expand('%:t') . '.nasm_out' 
  else
    call VNOn()
  endif  
endfunction

function! VNLink()
  if !filereadable(expand('%:r') . '.o')
    call VNCompile()
  endif
  if !exists("s:linker_emulation") 
    call VNSetLinkerEmulation()
  endif
  silent !clear
  silent execute '!ld ' .
          \ ' -m' . s:linker_emulation .
          \ ' -o ' . shellescape('%:r')
          \ shellescape('%:r'). '.o >/tmp/' . expand('%:t') . '.ld_out 2>&1'
  if v:shell_error != 0
    execute '!cat /tmp/' . expand('%:t') . '.ld_out' 
  else
    call VNOn()
  endif  
endfunction

function! VNDebug()
  if !filereadable(expand('%:r'))
    call VNLink()
  endif
  silent !clear
  silent execute '!gdb ' . shellescape('%:r')
  redraw!
endfunction

function! VNRun()
  if !filereadable(expand('%:r'))
    call VNLink()
  endif
  call VNRunArgs()
  silent !clear
  execute '!./' . shellescape('%:r') . ' ' . s:run_args
endfunction

function! VNOn()
  highlight Normal ctermbg=lightgreen 
  redraw!
  sleep 200m
  highlight Normal ctermbg=NONE 
  redraw!
endfunction

function! VNOff()
  highlight Normal ctermbg=lightred 
  redraw!
  sleep 200m
  highlight Normal ctermbg=NONE 
  redraw!
endfunction

function! VNRunArgs()
  if !exists('s:run_args')
    let s:run_args = input('[*] program arguments: ')
  endif
endfunction

if !exists('g:vn_map_keys')
  let g:vn_map_keys = 1
endif

if g:vn_map_keys
  nnoremap <F5> :call VNToggleSymbols()<CR>
  nnoremap <F6> :call VNCompile()<CR>
  nnoremap <F7> :call VNLink()<CR>
  nnoremap <F8> :call VNRun()<CR>
  nnoremap <F9> :call VNDebug()<CR>
endif
