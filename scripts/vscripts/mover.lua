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

Mover.Path = {
	loop = false;
	nodes = null;
	constructor(){
		nodes = [];
	}
	function pos(t){
		t = clampToPathSize(t);
		local idx = floor(t);
		t = t - idx;
		return nodes[idx].pos(t);
	}
	function draw(step, color, duration){
		foreach(node in nodes){
			node.draw(step, color, duration);
		}
	}
	function getSegmentSpeed(t){
		local idx = floorToPathSize(t);
		return nodes[idx].speed;
	}
	function getSegmentLength(t){
		local idx = floorToPathSize(t);
		return nodes[idx].curve.getLength();
	}
	function insert(idx, curv){		
		//if last
		if(idx == nodes.len() - 1){
			push(curv);
			return;
		}
		local node = Node(curv);
		nodes.insert(idx, node);
		
		nodes[idx + 1].setStart(node.getEnd());
		
		//if not first
		if(idx != 0){
			nodes[idx - 1].setEnd(node.getStart());
		}
	}
	function push(curv){
		local node = Node(curv);
		nodes.push(node);
		
		//if first
		if(nodes.len() == 1){
			return;
		}
		
		//second last node
		nodes[nodes.len() - 2].setEnd(node.getStart());
	}
	function clampToPathSize(t){
		return clamp(t, 0, nodes.len() - 0.001);
	}
	function floorToPathSize(t){
		return floor(clampToPathSize(t));
	}
	function size(){
		return nodes.len();
	}
}
Mover.Train <-  class extends Mover.Projectile{
	forward = true;
	stopped = true;
	
	path = null;
	currentSegment = 0;
	
	dest = null;
	
	t = null;
	dt = null;
	constructor(origin, speed = 0){
		Mover.Projectile.constructor(origin, Vector(0, 0, 0), speed);
		ent.GetScriptScope().think <- think.bindenv(this);
	}
	function setPath(p){
		path = p;
	}
	function teleportToTime(t){
		t = t;
		onArrival(t);
		ent.SetOrigin(path.pos(t));
	}
	function teleportToPathStart(){
		teleportToTime(0);
	}
	function teleportToPathEnd(){
		teleportToTime(path.size());
	}
	function computeDt(){ // compute dt
		//number of equal segments with length speed;
		local segments = path.getSegmentLength(t) / (speed * FrameTime()); 
		
		dt = 1.0/segments;
		dt = clamp(dt, 0.001, 1);
		dt *= forward ? 1 : -1; //set dt to negative if going backward
	}
	function startForward(){
		stopped = false;
		if(forward){
			return;
		}
		forward = true;
		dt *= -1;
	}
	function startBackward(){
		stopped = false;
		if(forward){
			return;
		}
		forward = false;
		dt *= -1;
	}
	function stop(){
		stopped = true;
		ent.SetVelocity(Vector(0,0,0));
	}
	function onArrival(t){
		local newSpeed = path.getSegmentSpeed(t);
		
		//update if newSpeed isn't null
		speed = newSpeed != null ? newSpeed : speed;
		
		//compute dt
		computeDt();
	}
	function think(){
		if(stopped || path == null){
			return FrameTime();
		}
		
		local unitPerTick = speed*FrameTime();
		dest = path.pos(t); //get next point on the curve/line
		if((ent.GetOrigin() - dest).LengthSqr() < (unitPerTick * unitPerTick)){ //if self would surpass destination within the next frame
			local pT = t;
			t += dt
			//update destination
			if(floor(pT) != floor(t)){ // end of segment
				if(t < path.size()){ //continue to next path
					onArrival(t);
				}else{ //no more path
					if(path.loop){
						teleportToTime(0);
					}
					stop();
					teleportToTime(t);
					return FrameTime();
				}
			}
			//Warning: will loop endlessly if dt is 0 as t never 
			think(); //double checking if the distance between origin and new destination is enough 
			return FrameTime(); 
		}
		goTo(dest);
		return FrameTime();
	}
};

Mover.PathBuilder <- {
	distSqr = null,
	lastPos = null,
	path = null,
	owner = null,
	function start(dist = null){ //distance between each pathnode
		this.distSqr = dist*dist;
		owner = activator;
		lastPos = owner.EyePosition();
		path = Mover.Path(); 
		return path;
	}
	function add(){ //manually add pathnode
		local origin = owner.EyePosition();
		local line = VectorManipulation.Line(lastPos, origin);
		local b = BCC(lastPos, line.interpolate(0.25), line.interpolate(0.75), origin);
		path.push(b);
		lastPos = origin;
	}
	function end(){
		distSqr = null;
		owner = null;
		path = null;
	}
	function think(duration){
		if(owner == null){
			return;
		}
		DebugDrawLine(lastPos, owner.EyePosition(), 0, 255, 0, true, duration);
		if(distSqr == null){
			return;
		}
		if((owner.EyePosition() - lastPos).LengthSqr() >= distSqr){
			add();
		}
	}
	function save(path){
		local toVector = function(vec){
			return "" + floor(vec.x) + "," + floor(vec.y) + "," + floor(vec.z) + "";
		}
		print("[" + toVector(path.nodes[0].curve.cp[0]));
		for(local i = 0; i < path.size(); i++){
			print("," + toVector(node.curve.cp[1]));
			print("," + toVector(node.curve.cp[2]));
			print("," + toVector(node.curve.cp[3]));
		}
		printl("]");
	}
	function load(arr){
		Assert(arr.len() > 3, "input array length <= 4");
		local path = Mover.Path();
		path.push(BCC(Vector(arr[0], arr[1], arr[2]), Vector(arr[3], arr[4], arr[5]), Vector(arr[6], arr[7], arr[8]), Vector(arr[9], arr[10], arr[11])));
		for(local i = 9; i < arr.len() - 9; i += 9){
			path.push(BCC(Vector(arr[i], arr[i+1], arr[i+2]), Vector(arr[i+3], arr[i+4], arr[i+5]), Vector(arr[i+6], arr[i+7], arr[i+8]), Vector(arr[i+9], arr[i+10], arr[i+11])));
		}
		//if path end == path start
		if(arr[0] == arr[arr.len()-3] && arr[1] == arr[arr.len()-2] && arr[2] == arr[arr.len()-1]){
			path.loop = true;
		}
		return path;
	}
}
Mover.Glider <- class extends Mover.Projectile{
		owner = null; //player handle
		maxSpeed = 1000; //number
		drag = 0.999;
		constructor(owner){
			Mover.Projectile.constructor(owner.GetOrigin(), owner.GetForwardVector(), owner.GetVelocity().Length());
			this.owner = owner;
			owner.__KeyValueFromInt("movetype", 0);
			EntitiesMaker.setParent(owner, ent);
			setCollision(true);
			ent.GetScriptScope().think <- think.bindenv(this);
			local ss = this;
			local localFunction = function():(ss){
				printl("jumped");
				ss.addVelocity(PlayerAngles.eyeFV(ss.owner) * 500);
			};
			PlayerControl.Jump.hook(owner, localFunction, -1);
			
		}
		function think():(VectorManipulation){
			local fv = PlayerAngles.eyeFV(owner);
			local up = PlayerAngles.getEye(owner).getUpVector();
			local right = PlayerAngles.getEye(owner).getRightVector();
			local vel = ent.GetVelocity();
			
			// Convert vertical speed to horizontal speed
			local vertVel = VectorManipulation.projectToLine(vel, up);
			local horizontalSpeed = vel.Length2D();
			
			vel -= vertVel;
			
			vel += fv * (vertVel.Length() * FrameTime() / 10);
			
			//side velocity
			local rtVel = (VectorManipulation.projectToLine(vel, right));
			vel -= rtVel;
			
			//change direction at a cost
			vel += fv * (vertVel.Length() * FrameTime() / 10);
			
			//limit max speed
			local forVel = (VectorManipulation.projectToLine(vel, fv)) * 0.001;
			vel -= forVel * FrameTime();
			
			// gravity
			vel.z -= 30;
			
			setVelocity(vel);
			return FrameTime();
		}
		function kill(){
			EntFireByHandle(owner, "ClearParent", "", 0.00, null, null);
			EntFireByHandle(ent, "Kill", "", 0.02, null, null);
		}
};
Mover.initialize <- function(temp, name){
		heTemplateName = temp;
		heName = name;
};

Mover.Movable <- class{
	pos = null; //vector
	response = null;
	detection = null;
	constructor(pos, d = null, r = null){
		this.pos = pos;
		this.detection = d;
		this.response = r;
	}
	function getPos(){
		return pos;
	}
	function setPos(vec){
		local diff = vec - pos;
		offset(diff);
	}
	function _setPos(vec){ //setpos without triggering response
		local diff = vec - pos;
		_offset(diff);
	}
	function _offset(vec){
		pos.x += vec.x;
		pos.y += vec.y;
		pos.z += vec.z;
	}
	function offset(vec){
		pos.x += vec.x;
		pos.y += vec.y;
		pos.z += vec.z;
		if(response){
			response.resolve(this);
		}
	}
}

//return an array of movable
Mover.MakePathMovable <- function(path){
	local pivotCube = CubeDetection(10, 100, Vector(0, 0, 255)); //larger blue cube
	local controlCube = CubeDetection(5, 100, Vector(0, 255, 0)); //smaller green cube
	local lineColor = Vector(255, 255, 255);
	local arr = [];
	
	//first start point
	local inter = path.nodes[1].interpolatable;
	arr.push(Movable(inter.start, PivotDetection(pivotCube, inter.ctrl1, null, lineColor)));
	
	local lastEnd = null;
	local lastCtrl2 = null;
	for(local i = 0; i < path.nodes.size(); i++){
		local inter = path.nodes[i].interpolatable;
		local t2 = Movable(inter.ctrl1, controlCube);
		local t3 = Movable(inter.end);
		local t4 = Movable(inter.ctrl2, controlCube);
		
		if(lastCtrl){
			// last ctrl2 - this start point - this ctrl1
			lastEnd.response = BezierResponse(lastCtrl, lastEnd, t2);
			lastEnd.detection = PivotDetection(pivotCube, lastCtrl2, t2, lineColor);
		}
		lastEnd = t3;
		lastCtrl2 = t4;
		arr.push(t2);
		arr.push(t3);
		arr.push(t4);
	}
	
	//do the same thing to last end point
	lastEnd.d = PivotDetection(pivotCube, null, lastCtrl2, lineColor);
	
	return arr;
}

//keep control points on the same line and mirrored
Mover.BezierResponse <- class{
	t1 = null; //first control point
	t2 = null; //pivot, start or end point
	t3 = null; //second control point
	oldPos = null;
	constructor(t1, t2, t3){
		this.t1 = t1;
		this.t2 = t2;
		this.t3 = t3;
		setOld();
	}
	function resolve(movable){//update the other point
		switch(movable){
			case t1:
				t3._setPos(t2.getPos() - t3.getPos() + t2.getPos());
				break;
			case t2:
				local offset = t2.getPos() - oldPos;
				t1._offset(offset);
				t3._offset(offset);
				setOld();
				break;
			case t3:
				break;
				t1._setPos(t2.getPos() - t3.getPos() + t2.getPos());
		}
	}
	function setOld(){
		local pos = t2.getPos();
		oldPos = Vector(pos.x, pos.y, pos.z);
	}
}

//ways to draw and detect the point
//To be used in combination with movable
Mover.BoxDetection <- class{
	color = null; //else
	alpha = null;
	min = null;
	max = null;
	constructor(min, max, alpha = 100, color = null){
		this.color = color ==  null ? Vector(RandomInt(0, 255), RandomInt(0, 255), RandomInt(0, 255)) : color;
		this.min = min;
		this.max = max;
		this.alpha = alpha;
	}
	function draw(pos, duration){ //draw the point
		draw2(pos, duration, color);
	}
	function draw2(pos, duration, color){//draw the point with custom color
		if(duration <= 0.015625){
			duration = 0;
		}
		DebugDrawBox(pos, min, max, color.x, color.y, color.z, alpha, duration);
	}
	function isLooking(pos, vec0, vec1):(Trace){
		return Trace.rayIntersectionAABB(vec0, vec1, pos, min, max);
	}
}

//same as boxdetection but draw a line between the control points
Mover.PivotDetection <- class{
	box = null;
	pos1 = null;
	pos2 = null;
	lineColor = null;
	constructor(box, pos1, pos2, color){
		this.box = box;
		this.pos1 = pos1;
		this.pos2 = pos2;
		this.lineColor = color;
	}
	function draw(pos, duration){ //draw the lines and box
		drawLine();
		box.draw(pos, duration);
	}
	function draw2(pos, duration, color){
		drawLine();
		box.draw2(pos, duration, color);
	}
	function drawLine(){
		if(pos1 && pos2){
			DebugDrawLine(pos1, pos2, lineColor.x, lineColor.y, lineColor.z, true, duration);
		}else if(pos1){
			DebugDrawLine(pos1, pos, lineColor.x, lineColor.y, lineColor.z, true, duration);
		}else{
			DebugDrawLine(pos2, pos, lineColor.x, lineColor.y, lineColor.z, true, duration);
		}
	}

}

Mover.CubeDetection <- function(size, alpha = 100, color = null){
	local sizehalf = size/2.0;
	return BoxDetection(Vector(-sizehalf, -sizehalf, -sizehalf), Vector(sizehalf, sizehalf, sizehalf), alpha, color);
}

Mover.SimpleMovableCube <- function(vec, size){
	return Movable(vec, CubeDetection(size));
}
Mover.SimpleMovableCube2 <- function(vec, d){
	return Movable(vec, d);
}

Mover.PointMover <- {
	optionPoints = [],
	selectedPoint = [],
	
	selectColor = Vector(0,255,0),
	deselectColor = Vector(255,0,0),
	
	selectAxisColor = Vector(255,255,255),
	
	maxDistance = 5000,
	player = null,
	moving = false,
	planeNorm = null,
	
	duration = FrameTime(),
	
	gridStep = 5,
	gridSize = 500,
	
	axisCenter = Vector(0,0,0),
	axis = {
		x = Mover.BoxDetection(Vector(-30, -2.5, -2.5), Vector(30, 2.5, 2.5), 255, Vector(255,0,0)),
		y = Mover.BoxDetection(Vector(-2.5, -30, -2.5), Vector(2.5, 30, 2.5), 255, Vector(0,255,0)),
		z = Mover.BoxDetection(Vector(-2.5, -2.5, -30), Vector(2.5, 2.5, 30), 255, Vector(0,0,255))
	},
	axisXMin = Vector(-30, -2.5, -2.5),
	axisYMin = Vector(-2.5, -30, -2.5),
	axisZMin = Vector(-2.5, -2.5, -30),
	
	function scaleAxis(scale){
		axisX.min = axisXMin * scale;
		axisY.min = axisYMin * scale;
		axisZ.min = axisZMin * scale;
		
		axisX.max = axisXMin * -scale;
		axisY.max = axisYMin * -scale;
		axisZ.max = axisZMin * -scale;
	}
	function move(arr){
		optionPoints = arr;
	}
	function getPointsOnAim(){
		if(optionPoints.len() == 0 && selectedPoint.len() == 0){
			return null;
		}
		local fv = PlayerAngles.eyeFV(player);
		local eyePos = player.EyePosition();
		
		local tmin = 1;
		local movable = null;
		foreach(v in optionPoints){
			local t = v.detection.isLooking(v.getPos(), eyePos, eyePos + (fv * maxDistance));
			if(!t){
				continue;
			}
			if(tmin > t.tmin){
				tmin = t.tmin;
				movable = v;
			}
		}		
		foreach(v in selectedPoint){
			local t = v.detection.isLooking(v.getPos(), eyePos, eyePos + (fv * maxDistance));
			if(!t){
				continue;
			}
			if(tmin > t.tmin){
				tmin = t.tmin;
				movable = v;
			}
		}
		if(movable){
			return [movable, tmin];
		}
		return null;
	}
	function getPlane(){ //return axis with the shortest distance
		local fv = PlayerAngles.eyeFV(player);
		local eyePos = player.EyePosition();
		local _axis = null;
		local tmin = 1;
		foreach(v in axis){
			local t = v.isLooking(axisCenter, eyePos, eyePos + (fv * maxDistance));
			if(!t){
				continue;
			}
			if(tmin > t.tmin){
				tmin = t.tmin;
				_axis = v;
			}
		}
		if(_axis){
			return [_axis, tmin];
		}
		return null;
	}
	function isAxis(b){
		foreach(k, v in axis){
			if(v == b){
				return k;
			}
		}
		return null;
	}
	function getPointAlongPlane():(Trace, VectorManipulation){
		local fv = PlayerAngles.eyeFV(player);
		local eyePos = player.EyePosition();
		local t = null;
		local dis = eyePos - axisCenter;
		dis[planeNorm] = 0;
		dis.Norm();
		if((t = Trace.rayIntersectionPlane(eyePos, eyePos + fv * maxDistance, axisCenter, dis)) != null){
			return eyePos + fv * (maxDistance * t);
		}
		return null;
	}
	function getSelected(){
		local point = getPointsOnAim();
		local axis = selectedPoint.len() ? getPlane() : null;
		//overlap
		if(point && axis){
			if(point[1]  < axis[1]){
				return point[0];
			}else{
				return axis[0];
			}
		}
		if(point){
			//printl("returning point");
			return point[0];
		}
		if(axis){
			//printl("returning axis");
			return axis[0];
		}
		return null;
	}
	function isSelected(b){
		foreach(v in selectedPoint){
			if(v == b) return true;
		}
		return false;
	}
	function select(b){
		printl("selecting: " + b);
		for(local i = optionPoints.len() - 1; i >= 0; i--){
			if(optionPoints[i] != b){
				continue;
			}
			selectedPoint.push(optionPoints[i]);
			optionPoints[i] = optionPoints.top();
			optionPoints.pop();
			return;
		}
	}
	function deselect(b){
		printl("deselecting: " + b);
		for(local i = selectedPoint.len() - 1; i >= 0; i--){
			if(selectedPoint[i] != b){
				continue;
			}
			optionPoints.push(selectedPoint[i]);
			selectedPoint[i] = selectedPoint.top();
			selectedPoint.pop();
			return;
		}
	}
	function hasPointSelected(){
		return selectedPoint.len() != 0;
	}
	function OnPressedAttack(){
		local selected = getSelected();
		local axis = isAxis(selected);
		if(!axis){
			printl("not axis");
			if(isSelected(selected)){
				printl("is selected");
				deselect(selected);
			}else{
				printl("is not selected");
				select(selected);
			}
			return;
		}
		if(hasPointSelected()){
			printl("moving");
			moving = true;
			planeNorm = axis;
		}
	}
	function OnUnpressedAttack(){
		//ignore if not moving points
		if(!moving){
			return;
		}
		moving = false;
	}
	function draw(){
		local selected = getSelected();
		
		if(moving){
			axis[planeNorm].draw2(axisCenter, duration, selectAxisColor);
		} else if(hasPointSelected()){
			foreach(v in axis){
				if(v == selected){
					v.draw2(axisCenter, duration, selectAxisColor);
					continue;
				}
				v.draw(axisCenter, duration);
			}
		}
		foreach(v in optionPoints){
			if(v == selected){
				v.detection.draw2(v.getPos(), duration, selectColor);
			}
			v.detection.draw(v.getPos(), duration);
		}		
		foreach(v in selectedPoint){
			if(v == selected){
				v.detection.draw2(v.getPos(), duration, deselectColor);
			}
			v.detection.draw2(v.getPos(), duration, selectColor);
		}
	}
	function think(){
		if(moving){
			local vec = getPointAlongPlane();
			
			if(!vec){
				draw();
				return;
			}
			//ignore everything but selected axis
			local old = Vector(axisCenter.x, axisCenter.y, axisCenter.z);
			foreach(k, v in vec){
				if(k != planeNorm){
					continue;
				}
				axisCenter[k] = v;
			}
			//how much the axis has moved
			old = axisCenter - old;
			foreach(v in selectedPoint){
				v.setPos(v.getPos() + old);
			}
		}
		draw();
	}
	function drawPlane(origin, xyz, gridStep, gridSize, duration){ //axis the plane is perpendicular to
		local f = floor(gridSize/(2 * gridStep));
		local lineLengthHalf = f * gridStep;
		local offset = Vector(origin.x - (origin.x % gridStep), origin.y - (origin.y % gridStep), origin.z - (origin.z % gridStep));
		offset[xyz] = origin[xyz];
		for(local i = 0; i < f; i++){
			if(xyz != "x"){
				local vec1 = Vector(i * gridStep,0,0);
				local vec2 = Vector(i * gridStep,0,0);
				if(xyz != "y"){
					vec1.y = lineLengthHalf;
					vec2.y = -lineLengthHalf;
				}
				if(xyz != "z"){
					vec1.z = lineLengthHalf;
					vec2.z = -lineLengthHalf;
				}
				DebugDrawLine(offset + vec1, offset + vec2, 0, 0, 255, true, duration);
				vec1.x *= -1;
				vec2.x *= -1;
				DebugDrawLine(offset + vec1, offset + vec2, 0, 0, 255, true, duration);
				//printl("not x");
			}
			if(xyz != "y"){				
				local vec1 = Vector(0,i * gridStep,0);
				local vec2 = Vector(0,i * gridStep,0);
				if(xyz != "x"){
					vec1.x = lineLengthHalf;
					vec2.x = -lineLengthHalf;
				}
				if(xyz != "z"){
					vec1.z = lineLengthHalf;
					vec2.z = -lineLengthHalf;
				}
				DebugDrawLine(offset + vec1, offset + vec2, 0, 0, 255, true, duration);
				vec1.y *= -1;
				vec2.y *= -1;
				DebugDrawLine(offset + vec1, offset + vec2, 0, 0, 255, true, duration);
				//printl("not y");
			}
			if(xyz != "z"){				
				local vec1 = Vector(0,0,i * gridStep);
				local vec2 = Vector(0,0,i * gridStep);
				if(xyz != "x"){
					vec1.x = lineLengthHalf;
					vec2.x = -lineLengthHalf;
				}
				if(xyz != "y"){
					vec1.y = lineLengthHalf;
					vec2.y = -lineLengthHalf;
				}
				DebugDrawLine(offset + vec1, offset + vec2, 0, 0, 255, true, duration);
				vec1.z *= -1;
				vec2.z *= -1;
				DebugDrawLine(offset + vec1, offset + vec2, 0, 0, 255, true, duration);
				//printl("not z");
			}
		}
	}
	function initialize(ply){
		player = ply;
		PlayerControl.KeyPress.hook("PressedAttack", ply, OnPressedAttack.bindenv(this), -1);
		PlayerControl.KeyPress.hook("UnpressedAttack", ply, OnUnpressedAttack.bindenv(this), -1);
	}
}
