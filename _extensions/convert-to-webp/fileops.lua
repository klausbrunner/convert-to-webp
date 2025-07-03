local fileops = {}

function fileops.file_exists(path)
	local f <close> = io.open(path, "rb")
	return f ~= nil
end

function fileops.file_size(path)
	local f <close> = io.open(path, "rb")
	return f and f:seek("end")
end

function fileops.run_and_capture(cmd)
	local p = io.popen(cmd .. " 2>&1")
	if not p then
		return "", false
	end
	local out = p:read("*a")
	local ok = p:close()
	return out, ok
end

function fileops.sh_quote(str)
	return "'" .. str:gsub("'", "'\\''") .. "'"
end

function fileops.get_mtime(path)
	local qp = fileops.sh_quote(path)
	for _, fmt in ipairs({ "-c %Y", "-f %m" }) do
		local out, ok = fileops.run_and_capture(("stat %s %s"):format(fmt, qp))
		if ok then
			return tonumber(out:match("%d+"))
		end
	end
end

return fileops
