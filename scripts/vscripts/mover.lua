Mover = {};
function VectorLengthSqr(vec)
	return vec.x * vec.x + vec.y * vec.y + vec.z * vec.z
end
function VectorClone(vec)
	return Vector(vec.x, vec.y, vec.z)
end
Mover.Projectile = {
	constructor = function(vecOrigin, iMoveType, iCollisiongroup)
		local hEnt = SpawnEntityFromTableSynchronous("hegrenade_projectile", {
			origin = vecOrigin,
			movetype = iMoveType,
			collisiongroup = iCollisiongroup,
		})
		return hEnt
	end,
	SetDir = function(self, vecDir)
		local flLength = VectorLengthSqr(vecDir);
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
BezierCurveCubic = class(
	{
		constructor = function(self, vecStart, vecCtrl1, vecCtrl2, vecEnd)
			self.vecStart = vecStart
			self.vecCtrl1 = vecCtrl1
			self.vecCtrl2 = vecCtrl2
			self.vecEnd = vecEnd
		end,
		F = function(self, flTime) --return a point at t of the curve
			local t1 = 1-flTime
			local v1 = self.vecStart * t1 * t1 * t1
			local v2 = self.vecCtrl1 * 3 * flTime * t1 * t1
			local v3 = self.vecCtrl2 * 3 * t1 * flTime * flTime
			local v4 = self.vecEnd * flTime * flTime * flTime
			return v1 + v2 + v3 + v4
		end,
		D1 = function(self, flTime) --return first derivative
			local t1 = 1-flTime
			local v1 = (self.vecCtrl1 - self.vecStart) * 3 * t1 * t1
			local v2 = (self.vecCtrl2 - self.vecCtrl1) * 6 * t1 * flTime
			local v3 = (self.vecEnd - self.vecCtrl2) * 3 * flTime * flTime
			return v1 + v2 + v3
		end,
		GetLength = function(self, iSteps)
			local flInv = 1.0/iSteps
			local flLength = 0
			for i = 1, iSteps do
				local vec1 = self:F(i * flInv)
				local vec2 = self:F((i + 1) * flInv)
				flLength = flLength + (p2 - p1):Length()
			end
			return flLength
		end,
		Draw = function(self, iSteps, vecColor, bNoDepth, flDuration)
			local flInv = 1.0/steps
			for i = 1, iSteps do
				local vec1 = self:F(i * flInv)
				local vec2 = self:F((i + 1) * flInv)
				DebugDrawLine(vec1, vec2, vecColor.x, vecColor.y, vecColor.z, bNoDepth, flDuration)
			end
		end,
		-- Return the time of the cloest point
		getClosestPoint = function(self, vecPoint, iSlices, iIterations) 
			return self:_getClosestPoint(iIterations, vecPoint, 0.0, 1.0, iSlices);
		end,
		_getClosestPoint = function(iIterations, vecPoint, flStart, flEnd, iSlices) 
			if iIterations <= 0 then
				return (flStart + flEnd) / 2
			end
			local flTick = (flEnd - flStart) / iSlices;
			local flBest = 0
			local flBestDistance = 99999
			local flTime = start
			while (flTime <= flEnd) do
				local flCurrentDistance = VectorLengthSqr(self:F(t) - vecPoint)
				if flCurrentDistance < flBestDistance then
					flBestDistance = flCurrentDistance
					flBest = flTime
				end
				flTime = flTime + flTick
			end
			return self:_getClosestPoint(iIterations - 1, vecPoint,  math.max(best - tick, 0), math.min(best + tick, 1), iSlices);
		end,
		-- Divide into two curves
		Half = function(self)
			local a1 = (self.vecStart + self.vecCtrl1) * 0.5
			local a2 = (self.vecCtrl1 + self.vecCtrl2) * 0.5
			local a3 = (self.vecCtrl2 + self.vecEnd) * 0.5
			
			local b1 = (a1 + a2) * 0.5
			local b2 = (a2 + a3) * 0.5
			local c1 = (b1 + b2) * 0.5
			return {getclass(self)(VectorClone(self.vecStart), a1, b1, VectorClone(c1)), getclass(self)(VectorClone(c1), b2, a3, VectorClone(self.vecEnd))};
		end,
		--return all the control points as an array
		GetPoints = function(self)
			return {self.vecStart, self.vecCtrl1, self.vecCtrl2, self.vecEnd};
		end,
		GetCenter = function(self)
			return (self.vecStart + self.vecCtrl1 + self.vecCtrl2 + self.vecEnd) * 0.25
		end,
	},
	nil,
	nil
)