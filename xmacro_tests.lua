
local tests = {}


tests[""] = function() return true end

tests["mod"] = function(which)
	if which == nil then
		return  (IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown())
	else
		local s = Split(which,"/")
		local i
		for i=1, getn(s), 1 do
			if (s[i] == "alt" and IsAltKeyDown()) or (s[i] == "ctrl" and IsControlKeyDown()) or (s[i] == "shift" and IsShiftKeyDown()) then
				return true
			end
		end
	end
	return false
end

tests["stance"] = function(which)
	local stance = getCurrentStance()
	if which == nil then
		return stance ~= 0
	end
	local s2 = Split(which,"/")
	local i
	for i=1, getn(s2), 1 do
		if tostring(stance)==s2[i] then
			return true
		end
	end
	return false
end

tests["@focus"] = function()
	return targetTest("focus")
end

tests["@mouseover"] = function()
	return targetTest("mouseover")
end


tests["harm"] = function(which, target)
	if nil ~= target and UnitIsEnemy("player",target) then
		return true
	else
		return false;
	end
end

tests["help"] = function(which, target)
	if nil ~= target and UnitIsFriend("player", target) then
		return true
	else
		return false;
	end
end

tests["exist"] = function(which,target)
	return target ~= nil and UnitExists(target)
end

tests["dead"] = function(which, target)
	return target ~= nil and UnitIsDeadOrGhost(target)
end


function xmacro_get_tests()
	return tests
end
