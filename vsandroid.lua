---
-- VSAndroid/vsandroid.lua
-- VS Android projects generator.
-- Copyright (c) 2015 Dmytro "StiX" Vovk and the Premake project
---


	premake.modules.vsandroid = {}
	
	local p = premake
	local vstudio = p.vstudio
	local android = p.modules.vsandroid
	local project = p.project
	local tree = p.tree


	function android.generatePackagingProj(prj)
		p.generate(prj, ".androidproj", p.modules.vsandroid_packaging.generatePackaging)
		
		-- Skip generation of empty user files
		local user = p.capture(function() vstudio.vc2010.generateUser(prj) end)
		if #user > 0 then
			p.generate(prj, ".androidproj.user", function() p.outln(user) end)
		end
		
		-- Only generate a filters file if the source tree actually has subfolders
		if tree.hasbranches(project.getsourcetree(prj)) then
			premake.generate(prj, ".vcxproj.filters", vstudio.vc2010.generateFilters)
		end
	end
	
	function android.generateProject(prj)
		if prj.kind == "Packaging" then
			android.generatePackagingProj(prj)
		else
			vstudio.vs2010.generateProject(prj)
		end
	end


	include("vsandroid_packaging.lua")
	include("vsandroid_packaging_user.lua")
	include("_preload.lua")

	configuration { "VSAndroid" }
		system "vsandroid"
		toolset "gcc"


	include("vsandroid_vcxproj.lua")

	return android
