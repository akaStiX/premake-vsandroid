---
-- VSAndroid/vsandroid_packaging_user.lua
-- VS Android projects generator.
-- Copyright (c) 2015 Dmytro "StiX" Vovk and the Premake project
---

	local p = premake
	local vc2010 = p.vstudio.vc2010
	local pack = p.modules.vsandroid_packaging


	premake.override(vc2010.elements, "debugSettings", function(oldfn, cfg)
		local elements = oldfn(cfg)
		
		if _ACTION == "android" then
			elements = table.join(elements, {	--TODO: add other options
					pack.additionalSymbolSearchPaths,
				})
		end
			
		return elements
	end)
	
	
	function pack.additionalSymbolSearchPaths(cfg)
		if cfg.symbolspath then
			p.w('<AdditionalSymbolSearchPaths>%s</AdditionalSymbolSearchPaths>', cfg.symbolspath)
		end
	end