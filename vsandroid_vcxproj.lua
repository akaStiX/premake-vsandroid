---
-- VSAndroid/vsandroid_vcxproj.lua
-- VS Android projects generator.
-- Copyright (c) 2015 Dmytro "StiX" Vovk and the Premake project
---


	local p = premake

	p.modules.vsandroid = { }
	local m = p.modules.vsandroid

	local android = p.modules.android
	local vc2010 = p.vstudio.vc2010
	local vstudio = p.vstudio
	local config = p.config


-- 
-- Utility functions
-- 

	function table.findAndRemove(t, value)
		for i, v in ipairs(t) do
    		if v == value then
      			table.remove(t, i)
				break
    		end
  		end
	end
	
	local function setBoolOption(optionName, flag, value)
		if flag ~= nil then
			vc2010.element(optionName, nil, value)
		end
	end

--
-- Add android tools to vstudio actions
--

	--if vstudio.vs2010_architectures ~= nil then
	--	vstudio.vs2010_architectures.android = "VSAndroid"
	--end
	

	premake.override(vc2010.elements, "globals", function(oldfn, cfg)
		return {
			vc2010.projectGuid,
			vc2010.ignoreWarnDuplicateFilename,
			m.keyword,
			m.projectName,
		}
	end)
	

	premake.override(vstudio, "projectfile", function(oldFn, prj)
		return p.filename(prj, ".vcxproj")		
	end)

	
	function m.keyword(prj)
		vc2010.element("Keyword", nil, "Android")
		vc2010.element("RootNamespace", nil, "%s", prj.name)
		vc2010.element("DefaultLanguage", nil, "en-US")
		vc2010.element("MinimumVisualStudioVersion", nil, "14.0")
		vc2010.element("ApplicationType", nil, "Android")
		vc2010.element("ApplicationTypeRevision", nil, "1.0")
	end

--
-- Extend configurationProperties
--

	premake.override(vc2010.elements, "configurationProperties", function(oldfn, cfg)
		local elements = oldfn(cfg)
		
		table.findAndRemove(elements, vc2010.characterSet)
		
		if cfg.kind ~= p.UTILITY and cfg.system == premake.ANDROID then
			elements = table.join(elements, {
				android.apiLevel,
				android.stlType,
				android.instructionSet,
			})
		end
		return elements
	end)



	function android.apiLevel(cfg)
		if cfg.androidapilevel ~= nil then
			_p(2,'<AndroidAPILevel>android-%d</AndroidAPILevel>', cfg.androidapilevel)
		end
	end



	function android.stlType(cfg)
		if cfg.stl ~= nil then
			local stl = {
				none		= "system",
				["gabi++"]	= "gabi++",
				stlport		= "stlport",
				gnu			= "gnustl",
				["libc++"]	= "c++",
			}
			
			local postfix = iif(cfg.flags.StaticRuntime, "_static", "_shared")
			local runtimeLib = iif(cfg.stl == "none", "system", stl[cfg.stl]..postfix)			
			vc2010.element("UseOfStl", nil, runtimeLib)
		end
	end
	
	
	function android.instructionSet(cfg)
		if cfg.instructionmode ~= nil then
			local IM = {
				disabled = "Disabled",
				thumb = "Thumb",
				arm = "ARM",
			}
			
			vc2010.element("ThumbMode", nil, IM[cfg.instructionmode])
		end
	end
	

	-- Note: this function is already patched in by vs2012...
	premake.override(vc2010, "platformToolset", function(oldfn, cfg)
		if cfg.toolchainversion ~= nil then
			local toolset = {
				["GCC 4.9"]		= "Gcc_4_9",
				["Clang 3.6"]	= "Clang_3_6",
			}

			vc2010.element("PlatformToolset", nil, toolset[cfg.toolchainversion])
		end
		--_p(2, '<TargetArchAbi>armeabi-v7a</TargetArchAbi>')
	end)


--
-- Extend compilation options.
--

	premake.override(vc2010.elements, "clCompile", function(oldfn, cfg)
		local elements = oldfn(cfg)
		
		table.replace(elements, vc2010.debugInformationFormat, android.debugInformationFormat)
		table.replace(elements, vc2010.warningLevel, android.warningLevel)
		table.replace(elements, vc2010.exceptionHandling, android.exceptionHandling)
		table.replace(elements, vc2010.enableEnhancedInstructionSet, android.enableEnhancedInstructionSet)
		
		if cfg.system == premake.ANDROID then
			elements = table.join(elements, {
				android.strictAliasing,
				android.floatabi,
				android.pic,
				android.verboseCompiler,
				android.undefineAllPreprocessorDefinitions,
				android.showIncludes,
				android.dataLevelLinking,
				android.shortEnums,
				android.cStandard,
				android.cppStandard,
				android.precompiledHeaderCompileAs,
				android.precompiledHeaderOutputDir,
			})
		end
		return elements
	end)
	
	premake.override(vc2010, "compileAs", function(oldfn, cfg)
		local precompiledAsCpp = cfg.precompiledheadercompileas == nil or cfg.precompiledheadercompileas == "CompileAsCpp"
		
		if cfg.project.language == "C" then
			vc2010.element("CompileAs", nil, "CompileAsC")
		elseif cfg.project.language == "C++" and precompiledAsCpp and not cfg.flags.NoPCH and cfg.pchheader then
		 	vc2010.element("CompileAs", nil, "CompileAsCpp")
		end
	end)
	
	function m.compileAs(cfg)
		if cfg.project.language == "C" then
			m.element("CompileAs", nil, "CompileAsC")
		end
	end
	
-- 
-- Replaced functions
-- 
	
	function android.debugInformationFormat(cfg)
		local value
		if cfg.flags.Symbols then
			if cfg.debugformat == "c7" then
				error("Debugformat option is unavailable for VS Android")
			end
			
			value = "FullDebug"
		else
			value = "None"
		end
		
		-- TODO: there is also LineNumber debug format option
		vc2010.element("DebugInformationFormat", nil, value)
	end
	
	function android.warningLevel(cfg)
		local warningsLevel = iif(cfg.warnings == "Off", "TurnOffAllWarnings", "EnableAllWarnings")
		vc2010.element("WarningLevel", nil, warningsLevel)
	end
	
	function android.exceptionHandling(cfg)
		if cfg.exceptionhandling == "SEH" then
			error ("SEH exceptions are not supported on Android")
		end
		
		if cfg.exceptionhandling ~= "Default" then
			local exceptions = {
				On = "Enabled",
				Off = "Disabled",
				UnwindTables = "UnwindTables",
			}
		
			vc2010.element("ExceptionHandling", nil, exceptions[cfg.exceptionhandling])
		end
	end
	
	function android.enableEnhancedInstructionSet(cfg)
		if cfg.vectorextensions == "NEON" then
			vc2010.element("EnableNeonCodegen", nil, "true")
		end
	end
	
-- 
-- Additional Android compilation settings 
-- 

	function android.strictAliasing(cfg)
		if cfg.strictaliasing ~= nil then	-- TODO: deregister existing strictaliasing and replace it with new boolean one
			vc2010.element("StrictAliasing", nil, iif(cfg.strictaliasing == "Off", "false", "true"))
		end
	end

	function android.floatabi(cfg)
		if cfg.floatabi ~= nil then
			vc2010.element("FloatABI", nil, cfg.floatabi)
		end
	end

	function android.pic(cfg)
		if cfg.pic ~= nil then
			vc2010.element("PositionIndependentCode", nil, iif(cfg.pic == "On", "true", "false"))
		end
	end
	
	function android.verboseCompiler(cfg)
		setBoolOption("Verbose", cfg.flags.VerboseCompiler, "true")
	end
	
	function android.undefineAllPreprocessorDefinitions(cfg)
		setBoolOption("UndefineAllPreprocessorDefinitions", cfg.flags.UndefineAllPreprocessorDefinitions, "true")
	end
	
	function android.showIncludes(cfg)
		setBoolOption("ShowIncludes", cfg.flags.ShowIncludes, "true")
	end
	
	function android.dataLevelLinking(cfg)
		setBoolOption("DataLevelLinking", cfg.flags.DataLevelLinking, "true")
	end
	
	function android.shortEnums(cfg)
		setBoolOption("UseShortEnums", cfg.flags.UseShortEnums, "true")
	end

	function android.cStandard(cfg)
		if cfg.cstandard ~= nil then
			vc2010.element("CLanguageStandard", nil, cfg.cstandard)
		end
	end
	
	function android.cppStandard(cfg)
		if cfg.cppstandard ~= nil then
			vc2010.element("CppLanguageStandard", nil, cfg.cppstandard)
		end
	end

	function android.precompiledHeaderCompileAs(cfg)
		if cfg.precompiledheadercompileas ~= nil then
			vc2010.element("PrecompiledHeaderCompileAs", nil, cfg.precompiledheadercompileas)
		end
	end

	function android.precompiledHeaderOutputDir(cfg)
		if cfg.precompiledheaderoutputdir ~= nil then
			vc2010.element("PrecompiledHeaderOutputFileDirectory", nil, cfg.precompiledheaderoutputdir)
		end
	end

--
-- Extend Linker options
--

	premake.override(vc2010, "linkIncremental", function(oldfn, cfg)
		if cfg.kind ~= p.STATICLIB then
			vc2010.element("IncrementalLink", nil, tostring(config.canLinkIncremental(cfg)))
		end
	end)
	
	-- function m.ignoreDefaultLibraries(cfg)	-- TODO: migrate to latest premake, since it has support for this
	-- 	if #cfg.ignoredefaultlibraries > 0 then
	-- 		local ignored = cfg.ignoredefaultlibraries
	-- 		for i = 1, #ignored do
	-- 			-- Add extension if required
	-- 			if not p.tools.msc.getLibraryExtensions()[ignored[i]:match("[^.]+$")] then
	-- 				ignored[i] = path.appendextension(ignored[i], ".lib")
	-- 			end
	-- 		end

	-- 		m.element("IgnoreSpecificDefaultLibraries", condition, table.concat(ignored, ';'))
	-- 	end
	-- end
	
	premake.override(vc2010.elements, "link", function(oldfn, cfg, explicit)
		if cfg.kind == p.SHAREDLIB then
			return {
				vc2010.additionalDependencies,
				vc2010.additionalLibraryDirectories,
				android.showProgress,
				android.verboseLinker,
				android.unresolvedSymbolReferences,
				android.optimizeforMemory,
				android.sharedLibrarySearchPath,
				android.forceSymbolReferences,
				android.debuggerSymbolInformation,
				android.packageDebugSymbols,
				android.generateMapFile,
				android.relocation,
				android.functionBinding,
				android.noExecStackRequired,
			}
		else
			return {}
		end
	end)
	
	function android.showProgress(cfg)
		setBoolOption("ShowProgress", cfg.flags.ShowLinkerProgress, "true")
	end
	
	function android.verboseLinker(cfg)
		setBoolOption("VerboseOutput", cfg.flags.VerboseLinker, "true")
	end
	
	function android.unresolvedSymbolReferences(cfg)
		setBoolOption("UnresolvedSymbolReferences", cfg.flags.UnresolvedSymbolReferences, "true")
	end
	
	function android.optimizeforMemory(cfg)
		setBoolOption("OptimizeforMemory", cfg.flags.OptimizeforMemory, "true")
	end
	
	function android.sharedLibrarySearchPath(cfg)
		if cfg.sharedlibrarysearchpath ~= nil then
			vc2010.element("SharedLibrarySearchPath", nil, cfg.sharedlibrarysearchpath)
		end
	end
	
	function android.forceSymbolReferences(cfg)
		if cfg.forcesymbolreferences ~= nil then
			vc2010.element("ForceSymbolReferences", nil, cfg.forcesymbolreferences)
		end
	end
	
	function android.debuggerSymbolInformation(cfg)
		if cfg.debuggersymbolinformation ~= nil then
			vc2010.element("DebuggerSymbolInformation", nil, iif(cfg.debuggersymbolinformation == "IncludeAll", "true", cfg.debuggersymbolinformation))
		end
	end
	
	function android.packageDebugSymbols(cfg)
		setBoolOption("PackageDebugSymbols", cfg.flags.PackageDebugSymbols, "true")
	end
	
	function android.generateMapFile(cfg)
		if cfg.generatemapfile ~= nil then
			vc2010.element("GenerateMapFile", nil, cfg.generatemapfile)
		end
	end
	
	function android.relocation(cfg)
		setBoolOption("Relocation", cfg.flags.ReadOnlyVarsRelocation, "true")
	end
	
	function android.functionBinding(cfg)
		setBoolOption("FunctionBinding", cfg.flags.ImmediateFunctionBinding, "true")
	end
	
	function android.noExecStackRequired(cfg)
		setBoolOption("NoExecStackRequired", cfg.flags.NoExecStackRequired, "true")
	end
	
	
-- 
-- Static library properties 
-- 
	
	premake.override(vc2010.elements, "lib", function(oldfn, cfg, explicit)
		if cfg.kind == p.STATICLIB then
			return {
				vc2010.additionalDependencies,
				vc2010.additionalLibraryDirectories,
				vc2010.additionalLinkOptions,
				android.verboseCompiler,	-- This is correct!!!
				android.createIndex,
				android.createThinArchive,
				android.noWarnOnCreate,
				android.truncateTimestamp,
				android.suppressStartupBanner,
			}
		else
			return {}
		end
	end)
	
	
	function android.createIndex(cfg)
		setBoolOption("CreateIndex", cfg.flags.CreateIndex, "true")
	end
	
	function android.createThinArchive(cfg)
		setBoolOption("CreateThinArchive", cfg.flags.CreateThinArchive, "true")
	end
	
	function android.noWarnOnCreate(cfg)
		setBoolOption("NoWarnOnCreate", cfg.flags.NoWarnOnCreate, "true")
	end
	
	function android.truncateTimestamp(cfg)
		setBoolOption("TruncateTimestamp", cfg.flags.TruncateTimestamp, "true")
	end
	
	function android.suppressStartupBanner(cfg)
		setBoolOption("SuppressStartupBanner", cfg.flags.SuppressStartupBanner, "true")
	end