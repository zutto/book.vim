local bookutil = {}


-- strips whitespaces
-- input: string
function bookutil.StripWhitespaces(input)
	return string.gsub(input, "%s+", "");
end
function bookutil.debug3(file, data)
	--vim._system(string.format("cat <<- EOF >> %s \n %s \nEOF", file, vim.inspect(data)));
end

function bookutil.debug2(file, data)
	--vim._system(string.format("cat <<- EOF >> %s \n %s \nEOF", file, vim.inspect(data)));
end

function bookutil.debug(file, data)
	--vim._system(string.format("cat <<- EOF >> %s \n %s \nEOF", file, vim.inspect(data)));
end


-- this is the biggest thing I dislike about lua - no built in way to create deep copies of tables :(, copied from SO IIRC, credit's to whoever wrote it!
function bookutil.deepcopy(orig, copies)
	   copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[bookutil.deepcopy(orig_key, copies)] = bookutil.deepcopy(orig_value, copies)
            end
            setmetatable(copy, bookutil.deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end



return bookutil;

