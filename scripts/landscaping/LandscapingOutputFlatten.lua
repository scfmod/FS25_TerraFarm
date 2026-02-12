---@class LandscapingOutputFlatten : LandscapingOutput
---@field targetY number
---@field litersToDrop number
LandscapingOutputFlatten = {}

local LandscapingOutputFlatten_mt = Class(LandscapingOutputFlatten, LandscapingOutput)

---@param workArea MachineWorkArea
---@param targetY number
---@param litersToDrop number
---@param fillTypeIndex number
---@return LandscapingOutputFlatten
---@nodiscard
function LandscapingOutputFlatten.new(workArea, targetY, litersToDrop, fillTypeIndex)
    local self = LandscapingOutput.new(LandscapingOperation.FLATTEN, workArea, LandscapingOutputFlatten_mt)
    ---@cast self LandscapingOutputFlatten

    self.targetY = targetY
    self.litersToDrop = litersToDrop
    self.fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    self.heightChangeAmount = 0.75

    self:checkMapResources()

    self.createTerrainDeformation = LandscapingInputFlatten.createTerrainDeformation

    return self
end

function LandscapingOutputFlatten:apply()
    if self.workArea.outputNode == nil then
        return
    else
        local valid = false

        for _, node in ipairs(self.workArea.areaNodes) do
            if self.workArea.areaNodeTerrainY[node] < self.targetY then
                valid = true
                break
            end
        end

        if not valid then
            return
        end
    end

    -- if self.workArea.outputNode == nil or self.workArea.outputNodeTerrainY > self.targetY then
    -- if self.workArea.outputNode == nil then
    --     return
    -- elseif #self.workArea.areaNodes > 1 then
    --     local firstNode = self.workArea.areaNodes[1]
    --     local lastNode = self.workArea.areaNodes[#self.workArea.areaNodes]

    --     if self.workArea.areaNodeTerrainY[firstNode] > self.targetY and self.workArea.areaNodeTerrainY[lastNode] > self.targetY and self.workArea.outputNodeTerrainY > self.targetY then
    --         return
    --     end
    -- elseif self.workArea.outputNodeTerrainY > self.targetY then
    --     return
    -- end

    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()
    local position = self.workArea.outputNodePosition
    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deformation:addSoftCircleBrush(position[1], position[3], self.radius, self.hardness, self.strength, nil)
        MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], self.radius)
        MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)

        if paintDeformation ~= nil then
            paintDeformation:addSoftCircleBrush(position[1], position[3], paintRadius, 0.2, 0.5, self.terrainLayerId)
        end
    else
        deformation:addSoftSquareBrush(position[1], position[3], self.radius * 2, self.hardness, self.strength, nil)
        MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], densityRadius * 2)
        MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)

        if paintDeformation ~= nil then
            paintDeformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, 0.2, 0.5, self.terrainLayerId)
        end
    end

    deformation:setOutsideAreaConstraints(0, math.rad(75), math.rad(75))
    deformation:setBlockedAreaMaxDisplacement(0)
    deformation:setDynamicObjectCollisionMask(0)
    deformation:setDynamicObjectMaxDisplacement(0)

    deformation:apply(true, 'onDeformationPreviewCallback', self)
end

local function volumeFromRadius(r) return 0.007 * (r ^ 2.55) end

function LandscapingOutputFlatten:onDeformationPreviewCallback(errorCode, displacedVolumeOrArea)
    if errorCode == TerrainDeformation.STATE_SUCCESS and displacedVolumeOrArea > volumeFromRadius(self.radius) then
        self.deformation:apply(false, 'onDeformationCallback', self)
    else
        self:onDeformationCallback(errorCode, 0)
    end
end
