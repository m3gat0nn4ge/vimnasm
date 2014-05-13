au BufRead,BufNewFile *.asm set filetype=nasm

function! VNGetBits()
  let b:target_line_num = search('\<BITS\>')
  let b:bits = matchstr(getline(b:target_line_num), '[0-9]\{2}')
  return b:bits
endfunction

function! VNSetObjectFormat()
" TODO: allow other formats than elf32|elf64
  let b:object_format = 'elf' . VNGetBits()
endfunction

function! VNSetDebugSymbols()
" TODO: allow toggling
  let b:debug_symbols = '-g'
endfunction

function! VNSetLinkerEmulation()
  if VNGetBits() == 64
    let b:linker_emulation = 'elf_x86_64'
  else
    let b:linker_emulation = 'elf_i386'
  endif
endfunction

function! VNCompile()
  if !exists("b:object_format") 
    call VNSetObjectFormat()
  endif
  if !exists("b:debug_symbols") 
    call VNSetDebugSymbols()
  endif
  silent !clear
  silent execute '!nasm ' . b:debug_symbols .
          \ ' -f ' . b:object_format .
          \ ' -o ' . shellescape('%:r') . '.o ' .
          \ shellescape('%') . ' >/tmp/' . expand('%:t') . '.nasm_out 2>&1'
  if v:shell_error != 0
    execute '!cat /tmp/' . expand('%:t') . '.nasm_out' 
  else
    highlight Normal ctermbg=lightgreen 
    redraw!
    sleep 200m
    highlight Normal ctermbg=NONE 
    redraw!
  endif  
endfunction

function! VNLink()
  if !filereadable(expand('%:r') . '.o')
    call VNCompile()
  endif
  if !exists("b:linker_emulation") 
    call VNSetLinkerEmulation()
  endif
  silent !clear
  silent execute '!ld ' .
          \ ' -m' . b:linker_emulation .
          \ ' -o ' . shellescape('%:r')
          \ shellescape('%:r'). '.o >/tmp/' . expand('%:t') . '.ld_out 2>&1'
  if v:shell_error != 0
    execute '!cat /tmp/' . expand('%:t') . '.ld_out' 
  else
    highlight Normal ctermbg=lightgreen 
    redraw!
    sleep 200m
    highlight Normal ctermbg=NONE 
    redraw!
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
  silent !clear
  execute '!./' . shellescape('%:r')
endfunction

if !exists('g:vn_map_keys')
  let g:vn_map_keys = 1
endif

if g:vn_map_keys
  nnoremap <F6> :call VNCompile()<CR>
  nnoremap <F7> :call VNLink()<CR>
  nnoremap <F8> :call VNRun()<CR>
  nnoremap <F9> :call VNDebug()<CR>
endif
