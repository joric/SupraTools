-- https://github.com/joric/supraworld/wiki/Modding

-- experimental, doesn't really stop in-game sequences, only removes them

local function removeCutscenes()
    for _, obj in ipairs(FindAllOf("SupraworldCutScene_C") or {}) do
        if obj and obj:IsValid() then
            print("--- disabling cutscene ---", obj:GetFullName())
            -- obj:SetActorEnableCollision(false) -- does not work, need NPC manager
            obj:K2_DestroyActor() -- this works
        end
    end
end

local function skipCutscene()

    removeCutscenes()

    for _, obj in ipairs(FindAllOf("LevelSequencePlayer") or {}) do
        if obj:IsValid() then
            print("--- player ---", obj:GetFullName(), obj:GetFrameDuration(), obj:IsPlaying() )
            obj:Stop()
        end
    end

    for _, obj in ipairs(FindAllOf("SupraCutScene_C") or {}) do
        if obj:IsValid() then
            print("--- cutscene ---", obj:GetFullName(), obj.isCurrentlyPlaying)
            -- obj:EndCutscene() -- can't do that, does not return camera control
        end
    end

    local obj = FindFirstOf("SupraCutSceneManager")
    if obj and obj:IsValid() then
        print("--- cutscene manager---", obj:GetFullName())
        local param = {}
        obj:EndCutscene(param); -- that doesn't seem to work
    end

end

-- RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    -- removeCutscenes() -- may be side effects, so disabled
-- end)

RegisterKeyBind(Key.P, skipCutscene)
