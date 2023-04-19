print("Hello!")
bunnyhopTable = {}
function plusbunnyhop()
    bunnyhopTable[Convars:GetCommandClient()] = 1
end
function minusbunnyhop()
    bunnyhopTable[Convars:GetCommandClient()] = nil
end
Convars:RegisterCommand("+bunnyhop", plusbunnyhop, "", FCVAR_CHEAT)
Convars:RegisterCommand("-bunnyhop", minusbunnyhop, "", FCVAR_CHEAT)
function think()
    for k, _ in pairs(bunnyhopTable) do
        if k:GetGraphParameter("Is On Ground") then 
            k:ApplyAbsVelocityImpulse(Vector(0,0,300))
        end
    end
    return FrameTime()
end
Entities:FindByClassname(nil, "worldent"):SetContextThink("thinker", think, 0)