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
		else
			vstudio.vs2010.generateProject(prj)
		end
	end


	include("vsandroid_packaging.lua")
	include("_preload.lua")

	configuration { "VSAndroid" }
		system "vsandroid"
		toolset "gcc"


	include("vsandroid_vcxproj.lua")

	return android
