CGrenadeProjectile = {
	SetDir = function(self, vecDir)
		local flLength = vecDir.x * vecDir.x + vecDir.y * vecDir.y + vecDir.z * vecDir.z;
		-- Normalize vector if length is not close to 1
		if flLength <= 0.95 or flLength >= 1.05 then
			vecDir = vecDir:Normalized()
		end
		flLength = self:GetVelocity():Length()
		self:SetVelocity(vecDir * flLength);
	end,
	SetSpeed = function(self, flSpeed)
		self:SetVelocity(self:GetVelocity():Normalized() * flSpeed);
	end,
	AddSpeed = function(self, flSpeed)
		self:ApplyAbsVelocityImpulse(self:GetVelocity():Normalized() * flSpeed)
	end,
	GoTo = function(self, vecPos)
		local vecDisplacement = vecPos - self:GetOrigin();
		self:SetVelocity(vecDisplacement:Normalized() * self:GetVelocity():Length())
	end,
	GetFuturePos = function(self, flTime)
		return self:GetOrigin() + self:GetVelocity() * flTime;
	end
}
--Allowing holders of this metatable to use function from CGrenadeProjectile and its parent
local instanceMT = {
	__index = CGrenadeProjectile,
}
--Allowing CGrenadeProjectile to inherit functions from CBaseEntity
local constructor = function(vecOrigin, iMoveType, iCollisiongroup)
	local hProjectile = SpawnEntityFromTableSynchronous("hegrenade_projectile", {
		origin = vecOrigin,
		movetype = iMoveType,
		collisiongroup = iCollisiongroup,
	})
	setmetatable(hProjectile, instanceMT)
	return hProjectile
end
local classMT = {
	__index = CBaseEntity,
	__call = constructor,
}
setmetatable(CGrenadeProjectile, classMT);