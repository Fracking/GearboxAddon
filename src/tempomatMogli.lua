--***************************************************************
--
-- tempomatMogli
-- 
-- version 1.92 by mogli (biedens)
-- 2015/03/16
--
--***************************************************************

local tempomatMogliVersion=1.701

-- allow modders to include this source file together with mogliBase.lua in their mods
if tempomatMogli == nil or tempomatMogli.version == nil or tempomatMogli.version < tempomatMogliVersion then
--***************************************************************
	--mogliBase20.newClass( "tempomatMogli", "tempomatMogli" )
	if _G[g_currentModName..".mogliBase"] == nil then
		source(Utils.getFilename("mogliBase.lua", g_currentModDirectory))
	end
	_G[g_currentModName..".mogliBase"].newClass( "tempomatMogli", "tempomatMogliV17" )
--***************************************************************
	
	tempomatMogli.version = tempomatMogliVersion
	local l_currentModName = g_currentModName
	
	--**********************************************************************************************************	
	-- tempomatMogli:load
	--**********************************************************************************************************	
	function tempomatMogli:load(xmlFile) 
		-- state
		self.tempomatMogliV17 = {}
		
		self.tempomatMogliV17.baseSpeed1 = 50
		self.tempomatMogliV17.baseSpeed2 = 10
		self.tempomatMogliV17.baseSpeed3 = 30
		
		if self.motor ~= nil and self.motor.maxForwardSpeed ~= nil then
			self.tempomatMogliV17.baseSpeed1 = math.floor( self.motor.maxForwardSpeed * 3.6 + 0.5 )
			if     self.tempomatMogliV17.baseSpeed1 < 20 then
				self.tempomatMogliV17.baseSpeed2 = math.floor( self.motor.maxForwardSpeed * 1.25 + 0.5 )
				self.tempomatMogliV17.baseSpeed3 = math.floor( self.motor.maxForwardSpeed * 1.80 + 0.5 )
			elseif self.tempomatMogliV17.baseSpeed1 < 30 then
				self.tempomatMogliV17.baseSpeed3 = 20
			end
		end
		
		tempomatMogli.registerState( self, "SpeedLimit2", self.tempomatMogliV17.baseSpeed2 )
		tempomatMogli.registerState( self, "SpeedLimit3", self.tempomatMogliV17.baseSpeed3 )
		tempomatMogli.registerState( self, "KeepSpeed",   false )
		tempomatMogli.registerState( self, "SpeedLimit",  -1 )
		self.tempomatMogliV17.modName = l_currentModName
		
		self.tempomatMogliSetSpeedLimit  = tempomatMogli.tempomatMogliSetSpeedLimit 
		self.tempomatMogliGetSpeedLimit  = tempomatMogli.tempomatMogliGetSpeedLimit 
		self.tempomatMogliGetSpeedLimit2 = tempomatMogli.tempomatMogliGetSpeedLimit2
		self.tempomatMogliGetSpeedLimit3 = tempomatMogli.tempomatMogliGetSpeedLimit3
		self.tempomatMogliSwapSpeedLimit = tempomatMogli.tempomatMogliSwapSpeedLimit 
	end	
	
	--**********************************************************************************************************	
	-- tempomatMogli:update
	--**********************************************************************************************************	
	function tempomatMogli:update(dt)
		
	-- inputs	
		if self:getIsActiveForInput(false) then		
			if     tempomatMogli.mbHasInputEvent( "gearboxMogliCONFLICT_1" )
					or tempomatMogli.mbHasInputEvent( "gearboxMogliCONFLICT_2" )
					or tempomatMogli.mbHasInputEvent( "gearboxMogliCONFLICT_3" )
					or tempomatMogli.mbHasInputEvent( "gearboxMogliCONFLICT_4" ) then
				-- ignore
			elseif tempomatMogli.mbHasInputEvent( "gearboxMogliSETSPEED" ) then -- speed limiter
				self:tempomatMogliSetSpeedLimit()
			elseif tempomatMogli.mbHasInputEvent( "gearboxMogliSWAPSPEED" ) then -- speed limiter
				self:tempomatMogliSwapSpeedLimit()
			end			
			tempomatMogli.mbSetState( self, "KeepSpeed", tempomatMogli.mbIsInputPressed( "gearboxMogliKEEPSPEED" ) )		
		else
			tempomatMogli.mbSetState( self, "KeepSpeed", false )		
		end
		
		if self.isServer and self.cruiseControl ~= nil then
			if self.movingDirection <= 0 and ( self.mrGbMS == nil or not ( self.mrGbMS.IsOn ) ) then
				self.tempomatMogliV17.keepSpeedLimit = nil		
			elseif self.tempomatMogliV17.KeepSpeed then
				if     self.tempomatMogliV17.keepSpeedLimit == nil then
					self.tempomatMogliV17.lastAxisFoward = 0
					self.tempomatMogliV17.keepSpeedLimit = math.max( self.lastSpeedReal*3600, tempomatMogli.getMinSpeed( self, true ) )
				end
			elseif self.tempomatMogliV17.keepSpeedLimit ~= nil then
				self.tempomatMogliV17.keepSpeedLimit = nil		
			end
			
			if self.tempomatMogliV17.keepSpeedLimit ~= nil then
				local s = math.floor( self.tempomatMogliV17.keepSpeedLimit + 0.5 )
				tempomatMogli.mbSetState( self, "SpeedLimit", s )		
			end
		else
			self.tempomatMogliV17.keepSpeedLimit = nil		
		end
		
		if self.tempomatMogliV17.KeepSpeed then
			if self.tempomatMogliV17.cruiseControlState == nil then
				self.tempomatMogliV17.cruiseControlSpeed = self.cruiseControl.speed
				self.tempomatMogliV17.cruiseControlState = self.cruiseControl.state
			end
			
			if self.tempomatMogliV17.SpeedLimit > 0 then
				self.cruiseControl.speed = self.tempomatMogliV17.SpeedLimit
				self.cruiseControl.state = Drivable.CRUISECONTROL_STATE_ACTIVE
			else
				self.cruiseControl.state = Drivable.CRUISECONTROL_STATE_OFF 
			end			
		elseif self.tempomatMogliV17.cruiseControlState ~= nil then
			self.cruiseControl.speed = self.tempomatMogliV17.cruiseControlSpeed
			self.cruiseControl.state = self.tempomatMogliV17.cruiseControlState
			if self.cruiseControlHud ~= nil and self.tempomatMogliV17.SpeedLimit > 0 then
				VehicleHudUtils.setHudValue(self, self.cruiseControlHud, self.cruiseControl.speed, 9999);
			end
			
			self.tempomatMogliV17.cruiseControlSpeed = nil
			self.tempomatMogliV17.cruiseControlState = nil
		end
	end
	
	--**********************************************************************************************************	
	-- tempomatMogli:getMinSpeed
	--**********************************************************************************************************	
	function tempomatMogli:getMinSpeed( inKmH )
		local minSpeed = 2
		
		if      type( self.mrGbMS )            == "table"
				and type( self.mrGbMGetGearSpeed ) == "function"
				and type( self.mrGbMGetAutomatic ) == "function"
				and not ( self.mrGbMS.Hydrostatic ) 
				and not ( self:mrGbMGetAutomatic( ) )
				and self.mrGbMS.IdleRpm	 ~= nil
				and self.mrGbMS.RatedRpm ~= nil then
			minSpeed = math.max( minSpeed, self:mrGbMGetGearSpeed() ) * self.mrGbMS.IdleRpm	/ self.mrGbMS.RatedRpm
		end
		
		if not ( inKmH ) then
			minSpeed = minSpeed / 3.6
		end
		
		return minSpeed 
	end
	
	--**********************************************************************************************************	
	-- tempomatMogli:getMaxSpeed
	--**********************************************************************************************************	
	function tempomatMogli:getMaxSpeed( inKmH )
		if self.motor == nil then
			return math.huge
		end
	
		local isRev    = false
		
		if      self.mrGbMS ~= nil
				and self.mrGbMS.IsOn then
			isRev = self.mrGbMS.ReverseActive
			if self.isReverseDriving then isRev = not ( isRev ) end
		elseif  g_currentMission.driveControl ~= nil
				and g_currentMission.driveControl.useModules ~= nil
				and g_currentMission.driveControl.useModules.shuttle 
				and self.driveControl ~= nil 
				and self.driveControl.shuttle ~= nil 
				and self.driveControl.shuttle.direction ~= nil 
				and self.driveControl.shuttle.isActive then
			if self.driveControl.shuttle.direction < 0 then
				isRev = true
			end
		else
			if self.movingDirection < 0 then
				isRev = true
			end
		end
		
		local maxSpeed = self.motor.maxForwardSpeed
		if iRev then
			maxSpeed = self.motor.maxBackwardSpeed 
		end		
		maxSpeed = maxSpeed + 0.0833333333333333333333333333333
		if inKmH then
			maxSpeed = maxSpeed * 3.6
		end
		
		return maxSpeed 
	end
	
	--**********************************************************************************************************	
	-- tempomatMogli:newUpdateVehiclePhysics
	--**********************************************************************************************************	
	function tempomatMogli:newUpdateVehiclePhysics( superFunc, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, doHandbrake, dt, ... )
		if     self.tempomatMogliV17                == nil 
				or self.tempomatMogliV17.keepSpeedLimit == nil
				or self.tempomatMogliV17.modName        == nil
				or self.tempomatMogliV17.modName        ~= l_currentModName then
			return superFunc( self, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, doHandbrake, dt, ... )
		end
		
		if type( self.mrGbMSetNeutralActive ) == "function" then
			self:mrGbMSetNeutralActive( false )
		end
		
		local currentSpeed  = self.lastSpeedReal*3600
		local inAxisForward = axisForward
		if     axisForward <= -0.2 then
		-- accelerate by 0.5..2 m/s^2
			local acc = 2 - math.min( 1.5, currentSpeed * 0.05 )
		
			if self.tempomatMogliV17.keepSpeedLimit < currentSpeed + 2 then
			--self.tempomatMogliV17.keepSpeedLimit = math.min( math.max( currentSpeed, self.tempomatMogliV17.keepSpeedLimit ) - axisForward * dt * 0.0036, tempomatMogli.getMaxSpeed( self, true ) )
				self.tempomatMogliV17.keepSpeedLimit = math.max( currentSpeed, self.tempomatMogliV17.keepSpeedLimit ) - axisForward * dt * 0.0036 * acc 
			end
		elseif axisForward >= 0.2 then	
		-- decelerate by 2..4 m/s^2 
			local acc = Utils.clamp( currentSpeed * 0.05, 2, 4 )
			
			if self.tempomatMogliV17.keepSpeedLimit > currentSpeed - 2 then
				self.tempomatMogliV17.keepSpeedLimit = math.max( math.min( currentSpeed, self.tempomatMogliV17.keepSpeedLimit ) - axisForward * dt * 0.0072 * acc, 1 )
			end
		end

		local temp1 = self.motor.speedLimit 
		
		self.motor.speedLimit = math.min( temp1, self.tempomatMogliV17.keepSpeedLimit )
		superFunc( self, -1, false, axisSide, axisSideIsAnalog, doHandbrake, dt, ... )
		self.motor.speedLimit    = temp1
	end
	
	function tempomatMogli:newDrivableOnLeave( superFunc )
		local oldFunc
		
		if not ( self.deactivateOnLeave ) and self.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
			oldFunc = self.setCruiseControlState
			self.setCruiseControlState = function (self, state, noEventSend) end
		end
		
		superFunc( self )
		
		if oldFunc ~= nil then
			self.setCruiseControlState = oldFunc
		end
	end
	
	Drivable.updateVehiclePhysics = Utils.overwrittenFunction( Drivable.updateVehiclePhysics, tempomatMogli.newUpdateVehiclePhysics )
	Drivable.onLeave              = Utils.overwrittenFunction( Drivable.onLeave,              tempomatMogli.newDrivableOnLeave )  
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSetSpeedLimit
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliSetSpeedLimit( noEventSend )
		self:setCruiseControlMaxSpeed(math.floor( self.lastSpeedReal*3600 + 0.5 ))
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSetSpeedLimit
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliGetSpeedLimit( )
		if self.tempomatMogliV17.lastSpeedLimit ~= nil then
			return self.tempomatMogliV17.lastSpeedLimit
		end
		return self.cruiseControl.speed
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSetSpeedLimit2
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliGetSpeedLimit2( )
		return self.tempomatMogliV17.SpeedLimit2
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSetSpeedLimit2
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliGetSpeedLimit3( )
		return self.tempomatMogliV17.SpeedLimit3
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSwapSpeedLimit
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliSwapSpeedLimit( noEventSend )
		local speed1 = self:tempomatMogliGetSpeedLimit2()
		local speed2 = self:tempomatMogliGetSpeedLimit3()
		local speed3 = self:tempomatMogliGetSpeedLimit()
		self:setCruiseControlMaxSpeed(speed1)
		tempomatMogli.mbSetState( self, "SpeedLimit2", speed2, noEventSend ) 		
		tempomatMogli.mbSetState( self, "SpeedLimit3", speed3, noEventSend ) 		
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:getSaveAttributesAndNodes
	--**********************************************************************************************************	
	function tempomatMogli:getSaveAttributesAndNodes(nodeIdent)
	
		local attributes = ""
	
		if self.tempomatMogliV17 ~= nil then
			if math.abs( self.tempomatMogliV17.SpeedLimit2 - self.tempomatMogliV17.baseSpeed2 ) < 1 then
				attributes = attributes.." mrGbMSpeed2=\"" .. tostring( self.tempomatMogliV17.SpeedLimit2 ) .. "\""     
			end
			if math.abs( self.tempomatMogliV17.SpeedLimit3 - self.tempomatMogliV17.baseSpeed3 ) < 1 then
				attributes = attributes.." mrGbMSpeed3=\"" .. tostring( self.tempomatMogliV17.SpeedLimit3 ) .. "\""     
			end
		end 
		
		return attributes
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:loadFromAttributesAndNodes
	--**********************************************************************************************************	
	function tempomatMogli:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
		local i
		
		if self.tempomatMogliV17 ~= nil then
			i = getXMLInt(xmlFile, key .. "#mrGbMSpeed2" )
			if i ~= nil then
				self.tempomatMogliV17.SpeedLimit2 = i
			end
			i = getXMLInt(xmlFile, key .. "#mrGbMSpeed3" )
			if i ~= nil then
				self.tempomatMogliV17.SpeedLimit3 = i
			end
		end
		
		if self.tempomatMogliV17.baseSpeed1 ~= nil then
			if     math.abs( self.cruiseControl.speed - self.tempomatMogliV17.baseSpeed2 ) < 1 then
				self.tempomatMogliV17.SpeedLimit2 = self.tempomatMogliV17.SpeedLimit3
				self.tempomatMogliV17.SpeedLimit3 = self.tempomatMogliV17.baseSpeed1
			elseif math.abs( self.cruiseControl.speed - self.tempomatMogliV17.baseSpeed3 ) < 1 then
				self.tempomatMogliV17.SpeedLimit3 = self.tempomatMogliV17.SpeedLimit2
				self.tempomatMogliV17.SpeedLimit2 = self.tempomatMogliV17.baseSpeed1
			end
		end
		
		return BaseMission.VEHICLE_LOAD_OK
	end 

end