  function book#run()
	"echo luaeval('if (book == nil) then book = require("book"); end')
	call luaeval('require("book"):run(_A[1])', [getline(1, '$')]) " no need to call getline? we don't use it?
	"call lua('if (nvim.g.book == nil then nvim.g.book = require("book"); nvim.g.book.run(_A[1]); else nvim.g.book.run(_A[1]); end', [getline(1, '$')])
    endfunction
