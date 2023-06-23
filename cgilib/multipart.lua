-- Handles multipart/form-data

local function parse(body, ct)
	if ct:match("([^;]+)") == "multipart/form-data" then
		local boundary = "--"..ct:match(";%s*boundary=([^;]+)")
		if not boundary then --[[error(400, require("cgilib.error")(400, REQUEST, _SERVER))]] error("bad request") end
		if boundary then
			local blob = io.stdin:read("*a")
			local start = 1
			local file
			local files = {}
			local raw = {}
			local function add_field()
				local cd, props, name
				if not file then goto continue end
				cd = file.headers["Content-Disposition"]
				props = file.properties["Content-Disposition"]
				name = props.name
				if not props.filename then
					files[name] = file.data
				else
					files[name] = {
						name = props.filename,
						data = file.data,
						type = file.headers["Content-Type"]
					}
				end
				raw[name] = {
					headers = file.headers,
					properties = file.properties,
					rawheaders = file.rawheaders,
					data = file.data
				}
				::continue::
				file = {}
			end
			while true do
				local st, en = blob:find(boundary, start, true)
				if file then
					file.data = blob:sub(file.start, st-1)
				end
				add_field()
				if blob:sub(en+1, en+3) == "--" then break end
				local headers = {}
				local rawheaders = {}
				local properties = {}
				local nxt = en+1
				local eoh = false
				while not eoh do
					local st2, en2 = blob:find("\n", nxt)
					if (blob:sub(en2+1, en2+1) == "\n") then
						eoh = true
					end
					local kv = blob:sub(nxt, en2-1)
					local key, value = kv:match("(.+): (.+)")
					local props = {}
					for k, v in value:gmatch("(.+)=([^;]+)", (value:find(";") or 0)+1) do
						props[k] = v:gsub("^\"", ""):gsub("\"$", "") -- fuck it
					end
					rawheaders[key] = value
					headers[key] = value:match("[^;]+")
					properties[key] = props
					nxt = en2+1
				end
				file.start = nxt+1
				file.headers = headers
				file.properties = properties
				file.rawheaders = rawheaders
				start = file.start
			end
			return files, raw
		end
	end
end

return parse