--[[ 
Ziplines!

How to use the script:

* Place this script underneath the ServerScriptService
* Create a model named Ziplines in the Workspace
* Within the Ziplines model you can place child models that represent individual ziplines.
	* Each individual zipline should include have a part named "Start" and "Finish" as their descendent representing their namesake. 
	  These parts should have attachments named "Attachment" as their children. These parts should also be have 
	  The parts should be CanCollide = false and be sizeable enough that the player can touch then b/c they will trigger usage of the zipline.
	* These models may have the following objects added for greater control:
		* BothWays [BoolValue] -> Set this to true if you want to allow the player to ride the zipline both ways. If 
		  non-existent defaults to false.
		* Speed [NumberValue] -> Set the value of this to what speed the zipline should travel at. If the speed values doesn't exist or it's
		  set to zero then it will be calculated based on angle of descent.

That's it! Enjoy!

EgoMoose
--]]


local slider = script:WaitForChild("Slider");
local heartBeat = game:GetService("RunService").Heartbeat;
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local physicsService = game:GetService("PhysicsService");
local Players = game:GetService("Players")
local ziplines = game.Workspace:WaitForChild("Ziplines"):GetChildren();

local SOUND_EVENT = ReplicatedStorage.Events.SoundEvent

physicsService:RegisterCollisionGroup("non-zipPlayers");

-- private functions

local function copyJoint(joint)
	local fake = Instance.new("Weld");
	fake.Part0 = joint.Part0;
	fake.Part1 = joint.Part1;
	fake.C0 = joint.C0;
	fake.C1 = joint.C1;
	fake.Name = joint.Name .. "_Fake";
	return fake;
end

local function setCollisionGroupRecursive(children, group)
	for i = 1, #children do
		if (children[i]:IsA("BasePart")) then
			children[i].CollisionGroup = group
		end
		setCollisionGroupRecursive(children[i]:GetChildren(), group)
	end
end

-- zip class

local zip = {};
local zip_mt = {__index = zip};
local zip_ref = setmetatable({}, {__mode = "k"});

function zip.new(character)
	local self = {};

	self.isRiding = false;

	self.slider = slider:Clone();
	self.slider.Anchored = false;
	self.attachS = self.slider:WaitForChild("Attachment");
	self.pris = self.slider:WaitForChild("PrismaticConstraint");
	self.ropeR = self.slider:WaitForChild("RopeConstraintR");
	self.ropeL = self.slider:WaitForChild("RopeConstraintL");
	self.weld = self.slider:WaitForChild("WeldConstraint");

	self.hrp = character:WaitForChild("HumanoidRootPart");
	self.humanoid = character:WaitForChild("Humanoid");

	local right, left;
	if (self.humanoid.RigType == Enum.HumanoidRigType.R15) then
		self.torso = character:WaitForChild("UpperTorso");
		right = character:WaitForChild("RightHand")
		left = character:WaitForChild("LeftHand")

		local rShoulder = character:WaitForChild("RightUpperArm"):WaitForChild("RightShoulder");
		local lShoulder = character:WaitForChild("LeftUpperArm"):WaitForChild("LeftShoulder");
		local rElbow = character:WaitForChild("RightLowerArm"):WaitForChild("RightElbow");
		local lElbow = character:WaitForChild("LeftLowerArm"):WaitForChild("LeftElbow");

		-- weird bug with mesh arm parts like rthro
		if not (rShoulder.Part0 or lShoulder.Part0) then
			repeat wait() until (rShoulder.Part0 and lShoulder.Part0)
		end

		local rShoulderFake = copyJoint(rShoulder);
		local lShoulderFake = copyJoint(lShoulder);
		local rElbowFake = copyJoint(rElbow);
		local lElbowFake = copyJoint(lElbow);

		rShoulderFake.C0 = rShoulder.C0 * CFrame.fromEulerAnglesXYZ(math.pi, 0, math.rad(15));
		rElbowFake.C0 = rElbow.C0 * CFrame.fromEulerAnglesXYZ(0, 0, -math.rad(10));

		lShoulderFake.C0 = lShoulder.C0 * CFrame.fromEulerAnglesXYZ(math.pi, 0, -math.rad(15));
		lElbowFake.C0 = lElbow.C0 * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(10));

		zip_ref[self] = {
			[rShoulder] = rShoulderFake;
			[lShoulder] = lShoulderFake;
			[rElbow] = rElbowFake;
			[lElbow] = lElbowFake;
		};
	else
		self.torso = character:WaitForChild("Torso");
		right = character:WaitForChild("Right Arm");
		left = character:WaitForChild("Left Arm");

		local rShoulder = self.torso:WaitForChild("Right Shoulder");
		local lShoulder = self.torso:WaitForChild("Left Shoulder");

		local rShoulderFake = copyJoint(rShoulder);
		local lShoulderFake = copyJoint(lShoulder);

		rShoulderFake.C0 = rShoulder.C0 * CFrame.fromEulerAnglesXYZ(0, 0, math.pi);
		lShoulderFake.C0 = lShoulder.C0 * CFrame.fromEulerAnglesXYZ(0, 0, math.pi);

		zip_ref[self] = {
			[rShoulder] = rShoulderFake;
			[lShoulder] = lShoulderFake;
		};
	end

	self.rHandAttach = right:WaitForChild("RightGripAttachment");
	self.lHandAttach = left:WaitForChild("LeftGripAttachment");

	setCollisionGroupRecursive(character:GetChildren(), "non-zipPlayers");
	return setmetatable(self, zip_mt);
end

function zip:poseArms(bool)
	for real, fake in next, zip_ref[self] do
		if (bool) then
			fake.Parent = real.Parent;
			real.Parent = nil;
		else
			real.Parent = fake.Parent;
			fake.Parent = nil;
		end
	end
end

function zip:slide(attachA, attachB, speed)
	self.isRiding = true;
	setCollisionGroupRecursive(self.humanoid.Parent:GetChildren(), "Zipline");

	local v = attachB.WorldPosition - attachA.WorldPosition;
	local cf = CFrame.new(attachA.WorldPosition, attachB.WorldPosition);

	local oldWalkSpeed = self.humanoid.WalkSpeed;
	self.humanoid.WalkSpeed = 0;

	attachA.CFrame = attachA.Parent.CFrame:inverse() * cf * CFrame.Angles(0, math.pi/2, 0);
	if (speed and speed <= 0) then
		speed = nil;
	end

	local length = v.magnitude;
	self.pris.TargetPosition = length;
	self.pris.UpperLimit = length;
	self.pris.Attachment0 = attachA;
	self.pris.Attachment1 = self.attachS;	
	self.pris.Speed = speed or math.abs(Vector3.new(0, -game.Workspace.Gravity, 0):Dot(v.unit));
	self.pris.ServoMaxForce = math.huge;

	self.ropeR.Attachment0 = self.attachS;
	self.ropeR.Attachment1 = self.rHandAttach;
	self.ropeL.Attachment0 = self.attachS;
	self.ropeL.Attachment1 = self.lHandAttach;

	self:poseArms(true);

	self.weld.Part0 = self.slider;
	self.weld.Part1 = self.torso;
	self.torso.CFrame = cf * CFrame.new(0, -3, 0) * CFrame.Angles(0, math.pi/2, 0);

	self.slider.CFrame = attachA.WorldCFrame;
	self.slider.Parent = game.Workspace;

	-- some added stability for first bit...
	delay(0.2, function() self.weld.Part1 = nil; end);
	while (math.abs(self.pris.CurrentPosition - length) > 0.01) do
		self.humanoid:ChangeState(Enum.HumanoidStateType.Freefall);
		heartBeat:Wait();
	end

	self.slider.Parent = nil;
	self.humanoid.WalkSpeed = oldWalkSpeed;

	self:poseArms(false);

	setCollisionGroupRecursive(self.humanoid.Parent:GetChildren(), "non-zipPlayers");
	delay(0.5, function() self.isRiding = false; end)
end

-- connections

local zips = {};
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAppearanceLoaded:Connect(function(character)
		zips[player] = zip.new(character);
		--print("Zip created for", player.Name);
	end)
end)

-- test this with deboucne 
for i = 1, #ziplines do
	local speed = ziplines[i]:FindFirstChild("Speed");
	local start = ziplines[i]:FindFirstChild("Start", true);
	local finish = ziplines[i]:FindFirstChild("Finish", true);

	local debounce = false;

	start.Touched:Connect(function(hit)
		local player = game.Players:GetPlayerFromCharacter(hit.Parent);

		if (not debounce and player and zips[player] and not zips[player].isRiding) then
			debounce = true;
			player.Character:SetAttribute("ziplining", true)
			player.Character.UpperTorso.CanCollide = false
			player.Character.HumanoidRootPart.CanCollide = false

			SOUND_EVENT:FireClient(player, "rbxassetid://6515384732", 0.8, 1.2, 0.2)
			SOUND_EVENT:FireClient(player, "rbxassetid://9120745575", 1, 1.3)
			
			delay(0.1, function() debounce = false end);
			zips[player]:slide(start.Attachment, finish.Attachment, speed and speed.Value);
		end
	end)


	finish.Touched:Connect(function(hit)
		if hit.Parent:GetAttribute("ziplining") then
			local player = game.Players:GetPlayerFromCharacter(hit.Parent);

			if (not debounce and player and zips[player] and not zips[player].isRiding) then
				player.Character:SetAttribute("ziplining", false)
				player.Character.UpperTorso.CanCollide = true
				player.Character.HumanoidRootPart.CanCollide = true
				debounce = true;
			end
		end
	end)		
end