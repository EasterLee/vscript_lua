--Util function
function cloneFilterFunction(tbl)
	local tClone = {}
	for k, v in pairs(tbl) do
		if type(v) ~= 'Function' then
			tClone[k] = v
		end
	end
	return tClone
end


CGrenadeProjectile = {
	flSpeed = 0,
	vecDir = Vector(0,0,0),
	flGravity = 0,
	flFriction = 0,
	SetSpeed = function(self, flSpeed)
		self.speed = flSpeed
		self:SetVelocity(flSpeed * vecDir)
	end
}
--Allowing holders of this metatable to use function from CGrenadeProjectile and its parent
CGrenadeProjectile.mt = {
	__index = CGrenadeProjectile,
}
--Allowing CGrenadeProjectile to inherit functions from CBaseEntity
local constructor = function(self, iMovetype, iCollisionGroup)
	local hProjectile = SpawnEntityFromTableSynchronous("hegrenade_projectile", {
		movetype = iMovetype,
		collisiongroup = iCollisionGroup
	})
	setmetatable(hProjectile, self.mt)
	return hProjectile
end
local mt = {
	__index = CBaseEntity,
	__call = constructor,
}
setmetatable(CGrenadeProjectile, mt);