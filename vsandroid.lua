---
-- VSAndroid/vsandroid.lua
-- VS Android projects generator.
-- Copyright (c) 2015 Dmytro "StiX" Vovk and the Premake project
---


	premake.modules.android = {}

	local android = premake.modules.android

	include("_preload.lua")

	configuration { "VSAndroid" }
		system "vsandroid"
		toolset "gcc"


	include("vsandroid_vcxproj.lua")

	return android
