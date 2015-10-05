---
-- VSAndroid/vsandroid.lua
-- VS Android projects generator.
-- Copyright (c) 2015 Dmytro "StiX" Vovk and the Premake project
---


	premake.modules.vsandroid = {}
	
	local p = premake
	local vstudio = p.vstudio
	local android = p.modules.vsandroid

	
	function android.generateProject(prj)
		if prj.kind == "Packaging" then
			p.generate(prj, ".androidproj", p.modules.vsandroid_packaging.generatePackaging)
			
			local user = p.capture(function() vstudio.vc2010.generateUser(prj) end)
			if #user > 0 then
				p.generate(prj, ".androidproj.user", function() p.outln(user) end)
			end
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
