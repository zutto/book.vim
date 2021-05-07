--
--
--
--
--
--
local function get_var(my_var_name, default_value)
  s, v = pcall(function()
    return vim.api.nvim_get_var(my_var_name)
  end)
  if s then return v else return default_value end
end



book = {
	config = {
		enabledInline = false,
		inlineEmbed = get_var("book_inlineEmbed", "!!"),
		inline=get_var("book_inline", "#!"),
		shebang=get_var("book_shebang", "!"),
		comment=get_var("book_comment", "#"),
		timeout = tonumber(get_var("book_timeout", 30)),
		onChange = tonumber(get_var("book_onchange", 0)),
		timeoutcmd = "/usr/bin/env timeout 30", ---?????? no.
	},
	currentBlocks = {},
};




function book:configure()
	--cant reconfigure without being an class
	if (not self) then
		return
	end

	self.inlineEmbed = get_var("book_inlineEmbed", "!!");
	self.inline=get_var("book_inline", "#!");
	self.shebang=get_var("book_shebang", "!");
	self.comment=get_var("book_comment", "#");
	self.timeout = tonumber(get_var("book_timeout", 30));
	self.onChange = tonumber(get_var("book_onchange", 0));
	return
end


--some todos:
--todo previous to next
--timeout to commands!!!
-- streaming output
-- inline exec
-- alot
function book:run(lines)
	if (not self) then
	        setmetatable(book, self);                                                                                             
	        self.__index = self;    
	end
	local blocks = {}
	local parsery = require("bookparser");
	local all_blocks = parsery.parse(lines);
	local util = require("bookutil");

	if (self.currentBlocks == nil) then self.currentBlocks = {}; end


	for _, block in ipairs(all_blocks) do
		local matched = false;
		for _, old_block in pairs(self.currentBlocks) do
			if (block == nil or old_block == nil) then
			end
			if (block:HashCode() == old_block:HashCode()) then
				matched = true;
				table.insert(blocks, old_block);
			end
		end
		if (matched) then 		table.insert(blocks, old_block);	-- add old block
		else				table.insert(blocks, block); 		-- add new block
		end
	end
	

	for i, block in ipairs(self.currentBlocks) do
		if (not block:Exists()) then
			block:Exit(1,0);
			table.remove(self.currentBlocks, i);
		end
			
	end

	self.currentBlocks = blocks;
	local prev = nil	
	for _, block in ipairs(self.currentBlocks) do
		if (block:Exists()) then
			block.timeout = self.config.timeout;
			if (self.timeout ~=nil and self.timeout > 0 and block.running and block.started ~= nil and block.started+book.config.timeout < os.time()) then
				block.Exit(1,0);
			end
			block:Exec(prev);
		else
			block:Exit(1,0);
			block = nil;
		end
		prev = nil
		if (block ~= nil and block ) then
			prev = util.deepcopy(block);
			--prev = block;
		end
	end
end

return book;

