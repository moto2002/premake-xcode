--
-- xcode6.lua
-- Define the Apple XCode action and support functions.
-- Copyright (c) 2015 Tom van Dijck
--

	premake.xcode6 = { }
	local api      = premake.api
	local xcode6   = premake.xcode6
	local project  = premake.project
	local solution = premake.solution

	newaction
	{
		trigger         = "xcode",
		shortname       = "Xcode",
		description     = "Generate Apple Xcode 6 project",
		os              = "macosx",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "SharedLib", "StaticLib", "Makefile", "None" },
		valid_languages = { "C", "C++" },
		valid_tools     = { cc = { "clang" } },

		onsolution = function(sln)
			premake.escaper(premake.xcode6.esc)
			premake.generate(sln, ".xcodeproj/project.pbxproj", xcode6.solution)
		end,

		supportsconfig = function(cfg)
			if (cfg.platform == 'x32') then
				return false;
			end
			return true;
		end,
	}


	function xcode6.solution(sln)
		_p('// !$*UTF8*$!')
		_p('{')
		_p(1, 'archiveVersion = 1;')
		_p(1, 'classes = {')
		_p(1, '};')
		_p(1, 'objectVersion = 46;')

		migBuildRuleId = xcode6.newid('migBuildRuleId')

		xcode6.mergeConfigs(sln)
		local tree = xcode6.getSolutionTree(sln)
		if tree then
			_p(1, 'objects = {')

			xcode6.PBXBuildFile(tree)
			xcode6.PBXBuildRule(tree)
			xcode6.PBXContainerItemProxy(tree)
			xcode6.PBXCopyFilesBuildPhase(tree)
			xcode6.PBXFileReference(tree)
			xcode6.PBXFrameworksBuildPhase(tree)
			xcode6.PBXGroup(tree)
			xcode6.PBXHeadersBuildPhase(tree)
			xcode6.PBXNativeTarget(tree)
			xcode6.PBXProject(tree)
			xcode6.PBXResourcesBuildPhase(tree)
			xcode6.PBXShellScriptBuildPhase(tree)
			xcode6.PBXSourcesBuildPhase(tree)
			xcode6.PBXTargetDependency(tree)
			xcode6.PBXVariantGroup(tree)
			xcode6.XCConfigurationList(tree)

			_p(1, '};')
			_p(1, 'rootObject = %s /* Project object */;', tree.id)
		end

		_p('}')
	end


	function xcode6.PBXBuildFile(tree)
		_p('/* Begin PBXBuildFile section */')

		premake.tree.traverse(tree, {
			onleaf = function(node)
				if node.buildId then
					_p(2, '%s = { isa = PBXBuildFile; fileRef = %s /* %s */; };', node.buildId, node.id, node.name)
				end
			end
		})

		_p('/* End PBXBuildFile section */')
	end


	function xcode6.PBXBuildRule(tree)
		_p('/* Begin PBXBuildRule section */')
		if tree.needsMigRule then
			_p(2, '%s /* PBXBuildRule */ = {', migBuildRuleId)
			_p(3, 'isa = PBXBuildRule;')
			_p(3, 'compilerSpec = com.apple.compilers.proxy.script;')
			_p(3, 'filePatterns = "*.mig";')
			_p(3, 'fileType = pattern.proxy;')
			_p(3, 'isEditable = 1;')
			_p(3, 'outputFiles = (')
			_p(4, '"$(DERIVED_FILES_DIR)/$(INPUT_FILE_BASE)_server.c",')
			_p(4, '"$(DERIVED_FILES_DIR)/$(INPUT_FILE_BASE)_user.c",')
			_p(4, '"$(DERIVED_FILES_DIR)/$(INPUT_FILE_BASE).h",')
			_p(3, ');')
			_p(3, 'script = "mig -header \\"${DERIVED_FILES_DIR}/${INPUT_FILE_BASE}.h\\" -user \\"${DERIVED_FILES_DIR}/${INPUT_FILE_BASE}_user.c\\" -server \\"${DERIVED_FILES_DIR}/${INPUT_FILE_BASE}_server.c\\" \\"${INPUT_FILE_PATH}\\"";')
			_p(2, '};')
		end
		_p('/* End PBXBuildRule section */')
	end


	function xcode6.PBXContainerItemProxy(tree)
		_p('/* Begin PBXContainerItemProxy section */')

		for prj in solution.eachproject(tree.solution) do
			_p(2, '%s /* PBXContainerItemProxy */ = {', prj.xcodeNode.containerItemProxyId)
			_p(3, 'isa = PBXContainerItemProxy;')
			_p(3, 'containerPortal = %s /* Project object */;', tree.id)
			_p(3, 'proxyType = 1;')
			_p(3, 'remoteGlobalIDString = %s;', prj.xcodeNode.targetId)
			_p(3, 'remoteInfo = "%s";', prj.name)
			_p(2, '};')
		end

		_p('/* End PBXContainerItemProxy section */')
		_p('')
	end


	function xcode6.PBXCopyFilesBuildPhase(tree)
		_p('/* Begin PBXCopyFilesBuildPhase section */')


		_p('/* End PBXCopyFilesBuildPhase section */')
		_p('')
	end


	function xcode6.PBXFileReference(tree)
		_p('/* Begin PBXFileReference section */')

		premake.tree.traverse(tree, {
			onleaf = function(node)
				if node.kind == 'fileConfig' then
					_p(2,'%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = %s; name = %s; path = %s; sourceTree = "<group>"; };',
						node.id, node.name, node.fileType, xcode6.quoted(node.name), xcode6.quoted(node.relpath))
				elseif node.kind == 'link' then
					_p(2,'%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = %s; name = %s; path = %s; sourceTree = %s; };',
						node.id, node.name, node.fileType, xcode6.quoted(node.name), xcode6.quoted(node.path), xcode6.quoted(node.sourceTree))
				elseif node.kind == 'product' then
					_p(2,'%s /* %s */ = {isa = PBXFileReference; explicitFileType = %s; includeInIndex = 0; path = %s; sourceTree = BUILT_PRODUCTS_DIR; };',
						node.id, node.name, node.targetType, xcode6.quoted(node.name))
				end
			end
		})

		_p('/* End PBXFileReference section */')
		_p('')
	end


	function xcode6.PBXFrameworksBuildPhase(tree)
		_p('/* Begin PBXFrameworksBuildPhase section */')

		for prj in solution.eachproject(tree.solution) do
			if prj.xcodeNode.frameworkBuildPhaseId then
				_p(2, '%s /* %s */ = {', prj.xcodeNode.frameworkBuildPhaseId, prj.name);
				_p(3, 'isa = PBXFrameworksBuildPhase;')
				_p(3, 'buildActionMask = 2147483647;')
				_p(3, 'files = (')
					for _, dep in ipairs(prj.xcodeNode.dependencies) do
						 _p(4, '%s /* %s */,', dep.xcodeNode.product.buildId, dep.name)
					end
					for _, linkT in ipairs(prj.xcodeNode.frameworks) do
						 _p(4, '%s /* %s */,', linkT.buildId, linkT.name)
					end
				_p(3, ');')
				_p(3, 'runOnlyForDeploymentPostprocessing = 0;')
				_p(2, '};')
			end
		end

		_p('/* End PBXFrameworksBuildPhase section */')
		_p('')
	end


	function xcode6.PBXGroup(tree)
		local settings = {}

		premake.tree.traverse(tree, {
			onnode = function(node)
				-- Skip over anything that isn't a group
				if node.kind == 'fileConfig' or node.kind == 'vgroup' or #node.children <= 0 then
					return
				end

				settings[node.productGroupId] = function()
					_p(2,'%s /* %s */ = {', node.productGroupId, node.name)
					_p(3,'isa = PBXGroup;')
					_p(3,'children = (')
					for _, childnode in ipairs(node.children) do
						if childnode.kind == 'fileConfig' or childnode.kind == 'link' or childnode.kind == 'product' then
							_p(4,'%s /* %s */,', childnode.id, childnode.name)
						else
							_p(4,'%s /* %s */,', childnode.productGroupId, childnode.name)
						end
					end
					_p(3,');')
					_p(3,'name = %s;', premake.xcode6.quoted(node.name))
					_p(3,'sourceTree = "<group>";')
					_p(2,'};')
				end
			end}, true)

		if not table.isempty(settings) then
			_p('/* Begin PBXGroup section */')
			xcode6.printSettingsTable(2, settings)
			_p('/* End PBXGroup section */')
			_p('')
		end
	end


	function xcode6.PBXHeadersBuildPhase(tree)
		_p('/* Begin PBXHeadersBuildPhase section */')


		_p('/* End PBXHeadersBuildPhase section */')
		_p('')
	end


	function xcode6.PBXNativeTarget(tree)
		_p('/* Begin PBXNativeTarget section */')

		for prj in solution.eachproject(tree.solution) do
			_p(2, '%s /* %s */ = {', prj.xcodeNode.targetId, prj.name);
			_p(3, 'isa = PBXNativeTarget;')
			_p(3, 'buildConfigurationList = %s /* Build configuration list for PBXNativeTarget "%s" */;', prj.xcodeNode.configList.id, prj.name)

			_p(3, 'buildPhases = (')
			_p(4, '%s /* Sources */,', prj.xcodeNode.sourcesBuildPhaseId)
			if prj.xcodeNode.frameworkBuildPhaseId then
				_p(4, '%s /* Frameworks */,', prj.xcodeNode.frameworkBuildPhaseId)
			end
			_p(3, ');')

			_p(3, 'buildRules = (')
			if prj.xcodeNode.needsMigRule then
				_p(4, '%s,', migBuildRuleId)
			end
			_p(3, ');')

			_p(3, 'dependencies = (')
			local deps = prj.xcodeNode.dependencies
			if (deps and #deps > 0) then
				for _, dep in ipairs(deps) do
					_p(4, '%s,', dep.xcodeNode.targetDependencyId)
				end
			end
			_p(3, ');')

			_p(3, 'name = %s;', xcode6.quoted(prj.name))
			_p(3, 'productName = %s;', xcode6.quoted(prj.name))
			_p(3, 'productReference = %s /* %s */;', prj.xcodeNode.product.id, prj.xcodeNode.product.name)
			_p(3, 'productType = "%s";', prj.xcodeNode.product.productType)
			_p(2, '};')
		end

		_p('/* End PBXNativeTarget section */')
		_p('')
	end


	function xcode6.PBXProject(tree)
		local sln = tree.solution

		_p('/* Begin PBXProject section */')

		_p(2, '%s /* Project object */ = {', tree.id)
		_p(3, 'isa = PBXProject;')
		_p(3, 'attributes = {')
		_p(4, 'BuildIndependentTargetsInParallel = YES;')
		_p(4, 'LastUpgradeCheck = 0610;')
		_p(3, '};')

		_p(3, 'buildConfigurationList = %s /* Build configuration list for PBXProject "%s" */;', tree.configList.id, sln.name)
		_p(3, 'compatibilityVersion = "Xcode 3.2";')
		_p(3, 'developmentRegion = English;')
		_p(3, 'hasScannedForEncodings = 0;')
		_p(3, 'knownRegions = (')
		_p(4, 'English,')
		_p(4, 'Base,')
		_p(3, ');')

		_p(3, 'mainGroup = %s;', tree.productGroupId)
		_p(3, 'productRefGroup = %s /* %s */;', tree.products.productGroupId, tree.products.name)
		_p(3, 'projectDirPath = "";')
		_p(3, 'projectRoot = "%s";', solution.getrelative(sln, sln.basedir))
		_p(3, 'targets = (')

		for prj in solution.eachproject(sln) do
			_p(4, '%s /* %s */,', prj.xcodeNode.targetId, prj.name)
		end

		_p(3, ');')
		_p(2, '};')
		_p('/* End PBXProject section */')
		_p('')
	end

	function xcode6.PBXResourcesBuildPhase(tree)
		_p('/* Begin PBXResourcesBuildPhase section */')


		_p('/* End PBXResourcesBuildPhase section */')
		_p('')
	end

	function xcode6.PBXShellScriptBuildPhase(tree)
		_p('/* Begin PBXShellScriptBuildPhase section */')


		_p('/* End PBXShellScriptBuildPhase section */')
		_p('')
	end

	function xcode6.PBXSourcesBuildPhase(tree)
		_p('/* Begin PBXSourcesBuildPhase section */')

		for prj in solution.eachproject(tree.solution) do
			_p(2, '%s /* Sources */ = {', prj.xcodeNode.sourcesBuildPhaseId)
			_p(3, 'isa = PBXSourcesBuildPhase;')
			_p(3, 'buildActionMask = 2147483647;')

			_p(3, 'files = (')
			premake.tree.traverse(prj.xcodeNode, {
				onleaf = function(node)
					if node.buildId then
						_p(4,'%s, /* %s */', node.buildId, node.name)
					end
				end})
			_p(3, ');')
			_p(3, 'runOnlyForDeploymentPostprocessing = 0;')
			_p(2, '};')
		end

		_p('/* End PBXSourcesBuildPhase section */')
		_p('')
	end

	function xcode6.PBXTargetDependency(tree)
		_p('/* Begin PBXTargetDependency section */')

		for prj in solution.eachproject(tree.solution) do
			_p(2, '%s /* PBXTargetDependency */ = {', prj.xcodeNode.targetDependencyId)
			_p(3, 'isa = PBXTargetDependency;')
			_p(3, 'target = %s /* %s */;', prj.xcodeNode.targetId, prj.name)
			_p(3, 'targetProxy = %s /* PBXContainerItemProxy */;', prj.xcodeNode.containerItemProxyId)
			_p(2, '};')
		end

		_p('/* End PBXTargetDependency section */')
		_p('')
	end

	function xcode6.PBXVariantGroup(tree)
		_p('/* Begin PBXVariantGroup section */')


		_p('/* End PBXVariantGroup section */')
		_p('')
	end

	function xcode6.XCBuildConfiguration(node)

		local settings = {}
		local cfg = node.config

		if cfg.flags.Cpp11 then
			settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++0x'
		end

		if cfg.flags.NoExceptions then
			settings['GCC_ENABLE_CPP_EXCEPTIONS'] = 'NO'
			settings['GCC_ENABLE_OBJC_EXCEPTIONS'] = 'NO'
		end

		if cfg.flags.NoRTTI then
			settings['GCC_ENABLE_CPP_RTTI'] = 'NO'
		end

		if cfg.flags.Symbols and not cfg.flags.NoEditAndContinue then
			settings['GCC_ENABLE_FIX_AND_CONTINUE'] = 'YES'
		end

		local optimizeMap = { On = 3, Size = 's', Speed = 3, Full = 'fast', Debug = 1 }
		settings['GCC_OPTIMIZATION_LEVEL'] = optimizeMap[cfg.optimize] or 0

		if cfg.pchheader and not cfg.flags.NoPCH then
			settings['GCC_PRECOMPILE_PREFIX_HEADER'] = 'YES'
			settings['GCC_PREFIX_HEADER'] = cfg.pchheader
		end

		settings['GCC_PREPROCESSOR_DEFINITIONS'] = table.join({'$(inherited)'}, premake.esc(cfg.defines))

		settings["GCC_SYMBOLS_PRIVATE_EXTERN"] = 'NO'

		if cfg.flags.FatalWarnings then
			settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'YES'
		end

		settings['GCC_WARN_ABOUT_RETURN_TYPE'] = 'YES'
		settings['GCC_WARN_UNUSED_VARIABLE'] = 'YES'

		if #cfg.includedirs > 0 then
			settings['HEADER_SEARCH_PATHS']      = table.join({'$(inherited)'}, solution.getrelative(cfg.solution, cfg.includedirs))
		end

		if #cfg.libdirs > 0 then
			settings['LIBRARY_SEARCH_PATHS']     = table.join({'$(inherited)'}, solution.getrelative(cfg.solution, cfg.libdirs))
		end

		local fwdirs = xcode6.getFrameworkDirs(node)
		if #fwdirs > 0 then
			settings['FRAMEWORK_SEARCH_PATHS']   = table.join({'$(inherited)'}, fwdirs)
		end

		if cfg.project then
			settings['OBJROOT']                  = solution.getrelative(cfg.solution, cfg.objdir)
			settings['CONFIGURATION_BUILD_DIR']  = solution.getrelative(cfg.solution, cfg.buildtarget.directory)
			settings['PRODUCT_NAME']             = cfg.buildtarget.basename
		else
			settings['USE_HEADERMAP'] = 'NO'
		end

		-- build list of "other" C/C++ flags
		local checks = {
			["-ffast-math"]          = cfg.flags.FloatFast,
			["-ffloat-store"]        = cfg.flags.FloatStrict,
			["-fomit-frame-pointer"] = cfg.flags.NoFramePointer,
		}

		local flags = { }
		for flag, check in pairs(checks) do
			if check then
				table.insert(flags, flag)
			end
		end
		settings['OTHER_CFLAGS'] = table.join(flags, cfg.buildoptions)
		settings['OTHER_LDFLAGS'] = table.join(flags, cfg.linkoptions)

		if cfg.warnings == "Extra" then
			settings['WARNING_CFLAGS'] = '-Wall'
		elseif cfg.warnings == "Off" then
			settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
		end

		_p(2, '%s /* %s */ = {', node.id, node.name)
		_p(3, 'isa = XCBuildConfiguration;')
		_p(3, 'buildSettings = {')
		xcode6.printSettingsTable(4, settings)
		_p(3, '};')
		_p(3, 'name = %s;', xcode6.quoted(node.name))
		_p(2, '};')
	end

	function xcode6.XCConfigurationList(tree)
		local configLists = {}
		local configs = {}

		-- find all configs and config lists.
		premake.tree.traverse(tree, {
			onnode = function(node)
				if node.configList then
					configLists[node.configList.id] = node.configList;
					for _,cfg in ipairs(node.configList.children) do
						configs[cfg.id] = cfg
					end
				end
			end
		}, true)

		_p('/* Begin XCBuildConfiguration section */')
		local keys = table.keys(configs)
		table.sort(keys)
		for _, k in ipairs(keys) do
			xcode6.XCBuildConfiguration(configs[k]);
		end
		_p('/* End XCBuildConfiguration section */')
		_p('')

		_p('/* Begin XCConfigurationList section */')
		keys = table.keys(configLists)
		table.sort(keys)
		for _, k in ipairs(keys) do
			local list = configLists[k]

			_p(2, '%s /* Build configuration list for "%s" */ = {', list.id, list.name)
			_p(3, 'isa = XCConfigurationList;')
			_p(3, 'buildConfigurations = (')
			for _, cfg in ipairs(list.children) do
				_p(4, '%s /* %s */,', cfg.id, cfg.name)
			end
			_p(3, ');')
			_p(3, 'defaultConfigurationIsVisible = 0;')
			_p(3, 'defaultConfigurationName = "%s";', list.children[1].name)
			_p(2, '};')
		end
		_p('/* End XCConfigurationList section */')
		_p('')
	end
