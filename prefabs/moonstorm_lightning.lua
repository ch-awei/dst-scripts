local assets =
{
    Asset("ANIM", "anim/moonstorm_lightningstrike.zip"),
}

local LIGHTNING_MAX_DIST_SQ = 140*140

local function PlayThunderSound(lighting)
	if not lighting:IsValid() or TheFocalPoint == nil then
		return
	end

    local pos = Vector3(lighting.Transform:GetWorldPosition())
    local pos0 = Vector3(TheFocalPoint.Transform:GetWorldPosition())
   	local diff = pos - pos0
    local distsq = diff:LengthSq()

	local k = math.max(0, math.min(1, distsq / LIGHTNING_MAX_DIST_SQ))
	local intensity = math.min(1, k * 1.1 * (k - 2) + 1.1)
	if intensity <= 0 then
		return
	end

    local minsounddist = 10
    local normpos = pos
   	if distsq > minsounddist * minsounddist then
       	--Sound needs to be played closer to us if lightning is too far from player
        local normdiff = diff * (minsounddist / math.sqrt(distsq))
   	    normpos = pos0 + normdiff
    end

    local inst = CreateEntity()

    --[[Non-networked entity]]

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetPosition(normpos:Get())
    inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_close", nil, intensity, true)

    inst:Remove()
end

local function StartFX(inst)
	for i, v in ipairs(AllPlayers) do
		local distSq = v:GetDistanceSqToInst(inst)
		local k = math.max(0, math.min(1, distSq / LIGHTNING_MAX_DIST_SQ))
		local intensity = -(k-1)*(k-1)*(k-1)				--k * 0.8 * (k - 2) + 0.8

		--print("StartFX", k, intensity)
		if intensity > 0 then
			v:ScreenFlash(intensity <= 0.05 and 0.05 or intensity)
			v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, intensity / 3)
		end
	end
end
local MUST_TAGS = {"moonstorm_glass"}
local function spawnglass(inst)

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 4, MUST_TAGS)        

    if #ents > 0 then
        local nx,ny,nz = ents[1].Transform:GetWorldPosition()
        local new = SpawnPrefab("moonglass_charged")
        ents[1].components.lootdropper:FlingItem(new)       
    else
        local glass = SpawnPrefab("moonstorm_glass")
        glass.spawnin(glass)
        glass.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetBank("Moonstorm_LightningStrike")
    inst.AnimState:SetBuild("moonstorm_lightningstrike")
    inst.AnimState:PlayAnimation("strike")
    inst.scrapbook_anim = "strike"

    inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_close", nil, nil, true)

    inst:AddTag("FX")

    --Dedicated server does not need to spawn the local sfx
    if not TheNet:IsDedicated() then
		inst:DoTaskInTime(0, PlayThunderSound)
	end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:DoTaskInTime(0, StartFX) -- so we can use the position to affect the screen flash

    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst:DoTaskInTime(.5, inst.Remove)

    inst:DoTaskInTime(0,function() spawnglass(inst) end)

    return inst
end

return Prefab("moonstorm_lightning", fn, assets)