
require("test2"):setup()
require("git"):setup()
require("auto-layout").setup({
   breakpoint_large = 90,  -- new large window threshold, defaults to 100
   breakpoint_medium = 60,  -- new medium window threshold, defaults to 50
 })

-- ~/.config/yazi/init.lua
th.git = th.git or {}
th.git.modified = ui.Style():fg("blue")
th.git.deleted = ui.Style():fg("red"):bold()

-- ~/.config/yazi/init.lua
-- function Linemode:size_and_mtime()
-- 	local time = math.floor(self._file.cha.mtime or 0)
-- 	if time == 0 then
-- 		time = ""
-- 	elseif os.date("%Y", time) == os.date("%Y") then
-- 		time = os.date("%b %d %H:%M", time)
-- 	else
-- 		time = os.date("%b %d  %Y", time)
-- 	end

-- 	local size = self._file:size()
-- 	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
-- end

