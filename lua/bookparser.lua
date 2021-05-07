-- todo
-- 		clean the code
-- 		make it more readable and understandable
--
-- 		probably some optimization is in order as well..
--
--


local bookparser = {
};

local parser = require("bookline");
local bookCode = require("bookcode");
--parses input into a bookline rows
-- input: table of strings { string1, string2, string3, string4 }
function bookparser.parse(input)
	local output = {};
	local shebangTracker = false;
	local util = require("bookutil");
	local book = require("book");

	local T = bookCode:New();
	for row, data in ipairs(input) do
		if (row > 1 and data ~= nil) then
			local line = parser:Input(row, data);

			-- line is empty shebang (ie, bash: `#!`), will ignore any previous output of the current block
			if (line.type == "Reset" and not shebangTracker) then
				T = bookCode:New();
				T.timeout = book.config.timeout;
			else
				-- line is shebang, start tracking output
				if ( line.type == "Shebang" ) then
					shebangTracker = true;
				end

				-- output begings after shebang
				if (shebangTracker and line.type == "Comment") then line.type = "Output"; end

				-- add to output
				T:AddRow(line);

				-- went past output, start tracking new block.
				if (shebangTracker and line:Empty()) then 
					table.insert(output, T);

					T = bookCode:New();
					shebangTracker = false;
				
				end
			end
		end
	end

	if (#T > 0 and T:HasShebang()) then table.insert(output, T); end
	return output;
end


return bookparser; 

