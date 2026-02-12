---@class LandscapingOutputSlope : LandscapingOutput
---@field litersToDrop number
---@field minY number
---@field maxY number
---@field nx number
---@field ny number
---@field nz number
---@field d number
---@field targetY number
LandscapingOutputSlope = {}

local LandscapingOutputSlope_mt = Class(LandscapingOutputSlope, LandscapingOutput)

---@param workArea MachineWorkArea
---@param minY number
---@param maxY number
---@param nx number
---@param ny number
---@param nz number
---@param d number
---@param targetY number
---@param litersToDrop number
---@param fillTypeIndex number
---@return LandscapingOutputSlope
---@nodiscard
function LandscapingOutputSlope.new(workArea, minY, maxY, nx, ny, nz, d, targetY, litersToDrop, fillTypeIndex)
    local self = LandscapingOutput.new(LandscapingOperation.SLOPE, workArea, LandscapingOutputSlope_mt)
    ---@cast self LandscapingOutputSlope

    self.litersToDrop = litersToDrop
    self.fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    self.heightChangeAmount = 0.75

    self.minY = minY
    self.maxY = maxY
    self.nx = nx
    self.ny = ny
    self.nz = nz
    self.d = d
    self.targetY = targetY

    self:checkMapResources()

    return self
end

function LandscapingOutputSlope:apply()
    local targetY = self.targetY - 0.05

    if self.workArea.outputNode == nil then
        return
    else
        local valid = false

        for _, node in ipairs(self.workArea.areaNodes) do
            if self.workArea.areaNodeTerrainY[node] < targetY then
                valid = true
                break
            end
        end

        if not valid then
            return
        end
    end

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

    -- deformation:apply(false, 'onDeformationCallback', self)
    deformation:apply(true, 'onDeformationPreviewCallback', self)
end

---@return TerrainDeformation
---@nodiscard
function LandscapingOutputSlope:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:setHeightTarget(self.minY, self.maxY, self.nx, self.ny, self.nz, self.d)
    self.deformation:enableSetDeformationMode()

    return self.deformation
end

local function volumeFromRadius(r) return 0.008 * (r ^ 2.55) end

function LandscapingOutputSlope:onDeformationPreviewCallback(errorCode, displacedVolumeOrArea)
    if errorCode == TerrainDeformation.STATE_SUCCESS and displacedVolumeOrArea > volumeFromRadius(self.radius) then
        self.deformation:apply(false, 'onDeformationCallback', self)
    else
        self:onDeformationCallback(errorCode, 0)
    end
end
