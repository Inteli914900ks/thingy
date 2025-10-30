type physicsTail = {
	root:BasePart,	

	rootPreviousCFrame:CFrame,	
	rootPreviousDeltaCFrame:CFrame,	

	weld:Weld,	
	weldOriginalCFrame:CFrame, 
	weldPreviousCFrame:CFrame, 
	weldCurrentCFrame:CFrame, 

	currentAngle:Vector3, 
	angularVelocity:Vector3, 
	wagAnimationBlendAlpha:number, 
	wagSeed:number, 

	pivotCFrame:CFrame, 
	inversePivotOffsetCFrame:CFrame, 

	character:Model, 
	inverseCharacterScale:number, 

	distanceToCamera:number, 
	renderingPhysics:boolean, 
}

local config = {
	stiffness = 96;
	damping = 9;
	linearAmplitude = Vector3.new(6.40000, 2.53333, 6.40000);
	angularAmplitude = Vector3.new(0, 18, 0);
	wagAnimationEnabled = true;
	wagAnimationDropAmplitude = 0.2;
	wagAnimationSwayAmplitude = 0.4;
	wagAnimationRollAmplitude = 0.5;
	wagAnimationBlendInAlpha = 0.008;
	wagAnimationBlendOutAlpha = 0.02;
	wagAnimationSpeed = 1;
	timeScale = 1;
	globalWindEnabled = false;
	gravityEnabled = false;
	customPersistantWindForce = Vector3.new(0, 0, 0);
	customPersistantLinearForce = Vector3.new(0, 0, 0);
	maxRenderDistance = 900;
	maxPhysicsTails = 3000;
	movementDistanceThreshold = 15;
	includedAccessoryNames = {};
	includedDescendantCharacters = {};
}

local configuration = config
local
includedAccessoryNames:{string},
includedDescendantCharacters:{Instance},

enabled:boolean,

stiffness:number,
damping:number,
linearAmplitude:Vector3|number,
angularAmplitude:Vector3|number,

wagAnimationEnabled:boolean,
wagAnimationDropAmplitude:number,
wagAnimationSwayAmplitude:number,
wagAnimationRollAmplitude:number,
wagAnimationBlendInAlpha:number,
wagAnimationBlendOutAlpha:number,
wagAnimationSpeed:number,

timeScale:number,

globalWindEnabled:boolean,
gravityEnabled:boolean,
customPersistantWindForce:Vector3,
customPersistantLinearForce:Vector3,

maxRenderDistance:number,
maxPhysicsTails:number,
movementDistanceThreshold:number
	=
	configuration.includedAccessoryNames,
	configuration.includedDescendantCharacters,

	true,

	configuration.stiffness,
	configuration.damping,
	configuration.linearAmplitude,
	configuration.angularAmplitude,

	configuration.wagAnimationEnabled,
	configuration.wagAnimationDropAmplitude,
	configuration.wagAnimationSwayAmplitude,
	configuration.wagAnimationRollAmplitude,
	configuration.wagAnimationBlendInAlpha,
	configuration.wagAnimationBlendOutAlpha,
	configuration.wagAnimationSpeed,

	configuration.timeScale,

	configuration.globalWindEnabled,
	configuration.gravityEnabled,
	configuration.customPersistantWindForce,
	configuration.customPersistantLinearForce,

	configuration.maxRenderDistance,
	configuration.maxPhysicsTails,
	configuration.movementDistanceThreshold

local instanceIsA = game.IsA
local instanceFindFirstChild = game.FindFirstChild
local instanceWaitForChild = game.WaitForChild
local instanceGetChildren = game.GetChildren
local instanceGetDescendants = game.GetDescendants
local instanceChildAddedRBXScriptConnection = game.ChildAdded.Connect
local instanceChildAddedRBXScriptOnce = game.ChildAdded.Once
local instanceDescendantAddedRBXScriptConnection = game.DescendantAdded.Connect
local instanceGetPropertyChangedSignal = game.GetPropertyChangedSignal
local instanceNew = Instance.new

local modelInstance = instanceNew("Model")
local modelGetScale = modelInstance.GetScale

local cframeIdentity = CFrame.identity
local cframeToObjectSpace = cframeIdentity.ToObjectSpace
local cframeVectorToObjectSpace = cframeIdentity.VectorToObjectSpace
local cframeInverse = cframeIdentity.Inverse
local cframeToEulerAnglesXYZ = cframeIdentity.ToEulerAnglesXYZ
local cframeFromEulerAngles = CFrame.fromEulerAngles
local cframeNew = CFrame.new

local vector3Zero = Vector3.zero
local vector3Cross = vector3Zero.Cross
local vector3New = Vector3.new

local gameGetService = game.GetService

local mathSin = math.sin
local mathCos = math.cos
local mathMin = math.min
local mathMax = math.max

local tableInsert = table.insert
local tableFind = table.find
local tableRemove = table.remove
local tableSort = table.sort
local tableConcat = table.concat
local tableUnpack = table.unpack

local stringFind = string.find
local stringLower = string.lower
local stringLen = string.len
local stringByte = string.byte

local dateTimeNow = DateTime.now

local accessoryTypeBack = Enum.AccessoryType.Back
local accessoryTypeWaist = Enum.AccessoryType.Waist

local RunService:RunService = gameGetService(game, "RunService")
local Players:Players = gameGetService(game, "Players")

local playersGetPlayerFromCharacter = Players.GetPlayerFromCharacter

local camera = workspace.CurrentCamera

local physicsTails:{physicsTail} = {}

local charactersSetUpForPhysicsTails:{[Model]:boolean} = {}

local timeStep = 1 / 120 
local inverseTimeStep = 1 / timeStep 

local function calculateElasticity(
	position: Vector3,
	velocity: Vector3,
	stiffness: number,
	damping: number
): (Vector3, Vector3)
	local springForce = stiffness * position 
	local dampingForce = damping * velocity
	local acceleration = springForce + dampingForce

	local newVelocity = velocity - acceleration * timeStep
	local newValue = position + newVelocity * timeStep

	return newValue, newVelocity
end

local function vector3ToAngles(vector3:Vector3):CFrame
	return cframeFromEulerAngles(vector3.X, vector3.Y, vector3.Z)
end

local function lerp(from:number, to:number, alpha:number):number
	return from + (to - from) * alpha
end

local function updatePhysicsTailToStatic(physicsTail:physicsTail)

	local characterScale = physicsTail.inverseCharacterScale * modelGetScale(physicsTail.character)

	local weldOriginalCFrame = physicsTail.weldOriginalCFrame 
	physicsTail.weld.C0 = weldOriginalCFrame.Rotation + weldOriginalCFrame.Position * characterScale
end

local tailScaledAnimationTime = 0

local function getTailAnimationOffset(physicsTail:physicsTail):Vector3
	local wagAnimationBlendAlpha = physicsTail.wagAnimationBlendAlpha 
	if physicsTail.angularVelocity.Magnitude > 0.3 then

		wagAnimationBlendAlpha = wagAnimationBlendAlpha < 0.01 and 0 or wagAnimationBlendAlpha * (1 - wagAnimationBlendOutAlpha)
	else
		wagAnimationBlendAlpha = wagAnimationBlendAlpha > 0.99 and 1 or lerp(wagAnimationBlendAlpha, 1, wagAnimationBlendInAlpha)
	end
	physicsTail.wagAnimationBlendAlpha = wagAnimationBlendAlpha

	if wagAnimationBlendAlpha > 0 then
		local wagTime = tailScaledAnimationTime + physicsTail.wagSeed

		local fluctuatingWagTime = wagTime + mathSin(wagTime) * mathSin(wagTime * 0.22727272727272727) * 0.9

		return vector3New(
			(mathSin(fluctuatingWagTime * 2) + 0.8) * wagAnimationDropAmplitude * wagAnimationBlendAlpha,
			mathCos(fluctuatingWagTime) * wagAnimationSwayAmplitude * wagAnimationBlendAlpha,
			mathSin(fluctuatingWagTime) * -wagAnimationRollAmplitude * wagAnimationBlendAlpha
		)
	end

	return vector3Zero
end

local function updatePhysicsTailToInterpolation(physicsTail:physicsTail, interpolationAlpha:number)

	local characterScale = physicsTail.inverseCharacterScale * modelGetScale(physicsTail.character)

	local weldCFrame = physicsTail.weldPreviousCFrame:Lerp(physicsTail.weldCurrentCFrame, interpolationAlpha)

	if wagAnimationEnabled then

		weldCFrame *= cframeInverse(
			cframeToObjectSpace(weldCFrame,
				physicsTail.pivotCFrame * vector3ToAngles(getTailAnimationOffset(physicsTail)) * physicsTail.inversePivotOffsetCFrame
			)
		)
	end

	physicsTail.weld.C0 = weldCFrame.Rotation + weldCFrame.Position * characterScale
end

local persistantTailWindUnit:Vector3 
local persistantTailWindAlpha:number 
local persistantTailWindAlpha_Times_04:number 
local persistantTailWindAlpha_Squared_Times_006:number 
local persistantTailWindForceRelevant = false 

local function updateTailPersistantWindForceInformation()
	local persistantTailWindForce = globalWindEnabled and (workspace.GlobalWind + customPersistantWindForce) or customPersistantWindForce

	persistantTailWindUnit = persistantTailWindForce.Unit

	persistantTailWindAlpha = persistantTailWindForce.Magnitude * 0.5

	persistantTailWindAlpha_Times_04 = persistantTailWindAlpha * 0.4
	persistantTailWindAlpha_Squared_Times_006 = persistantTailWindAlpha * persistantTailWindAlpha * 0.06

	persistantTailWindForceRelevant = persistantTailWindAlpha > 0
end
updateTailPersistantWindForceInformation()

local workspaceGlobalWindPropertyChangeSignal = instanceGetPropertyChangedSignal(workspace, "GlobalWind")
workspaceGlobalWindPropertyChangeSignal.Connect(workspaceGlobalWindPropertyChangeSignal, updateTailPersistantWindForceInformation)

local gravityForce:Vector3 
local persistantTailLinearForce:Vector3 
local persistantTailLinearForceRelevant = false 
local function updateTailPersistantLinearForceInformation()

	persistantTailLinearForce = gravityEnabled and (gravityForce + customPersistantLinearForce) or customPersistantLinearForce

	persistantTailLinearForceRelevant = persistantTailLinearForce.Magnitude > 0
end

local function updateGravityInformation()
	local gravity = workspace.Gravity

	gravityForce = vector3New(0,

		mathMax((196.2 - gravity) * 0.004, -1))

	updateTailPersistantLinearForceInformation()
end
updateGravityInformation()

local workspaceGravityPropertyChangeSignal = instanceGetPropertyChangedSignal(workspace, "Gravity")
workspaceGravityPropertyChangeSignal.Connect(workspaceGravityPropertyChangeSignal, updateGravityInformation)

local tailScaledTime = 0

local function updatePhysicsTail(physicsTail:physicsTail, updateWeld:boolean, interpolationAlpha:number)

	local rootCFrame = physicsTail.root.CFrame

	local rootDeltaCFrame = cframeToObjectSpace(physicsTail.rootPreviousCFrame, rootCFrame)

	if rootDeltaCFrame.Position.Magnitude > movementDistanceThreshold then
		rootDeltaCFrame = rootDeltaCFrame.Rotation 
	end

	local rootAcceleration = cframeToObjectSpace(physicsTail.rootPreviousDeltaCFrame, rootDeltaCFrame)

	local tailForce = rootAcceleration.Position * linearAmplitude

	if persistantTailWindForceRelevant then

		local sinUnixTime4 = mathSin(tailScaledTime * 4)

		local unstableWindFlow = mathSin(tailScaledTime * 2 * sinUnixTime4) * persistantTailWindAlpha_Times_04

		local stableWindFlow = mathSin(tailScaledTime * 2) * sinUnixTime4

		tailForce -= cframeVectorToObjectSpace(rootCFrame, persistantTailWindUnit * persistantTailWindAlpha_Squared_Times_006 * (1 + (stableWindFlow + unstableWindFlow) * 0.4))
	end

	if persistantTailLinearForceRelevant then tailForce -= cframeVectorToObjectSpace(rootCFrame, persistantTailLinearForce) end

	local pivotCFrame = physicsTail.pivotCFrame 

	local displacement = pivotCFrame.Position - physicsTail.weldPreviousCFrame.Position
	local torque = vector3Cross(displacement, tailForce)

	local angularAcceleration = vector3New(cframeToEulerAnglesXYZ(rootAcceleration)) * angularAmplitude

	local newCurrentAngle, newAngularVelocity = calculateElasticity(physicsTail.currentAngle, physicsTail.angularVelocity, stiffness, damping)

	physicsTail.currentAngle = newCurrentAngle

	local characterScale = physicsTail.inverseCharacterScale * modelGetScale(physicsTail.character)

	physicsTail.angularVelocity = newAngularVelocity + torque / characterScale - angularAcceleration

	local currentAngleCFrame = vector3ToAngles(newCurrentAngle) 
	local newWeldCurrentCFrame = pivotCFrame * currentAngleCFrame * physicsTail.inversePivotOffsetCFrame
	local newWeldPreviousCFrame = physicsTail.weldCurrentCFrame
	if updateWeld then

		local weldCFrame = newWeldPreviousCFrame:Lerp(newWeldCurrentCFrame, interpolationAlpha)

		if wagAnimationEnabled then

			weldCFrame *= cframeInverse(
				cframeToObjectSpace(weldCFrame,
					pivotCFrame * vector3ToAngles(getTailAnimationOffset(physicsTail)) * physicsTail.inversePivotOffsetCFrame
				)
			)
		end

		physicsTail.weld.C0 = weldCFrame.Rotation + weldCFrame.Position * characterScale
	end

	physicsTail.rootPreviousCFrame = rootCFrame
	physicsTail.rootPreviousDeltaCFrame = rootDeltaCFrame

	physicsTail.weldPreviousCFrame = newWeldPreviousCFrame
	physicsTail.weldCurrentCFrame = newWeldCurrentCFrame
end

local r6TailPivotOffset = cframeNew(0, 0.3, 0)

local function getTailPivotOffsetFromRoot(root:Part):CFrame?

	local waistRigAttachment:Attachment = instanceFindFirstChild(root, "WaistRigAttachment")
	if waistRigAttachment then
		return waistRigAttachment.CFrame * cframeNew(0, 0, root.Size.Z * 0.5)
	end

	local waistBackAttachment:Attachment = instanceFindFirstChild(root, "WaistBackAttachment")
	if waistBackAttachment then
		return waistBackAttachment.CFrame * r6TailPivotOffset
	end
end

local function nameToTailWagSeed(name:string):number
	local wagSeed = 0
	for _, byte:string in {stringByte(name, 1, stringLen(name))} do
		wagSeed += (byte * byte)
	end
	return wagSeed
end

local function cframeOrAttachmentOrNilParameterToCFrame(parameter:CFrame|Attachment?):CFrame
	return parameter and (typeof(parameter) == "CFrame" and parameter or parameter.CFrame) or cframeIdentity
end

local function setUpWeld(character:Model, weld:Weld, tailPart:BasePart, customPivotOffset:CFrame|Attachment?)

	local flipAccessoryWeldParts = false
	local root:Part = weld.Part0
	if not root then warn("TuxPhysicsTails: Weld \""..weld.Name.."\" for the character \""..character.Name.."\" did not have Part0. Make sure the character has finished loading and you've set Part0.") return end
	if root == tailPart then
		root = weld.Part1
		if not root then warn("TuxPhysicsTails: Weld \""..weld.Name.."\" for the character \""..character.Name.."\" did not have Part1. Make sure the character has finished loading and you've set Part0.") return end
		flipAccessoryWeldParts = true
	end

	local pivotOffset:CFrame?
	if customPivotOffset then
		pivotOffset = cframeOrAttachmentOrNilParameterToCFrame(customPivotOffset)
	else
		pivotOffset = getTailPivotOffsetFromRoot(root)
	end
	if not pivotOffset then warn("TuxPhysicsTails: Could not find attachment on part \""..root.Name.."\" for the character \""..character.Name.."\". Make sure the character has finished loading and you've set Part0.") return end

	local weldOriginalCFrame:CFrame
	if flipAccessoryWeldParts then
		weldOriginalCFrame = weld.C1 * cframeInverse(weld.C0) 

		weld.Part0, weld.Part1 = root, tailPart
	else
		weldOriginalCFrame = weld.C0 * cframeInverse(weld.C1) 
	end

	weld.C0 = weldOriginalCFrame 
	weld.C1 = cframeIdentity 

	pivotOffset = cframeToObjectSpace(weldOriginalCFrame, cframeNew(pivotOffset.Position))

	local wagSeed = nameToTailWagSeed(character.Name)
	local player = playersGetPlayerFromCharacter(Players, character)
	if player then
		wagSeed += player.UserId
	end

	local physicsTail = {
		root = root,
		rootPreviousCFrame = root.CFrame,
		rootPreviousDeltaCFrame = cframeIdentity,

		weld = weld,
		weldOriginalCFrame = weldOriginalCFrame,
		weldPreviousCFrame = weldOriginalCFrame,

		weldCurrentCFrame = weldOriginalCFrame,

		currentAngle = vector3Zero,
		angularVelocity = vector3Zero,
		wagAnimationBlendAlpha = 0,
		wagSeed = wagSeed,

		pivotCFrame = weldOriginalCFrame * pivotOffset,
		inversePivotOffsetCFrame = cframeInverse(pivotOffset),

		character = character,
		inverseCharacterScale = 1 / modelGetScale(character),
	}
	tableInsert(physicsTails, physicsTail)

	weld.AncestryChanged:Connect(function()
		if not weld.Parent then
			local index = tableFind(physicsTails, physicsTail)
			tableRemove(physicsTails, index)
		end
	end)
end

local function setUpTailAccessory(character:Model, accessory:Accessory)

	local handle:Part = instanceFindFirstChild(accessory, "Handle")
	if not handle then

		instanceChildAddedRBXScriptOnce(accessory.ChildAdded, function()
			setUpTailAccessory(character, accessory)
		end)
		return
	end

	local weld:Weld = instanceFindFirstChild(handle, "AccessoryWeld")
	if not weld then return end

	setUpWeld(character, weld, handle)
end

local includedAccessoryNamesValidationSet:{[Instance]:boolean} = {}

local includedAccessoryNamesValidationSetNeedsUpdating = true

local function updateIncludedAccessoryNamesValidationSet()
	includedAccessoryNamesValidationSet = {}
	for _, accessoryName in includedAccessoryNames do
		includedAccessoryNamesValidationSet[accessoryName] = true
	end
	includedAccessoryNamesValidationSetNeedsUpdating = false
end

local function isTailAccessory(accessory:Accessory):boolean
	local accessoryType = accessory.AccessoryType
	local accessoryName = accessory.Name
	if accessoryType == accessoryTypeBack or accessoryType == accessoryTypeWaist then
		if stringFind(stringLower(accessoryName), "tail", 1, true) then
			return true
		else
			if includedAccessoryNamesValidationSetNeedsUpdating then updateIncludedAccessoryNamesValidationSet() end
			if includedAccessoryNamesValidationSet[accessoryName] then
				return true
			end
		end
	end
	return false
end

local function setUpCharacter(character:Model)
	if charactersSetUpForPhysicsTails[character] then return end
	charactersSetUpForPhysicsTails[character] = true

	local instanceChildAddedConnection = instanceChildAddedRBXScriptConnection(character.ChildAdded, function(child:Instance)
		if child.ClassName == "Accessory" and isTailAccessory(child) then
			setUpTailAccessory(character, child)
		end
	end)

	for _, child in instanceGetChildren(character) do
		if child.ClassName == "Accessory" and isTailAccessory(child) then
			setUpTailAccessory(character, child)
		end
	end

	local characterParentPropertyChangedSignal = instanceGetPropertyChangedSignal(character, "Parent")
	local characterParentPropertyChangedConnection
	characterParentPropertyChangedConnection = characterParentPropertyChangedSignal.Connect(characterParentPropertyChangedSignal, function()
		if not character.Parent then
			charactersSetUpForPhysicsTails[character] = nil
			instanceChildAddedConnection.Disconnect(instanceChildAddedConnection)
			characterParentPropertyChangedConnection.Disconnect(characterParentPropertyChangedConnection)
		end
	end)
end

Players.PlayerAdded.Connect(Players.PlayerAdded, function(player: Player)

	player.CharacterAdded.Connect(player.CharacterAdded, setUpCharacter)
end)

for _, player in Players.GetPlayers(Players) do
	local character = player.Character

	player.CharacterAdded.Connect(player.CharacterAdded, setUpCharacter)

	if not character then continue end
	setUpCharacter(character)
end

local includedDescendantCharactersValidationSet:{[Instance]:boolean} = {}

local includedDescendantCharactersValidationSetNeedsUpdating = true

local function updateIncludedDescendantCharactersValidationSet()
	includedDescendantCharactersValidationSet = {}
	for _, instance in includedDescendantCharacters do
		includedDescendantCharactersValidationSet[instance] = true
	end
	includedDescendantCharactersValidationSetNeedsUpdating = false
end

local function checkIncludedDescendantCharactersValidationSet(instance:Instance):boolean?
	local current = instance
	while current do
		if includedDescendantCharactersValidationSet[current] then
			return true
		end
		current = current.Parent
	end
	return false
end

instanceDescendantAddedRBXScriptConnection(workspace.DescendantAdded, function(child:Instance)
	if child.ClassName == "Model" then
		if charactersSetUpForPhysicsTails[child] then return end
		if includedDescendantCharactersValidationSetNeedsUpdating then updateIncludedDescendantCharactersValidationSet() end
		for _, includedDescendantCharactersInstance in includedDescendantCharacters do
			if checkIncludedDescendantCharactersValidationSet(child) then
				if instanceFindFirstChild(child, "Humanoid") then
					setUpCharacter(child)
				end
				return
			end
		end
	end
end)

local function checkCurrentIncludedDescendantCharacters()
	if includedDescendantCharactersValidationSetNeedsUpdating then updateIncludedDescendantCharactersValidationSet() end

	local alreadyCheckedDescendants:{[Instance]:boolean} = {}
	for _, includedDescendantCharactersInstance:Instance in includedDescendantCharacters do
		for _, descendant in instanceGetDescendants(includedDescendantCharactersInstance) do
			if alreadyCheckedDescendants[descendant] then continue end
			alreadyCheckedDescendants[descendant] = true
			if checkIncludedDescendantCharactersValidationSet(descendant) then
				if instanceFindFirstChild(descendant, "Humanoid") then
					setUpCharacter(descendant)
				end
			end
		end
	end
end
checkCurrentIncludedDescendantCharacters()

local cameraPosition = vector3Zero
local function physicsTailsDistanceToCameraComparer(a:physicsTail, b:physicsTail):boolean
	return a.distanceToCamera < b.distanceToCamera
end

local accumulator = 0

local isCurrentlyEnabled = true

RunService.PreRender.Connect(RunService.PreRender, function(deltaTime)
	if isCurrentlyEnabled ~= enabled then
		isCurrentlyEnabled = enabled

		if not enabled then

			for _, physicsTail in physicsTails do
				if physicsTail.renderingPhysics then
					physicsTail.renderingPhysics = false
					updatePhysicsTailToStatic(physicsTail)
				end
			end
		end
	end

	if not enabled then
		return
	end

	deltaTime = mathMin(deltaTime, 0.1) * timeScale

	tailScaledAnimationTime += deltaTime * wagAnimationSpeed
	tailScaledTime += deltaTime
	accumulator += deltaTime

	local stepCount = 0 
	while accumulator >= timeStep do
		accumulator -= timeStep
		stepCount += 1
	end

	cameraPosition = camera.CFrame.Position

	local tailsCurrentlyRenderingPhysics:{physicsTail} = {}

	for _, physicsTail in physicsTails do
		local distanceToCamera = (physicsTail.root.CFrame.Position - cameraPosition).Magnitude

		if distanceToCamera <= maxRenderDistance then

			physicsTail.distanceToCamera = distanceToCamera

			tableInsert(tailsCurrentlyRenderingPhysics, physicsTail)
		elseif physicsTail.renderingPhysics then
			physicsTail.renderingPhysics = false
			updatePhysicsTailToStatic(physicsTail)
		end
	end

	tableSort(tailsCurrentlyRenderingPhysics, physicsTailsDistanceToCameraComparer)

	local unixTime = dateTimeNow().UnixTimestampMillis * 0.001 * timeScale

	local interpolate = stepCount == 0 
	local interpolationAlpha = accumulator * inverseTimeStep 

	local tailsUpdated = 0
	for _, physicsTail in tailsCurrentlyRenderingPhysics do
		if tailsUpdated > maxPhysicsTails then
			if physicsTail.renderingPhysics then
				physicsTail.renderingPhysics = false
				updatePhysicsTailToStatic(physicsTail)
			end
		else
			if interpolate then

				if not physicsTail.renderingPhysics then continue end

				updatePhysicsTailToInterpolation(physicsTail, interpolationAlpha)
			else

				if not physicsTail.renderingPhysics then

					physicsTail.rootPreviousCFrame = physicsTail.root.CFrame
					physicsTail.rootPreviousDeltaCFrame = cframeIdentity

					local weldOriginalCFrame = physicsTail.weldOriginalCFrame

					physicsTail.weldPreviousCFrame = weldOriginalCFrame
					physicsTail.weldCurrentCFrame = weldOriginalCFrame

					physicsTail.currentAngle = vector3Zero

					physicsTail.angularVelocity = vector3Zero

					physicsTail.wagAnimationBlendAlpha = 0

					physicsTail.renderingPhysics = true
				end

				for i=1, stepCount do
					updatePhysicsTail(physicsTail, stepCount == i, interpolationAlpha)
				end
			end

			tailsUpdated += 1
		end
	end
end)

local function validateParameter(got:any, expect:string|{string}, optional:boolean?)
	if got == nil and optional then return end
	local parameterType = typeof(got)
	if typeof(expect) == "string" then
		if parameterType ~= expect and not (parameterType == "Instance" and instanceIsA(got, expect)) then
			local gotStr = parameterType == "Instance" and got.ClassName or parameterType
			error("TuxPhysicsTails: invalid argument ("..expect..(optional and "?" or "").." expected, got "..gotStr..")", 2)
		end
	else
		local isOnOfExpected = false
		if parameterType == "Instance" then
			for _, expectStr in expect do
				if instanceIsA(got, expectStr) then
					isOnOfExpected = true
					break
				end
			end
		else
			for _, expectStr in expect do
				if parameterType == expectStr then
					isOnOfExpected = true
					break
				end
			end
		end

		if not isOnOfExpected then
			local gotStr = parameterType == "Instance" and got.ClassName
			error("TuxPhysicsTails: invalid argument ("..tableConcat(expect, "|")..(optional and "?" or "").." expected, got "..gotStr..")", 2)
		end
	end
end
