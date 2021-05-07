--todo:
-- 	#1
-- 	parser for shebang arguments (needed in bookcode, and probably other use cases)
-- 	we dont do any lexing in our so, this is special case requirement
-- 	
-- 	#2
-- 	parser for inline output detection 
-- 	for example:
-- 		( { type = "code", data = "echo 'foo bar'; # foo bar", row = 1 }
-- 	this type of lines, # foo bar is inline output
--
-- 	
-- 	#3
-- 	- sanitize the code
-- 	- comment the code better
-- 	- make it more readable
--
--


local bookline = {};
local util = require("bookutil");

-- takes line number and input string, and returns a bookline object
function bookline:Input(lineNumber, str)
	local book = require("book");
	line = line or { 
		input = str,
		data = str,
		stripped = nil,
		row = 0,
		comment = book.config.comment,
		shebang = string.format("%s%s", book.config.comment, book.config.shebang),
		inline = book.config.inline,
		embedInline = book.config.inlineEmbed,
	};

	setmetatable(line, self);
	

	self.__index = self;


	line.data = str;
	line.input = line.data;
	line.row = lineNumber;
	wotline = line:parse();
	return line;
end



--todo finish
function bookline:ParseArgs()
	if (self.input == nil) then return; end
	for line in string.gmatch(self.input, "[^--]+") do 

		--with key = value
		if (string.match(line, "=")) then
			local key, value = string.match(line, "(.+)=(.+)");

		--with just key
		else
		end
	end


end


function bookline:ShebangArgs()
	if ( self.input == nil ) then return; end
	local args = require("bookargtokenizer"); --this name will be the end of me..
	local a = args:New(string.gsub(self.input, string.format("^%s%%s?%s", self.shebang, self:Shebang()), ""));
	return a.Args;

end

--returns shebang (#!/foo/bar -arg1 -flag2) if found, otherwise nil (NOTE: cannot be empty #!)
function bookline:Shebang()
	if ( self.input == nil ) then return; end
	if (string.match(self.input, string.format("^%s", self.shebang))) then
		return string.match(self.input, string.format("^%s%%s?([^%%s]+).?", self.shebang));
	else
		return nil;
	end
end


--returns true if line contains empty shebang (#!), nil if not
function bookline:ShebangReset()
	if (self.input == nil) then return; end
	local input = util.StripWhitespaces(self.input);
	if (input ~= "" and string.match(input, string.format("^%s$", self.shebang))) then
		return true;
	else
		return nil;
	end
end

-- return true if line is a comment
function bookline:Comment()
	if ( self.input == nil ) then return; end
	if ( string.match(self.input, string.format("^%%s?%s", self.comment))) then
		return true;
	end

	return false
end

-- returns true if line is empty
function bookline:Empty()
	if ( self.input == nil ) then return nil; end
	if ( string.gsub(self.input, "[%s]+", "") == "") then
		return true;
	end

	return false;
end


-- parses the lines type, mostly guesswork
function bookline:parse()
	if ( self.input == nil ) then return; end


	if 	(self:Shebang() ~= nil) then 	self.type = "Shebang"; self:ParseArgs(); 	-- line starts with shebang (typically #!/foo/bar)
	elseif 	(self:ShebangReset()) 	then 	self.type = "Reset"; 	-- line starts with shebang ( #! ) but has no data, reset signal 
	elseif 	(self:Comment()) 	then	self.type = "Comment";  -- line starts with comment ( #, or whatever configured)
	elseif 	(self:Empty()) 		then 	self.type = "Code"; 	-- empty lines, type may or may not be changed later depending on shebangs found (see bookparser.lua)
	else					self.type = "Code"; 	-- no other rules matched, guessing identify it as a line of code. doesnt look like a duck, or walk like a duck, so it's probably not a duck, right?
	end

	return self;
end

return bookline;
