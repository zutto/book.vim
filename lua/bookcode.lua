-- todo
-- 		ok theres a tons of stuff to do here
--
--
-- 		clean the code
-- 		comment the code <--- quite high prio at the moment, things here need explanation
-- 		make it readable
-- 		remove hacks...
--
-- 		a lot of optimization is in order as well
--
--
--
--

local bookcode = {}


-- ::New creates a new group of lines that represent a block of code.
function bookcode:New(o)
        o = o or {                                                                      
                code = {},                           
                output = {},    
                                                                                   
                -- std in, out, err                   
                sin = nil,                             
                sout = nil,    
                serr = nil,    
                                
                --               
                handle = nil,    
                opt = nil,                                                                                           
		running = false,

		cleaned = false,
		started = os.time(),
		timeout = 99999999,
        };    
                                  
        setmetatable(o, self);                              
                                                                                         
                                
        self.__index = self;    
	o.started = os.time();
        return o;   
end

--adds single row of code
--input: bookline
function bookcode:AddRow(input)
	local util = require("bookutil");
	table.insert(self.code, util.deepcopy(input)); --without deepcopy, the table references the last row over and over again .. I hate this in lua
end


-- called with stdout, no active timer running to monitor this or anything
function bookcode:Timeout()
	if (self.running and self.timeout > 0 and self.started+self.timeout < os.time()) then
		self:Exit(1, 0);
	end
end

-- adds code into the group (overrides old)
-- input: table of sorted booklines, { bookline, bookline, bookline }
function bookcode:Code(input)
	for k, v in ipairs(input) do
		if ( v.type == nil or v.data == nil ) then
			return false;
		end    
	end
	
	self.code = input;
	return true;

end

-- returns true if lines of code have shebang
function bookcode:HasShebang()
	if (self.code == nil) then return false; end
	for _, v in ipairs(self.code) do
		if (v.type == "Shebang") then
			return true;
		end
	end
	return false;
end


--name is misleading, this is not a hash. - no built in hashing in lua, plan was to implement djb2 but something happened.
--returns whitespaceless chunk of all the self.code data
function bookcode:Hash()
	local util = require("bookutil");
	local chunk = "";

	for _, line in ipairs(self.code) do
		chunk = string.format("%s%s", chunk, util.StripWhitespaces(line.data));
	end

	return chunk;
end


--another misleading name, returns a chunk of all self.code where self.code[n].type equals to "Code"
function bookcode:HashCode()
	local util = require("bookutil");
	local chunk = "";

	for _, line in ipairs(self.code) do
		if (line.type == "Code") then
			chunk = string.format("%s%s", chunk, util.StripWhitespaces(line.data));
		end
	end

	return chunk;
end


-- tests if this block of code exists in the buffer
function bookcode:Exists()
	return self:Position(true);
end


--re-positions code so that paste doesn't override other stuff, returns false if it does not exist.
--noupdate: set this to anything but nil to update blocks known code (used for updating row numbers & output)
--
function bookcode:Position(noupdate)
	-- the first parameter, buffers is still a mystery to me.. TODO? halp?
	-- (buffer, start, stop, error on nil)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false);

	--parse blocks
	local blocks = require("bookparser").parse(lines);
	if (blocks == nil or #blocks < 1) then
		return false
	end

	-- lazy string globbing, because hash.. --TODO, I'M LAZY
	for _, group in ipairs(blocks) do
		if (group:HashCode() == self:HashCode()) then
			if (noupdate == nil) then
				--mux deletes
				for k, v in ipairs(self.code) do
					for kk, vv in ipairs(group.code) do
						if (vv.data == v.data and v.type == "Output") then
							vv.deleted = v.deleted;
						end
					end
				end
				self.code = group.code;
			end
			return true;
		end
	end
	return false;
end




--returns starting line for output
--startFromShebang: set to true to get starting position from #!shebang line instead
--this used if we're printing blocks rather than stdout.. which we dont do atm
function bookcode:GetOutputStart(startFromShebang)
	if (not self:Position()) then return; end


	if (startFromShebang ~= nil) then
		for _, v in ipairs(self.code) do
			if (v.type == "Shebang") then
				return v.row;
			end
		end
	else
		local r = self.code[#self.code].row;
		for _, v in ipairs(self.code) do
				--require("bookutil").debug2("output", {me="set row to", newrow= v.row, oldrow=r, del = v.deleted, type=v.type});
			if (v.type == "Output" and v.row < r) then
				if (v.deleted or self.cleaned ~= true) then
					r = v.row;
				end
			end
		end
		return r;
	end

	return nil;
end


-- cleans the output (used if we see ansi clear escape cope for example..
-- (updated to mark output to be deleted, rather than directly replace it)
function bookcode:CleanOutput()
	local min = self:GetOutputStart(true);
	if (min == nil) then return; end
	--mark lines to be deleted.. all of them
	for i, v in ipairs(self.code) do
		if (v.type == "Output") then
			self.code[i].deleted = true;
		end
	end
--	end
--	if (min == nil) then return; end
--	local max = self.code[#self.code].row;
--	local util = require("bookutil");
--	vim.api.nvim_buf_set_lines(0, min, max, false, {""});
end


--render data, remove old stdout marked for deletion
--min: starting line
--max: ending line
-------- note: min max doesn't mean you need to make it long as the input is, just what lines you want to replace! - think of this as select & paste over
--lines: table of strings {"str1", "str2", "str3} to output into the buffer
function bookcode:Render(min, max, lines)

	--figure out deleted lines
	local delstart, delstop = -1, -1;
	for k, v in ipairs(self.code) do
		if (v.type == "Output" and v.deleted ~= nil and v.deleted) then
			if (delstart < 0 and v.row < delstart) 		then delstart = v.row;
			elseif (delstop < 0 and v.row > delstop) 	then delstop = v.row
			end
		end
	end
	
	--we know range that we want to delete, now mix it with output
	if (delstart > -1 and delstop > -1 and delstart < delstop) then
		-- more lines in new output than old? do nothing
		if( #lines > (delstop - delstart)) then
			--less lines and max is less than delstop? set max to delstop
		elseif (#lines < (delstop - delstart) and max < delstop) then
			max = delstop;
		end
	end

	--the magic
	vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), min, max, false, lines);
end


--prints output "realtime" (as received from the event loop, instead of waiting for finish)
function bookcode:stdPrinter(input, reset)
	if (not self:Position() or #input < 1) then return; end


	-- clean the output from previous stdout (re-running :Book on same block)
	if (not self.cleaned or reset) then
		self:CleanOutput(reset);
		self.cleaned = true;
	end

	--set the starting and end positions 
	----- holy shit this needs to be updated, pls send halp
	local min = self:GetOutputStart(reset);
	if (reset ~= nil) then min = min + 1; end
	if (min == nil) then return; end
	local max = self.code[#self.code].row;
	if (max <= min) then max = min; end
	if (#input < 1) then return end;

	self:Render(min-1, max-1, input);
end

--deprecated in favour of streaming output
function bookcode:Print(input)
	--reposition - if false, our code doenst exist anymore.
	if (not self:Position()) then return; end
	--sort just incase ??? should be in order
	-- table.sort(self.code, function(a, b) return a.row < b.row; end);


	-- theres probably a way for max < min - TODO FIX
	local min, max = 0, self.code[#self.code].row;
	for _, v in ipairs(self.code) do
		if (v.type == "Shebang") then
			min = v.row;
		end
	end
	

	local moutput = {};
	for k, v in ipairs(self.output) do
		table.insert(moutput, v);
	end
	

	if (input ~= nil) then min = self.code[#self.code].row-1; moutput = input; end
	if (max < min+1) then max = min+1; end
	local util = require("bookutil");

	if (moutput[#moutput] ~= "") then
		table.insert(moutput, "");
	end

	vim.api.nvim_buf_set_lines(0, min, max, false, moutput);

end


--accepts stdin from the process
---------------------------------- oh god pls no
function bookcode:StdOut(err, data)
	local util = require("bookutil");
	local book = require("book");
	if (data ~= nil) then
		local mine = {}
		local parrotmode = nil;
		for line in string.gmatch(data, "[^\n]+") do
			local stripped = util.StripWhitespaces(line);
			--todo fix
			--for giggles, ansi reset detection.. need to write library to handle these ansi escape codes properly, this is horrible way.
			--(ie: $(clear) on bash)
--			if (string.match(stripped, "%^%[%[2J") and 
			if(line ~= nil and string.match(stripped, string.char(27).."%[%d?J") or string.match(stripped, string.char(27).."%[%d?;?%d?H")) then
				-- this is useless?
				self:stdPrinter(mine, parrotmode);
				mine = {};
				parrotmode = true;
				line = string.match(line, string.format("^.+%s(.*)", string.char(27).."%[H"));
				if (line ~= nil) then
					line = string.gsub(line, string.format("%s", string.char(27).."%[%d?J"), "");
				end
				self:CleanOutput();
			end

			if (line ~= nil and util.StripWhitespaces(line) ~= "") then
				table.insert(self.output, string.format("%s %s", book.config.comment, line));
				table.insert(mine, string.format("%s %s", book.config.comment, line));
			end
		end

		--self:Print(mine);
		if(#mine > 0) then
			self:stdPrinter(mine);
			--self:Position();
		end
	end
	self:Timeout();
	return;

end

--accepts stderr from the process
function bookcode:StdErr(err, data)
	if (1 == 1) then
		return self:StdOut(err, data);
	end
	local util = require("bookutil");
	local book = require("book");
	if (data ~= nil) then
		for line in string.gmatch(data, "[^\n]+") do
			local stripped = util.StripWhitespaces(line);
			if (stripped ~= "") then
				table.insert(self.output, string.format("%s [ERR%s] %s", book.config.comment, tostring(err), line));
			end
		end

--		self:Print();
		self:Timeout();
		return;
	end
end



--returns the args from shebang line
function bookcode:GetArgs()
	if ( self.code == nil or #self.code < 1) then
		return nil;
	end
	for _, v in ipairs(self.code) do
		if (v.type == "Shebang") then
			return v:ShebangArgs();
		end
	end

	return {};
end



--returns the command from shebang line
function bookcode:GetCmd()
	if ( self.code == nil or #self.code < 1) then
		return nil;
	end
	for _, v in ipairs(self.code) do
		if (v.type == "Shebang") then
			return v:Shebang();
		end
	end
	return nil;
end



--closes FD pipes on exit
function bookcode:Exit(code, signal)
	if (self.sout ~= nil) then
		self.sout:read_stop();
		if (not self.sout:is_closing()) then self.sout:close(); end
	end

	if (self.serr ~= nil) then
		self.serr:read_stop();
		if (not self.serr:is_closing()) then self.serr:close(); end
	end


	self.running = false;
	if (self.handle ~= nil) then
		self.handle:close();
	end
	self.handle = nil;
	self.sin = nil;
	self.sout = nil;
	self.serr = nil;
	self.cleaned = false;
--	self:Print();
end



--runs the cmd from shebang line
function bookcode:Exec(previous)
	local book = require("book");
--	require("bookutil").debug("output", {prevvvv = previous});
	-- one instance running only.
	if (self.running or self.sout ~= nil or self.sin ~= nil) then return; end
	self.sin, self.sout, self.serr = vim.loop.new_pipe(false), vim.loop.new_pipe(false), vim.loop.new_pipe(false); 
	self.opt = {
		stdio = { self.sin, self.sout, self.serr },
		args = self:GetArgs(),
		command = self:GetCmd(),
	}
--	require("bookutil").debug3("output", self.opt.args);
	local vs = vim.schedule_wrap;
	if (self.opt.command ~= nil) then
		self.output = {};
		self.running = true;
		-- init
		self.handle = vim.loop.spawn(self.opt.command, self.opt, vs(function(c, s) self:Exit(c, s); end));

		--pipes
		self.sout:read_start(vs ( function(e, o) self:StdOut(e, o); end )); 
		self.serr:read_start(vs ( function(e, o) self:StdErr(e, o); end )); 
		local prev = "";
		if (previous ~= nil) then
			previous:Position();
			for k, v in ipairs(previous.code) do
				if (v ~= nil and v.type == "Output") then
					local data = string.gsub(v.data, string.format("^%s ", book.config.comment), "");
					if (prev ~= "") then 	prev = string.format("%s\n%s", prev, data);
					else 			prev = string.format("%s", data);
					end
				end
			end
		end
		--stdin
		for _, v in ipairs(self.code) do
			if (v.type == "Code") then
				local data = v.data
				if (prev ~= "" and string.match(v.data, string.format("^([^%s]+)", book.config.comment)) ~= nil and string.match(string.match(v.data, string.format("^([^%s]+)", book.config.comment)), book.config.inlineEmbed)) then
					data = string.gsub(v.data, book.config.inlineEmbed, prev);
				end
--				require("bookutil").debug("output", { to = self.opt.command, data = data, pre, prevy = prev});
				self.sin:write(string.format("%s\n", data));
			end
		end

		--process exits when shutdown is called last input should be released only after exit... should...
		self.sin:shutdown();
		self.running = false;
	end
end


return bookcode;
