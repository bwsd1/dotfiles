" make recipe lines must begin with a tab
setlocal noexpandtab
let b:undo_indent = 'setlocal expandtab<'
setlocal shiftwidth=0
let b:undo_indent .= '|setlocal shiftwidth<'
if &softtabstop != -1
  let &l:softtabstop = &l:shiftwidth
  let b:undo_indent .= '|setlocal softtabstop<'
endif
