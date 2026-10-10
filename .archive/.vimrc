" Vim-plug 자동 설치용
" START - Setting up Vundle - the vim plugin bundler
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
                \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

filetype off
set rtp+=~/.vim/autoload/plug.vim

call plug#begin('~/.vim/plugged')
" Yggdroot/indentLine
" https://github.com/Yggdroot/indentLine
Plug 'Yggdroot/indentLine'
let g:indentLine_char = '|'
" let g:indentLine_char_list = ['|', '¦', '┆', '┊']
let g:indentLine_setColors = 0

" NerdTree
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
" NerdTree Configs
" let g:loaded_nerdtree_git_status=1
let g:NERDTreeShowGitStatus=1
let g:NERDTreeGitStatusShowClean=1
let g:NERDTreeShowLineNumbers=1

" vim-fugitive
" https://github.com/tpope/vim-fugitive
" Plugin for git
Plug 'tpope/vim-fugitive'

" vim-diminactive
" https://github.com/blueyed/vim-diminactive
" Change background color depends on cursor location
Plug 'blueyed/vim-diminactive'

 " nvim-treesitter
 if has("nvim")
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
 endif

" vim-airline
" https://github.com/vim-airline/vim-airline
" Show status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" vim-airline configs
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s:'
let g:airline#extensions#tabline#left_sep     = ''
let g:airline#extensions#tabline#left_alt_sep = ''

let g:airline_theme = 'spaceduck'

" ctrlp
" https://github.com/ctrlpvim/ctrlp.vim
" Full path fuzzy file, buffer, mru, tag, .. finder for Vim
Plug 'ctrlpvim/ctrlp.vim'

" vim-indent-object
" https://github.com/michaeljsmith/vim-indent-object
" provide a convenient way to select
Plug 'michaeljsmith/vim-indent-object'

" vim tmux seamless navigation
" Alt + hjkl to move pane/buffer
Plug 'christoomey/vim-tmux-navigator'
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :TmuxNavigateRight<cr>
nnoremap <silent> <C-\> :TmuxNavigatePrevious<cr>

" nerdcommenter
" https://github.com/preservim/nerdcommenter
" Select & Comment!
Plug 'preservim/nerdcommenter'

" vim-syntastic
" https://github.com/vim-syntastic/syntastic
" Syntax checker
Plug 'vim-syntastic/syntastic'
" syntastic settings
" For now recommend settings"
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" colorschemes
Plug 'pineapplegiant/spaceduck', {'branch': 'main'}
Plug 'sheerun/vim-polyglot'
" For spaceduck syntax highlight more gracefully
Plug 'junegunn/seoul256.vim'
Plug 'morhetz/gruvbox'
Plug 'sainnhe/everforest'
Plug 'NLKNguyen/papercolor-theme'
Plug 'romainl/Apprentice'
Plug 'nanotech/jellybeans.vim'

" coc-nvim
" https://github.com/neoclide/coc.nvim
" Language support
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install --frozen-lockfile'}

" fzf.vim
" https://github.com/junegunn/fzf.vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
nnoremap <leader><C-n> :Files<CR>

if executable("rg")
    nnoremap <leader>r :Rg!<CR>
else
    nnoremap <leader>r :Ag!<CR>
endif

set rtp+=~/.vim/plugged/fzf
Plug 'junegunn/fzf.vim'

call plug#end()

" colorscheme
if exists('termguicolors')
    let &t_8f = "\<ESC>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<ESC>[48;2;%lu;%lu;%lum"
    set termguicolors
endif
colorscheme spaceduck

""""""" Coc Settings
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
let g:coc_global_config="$HOME/.config/coc/coc-settings.json"
let g:coc_global_extensions = ['coc-explorer', 'coc-json', 'coc-tsserver', 'coc-import-cost', 'coc-eslint', 'coc-snippets', 'coc-git', 'coc-pyright']
if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
# inoremap <silent><expr> <TAB>
#       \ pumvisible() ? "\<C-n>" :
#       \ <SID>check_back_space() ? "\<TAB>" :
#       \ coc#refresh()
# inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
#inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
#                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"


inoremap <slient><expr> <TAB>
            \ coc#pum#visible() ? coc#pum#next(1) :
            \ check_back_space() ? "\<Tab>" :
            \ coc#refresh()

inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <slient><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
            \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"



function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif


" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
"nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
"nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
""""""" End of Coc Settings

" Pipe selected visual block -- CHARACTER WISE -- to command.
" <C-u> after colon is used to cancel " '<,'> ", and it will be piped to
" command's stdin.
xnoremap <leader>c :<C-u> call PipeRangedSelection()<CR>

function! PipeRangedSelection()
	let cmd = input("Command: ")
	redraw
	echo system(cmd, GetVisualSelection(visualmode()))
endfunction

" Forked from https://stackoverflow.com/a/61486601
function! GetVisualSelection(mode)
	" call with visualmode() as the argument
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end]     = getpos("'>")[1:2]
	let lines = getline(line_start, line_end)
	if a:mode ==# 'v'
		" Must trim the end before the start, the beginning will shift left.
		let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
		let lines[0] = lines[0][column_start - 1:]
	elseif  a:mode ==# 'V'
		" Line mode no need to trim start or end
	elseif  a:mode == "\<c-v>"
		" Block mode, trim every line
		let new_lines = []
		let i = 0
		for line in lines
			let lines[i] = line[column_start - 1: column_end - (&selection == 'inclusive' ? 1 : 2)]
			let i = i + 1
		endfor
	else
		return ''
	endif
	"for line in lines
	"    echom line
	"endfor
	return join(lines, "\n")
endfunction

" Keymapping
" NERDTreeKeymapping
" map <Leader>nte <ESC>:NERDTree<CR>
nmap <C-n> <ESC>:NERDTreeToggle<CR>
map <Leader>nte <ESC>:NERDTree<CR>
" map <Leader>ntf <ESC>:NERDTreeFocus<CR>
" map <C-f> <C-f> <ESC>:NERDTreeFocus<CR>
nmap <C-A-f> <ESC>:NERDTreeFocus<CR>

" Moving tab
map <Leader>tn <ESC>:tabn<CR>
map <Leader>tp <ESC>:tabp<CR>

nnoremap <space> za


" Python configs
aug python
    au FileType python setlocal ts=4 sts=4 sw=4 expandtab
    au FileType python set colorcolumn=80
    au FileType python set textwidth=79
    " au FileType python highlight ColorColumn ctermbg=3
aug end

if $TERM == "xterm-256color"
        set t_Co=256
endif

" General configs
set nocompatible
set wrap
set sw=4
set ts=4
set softtabstop=4
set autoindent
set encoding=utf-8
set hidden
set nu
set cursorline
set nobackup
set nowritebackup
set cmdheight=2
set updatetime=300
set shortmess+=c
set hlsearch
set smartindent
set expandtab
set backspace=indent,eol,start
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
autocmd BufReadPost,FileReadPost * normal zR

highlight ColorColumn ctermbg=16

" Theme
syntax enable
" set background=dark

set laststatus=2
set statusline=\ %<%l:%v\ [%P]%=%a\ %h%m%r\ %F\

if has("syntax")
syntax on
endif
