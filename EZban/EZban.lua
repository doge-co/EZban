local DS = game:GetService("DataStoreService");
local MS = game:GetService("MessagingService");
local RS = game:GetService("RunService");
local chnl = "UserBanned";
local chnl2 = "UserWarned";
local store ; --DS:GetDataStore("BanInfo")
local store2;--DS:GetDataStore("TimeBanInfo")
local store3;-- = DS:GetDataStore("Warnings")
local bob = script:FindFirstChild("Cage");
local users_with_warnings = {};

local function wait(n)
	local l = 0;
	while l<n do l+=game:GetService("RunService").Heartbeat:Wait(); end;
end;
local function round(n)
	return math.floor(n+.5);
end;
local plrs = game:GetService("Players");
plrs.PlayerAdded:Connect(function(plr)
	local z = coroutine.create(function(plr)
		plr.CharacterAdded:Wait();
		local char = plr.Character;
		repeat wait() until char:FindFirstChild("HumanoidRootPart");
		wait(.1);
		while wait(.1) do
			char.HumanoidRootPart.Position = workspace:FindFirstChild("Cage").Bottom.Position + Vector3.new(0,5,0)
		end
	end)
	print("Player added");
	
	store = DS:GetDataStore("BanInfo");
	store2 = DS:GetDataStore("TimeBanInfo");
	store3 = DS:GetDataStore("Warnings");
	
	pcall(function()
		users_with_warnings = store3:GetAsync("WarnedUsers");
		if users_with_warnings == nil then
			users_with_warnings = {};
		end;
	end);
	
	local data = nil;
	local data2 = nil;
	local s,e = pcall(function()
		data = store:GetAsync(plr.UserId);
		data2 = store2:GetAsync(plr.UserId);
	end)
	if s then
		if data ~= nil then
			if data[3] ~= nil then
				if data[2] ~= nil then
					local caged = data[2];
					if caged then
						coroutine.resume(z,plr);
					else
						plr:Kick("You were banned from this experience.");
					end;
				end;
			end;
		end;
		if data2 ~= nil then
			if data2[3] ~= nil then
				local Mode = data2[2];
				local TLIS = os.difftime(data2[1],Timenow);
				local timeleft = 0;
				local finaltime = nil;
				if TLIS > 0 then
					if Mode == "minutes" then timeleft = TLIS/60	elseif Mode == "hours" then timeleft = TLIS/3600	elseif Mode == "days" then timeleft = TLIS/86400	elseif Mode == "weeks" then timeleft = TLIS/604800 end;
					print(timeleft);
					if timeleft > 1 then
						finaltime = round(timeleft);
					end;

					if finaltime ~= nil then
						plr:Kick("You were banned from the game. You will be unbanned in "..tostring(finaltime).." "..data2[2]);
					else
						plr:Kick("You were banned from the game. You will be unbanned in "..tostring(timeleft).." "..data2[2]);
					end;
				end;
			end;
		end;
	end;
	if e then
		warn(e);
	else
		print("Loaded player ban info.");
	end;
end);

if not workspace:FindFirstChild("Cage") then
	bob.Parent = workspace;
end;
coroutine.wrap(
	function()
		while wait(1) do
			Timenow = os.time();
		end;
	end
)();

if not RS:IsStudio() then
	MS:SubscribeAsync(chnl,function(Msg)
		print(Msg["Data"]);
		if game.Players:GetPlayerByUserId(Msg["Data"]) then
			game.Players:GetPlayerByUserId(Msg["Data"]):Kick();
		end
	end)
end
local EZban = {};
function EZban.Ban(User,reason,caged)
	print("Ban ran.");
	if type(User) ~= "string" then
		error("Argument 1 expected string got: "..type(User));
	end
	local UserId = game.Players:GetUserIdFromNameAsync(User);
	local tag = Instance.new("StringValue");
	tag.Name = "Banned";
	local tag2 = Instance.new("BoolValue");
	tag2.Name = "Caged";
	tag2.Value = caged;
	local info = {tag.Name,tag2.Value,UserId};
	store:SetAsync(UserId,info);
	print("Banned");
	if game.Players:GetPlayerByUserId(UserId) then
		game.Players:GetPlayerByUserId(UserId):Kick(reason);
	else
		MS:PublishAsync(chnl,UserId);
	end;
end;
function EZban.Unban(User)
	if type(User) ~= "string" then
		error("Argument 1 expected string got: "..type(User));
	end
	local UserId = game.Players:GetUserIdFromNameAsync(User);
	local data = nil;
	local data2 = nil;
	local s,e = pcall(function()
		data = store:GetAsync(UserId);
		data2 = store2:GetAsync(UserId);
	end);
	if s then
		if data ~= {} or nil then
			print(data);
			local info = {};
			store:SetAsync(UserId,info);
		end;
		if data2 ~= {} or nil then
			print(data2);
			local info = {};
			store2:SetAsync(UserId,info);
		end;
	end;
end;

function EZban.TimeBan(User,Length,Mode,Reason)
	if type(User) ~= "string" then
		error("Argument 1 expected string got: "..type(User));
	end;
	local UserId = plrs:GetUserIdFromNameAsync(User);
	local LIS = 0;
	Mode = string.lower(Mode);
	if Mode == "minutes" then LIS = Length*60	elseif Mode == "hours" then LIS = Length*3600	elseif Mode == "days" then LIS = Length*86400	elseif Mode == "weeks" then LIS = Length*604800 end;
	local endE = Timenow + LIS;
	local info = {endE,Mode,UserId};
	store2:SetAsync(UserId,info);

	if plrs:GetPlayerByUserId(UserId) then
		plrs:GetPlayerByUserId(UserId):Kick("You were banned for "..Length.." "..Mode.." for "..Reason);
	else
		MS:PublishAsync(chnl,UserId);
	end;
end;

function EZban.Warn(User,warning)
	local has_warning = true;
	if User == nil then
		return;
	end;
	local default_body = "A game administrator has sent you a warning for current user activities. If such activities continue, you may be banned from the game.";

	local W_Clone = script.WarnGui:Clone();
	if warning == nil then
		W_Clone.MainFrame.Body.Text = default_body;
		has_warning = false;
	else
		W_Clone.MainFrame.Body.Text = warning;
	end;
	if plrs:FindFirstChild(User) then
		W_Clone.Parent = plrs:FindFirstChild(User).PlayerGui;
	elseif not RS:IsStudio() then
		if has_warning then
			MS:PublishAsync(chnl2,plrs:GetUserIdFromNameAsync(User));
			users_with_warnings[plrs:GetUserIdFromNameAsync(User)] = warning;
			store3:SetAsync("WarnedUsers",users_with_warnings);
			print("Saved warning data");
		else
			users_with_warnings[plrs:GetUserIdFromNameAsync(User)] = default_body;
			MS:PublishAsync(chnl2,plrs:GetUserIdFromNameAsync(User));
			store3:SetAsync("WarnedUsers",users_with_warnings);
			print("Saved warning data");
		end;
	else
		if has_warning then
			users_with_warnings[plrs:GetUserIdFromNameAsync(User)] = warning;
			store3:SetAsync("WarnedUsers",users_with_warnings);
			print("Saved warning data");
		else
			users_with_warnings[plrs:GetUserIdFromNameAsync(User)] = default_body;
			store3:SetAsync("WarnedUsers",users_with_warnings);
			print("Saved warning data");
		end;
	end;
end;
function EZban.SusBan(User)
	local A_n = nil;
	for i,v in pairs(game.Players:GetPlayers()) do
		local clone = script.AmogusGui:Clone();
		clone.MainFrame.Msg.Text = User.." was voted off.";
		clone.Parent = v.PlayerGui;
		A_n = clone;
	end;

	for i = 0,string.len(A_n.MainFrame.Msg.Text),1 do
		wait(.125);
	end;
	EZban.Ban(User,"You have been voted out.",false);
end;
return
