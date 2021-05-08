## note
This is not actively maintained, and has been left in a semi-working state of work-in-progress. Hopefully one day I'll get back to actually finishing this properly. I am just throwing this out to public, so it doesn't just sit on my computer, it's a fun plugin made in a rush during 2020 advent of code.

# book.vim
Vim plugin to evaluate scripts & code inline with ease!

## Features
* Easy to use - just write your shebang under your code.
* Configurable!
* Evaluate multiple chunks of code
* Evaluate output of previous code chunk in a following chunk! (* note: theres probably bugs with this)
* Code is stil

## Usage
Just write `#!/bin/bash` and run :Book to get output! ( asciinema recording explains better than thousand words!)

#### Simple usage
[![asciicast](https://asciinema.org/a/93QJfa7hAlm5fmf7UXI6GA1q6.svg)](https://asciinema.org/a/93QJfa7hAlm5fmf7UXI6GA1q6)
### Long running scripts with a piped output and not just a simple command? Not a problem!
[![asciicast](https://asciinema.org/a/eh9lYJo3vCkPecSkXRZLObjG1.svg)](https://asciinema.org/a/eh9lYJo3vCkPecSkXRZLObjG1)
#### Previous commands output to next chunk of code? can do. Default replacement variable: `!!`
[![asciicast](https://asciinema.org/a/412725.svg)](https://asciinema.org/a/412725)

#### want to have code cut from the chunk? not a problem.
Just insert a shebang line without command to split the output.
```
#!/bin/bash
echo "Hello World!";    
#!    
echo "foo bar!";    
#!/bin/bash         
# /bin/bash: line 1: unexpected EOF while looking for matching `''
# /bin/bash: line 24: syntax error: unexpected end of file

##  Configuration
#### Basic settings
```
" comment is the character(S) prefixing all output lines, 
" to preserve the executability of the code outside of vim.
let g:book_comment='#' 

" Shebang is the *nix magic, prefixed by a comment character with this as a suffix
" #!/bin/bash as an example.
let g:book_shebang='!'

" Embed output of previous chunk into the following chunk of code with this value.
" It literally replaces the inlineEmbed value with the output of previous command.
" This is a buggy feature, and possibly removed later on.
let g:book_inlineEmbed='!!'

" Don't think that this works, but is a plan to ensure that there are
" no code that just keep executing forever if configured.
let g:book_timeout='2' " don't this this currently works..

" Another planned feature of evaluating single lines of code.
let g:book_inline='#!' " this is a planned feature.

" evaluate only on change. I don't this this is implemented either,
" all code blocks are re-evaluated upon execution of :Book.
let g:book_onchange='0' "
```

#### How do I  evaluate my code right after leaving input mode?
Add this to your vimrc.
```
autocmd InsertLeave * :Book
```

#### different shebang lines for different languages? no problem!
 take a look at this example and adjust it to your preferences!
```
augroup book_settings    
        autocmd!    
        autocmd BufNewFile,BufRead,Filetype *.sh let g:book_comment='#'    
        autocmd BufNewFile,BufRead,Filetype *.sh let g:book_shebang='!'    
        autocmd BufNewFile,BufRead,Filetype *.sh let g:book_inline='#!'    
        autocmd BufNewFile,BufRead,Filetype *.sh let g:book_inlineEmbed='!!'    
        autocmd BufNewFile,BufRead,Filetype *.sh let g:book_timeout='0'    
        autocmd BufNewFile,BufRead,Filetype *.sh let g:book_onchange='0' "only re-run on change    
    
        autocmd!    
        autocmd BufNewFile,BufRead,Filetype *.lua let g:book_comment='--'    
        autocmd BufNewFile,BufRead,Filetype *.lua let g:book_shebang='!'    
        autocmd BufNewFile,BufRead,Filetype *.lua let g:book_inline='--'    
        autocmd BufNewFile,BufRead,Filetype *.lua let g:book_inlineEmbed='!!'    
        autocmd BufNewFile,BufRead,Filetype *.lua let g:book_timeout='0'    
        autocmd BufNewFile,BufRead,Filetype *.lua let g:book_onchange='0' "only re-run on change    
    
augroup end    
```



---
---
---

[![asciicast](https://asciinema.org/a/412666.svg)](https://asciinema.org/a/412666)


