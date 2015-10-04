---
-- VSAndroid/vsandroid_packaging.lua
-- VS Android projects generator.
-- Copyright (c) 2015 Dmytro "StiX" Vovk and the Premake project
---

	premake.modules.vsandroid_packaging = {}

	local p = premake
	local pack = p.modules.vsandroid_packaging
	local vc2010 = p.vstudio.vc2010
	local project = p.project
	local vstudio = p.vstudio
	local solution = p.solution
	local tree = premake.tree
	
	
---
-- Override vs action's methods
---
	
	premake.override(vstudio, "tool", function(oldfn, prj)
		if prj.kind == "Packaging" then
			return "39E2626F-3545-4960-A6E8-258AD8476CE5"
		end
		
		return oldfn(prj)
	end)
	
	function pack.configurationPlatforms(sln)	-- TODO: refactor original premake to fix this
		local descriptors = {}
		local sorted = {}

		for cfg in solution.eachconfig(sln) do

			-- Create a Visual Studio solution descriptor (i.e. Debug|Win32) for
			-- this solution configuration. I need to use it in a few different places
			-- below so it makes sense to precompute it up front.

			local platform = vstudio.solutionPlatform(cfg)
			descriptors[cfg] = string.format("%s|%s", cfg.buildcfg, platform)

			-- Also add the configuration to an indexed table which I can sort below

			table.insert(sorted, cfg)

		end

		-- Sort the solution configurations to match Visual Studio's preferred
		-- order, which appears to be a simple alpha sort on the descriptors.

		table.sort(sorted, function(cfg0, cfg1)
			return descriptors[cfg0]:lower() < descriptors[cfg1]:lower()
		end)

		-- Now I can output the sorted list of solution configuration descriptors

		-- Visual Studio assumes the first configurations as the defaults.
		if sln.defaultplatform then
			_p(1,'GlobalSection(SolutionConfigurationPlatforms) = preSolution')
			table.foreachi(sorted, function (cfg)
				if cfg.platform == sln.defaultplatform then
					_p(2,'%s = %s', descriptors[cfg], descriptors[cfg])
				end
			end)
			_p(1,"EndGlobalSection")
		end

		_p(1,'GlobalSection(SolutionConfigurationPlatforms) = preSolution')
		table.foreachi(sorted, function (cfg)
			if not sln.defaultplatform or cfg.platform ~= sln.defaultplatform then
				_p(2,'%s = %s', descriptors[cfg], descriptors[cfg])
			end
		end)
		_p(1,"EndGlobalSection")

		-- For each project in the solution...

		_p(1,"GlobalSection(ProjectConfigurationPlatforms) = postSolution")

		local tr = solution.grouptree(sln)
		tree.traverse(tr, {
			onleaf = function(n)
				local prj = n.project

				-- For each (sorted) configuration in the solution...

				table.foreachi(sorted, function (cfg)

					local platform, architecture

					-- Look up the matching project configuration. If none exist, this
					-- configuration has been excluded from the project, and should map
					-- to closest available project configuration instead.

					local prjCfg = project.getconfig(prj, cfg.buildcfg, cfg.platform)
					local excluded = (prjCfg == nil or prjCfg.flags.ExcludeFromBuild)

					if prjCfg == nil then
						prjCfg = project.findClosestMatch(prj, cfg.buildcfg, cfg.platform)
					end

					local descriptor = descriptors[cfg]
					local platform = vstudio.projectPlatform(prjCfg)
					local architecture = vstudio.archFromConfig(prjCfg, true)

					_p(2,'{%s}.%s.ActiveCfg = %s|%s', prj.uuid, descriptor, platform, architecture)

					-- Only output Build.0 entries for buildable configurations

					if not excluded and prjCfg.kind ~= premake.NONE then
						_p(2,'{%s}.%s.Build.0 = %s|%s', prj.uuid, descriptor, platform, architecture)
						
						if prjCfg.kind == "Packaging" then
							_p(2,'{%s}.%s.Deploy.0 = %s|%s', prj.uuid, descriptor, platform, architecture)
						end
					end

				end)
			end
		})
		_p(1,"EndGlobalSection")
	end
	
	vstudio.sln2005.sectionmap["ConfigurationPlatforms"] = pack.configurationPlatforms
	
	
	pack.elements = {}
	
	pack.elements.project = function(prj)
		return {
    	    vc2010.xmlDeclaration,
			pack.project,
			vc2010.projectConfigurations,
			pack.globals,
			pack.importDefaultProps,
			pack.configurationPropertiesGroup,
			pack.importExtensionSettings,
			vc2010.userMacros,
			pack.itemDefinitionGroups,
			pack.files,
			vc2010.projectReferences,
			pack.importExtensionTargets,
		}
	end
	
	
	function pack.generatePackaging(prj)
		p.utf8()
		p.callArray(pack.elements.project, prj)
		p.out('</Project>')
	end
	
	pack.elements.globals = function(prj)
		return {
			pack.keyword,
			vc2010.projectGuid,
			vc2010.ignoreWarnDuplicateFilename,
			
		}
	end
	
	function pack.globals(prj)
		vc2010.propertyGroup(nil, "Globals")
		p.callArray(pack.elements.globals, prj)
		p.pop('</PropertyGroup>')
	end
	
	function pack.keyword(prj)
		vc2010.element("RootNamespace", nil, "%s", prj.name)
		vc2010.element("MinimumVisualStudioVersion", nil, "14.0")
		vc2010.element("ProjectVersion", nil, "1.0")
	end
	
	function pack.importDefaultProps(prj)
		p.w('<Import Project="$(AndroidTargetsPath)\\Android.Default.props" />')
	end
	
	function pack.configurationPropertiesGroup(prj)
		for cfg in project.eachconfig(prj) do
			pack.configurationProperties(cfg)
		end
	end
	
	function pack.useDebugLibraries(cfg)
		local runtime = vstudio.projectPlatform(cfg)
		vc2010.element("UseDebugLibraries", nil, tostring(runtime:endswith("Debug")))
	end
	
	function pack.configurationProperties(cfg)
		vc2010.propertyGroup(cfg, "Configuration")
		pack.useDebugLibraries(cfg)
		p.pop('</PropertyGroup>')
	end
	
	function pack.importExtensionSettings(prj)
		p.w('<Import Project="$(AndroidTargetsPath)\\Android.props" />')
		p.w('<ImportGroup Label="ExtensionSettings" />')
		p.w('<ImportGroup Label="Shared" />')
	end

	
--
-- Write a configuration's item definition group, which contains all
-- of the per-configuration compile and link settings.
--

	pack.elements.antPackage = function(cfg)
		return {
			pack.androidAppLibName,
			pack.applicationName,
			pack.workingDirectory,
			pack.antTarget,
			pack.additionalOptions,
		}
	end
	
	function pack.antPackage(cfg)
		p.push('<AntPackage>')
		p.callArray(pack.elements.antPackage, cfg)
		p.pop('</AntPackage>')
	end

	function pack.itemDefinitionGroup(cfg)
		p.push('<ItemDefinitionGroup %s>', vc2010.condition(cfg))
		pack.antPackage(cfg)
		p.pop('</ItemDefinitionGroup>')
	end

	function pack.itemDefinitionGroups(prj)
		for cfg in project.eachconfig(prj) do
			pack.itemDefinitionGroup(cfg)
		end
	end
	
	function pack.androidAppLibName(cfg)
		vc2010.element("AndroidAppLibName", nil, "$(RootNamespace)")	-- TODO: fix
	end
	
	function pack.applicationName(cfg)
		if cfg.targetname ~= nil then
			vc2010.element("ApplicationName", nil, cfg.targetname)
		end
	end
	
	function pack.workingDirectory(cfg)
		if cfg.targetdir ~= nil then
			vc2010.element("WorkingDirectory", nil, cfg.targetdir)
		end
	end
	
	function pack.antTarget(cfg)
		-- TODO: should I expose this, should I fall to default options or should I stick to Debug\Release configs?! 
	end
	
	function pack.additionalOptions(cfg)
		if #cfg.deploymentoptions > 0 then
			local opts = table.concat(cfg.deploymentoptions, " ")
			vc2010.element("AdditionalOptions", nil, opts)
		end
	end
	
	function pack.importExtensionTargets(prj)
		p.w('<Import Project="$(AndroidTargetsPath)\\Android.targets" />')
		p.w('<ImportGroup Label="ExtensionTargets" />')
	end
	
	vc2010.elements.ContentFile = function(cfg, file)
		return {}
	end

	vc2010.elements.ContentFileCfg = function(fcfg, condition)
		return {}
	end
	
	function pack.antBuild(prj)
		if prj.antbuild ~= nil then
			p.x('<AntBuildXml Include="%s" />', prj.antbuild)
		end
	end
	
	function pack.antProperties(prj)
		if prj.antproperties ~= nil then
			p.x('<AntProjectPropertiesFile Include="%s" />', prj.antproperties)
		end
	end
	
	function pack.manifest(prj)
		if prj.androidmanifest ~= nil then
			p.x('<AndroidManifest Include="%s" />', prj.androidmanifest)
		end
	end
	
	function pack.files(prj)
		local groups = vc2010.categorizeSources(prj)
		
		local category = "Content"
		local newGroups = {}
		newGroups[category] = newGroups[category] or {}

		for group, files in pairs(groups) do
			for _, file in ipairs(files) do
				table.insert(newGroups[category], file)
			end
		end
		
		vc2010.emitFiles(prj, newGroups, category)
		
		p.push('<ItemGroup>')
		pack.antBuild(prj)
		pack.manifest(prj)
		pack.antProperties(prj)
		p.pop('</ItemGroup>')
	end
	
	
	function pack.project(prj)
		p.push('<Project DefaultTargets="Build" ToolsVersion="14.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
	end
	
	