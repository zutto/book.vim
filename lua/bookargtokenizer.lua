local booktokenizer = {};



-- parse input string into tokens
-- ^ only for arguments --arg1, -arg1, --arg1=123, -arg1=123, --arg1 " asd asd ", -arg1 " asd asd ", etc
-- not very good tokenizer, but keeping it extremely simple.
function booktokenizer:New(input)
	local o = o or {
		Args = {},

		--
		groupCaptureActive = false,
		groupDelimeter = '',
		previous = '',
		current = {},

	};
	self.__index = self;

	setmetatable(o, self);

	o:Parse(input);
	return o;
end


function booktokenizer:Parse(input)
	for chr in string.gmatch(input, ".") do
		if(self:groupStart(chr)) then
			self.groupCaptureActive = true;
			self.groupDelimeter = chr;
		elseif(self:groupEnd(chr)) then
			self.groupCaptureActive = false;
			self.groupDelimeter = '';
			table.insert(self.Args, table.concat(self.current));
			self.current = {};
		elseif(self:argDelimeter(chr)) then
			if (#self.current > 0) then
				table.insert(self.Args, table.concat(self.current));
			end
			self.current = {};
		else
			table.insert(self.current, chr);
		end
		self.previous = chr;
	end
	if (#self.current > 0) then
		table.insert(self.Args, table.concat(self.current));
	end
end


function booktokenizer:groupStart(c)
	if (not self.groupCaptureActive and string.match(c, "[\"']") and not self:Escape()) then
		return true;
	end
	

	return false;
end


function booktokenizer:groupEnd(c)
	if (self.groupCaptureActive and string.match(c, "[\"']") and not self:Escape()) then
		return true;
	end
	

	return false;
end

function booktokenizer:Escape()
	if(string.match(self.previous, "\\")) then
		return true;
	end

	return false;
end

function booktokenizer:argDelimeter(c)
	if (not self.groupCaptureActive and string.match(c, "[=%s]") and not self:Escape()) then
		return true;
	end

	return false;
end
return booktokenizer;
