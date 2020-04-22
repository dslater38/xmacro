-- /cst [option1,option2,...][option1,option2,...]... spell;[option1,option2,...][option1,option2,...]... spell;[option1,option2,...][option1,option2,...]... spell



local tests = {}

local focus_target=nil

local function print(str)
    DEFAULT_CHAT_FRAME:AddMessage(str);
end

function setFocus(name)
	if name=="target" then
		focus_target=UnitName("target")
	else
		focus_target=name
	end
end

function cleatFocusTarget()
	focus_target = nil;
end


function getCurrentStance()
	local i,active
	for i=1, GetNumShapeshiftForms(), 1 do
		_,_,active,_ = GetShapeshiftFormInfo(i)
		if active == 1 then
			return i
		end
	end
	return 0
end


function targetTest(target)
	local x = UnitExists(target)
	if x == nil then
		return false,nil
	end
	return true,x
end

function castFocusTarget(spell)
	local en = UnitExist("target")
	TargetByName(focus_target);
	CastSpellByName(spell)
	if en ~= nil then
		TargetLastTarget();
	end
end

function doCastSpell(spell, target, bIsCast)
	if target ~= nil and target ~= "target" then
		local ue = UnitExists("target")
		ClearTarget()
		if bIsCast then
			CastSpellByName(spell)
		else
			UseItem(spell)
		end
		SpellTargetUnit(target)
		if ue then
			TargetLastTarget()
		end
	else
		CastSpellByName(spell)
	end
end


function Split(str, delim, maxNb)
    -- Eliminate bad cases...
	local result = {}
    if string.find(str, delim) == nil then
        result[1] = str;
		return result;
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end

    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end


function breakAtSemiColon(str)
	return Split(str,";")
end

function breakOptionsOut(str)
	local s,t,ss,index,i,j
	local moptions = {}
	index = 1
	TRACE("+-+" .. str .. "+-+\n")
	ss = str
	i=1
	repeat
		i,j,s,t = strfind(str,"(%b[])()",i)
		if i == nil then
			break;
		end
		moptions[index] = s
		index = index + 1
		if nil ~= t then
			ss = string.sub(str,t)
		end
		i = j

	until(false)
--	for s,t in string.gmatch(str,"(%b[])()") do
--		--print("--" .. s .. "--" .. "\n")
--		moptions[index] = s
--		index = index + 1
--		if nil ~= t then
--			ss = string.sub(str,t)
--		end
--	end
	ss = string.gsub(ss,"^%s+","")
	-- print( "--" .. ss  .. "--" .. "\n")
	return moptions,ss
end


function testCondition1(c)
	local s = Split(c,":")
	local s1,s2
	local t = {}
	local target=nil
	t.type = "comp"

	if strfind(c,"@") ~= nil then
		t.value = "true"
		target = c
	else
		t.value = c
	end
	return t,target
end

--~ function testCondition(k,v)
--~ 	if v ~= nil then
--~ 		return testCondition2(k,v)
--~ 	else
--~ 		return testCondition1(k)
--~ 	end
--~ end

function matchOptions2(str)
	TRACE(str);
	local s = string.sub(str, 2, strlen(str)-1);
	local ss = Split(s, ",")
	local t = {}
	local opt,s2,i
	local target = nil
	t.children = {}
	i=1
	if getn(ss) > 1 then
		t.type = "and"
		for opt=1,getn(ss),1 do
			s2,target = testCondition1(ss[opt])
			if s2 ~= nil then
				TRACE(s2.type .. " , " .. s2.value .. "\n")
				t.children[i] = s2
				i = i+1
			end
		end
	elseif getn(ss) == 1 then
		t,target = testCondition1(ss[1])
	else
	TRACE("matchOptions2() returning nil\n")
		return nil
	end
	return t,target
end

--~ function matchOptions(str)
--~ 	local s = string.sub(str, 2, #str-1);
--~ 	local ss = Split(s, ",")
--~ 	local opt,s2
--~ 	for opt=1,#ss,1 do
--~ 		s2 = Split(ss[opt],":")
--~ 		if #s2 == 2 then
--~ 			testCondition(s2[1], s2[2])
--~ 			--print("{" .. s2[1] .. ", " .. s2[2] .. "}\n")
--~ 		else
--~ 			testCondition(s2[1])
--~ 			--print("{" .. s2[1] .. "}\n")
--~ 		end
--~ 	end
--~ end

function parse(smacro)
	local s
	local tt = breakAtSemiColon(smacro)
	local moptions,spell
	local spell_list = {}
	local idx = 1
	local target = nil
	for s=1, getn(tt), 1 do
		local t = {}

		spell_list[idx] = {}
        TRACE(tostring(tt[s]) .. "\n" )
		moptions,spell = breakOptionsOut(tt[s])
		if getn(moptions) > 1 then
			t.type = "or"
			t.children = {}
			local i=1
			for s=1,getn(moptions),1 do
				TRACE(moptions[s])
				t.children[i],target = matchOptions2(moptions[s])
				i = i+1
			end
		elseif getn(moptions) == 1 then
			TRACE(moptions[s])
			t,target = matchOptions2(moptions[1])
		else
			t,target = matchOptions2("[]")
		end
		spell_list[idx].test = t
		spell_list[idx].spell = spell
		spell_list[idx].target = target
		idx = idx+1
	end
	return spell_list,target
end

--~ function mkMod()
--~ 	if IsAltKeyDown() then
--~ 		return "alt"
--~ 	elseif IsCtlKeyPressed() then
--~ 		return "ctrl"
--~ 	elseif IsShiftKeyDown() then
--~ 		return "shift"
--~ 	else
--~ 		return ""
--~ 	end
--~ end

--~ function isModKeyPressed(which)
--~ 	if which == nil then
--~ 		return  (IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown())
--~ 	else
--~ 		local s = Split(which,"/")
--~ 		local i
--~ 		for i=1, #s, 1 do
--~ 			if (s[i] == "alt" and IsAltKeyDown()) or (s[i] == "ctrl" and IsControlKeyDown()) or (s[i] == "shift" and IsShiftKeyDown()) then
--~ 				return true
--~ 			end
--~ 		end
--~ 	end
--~ 	return false
--~ end

--~ function isInStance(which)
--~ 	local stance = getCurrentStance()
--~ 	if which == nil then
--~ 		return false
--~ 	end
--~ 	local s2 = Split(which,"/")
--~ 	local i
--~ 	for i=1, #s2, 1 do
--~ 		if tostring(stance)==s2[i] then
--~ 			return true
--~ 		end
--~ 	end
--~ 	return false
--~ end

function evalComp(t,target)
	local op = t.value
	local isNot = false
	local bRetVal = false
	-- local target = getCurrentTarget()
	local f,t

	--TRACE(t.type .. "\n")
	--TRACE(t.value .. "\n")

	if string.find(op, "no") == 1 then
		isNot = true
		op = string.sub(op,3)
	end
	local s = Split(op,":")
	op = s[1]

	if op == nil then
	else
		f = tests[op]
		if f ~= nil then
			bRetVal,t = f(s[2], target)
			if bRetVal == true and t ~= nil then
				target = t
			end
		else
			return false
		end
	end


--~ 	if op == "mod" then
--~ 		bRetVal = isModKeyPressed(s[2])
--~ 	elseif op == "stance" then
--~ 		bRetVal = isInStance(s[2])
--~ 	elseif string.len(op) == 0 then
--~ 		return true
--~ 	elseif string.match(op,"^%a*$") == op then
--~ 		return true
--~ 	elseif op == "true" then
--~ 		return true
--~ 	else
--~ 		return false
--~ 	end
	if isNot == true then
		if bRetVal==false then
			bRetVal = true
		else
			bRetVal = false
		end
	end
	return bRetVal;
end

function evalOr(t,target)
	local i
	local c = t.children
	for i=1, getn(c), 1 do
		if eval(c[i],target) == true then
			return true
		end
	end
	return false
end

function evalAnd(t,target)
	local i
	local c = t.children
	for i=1, getn(c), 1 do
		if eval(c[i],target) == false then
			return false
		end
	end
	return true
end

function eval(t,target)
	local bRet = false
	TRACE(t.type)
	if t.type == "or" then
		TRACE("or\n")
		bRet = evalOr(t,target)
	elseif t.type == "and" then
		TRACE("and\n")
		bRet = evalAnd(t,target)
	elseif t.type == "comp" then
		TRACE("comp\n")
		bRet = evalComp(t,target)
	end
	return bRet
end

--~ -- local spell_list = parse("[mod:alt,stance:1][mod:ctrl,stance:3][nomod]   Cat Form;[mod][stance:4][]  Bear Form")
--~ local spell_list,target = parse("[nomod,@focus]Cat Form;[mod:alt]Bear Form")

--~ local i
--~ local matched = false
--~ for i=1, #spell_list, 1 do
--~ 	local t = spell_list[i].test
--~ 	local b = eval(t)
--~ 	if b == true then
--~ 		doCastSpell(spell_list[i].spell, spell_list[i].target)
--~ 		-- print(spell_list[i].spell .. "\n")
--~ 		matched = true
--~ 		break
--~ 	end
--~ end

--~ if matched == false then
--~ 	print("ERROR: No MATCH\n")
--~ end


function xRunMacro(macrostr,bIsCast)
	local spell_list,target = parse(macrostr)

	local i
	local matched = false
	for i=1, getn(spell_list), 1 do
		local t = spell_list[i].test
		local b = eval(t,spell_list[i].target)
		if b == true then
			TRACE(spell_list[i].spell .. "\n")
			doCastSpell(spell_list[i].spell, spell_list[i].target,bIsCast)
			matched = true
			break
		end
	end

	if matched == false then
		print("ERROR: No MATCH\n")
	end
end


function xmacro_CastCommand(cmd)
	xRunMacro(cmd,false)
end

function xmacro_UseCommand(cmd)
	xRunMacro(cmd,true)
end

function xmacro_cancelform(cond)
	local doit = true
	if cond ~= nil then
		local spell_list,target = parse(cond)
		local i,sp
		local matched = false
		for sp in spell_list do
			local t = spell_list[sp].test
			local b = eval(t,spell_list[sp].target)
			if b == true then
				matched = true
				break
			end
		end
		if not matched then
			doit = false
		end
	end
	if doit then
		local s = getCurrentStance();
		if s ~= nil and s > 0 then
			CastShapeshiftForm(s);
		end
	end
end

function xmacro_installSlashCommands()
	SlashCmdList["XMACRO_CAST"] = xmacro_CastCommand;
	SlashCmdList["XMACRO_USE"] = xmacro_USeCommand;
	SlashCmdList["XMACRO_CANCELFORM"] = xmacro_cancelform;

	SLASH_XMACRO_CAST1="/xcast"
	SLASH_XMACRO_CAST2="/xc"
	SLASH_XMACRO_USE1="/xuse"
	SLASH_XMACRO_USE2="/xu"
	SLASH_XMACRO_CANCELFORM1="/xcancelform"


end



-- xRunMacro("[mod:alt,stance:1][mod:ctrl,stance:3][nomod]   Cat Form;[mod][stance:4][]  Bear Form")


xmacro_installSlashCommands();


-- b = eval(t)

--local s
--local tt = breakAtSemiColon("[mod:alt,stance:1][mod:ctrl,stance:3][]   Cat Form;[mod][stance:4][]  Bear Form")
--local moptions,spell
--for s=1, #tt, 1 do
--	 -- print(tostring(tt[s]) .. "\n" )
--	moptions,spell = breakOptionsOut(tt[s])
--	for s=1,#moptions,1 do
--		matchOptions(moptions[s])
--		--print("--" .. moptions[s] .. "--\n")
--	end
--	print(spell .. "\n")
--end







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
