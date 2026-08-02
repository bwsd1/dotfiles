setlocal noexpandtab
if !exists('b:undo_indent')
  let b:undo_indent = 'setlocal expandtab<'
else
  let b:undo_indent .= '|setlocal expandtab<'
endif
setlocal shiftwidth=0
let b:undo_indent .= '|setlocal shiftwidth<'
if &softtabstop != -1
  let &l:softtabstop = &l:shiftwidth
  let b:undo_indent .= '|setlocal softtabstop<'
endif
