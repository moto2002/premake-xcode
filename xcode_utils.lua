--
-- xcode6_utils.lua
-- Define the Apple XCode action and support functions.
-- Copyright (c) 2015 Blizzard Entertainment
--
	local api      = premake.api
	local context  = premake.context
	local xcode6   = premake.xcode6
	local project  = premake.project
	local solution = premake.solution


	function xcode6.newid(...)
		local name = table.concat({...}, ';');
		return string.sub(name:sha1(), 1, 24)
	end


	function xcode6.getFileType(filename)
		local types = {
			[".a"]         = "archive.ar",
			[".app"]       = "wrapper.application",
			[".c"]         = "sourcecode.c.c",
			[".cc"]        = "sourcecode.cpp.cpp",
			[".cpp"]       = "sourcecode.cpp.cpp",
			[".css"]       = "text.css",
			[".cxx"]       = "sourcecode.cpp.cpp",
			[".dylib"]     = "compiled.mach-o.dylib",
			[".S"]         = "sourcecode.asm.asm",
			[".framework"] = "wrapper.framework",
			[".gif"]       = "image.gif",
			[".h"]         = "sourcecode.c.h",
			[".hh"]        = "sourcecode.cpp.h",
			[".hpp"]       = "sourcecode.cpp.h",
			[".hxx"]       = "sourcecode.cpp.h",
			[".html"]      = "text.html",
			[".inl"]       = "sourcecode.c.h",
			[".lua"]       = "sourcecode.lua",
			[".m"]         = "sourcecode.c.objc",
			[".mm"]        = "sourcecode.cpp.objc",
			[".mig"]       = "sourcecode.mig",
			[".nib"]       = "wrapper.nib",
			[".pch"]       = "sourcecode.c.h",
			[".plist"]     = "text.plist.xml",
			[".strings"]   = "text.plist.strings",
			[".xib"]       = "file.xib",
			[".icns"]      = "image.icns",
			[".s"]         = "sourcecode.asm",
			[".sh"]        = "text.script.sh",
			[".bmp"]       = "image.bmp",
			[".wav"]       = "audio.wav",
			[".xcassets"]  = "folder.assetcatalog",
			[".xcconfig"]  = "text.xcconfig",
			[".xml"]       = "text.xml",
		}

		local ext = string.lower(path.getextension(filename));
		return types[ext] or "text"
	end


	function xcode6.getBuildCategory(filename)
		local categories = {
			[".a"] = "Frameworks",
			[".app"] = "Applications",
			[".c"] = "Sources",
			[".cc"] = "Sources",
			[".cpp"] = "Sources",
			[".cxx"] = "Sources",
			[".dylib"] = "Frameworks",
			[".framework"] = "Frameworks",
			[".m"] = "Sources",
			[".mig"] = "Sources",
			[".mm"] = "Sources",
			[".strings"] = "Resources",
			[".nib"] = "Resources",
			[".xib"] = "Resources",
			[".icns"] = "Resources",
			[".s"] = "Sources",
			[".S"] = "Sources",
			[".txt"] = "Resources"
		}
		return categories[path.getextension(filename)]
	end


	function xcode6.getProductType(prj)
		local types = {
			ConsoleApp  = "com.apple.product-type.tool",
			WindowedApp = "com.apple.product-type.application",
			StaticLib   = "com.apple.product-type.library.static",
			SharedLib   = "com.apple.product-type.library.dynamic",
		}
		return types[prj.kind]
	end


	function xcode6.getTargetType(prj)
		local types = {
			ConsoleApp  = "\"compiled.mach-o.executable\"",
			WindowedApp = "wrapper.application",
			StaticLib   = "archive.ar",
			SharedLib   = "\"compiled.mach-o.dylib\"",
		}
		return types[prj.kind]
	end


	function xcode6.getTargetName(prj, cfg)
		if prj.external then
			return cfg.project.name
		end
		return cfg.buildtarget.bundlename ~= "" and cfg.buildtarget.bundlename or cfg.buildtarget.name;
	end


	function xcode6.isItemResource(project, node)
		local res;
		if project and project.xcodebuildresources and type(project.xcodebuildresources) == "table" then
			res = project.xcodebuildresources
		end

		local function checkItemInList(item, list)
			if item and list and type(list) == "table" then
				for _,v in pairs(list) do
					if string.find(item, v) then
						return true
					end
				end
			end
			return false
		end

		return checkItemInList(node.path, res);
	end


	function xcode6.getFrameworkDirs(cfg)
		local done = {}
		local dirs = {}

		if cfg.project then
			table.foreachi(cfg.links, function(link)
				if link:find('.framework$') and path.isabsolute(link) then
					local dir = solution.getrelative(cfg.solution, path.getdirectory(link))
					if not done[dir] then
						table.insert(dirs, dir)
						done[dir] = true
					end
				end
			end)
		end

		local frameworkdirs = xcode6.fetchlocal(cfg, 'xcode_frameworkdirs')
		if frameworkdirs then
			table.foreachi(frameworkdirs, function(dir)
				if path.isabsolute(dir) then
					dir = solution.getrelative(cfg.solution, dir)
				end
				if not done[dir] then
					table.insert(dirs, dir)
					done[dir] = true
				end
			end)
		end

		return dirs
	end

	local escapeSpecialChars = {
		['\n'] = '\\n',
		['\r'] = '\\r',
		['\t'] = '\\t',
	}


	local function escapeChar(c)
		return escapeSpecialChars[c] or '\\'..c
	end


	local function escapeArg(value)
		value = value:gsub('[\'"\\\n\r\t ]', escapeChar)
		return value
	end


	function xcode6.esc(value)
		value = value:gsub('["\\\n\r\t]', escapeChar)
		return value
	end


	function xcode6.quoted(value)
		value = value..''
		if not value:match('^[%a%d_./]+$') then
			value = '"' .. xcode6.esc(value) .. '"'
		end
		return value
	end


	function xcode6.filterEmpty(dirs)
		return table.translate(dirs, function(val)
			if val and #val > 0 then
				return val
			else
				return nil
			end
		end)
	end


	function xcode6.printSetting(level, name, value)
		if type(value) == 'function' then
			value(level, name)
		elseif type(value) ~= 'table' then
			_p(level, '%s = %s;', xcode6.quoted(name), xcode6.quoted(value))
		elseif #value == 1 then
			_p(level, '%s = %s;', xcode6.quoted(name), xcode6.quoted(value[1]))
		elseif #value > 1 then
			_p(level, '%s = (', xcode6.quoted(name))
			for _, item in ipairs(value) do
				_p(level + 1, '%s,', xcode6.quoted(item))
			end
			_p(level, ');')
		end
	end


	function xcode6.printSettingsTable(level, settings)
		-- Maintain alphabetic order to be consistent
		local keys = table.keys(settings)
		table.sort(keys)
		for _, k in ipairs(keys) do
			xcode6.printSetting(level, k, settings[k])
		end
	end


	function xcode6.fetchlocal(cfg, key)
		local prj = cfg.project

		-- If it's a solution config, just fetch the value normally.
		if not prj then
			return cfg[key]
		end

		-- If it's a project config, then we only want values specified at the project or configuration level.
		local field = premake.field.get(key)
		if not field then
			return cfg[key]
		end

		local value = nil
		if premake.field.merges(field) then
			value = context.fetchvalue(prj, key, true)
			value = premake.field.merge(field, value, context.fetchvalue(cfg, key, true))
		else
			value = context.fetchvalue(cfg, key, true)
			if value == nil then
				value = context.fetchvalue(prj, key, true)
			end
		end

		return value
	end

