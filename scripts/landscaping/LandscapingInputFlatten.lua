---@class LandscapingInputFlatten : LandscapingInput
---@field targetY number
LandscapingInputFlatten = {}

local LandscapingInputFlatten_mt = Class(LandscapingInputFlatten, LandscapingInput)

---@param workArea MachineWorkArea
---@param targetY number
---@return LandscapingInputFlatten
---@nodiscard
function LandscapingInputFlatten.new(workArea, targetY)
    local self = LandscapingInput.new(LandscapingOperation.FLATTEN, workArea, LandscapingInputFlatten_mt)
    ---@cast self LandscapingInputFlatten

    self.targetY = targetY
    self.heightChangeAmount = 0.75

    self:checkMapResources()

    return self
end

function LandscapingInputFlatten:apply()
    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()

    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.areaNodePosition) do
            if self.state.forceNodes or self.workArea.areaNodeActive[node] then
                if self.state.allowGradingUp or self.workArea.areaNodeTerrainY[node] >= self.targetY then
                    deformation:addSoftCircleBrush(position[1], position[3], self.radius, self.hardness, self.strength, -1)
                    MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], self.radius)
                end

                MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)

                if paintDeformation ~= nil then
                    paintDeformation:addSoftCircleBrush(position[1], position[3], paintRadius, 0.2, 0.5, self.terrainLayerId)
                end
            end
        end
    else
        for node, position in pairs(self.workArea.areaNodePosition) do
            if self.state.forceNodes or self.workArea.areaNodeActive[node] then
                if self.state.allowGradingUp or self.workArea.areaNodeTerrainY[node] >= self.targetY then
                    deformation:addSoftSquareBrush(position[1], position[3], self.radius * 2, self.hardness, self.strength, -1)
                    MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], self.radius * 2)
                end

                MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)

                if paintDeformation ~= nil then
                    paintDeformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, 0.2, 0.5, self.terrainLayerId)
                end
            end
        end
    end

    if #self.modifiedAreas == 0 then
        deformation:cancel()
        return
    end

    deformation:setOutsideAreaConstraints(0, math.rad(75), math.rad(75))
    deformation:setBlockedAreaMaxDisplacement(0.01)
    deformation:setDynamicObjectCollisionMask(0)
    deformation:setDynamicObjectMaxDisplacement(0.01)

    deformation:apply(false, 'onDeformationCallback', self)
end

---@return TerrainDeformation
---@nodiscard
function LandscapingInputFlatten:createTerrainDeformation()
    self.deformation = TerrainDeformation.new(g_terrainNode)

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:setHeightTarget(self.targetY, self.targetY, 0, 1, 0, -self.targetY)
    self.deformation:enableSetDeformationMode()

    return self.deformation
end
