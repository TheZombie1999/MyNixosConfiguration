
local set_pid = ya.sync( function (state, pid)
	ya.dbg("set_pid")
	ya.dbg(pid)
	state.pid = pid
end)

local get_pid = ya.sync( function (state)
	ya.dbg("get_pid")
	ya.dbg(pid)
	return state.pid
end)

local function setup(state, job)
	ps.sub("cd", function()
		ya.dbg("CD")
		local pid = get_pid()
		ya.dbg(pid)
		if (pid ~= nil) then
			ya.dbg("Not Nil")
			cwd = tostring(cx.active.current.cwd)
			command=string.format("bash -c 'echo %s > ~/.local/share/bash/dir'", cwd)
			os.execute(command)
			os.execute(string.format("bash -c 'kill -s SIGUSR1 %d'", pid))
			os.execute(string.format("bash -c 'kill -s SIGINT %d'", pid))
		end
	end)
end

local function entry(state)
	ya.dbg("test")
	
	local child, err = Command("alacritty"):spawn()
	local pid = child:id()
	ya.sleep(1)
	local output, err = Command("pgrep"):arg("-P"):arg(tostring(pid)):output()
	ya.dbg(string.format("Ouput: %s", output.stdout))
	local pid_bash = tonumber(output.stdout)
	set_pid(pid_bash)
	child:wait()
end

return { setup = setup, entry = entry }

