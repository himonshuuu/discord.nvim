if exists('g:loaded_presence_nvim')
  finish
endif
let g:loaded_presence_nvim = 1

lua << EOF
require('presence').setup()
EOF


