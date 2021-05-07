if exists('g:book_loaded')
      finish
endif
 "   let g:book_loaded = 1
 "   let g:book = 0 
 "   let g:book_comment='#'
 "   let g:book_shebang='!'
 "   let g:book_inlineEmbed='!!'
 "   let g:book_timeout='30' 
 "   let g:book_inline='#!'
    "set book_comment = #
    command Book :call book#run()
    command BookConfigure :call book#configure() "probably doesn't work?
