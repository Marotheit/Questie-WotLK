----------------------------------------------------------------------------
--  TomTom: A navigational assistant for World of Warcraft
--  CrazyTaxi: A crazy-taxi style arrow used for waypoint navigation.
--  concept taken from MapNotes2 (Thanks to Mery for the idea, along
--  with the artwork.)
----------------------------------------------------------------------------
local Astrolabe = DongleStub("Astrolabe-0.4")
local sformat = string.format
local L = TomTomLocals

local GetPlayerBearing
function GetPlayerBearing()
	local obj; -- Remains an upvalue
	do
		local t = {Minimap:GetChildren()}; -- Becomes garbage
		for k, v in pairs(t) do
			if v:IsObjectType("Model") and not v:GetName() then
				local model = v:GetModel():lower()
				if model:match("interface\\minimap\\minimaparrow") then
					obj = v; break;
				end
			end
		end
	end
	if not obj then return; end

	-- If we've found what we were looking for, rewrite function to skip the search next time.
	GetPlayerBearing = function()
		if GetCVar("rotateMinimap") ~= "0" then
			return (MiniMapCompassRing:GetFacing() * -1)
		else
			return obj:GetFacing();
		end
	end
	return GetPlayerBearing();
end

local sformat = string.format
local function ColorGradient(perc, tablee)
	local num = table.getn(tablee)
	local hexes = tablee[1] == "string"
	if perc == 1 then
		return tablee[num-2], tablee[num-1], tablee[num]
	end
	num = num / 3
	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2
	r1, g1, b1 = tablee[(segment*3)+1], tablee[(segment*3)+2], tablee[(segment*3)+3]
	r2, g2, b2 = tablee[(segment*3)+4], tablee[(segment*3)+5], tablee[(segment*3)+6]
	if not r1 then return end
	if not r2 or not g2 or not b2 then
		return r1, g1, b1
	else
		return r1 + (r2-r1)*relperc,
			g1 + (g2-g1)*relperc,
			b1 + (b2-b1)*relperc
	end
end

local twopi = math.pi * 2

function WayFrame_OnClick()
	if (MouseIsOver(TomTomCrazyArrow) ~= nil) and (arg1 == "RightButton") then
		TomTomCrazyArrow:Hide()
	end
end

local wayframe = CreateFrame("Button", "TomTomCrazyArrow", UIParent)
wayframe:SetHeight(42)
wayframe:SetWidth(56)
wayframe:SetPoint("CENTER", 0, 0)
wayframe:EnableMouse(true)
wayframe:SetMovable(true)
wayframe:Hide()
wayframe.title = wayframe:CreateFontString("OVERLAY", nil, "GameFontHighlightSmall")
wayframe.status = wayframe:CreateFontString("OVERLAY", nil, "GameFontNormalSmall")
wayframe.tta	= wayframe:CreateFontString("OVERLAY", nil, "GameFontNormalSmall")
wayframe.title:SetPoint("TOP", wayframe, "BOTTOM", 0, 0)
wayframe.status:SetPoint("TOP", wayframe.title, "BOTTOM", 0, 0)
wayframe.tta:SetPoint("TOP", wayframe.status, "BOTTOM", 0, 0)

local function OnDragStart(self, button)
	if IsControlKeyDown() and IsShiftKeyDown() then
		self:StartMoving()
		wayframe:SetClampedToScreen(true);
	end
end

local function OnDragStop(self, button)
	self:StopMovingOrSizing()
end

local function OnEvent(self, event, ...)
	if event == "ZONE_CHANGED_NEW_AREA" then
		self:Show()
	end
end

wayframe:SetScript("OnDragStart", OnDragStart)
wayframe:SetScript("OnDragStop", OnDragStop)
wayframe:RegisterForDrag("LeftButton")
wayframe:RegisterEvent("ZONE_CHANGED_NEW_AREA")
wayframe:SetScript("OnEvent", OnEvent)
wayframe.arrow = wayframe:CreateTexture("OVERLAY")
wayframe.arrow:SetTexture("Interface\\AddOns\\Questie\\Images\\Arrow")
wayframe.arrow:SetAllPoints()

local active_point, arrive_distance, showDownArrow, point_title
function SetCrazyArrow(uid, dist, title)
	active_point = uid
	arrive_distance = dist
	point_title = title
	if active_point and not isHide then
		wayframe.title:SetText(point_title or "Unknown waypoint")
		wayframe:Show()
	else
		wayframe:Hide()
	end
end

function SetArrowObjective(hash)
	if arrow_objective == hash then
		wayframe:Hide();
		arrow_objective = 0;
		return;
	end
	arrow_objective = hash
	if not QuestieTrackedQuests[hash]["arrowPoint"] then return end
	local objective = QuestieTrackedQuests[hash]["arrowPoint"]
	SetCrazyArrow(objective, objective.dist, objective.title)
end

local status = wayframe.status
local tta = wayframe.tta
local arrow = wayframe.arrow
local count = 0
local last_distance = 0
local tta_throttle = 0
local speed = 0
local speed_count = 0
local function OnUpdate(self, elapsed)
	if not active_point then
		self:Hide()
		return
	end
	local dist,x,y
	if arrow_objective then
		if QuestieTrackedQuests[arrow_objective] then
			local objective = QuestieTrackedQuests[arrow_objective]["arrowPoint"]
			if objective then
				SetCrazyArrow(objective, objective.dist, objective.title)
			end
		else
			self:Hide()
		end
	end
	if not active_point then
		self:Hide()
		return
	end
	local dist,x,y = GetDistanceToIcon(active_point)
	-- The only time we cannot calculate the distance is when the waypoint
	-- is on another continent, or we are in an instance
	if not dist or IsInInstance() then
		if not active_point.x and not active_point.y then
			active_point = nil
		end
		self:Hide()
		return
	end
	status:SetText(sformat("%d yards", dist))
	local cell
	-- Showing the arrival arrow?
	if dist <= 5 then
		if not showDownArrow then
			arrow:SetHeight(70)
			arrow:SetWidth(53)
			arrow:SetTexture("Interface\\AddOns\\Questie\\Images\\Arrow-UP")
			arrow:SetVertexColor(0, 1, 0)
			showDownArrow = true
		end
		count = count + 1
		if count >= 55 then
			count = 0
		end
		cell = count
		local column = cell % 9
		local row = floor(cell / 9)
		local xstart = (column * 53) / 512
		local ystart = (row * 70) / 512
		local xend = ((column + 1) * 53) / 512
		local yend = ((row + 1) * 70) / 512
		arrow:SetTexCoord(xstart,xend,ystart,yend)
	else
		if showDownArrow then
			arrow:SetHeight(56)
			arrow:SetWidth(42)
			arrow:SetTexture("Interface\\AddOns\\Questie\\Images\\Arrow")
			showDownArrow = false
		end
		local degtemp = GetDirectionToIcon(active_point)
		if degtemp < 0 then degtemp = degtemp + 360; end
		local angle = math.rad(degtemp)
		local player = GetPlayerBearing()
		angle = angle - player
		local perc = 1- math.abs((math.pi - math.abs(angle)) / math.pi)
		local gr,gg,gb = 1, 1, 1
		local mr,mg,mb = 0.75, 0.75, 0.75
		local br,bg,bb = 0.5, 0.5, 0.5
		local tablee = {};
		table.insert(tablee, gr)
		table.insert(tablee, gg)
		table.insert(tablee, gb)
		table.insert(tablee, mr)
		table.insert(tablee, mg)
		table.insert(tablee, mb)
		table.insert(tablee, br)
		table.insert(tablee, bg)
		table.insert(tablee, bb)
		local r,g,b = ColorGradient(perc,tablee)
		if not g then
			g = 0;
		end
		arrow:SetVertexColor(1-g,-1+g*2,0)
		cell = floor(angle / twopi * 108 + 0.5) % 108
		local column = cell % 9
		local row = floor(cell / 9)
		local xstart = (column * 56) / 512
		local ystart = (row * 42) / 512
		local xend = ((column + 1) * 56) / 512
		local yend = ((row + 1) * 42) / 512
		arrow:SetTexCoord(xstart,xend,ystart,yend)
	end

	-- Calculate the TTA every second  (%01d:%02d)

	tta_throttle = tta_throttle + elapsed

	if tta_throttle >= 1.0 then
		-- Calculate the speed in yards per sec at which we're moving
		local current_speed = (last_distance - dist) / tta_throttle

		if last_distance == 0 then
			current_speed = 0
		end

		if speed_count < 2 then
			speed = (speed + current_speed) / 2
			speed_count = speed_count + 1
		else
			speed_count = 0
			speed = current_speed
		end

		if speed > 0 then
			local eta = math.abs(dist / speed)
			tta:SetFormattedText("%01d:%02d", eta / 60, eta % 60)
		else
			tta:SetText("***")
		end

		last_distance = dist
		tta_throttle = 0
	end
end

function ShowHideCrazyArrow()
	if wayframe:IsShown() then
		wayframe:Show()
		if true then
			wayframe:EnableMouse(false)
		else
			wayframe:EnableMouse(true)
		end
		-- Set the scale and alpha
		wayframe:SetScale(1)
		wayframe:SetAlpha(1)
		local width = 80
		local height = 80
		wayframe.title:SetWidth(width)
		wayframe.title:SetHeight(height)
		if true then
			tta:Show()
		else
			tta:Hide()
		end
	else
		wayframe:Hide()
	end
end

wayframe:SetScript("OnUpdate", OnUpdate)
wayframe:RegisterForClicks("RightButtonUp")
wayframe:SetScript("OnClick", WayFrame_OnClick)

local function getCoords(column, row)
	local xstart = (column * 56) / 512
	local ystart = (row * 42) / 512
	local xend = ((column + 1) * 56) / 512
	local yend = ((row + 1) * 42) / 512
	return xstart, xend, ystart, yend
end

--this is where texcoords are extracted incorrectly (I think), leading the arrow to not point in the correct direction
local texcoords = setmetatable({}, {__index = function(t, k)
	-- this was k:match("(%d+):(%d+)") - so we need string.match, but that's not in Lua 5.0
	local fIndex, lIndex = string.find(k, "(%d+)")
	local col = string.sub(k, fIndex, lIndex)
	fIndex2, lIndex2 = string.find(k, ":(%d+)")
	local row = string.sub(k, fIndex2+1, lIndex2)
	col,row = tonumber(col), tonumber(row)
	local obj = {getCoords(col, row)}
	rawset(t, k, obj)
	return obj
end})

wayframe:RegisterEvent("ADDON_LOADED")
wayframe:SetScript("OnEvent", function(self, event, arg1, ...)
	if true then
		if true then
			local feed_crazy = CreateFrame("Frame")
			local crazyFeedFrame = CreateFrame("Frame")
			local throttle = 1
			local counter = 0
			crazyFeedFrame:SetScript("OnUpdate", function(self, elapsed)
				elapsed = 1/GetFramerate()
				counter = counter + elapsed
				if counter < throttle then
					return
				end
				counter = 0
				local angle = GetDirectionToIcon(active_point)
				local player = GetPlayerBearing()
				if not angle or not player then
					feed_crazy.iconCoords = texcoords["1:1"]
					feed_crazy.iconR = 0.2
					feed_crazy.iconG = 1.0
					feed_crazy.iconB = 0.2
					feed_crazy.text = "No waypoint"
					return
				end
				angle = angle - player
				local perc = math.abs((math.pi - math.abs(angle)) / math.pi)
				local gr,gg,gb = 1, 1, 1
				local mr,mg,mb = 0.75, 0.75, 0.75
				local br,bg,bb = 0.5, 0.5, 0.5
				local tablee = {};
				table.insert(tablee, gr)
				table.insert(tablee, gg)
				table.insert(tablee, gb)
				table.insert(tablee, mr)
				table.insert(tablee, mg)
				table.insert(tablee, mb)
				table.insert(tablee, br)
				table.insert(tablee, bg)
				table.insert(tablee, bb)
				local r,g,b = ColorGradient(perc, tablee)
				feed_crazy.iconR = r
				feed_crazy.iconG = g
				feed_crazy.iconB = b
				cell = Questie:Modulo(floor(angle / twopi * 108 + 0.5) ,108)
				local column = Questie:Modulo(cell, 9)
				local row = floor(cell / 9)
				local key = column .. ":" .. row
				feed_crazy.iconCoords = texcoords[key]
				feed_crazy.text = point_title or "Unknown waypoint"
			end)
		end
	end
end)

-- calculations have to be redone - we are NOT actually working with Astrolabe "icons" here as TomTom did and want the arrow API
-- to be accessible to everyone
function GetDirectionToIcon( point )
	if not point then return end
	local C,Z,X,Y = Astrolabe:GetCurrentPlayerPosition() -- continent, zone, x, y
	local dist, xDelta, yDelta = Astrolabe:ComputeDistance( C, Z, X, Y, point.c, point.z, point.x, point.y )
	if not xDelta or not yDelta then return end
	local dir = atan2(xDelta, -(yDelta))
	if ( dir > 0 ) then
		return twopi - dir;
	else
		return -dir;
	end
end

function GetDistanceToIcon( point )
	local C,Z,X,Y = Astrolabe:GetCurrentPlayerPosition() -- continent, zone, x, y
	local dist, xDelta, yDelta = Astrolabe:ComputeDistance( C, Z, X, Y, point.c, point.z, point.x, point.y )
	return dist, xDelta, yDelta
end
