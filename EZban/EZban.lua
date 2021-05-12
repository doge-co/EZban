local DS = game:GetService("DataStoreService")
local MS = game:GetService("MessagingService")
local RS = game:GetService("RunService")
local chnl = "UserBanned"
local chnl2 = "UserWarned"
local store = DS:GetDataStore("BanInfo")
local store2 = DS:GetDataStore("TimeBanInfo")
local store3 = DS:GetDataStore("Warnings")
local bob = script.Cage:Clone()
local Timenow = os.time()
local users_with_warnings = {}
local function wait(N)
	local e_l = 0
	while e_l < N do
		e_l += RS.RenderStepped:Wait()
	end
end
pcall(function()
	users_with_warnings = store3:GetAsync("WarnedUsers")
	if users_with_warnings == nil then
		users_with_warnings = {}
	end
end)
if not workspace:FindFirstChild("Cage") then
	bob.Parent = workspace
else
	bob:Destroy()
end

local function round(n)
	return math.floor(n+.5)
end
local plrs = game:GetService("Players")
local z = coroutine.create(function(plr)
	plr.CharacterAdded:Wait()
	local char = plr.Character
	repeat wait() until char:FindFirstChild("HumanoidRootPart")
	wait(.1)
	while wait(.1) do
		char.HumanoidRootPart.Position = workspace:FindFirstChild("Cage").Bottom.Position + Vector3.new(0,5,0)
	end
end)
spawn(
	function()
		while wait(1) do
			Timenow = os.time()
		end
	end
)

function plradded(plr)
	print("Player added")
	local data = nil
	local data2 = nil
	local s,e = pcall(function()
		data = store:GetAsync(plr.UserId)
		data2 = store2:GetAsync(plr.UserId)
	end)
	if s then
		if data ~= nil then
			if data[3] ~= nil then
				if data[2] ~= nil then
					local caged = data[2]
					if caged then
						coroutine.resume(z,plr)
					else
						plr:Kick("You were banned from this game.")
					end
				end
			end
		end
		if data2 ~= nil then
			if data2[3] ~= nil then
				local Mode = data2[2]
				local TLIS = os.difftime(data2[1],Timenow)
				local timeleft = 0
				local finaltime = nil
				if TLIS > 0 then
					if Mode == "minutes" then timeleft = TLIS/60	elseif Mode == "hours" then timeleft = TLIS/3600	elseif Mode == "days" then timeleft = TLIS/86400	elseif Mode == "weeks" then timeleft = TLIS/604800 end
					print(timeleft)
					if timeleft > 1 then
						finaltime = round(timeleft)
					end

					if finaltime ~= nil then
						plr:Kick("You were banned from the game. You will be unbanned in "..tostring(finaltime).." "..data2[2])
					else
						plr:Kick("You were banned from the game. You will be unbanned in "..tostring(timeleft).." "..data2[2])
					end
				end
			end
		end
	end
	if e then
		warn(e)
	else
		print("Loaded player ban info.")
		for i,v in pairs(users_with_warnings) do
			if i == tostring(plr.UserId) then
				print("Found")
				local clone = script.WarnGui:Clone()
				clone.MainFrame.Body.Text = v
				clone.Parent = plr.PlayerGui
				table.remove(users_with_warnings,i)
				store3:SetAsync("WarnedUsers",users_with_warnings)
			end
		end
	end
end
plrs.PlayerAdded:Connect(plradded)
if not RS:IsStudio() then
	MS:SubscribeAsync(chnl,function(Msg)
		if game.Players:GetPlayerByUserId(Msg["Data"]) then
			game.Players:GetPlayerByUserId(Msg["Data"]):Kick()
		end
	end)
	MS:SubscribeAsync(chnl2,function(Msg)
		if game.Players:GetPlayerByUserId(Msg["Data"]) then
			local clone = script.WarnGui:Clone()
			clone.Parent = game.Players:GetPlayerByUserId(Msg["Data"]).PlayerGui
		end
	end)
end
local EZban = {}
function EZban.Ban(User,reason,caged)
	print("Ban ran.")
	local UserId = game.Players:GetUserIdFromNameAsync(User)
	local tag = Instance.new("StringValue")
	tag.Name = "Banned"
	local tag2 = Instance.new("BoolValue")
	tag2.Name = "Caged"
	tag2.Value = caged
	local info = {tag.Name,tag2.Value,UserId}
	store:SetAsync(UserId,info)
	print("Banned")
	if game.Players:GetPlayerByUserId(UserId) then
		game.Players:GetPlayerByUserId(UserId):Kick(reason)
	elseif not RS:IsStudio() then
		MS:PublishAsync(chnl,UserId)
	end
end
function EZban.SusBan(User)
	local A_n = nil
	for i,v in pairs(game.Players:GetPlayers()) do
		local clone = script.AmogusGui:Clone()
		clone.MainFrame.Msg.Text = User.." was voted off."
		clone.Parent = v.PlayerGui
		A_n = clone
	end
	
	for i = 0,string.len(A_n.MainFrame.Msg.Text),1 do
		wait(.125)
	end
	EZban.Ban(User,"You have been voted out.",false)
end
function EZban.Unban(User)
	local UserId = game.Players:GetUserIdFromNameAsync(User)
	local data = nil
	local data2 = nil
	local s,e = pcall(function()
		data = store:GetAsync(UserId)
		data2 = store2:GetAsync(UserId)
	end)
	if s then
		if data ~= {} or nil then
			print(data)
			local info = {}
			store:SetAsync(UserId,info)
		end
		if data2 ~= {} or nil then
			print(data2)
			local info = {}
			store2:SetAsync(UserId,info)
		end
	end
end
function EZban.Warn(User,warning)
	local has_warning = true
	if User == nil then
		return
	end
	local default_body = "A game administrator has sent you a warning for current user activities. If such activities continue, you may be banned from the game."

	local W_Clone = script.WarnGui:Clone()
	if warning == nil then
		W_Clone.MainFrame.Body.Text = default_body
		has_warning = false
	else
		W_Clone.MainFrame.Body.Text = warning
	end
	if plrs:FindFirstChild(User) then
		W_Clone.Parent = plrs:FindFirstChild(User).PlayerGui
	elseif not RS:IsStudio() then
		if has_warning then
			MS:PublishAsync(chnl2,plrs:GetUserIdFromNameAsync(User))
			users_with_warnings[plrs:GetUserIdFromNameAsync(User)] = warning
			store3:SetAsync("WarnedUsers",users_with_warnings)
			print("Saved warning data")
		else
			users_with_warnings[plrs:GetUserIdFromNameAsync(User)] = default_body
			MS:PublishAsync(chnl2,plrs:GetUserIdFromNameAsync(User))
			store3:SetAsync("WarnedUsers",users_with_warnings)
			print("Saved warning data")
		end
	else
		if has_warning then
			users_with_warnings[plrs:GetUserIdFromNameAsync(User)] = warning
			store3:SetAsync("WarnedUsers",users_with_warnings)
			print("Saved warning data")
		else
			users_with_warnings[plrs:GetUserIdFromNameAsync(User)] = default_body
			store3:SetAsync("WarnedUsers",users_with_warnings)
			print("Saved warning data")
		end
	end
end
function EZban.TimeBan(User,Length,Mode,Reason)
	local UserId = plrs:GetUserIdFromNameAsync(User)
	local LIS = 0
	Mode = string.lower(Mode)
	if Mode == "minutes" then LIS = Length*60	elseif Mode == "hours" then LIS = Length*3600	elseif Mode == "days" then LIS = Length*86400	elseif Mode == "weeks" then LIS = Length*604800 end	
	local endE = Timenow + LIS
	local info = {endE,Mode,UserId}
	store2:SetAsync(UserId,info)
	if plrs:GetPlayerByUserId(UserId) then
		plrs:GetPlayerByUserId(UserId):Kick("You were banned for "..Length.." "..Mode.." for "..Reason)
	elseif not RS:IsStudio() then
		MS:PublishAsync(chnl,UserId)
	end
end

return EZban