" Define autocommands to handle auto-update events
function presence#SetAutoCmds()
    augroup presence_events
        autocmd!
        if exists('g:presence_auto_update') && g:presence_auto_update
            autocmd FocusGained * lua require('presence').handle_focus_gained(require('presence'))
            autocmd TextChanged * lua require('presence').handle_text_changed(require('presence'))
            autocmd VimLeavePre * lua require('presence').handle_vim_leave_pre(require('presence'))
            autocmd WinEnter * lua require('presence').handle_win_enter(require('presence'))
            autocmd WinLeave * lua require('presence').handle_win_leave(require('presence'))
            autocmd BufEnter * lua require('presence').handle_buf_enter(require('presence'))
            autocmd BufAdd * lua require('presence').handle_buf_add(require('presence'))
        endif
    augroup END
endfunction
