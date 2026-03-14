---@class LandscapingOutput : LandscapingBase
---@field outputLiters number
LandscapingOutput = {}

local LandscapingOutput_mt = Class(LandscapingOutput, LandscapingBase)

---@param operation LandscapingOperation
---@param workArea MachineWorkArea
---@param terrainLayerId? number
---@param customMt table
---@return LandscapingOutput
---@nodiscard
function LandscapingOutput.new(operation, workArea, terrainLayerId, customMt)
    local self = LandscapingBase.new(operation, workArea, nil, customMt)
    ---@cast self LandscapingOutput

    self.radius = self.state.outputRadius
    self.strength = self.state.outputStrength
    self.hardness = self.state.outputHardness
    self.brushShape = self.state.outputBrushShape

    self.terrainLayerId = terrainLayerId or self.vehicle:getMachineOutputLayerId()
    self.yield = self.state.outputRatio
    self.outputLiters = 0

    return self
end

function LandscapingOutput:apply()
    if self.workArea.outputNode == nil then
        return
    end

    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()
    local position = self.workArea.outputNodePosition
    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deformation:addSoftCircleBrush(position[1], position[3], self.radius, self.hardness, self.strength, nil)
        LandscapingUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], self.radius)
        LandscapingUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)

        if paintDeformation ~= nil then
            paintDeformation:addSoftCircleBrush(position[1], position[3], paintRadius, 0.2, 0.5, self.terrainLayerId)
        end
    else
        deformation:addSoftSquareBrush(position[1], position[3], self.radius * 2, self.hardness, self.strength, nil)
        LandscapingUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], densityRadius * 2)
        LandscapingUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)

        if paintDeformation ~= nil then
            paintDeformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, 0.2, 0.5, self.terrainLayerId)
        end
    end

    deformation:setOutsideAreaConstraints(0, math.rad(75), math.rad(75))
    deformation:setBlockedAreaMaxDisplacement(0)
    deformation:setDynamicObjectCollisionMask(0)
    deformation:setDynamicObjectMaxDisplacement(0)

    deformation:apply(false, 'onDeformationCallback', self)
end

function LandscapingOutput:applyMapResources()
    if self.workArea.outputNode ~= nil then
        local layer = g_resourceManager:getResourceLayerAtWorldPos(self.workArea.outputNodePosition[1], self.workArea.outputNodePosition[3])

        if layer ~= nil then
            self.terrainLayerId = g_resourceManager:getResourcePaintLayerId(layer, true)
        end
    end
end

---@param volume number
function LandscapingOutput:onDeformationSuccess(volume)
    if self.fillType ~= nil and volume > 0 then
        self:applyDeformationChanges()

        self.outputLiters = LandscapingUtils.volumeToFillTypeLiters(volume, self.fillType.index) / self.state.outputRatio
    end
end

---@return TerrainDeformation?
---@nodiscard
function LandscapingOutput:createPaintDeformation()
    if self.state.enableOutputGroundTexture then
        self.paintDeformation = TerrainDeformation.new(g_terrainNode)
        self.paintDeformation:enablePaintingMode()

        return self.paintDeformation
    end
end
