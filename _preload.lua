---
-- VSAndroid/_preload.lua
-- VS Android projects generator.
-- Copyright (c) 2015 Dmytro "StiX" Vovk and the Premake project
---


	local p = premake
	local api = p.api
	local vstudio = p.vstudio

--
-- Register the new Android APIs
--

	p.ANDROID = "vsandroid"

	api.addAllowed("system", p.ANDROID)
	api.addAllowed("kind", { "Packaging" })
	api.addAllowed("architecture", { "arm", "arm64" })
	api.addAllowed("vectorextensions", { "NEON" })
	api.addAllowed("exceptionhandling", {"UnwindTables"})
	api.addAllowed("flags", {
		"ShowIncludes",
		"VerboseCompiler",
		"VerboseLinker",
		"UndefineAllPreprocessorDefinitions",
		"DataLevelLinking",
		"UseShortEnums",
		"ShowLinkerProgress",
		"UnresolvedSymbolReferences",
		"OptimizeforMemory",
		"PackageDebugSymbols",
		"ReadOnlyVarsRelocation",
		"ImmediateFunctionBinding",
		"NoExecStackRequired",
		"CreateIndex",
		"CreateThinArchive",
		"NoWarnOnCreate",
		"TruncateTimestamp",
		"SuppressStartupBanner",
		"WholeArchive",
	})
	
	vstudio.vs2010_architectures.arm = "ARM"
	vstudio.vs2010_architectures.arm64 = "ARM64"
	vstudio.vs200x_architectures.arm = "ARM"
	vstudio.vs200x_architectures.arm64 = "ARM64"

	-- local os = p.fields["os"];
	-- if os ~= nil then
	-- 	table.insert(sys.allowed, { "android",  "Android" })
	-- end


--
-- Register new project properties
--

	api.register {
		name = "floatabi",
		scope = "config",
		kind = "string",
		allowed = {
			"soft",
			"softfp",
			"hard",
		},
	}

	api.register {
		name = "androidapilevel",
		scope = "config",
		kind = "integer",
	}

	api.register {
		name = "toolchainversion",
		scope = "config",
		kind = "string",
		allowed = {
			"GCC 4.9",
			"Clang 3.8",
		},
	}

	api.register {
		name = "stl",
		scope = "config",
		kind = "string",
		allowed = {
			"none",
			"gabi++",
			"stlport",
			"gnu",
			"libc++",
		},
	}
	
	api.register {
		name = "instructionmode",
		scope = "config",
		kind = "string",
		allowed = {
			"disabled",
			"arm",
			"thumb",
		},
	}
	
	-- api.register {
	-- 	name = "strictaliasing",
	-- 	scope = "config",
	-- 	kind = "boolean",
	-- }
	
	-- api.register {
	-- 	name = "pic",
	-- 	scope = "config",
	-- 	kind = "string",
	-- 	allowed = {
	-- 		"On",
	-- 		"Off",
	-- 	}
	-- }
	
	api.register {
		name = "cstandard",
		scope = "config",
		kind = "string",
		allowed = {
			"Default",
			"c89",
			"c99",
			"c11",
			"gnu99",
			"gnu11",
		}
	}
	
	api.register {
		name = "cppstandard",
		scope = "config",
		kind = "string",
		allowed = {
			"Default",
			"c++98",
			"c++11",
			"c++1y",
			"gnu++98",
			"gnu++11",
			"gnu++1y",
		}
	}
	
	api.register {
		name = "precompiledheadercompileas",
		scope = "config",
		kind = "string",
		allowed = {
			"CompileAsC",
			"CompileAsCpp",
		}
	}
	
	api.register {
		name = "precompiledheaderoutputdir",
		scope = "config",
		kind = "path",
		tokens = true,
	}
	
	api.register {
		name = "sharedlibrarysearchpath",
		scope = "config",
		kind = "path",
		tokens = true,
	}
	
	api.register {
		name = "forcesymbolreferences",
		scope = "config",
		kind = "path",
	}
	
	api.register {
		name = "debuggersymbolinformation",
		scope = "config",
		kind = "string",
		allowed = {
			"IncludeAll",
			"OmitUnneededSymbolInformation",
			"OmitDebuggerSymbolInformation",
			"OmitAllSymbolInformation"
		}
	}
	
	api.register {
		name = "generatemapfile",
		scope = "config",
		kind = "path",
		tokens = true,
	}
	
---
--  Android packaging API
---	
	api.register {
		name = "antbuild",
		scope = "project",
		kind = "string",
		tokens = true,
	}
	
	api.register {
		name = "androidmanifest",
		scope = "project",
		kind = "string",
		tokens = true,
	}
	
	api.register {
		name = "antproperties",
		scope = "project",
		kind = "string",
		tokens = true,
	}
	
	
	newaction {
		trigger     = "android",
		shortname   = "Android project for Visual Studio 2015",
		description = "Generate Android project files for Visual Studio 2015",

		os = "windows",

		valid_kinds     = { "Packaging", "StaticLib", "SharedLib" },
		valid_languages = { "C", "C++" },
		valid_tools     = {
			cc    = { "gcc", "clang" },
		},

		-- Solution and project generation logic

		onSolution = function(sln)
			vstudio.vs2005.generateSolution(sln)
		end,
		
		onProject = function(prj)
			p.modules.vsandroid.generateProject(prj)
		end,
		
		-- onRule = function(rule)
		-- 	vstudio.vs2010.generateRule(rule)
		-- end,

		-- onCleanSolution = function(sln)
		-- 	vstudio.cleanSolution(sln)
		-- end,
		
		-- onCleanProject = function(prj)
		-- 	vstudio.cleanProject(prj)
		-- end,
		
		-- onCleanTarget = function(prj)
		-- 	vstudio.cleanTarget(prj)
		-- end,

		-- pathVars = vstudio.pathVars,

		-- This stuff is specific to the Visual Studio exporters

		vstudio = {
			solutionVersion = "12",
			versionName     = "2015",
			-- targetFramework = "4.5",
			toolsVersion    = "12.0",	-- the default sample has this version
			filterToolsVersion = "4.0",
			-- platformToolset = "v140"
		}
	}
