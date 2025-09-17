---@class ModI3DManager
---@field i3dNodes table<string, number>
---@field i3dFilenames table<string, string>
ModI3DManager = {}

local ModI3DManager_mt = Class(ModI3DManager)

---@return ModI3DManager
---@nodiscard
function ModI3DManager.new()
    ---@type ModI3DManager
    local self = setmetatable({}, ModI3DManager_mt)

    self.i3dNodes = {}
    self.i3dFilenames = {}

    return self
end

---@param uniqueId string
---@return number?
function ModI3DManager:getI3DNode(uniqueId)
    local node = self.i3dNodes[uniqueId]

    if node == nil then
        Logging.warning('ModI3DManager:getI3dNode() i3dNode "%s" not found', tostring(uniqueId))
    end

    return node
end

---@param uniqueId string
---@return number?
function ModI3DManager:getCachedI3DNode(uniqueId)
    local i3dFilename = self.i3dFilenames[uniqueId]

    if i3dFilename ~= nil then
        local node = self:loadSharedI3DFile(i3dFilename)

        if node ~= 0 then
            setTranslation(node, 0, 0, 0)
            setVisibility(node, false)

            return node
        end
    end
end

---@param uniqueId string
---@return number?
function ModI3DManager:cloneI3DNode(uniqueId)
    local node = self.i3dNodes[uniqueId]

    if node ~= nil then
        return clone(node, true, false, false)
    end
end

---@param uniqueId string
---@return boolean
function ModI3DManager:reloadI3DNode(uniqueId)
    if self:deleteI3DNode(uniqueId) then
        return self:loadI3DFile(uniqueId, self.i3dFilenames[uniqueId])
    end

    return false
end

function ModI3DManager:loadInternalI3DFiles()
    self:loadModI3DFile('visArrowShape', 'objects/shapes/arrow.i3d')
    self:loadModI3DFile('visLineShape', 'objects/shapes/lineShape.i3d')
    self:loadModI3DFile('visMarkerShape', 'objects/shapes/markerShape.i3d')
end

---@param uniqueId string
---@param i3dFilename string
---@param modName? string
function ModI3DManager:loadModI3DFile(uniqueId, i3dFilename, modName)
    modName = modName or g_modName

    local modDirectory = g_modNameToDirectory[modName] or g_modsDirectory .. modName

    if modDirectory ~= nil then
        return self:loadI3DFile(modName .. '.' .. uniqueId, modDirectory .. i3dFilename)
    else
        Logging.warning('ModI3DManager:loadModI3dFile() Mod directory for "%s" not found', tostring(modName))
    end

    return false
end

---@param i3dFilename string
---@return number node -- Returns 0 if any errors
function ModI3DManager:loadSharedI3DFile(i3dFilename)
    local rootNode = g_i3DManager:loadSharedI3DFile(i3dFilename)

    if rootNode ~= nil and rootNode ~= 0 then
        local node = getChildAt(rootNode, 0)

        if node ~= 0 then
            link(getRootNode(), node)
            setTranslation(node, 0, 0, 0)
            setVisibility(node, false)
            delete(rootNode)
            return node
        else
            delete(rootNode)
            Logging.error('ModI3DManager:loadSharedI3DFile() Child node not found ("%s")', i3dFilename)
        end
    end

    return 0
end

---@param uniqueId string
---@param i3dFilename string
---@return boolean
---@nodiscard
function ModI3DManager:loadI3DFile(uniqueId, i3dFilename)
    if self.i3dNodes[uniqueId] == nil then
        local node = self:loadSharedI3DFile(i3dFilename)

        if node ~= 0 then
            self.i3dNodes[uniqueId] = node
            self.i3dFilenames[uniqueId] = i3dFilename

            g_modDebug:debug('ModI3DManager:loadI3dFile() Loaded I3D file "%s" (uniqueId: "%s")', i3dFilename, uniqueId)

            return self.i3dNodes ~= nil
        end
    else
        Logging.warning('ModI3DManager:loadI3dFile() Duplicate entry "%s" ("%s")', uniqueId, i3dFilename)
        return true
    end

    return false
end

---@param uniqueId string
---@return boolean
function ModI3DManager:deleteI3DNode(uniqueId)
    local node = self.i3dNodes[uniqueId]

    if node == nil then
        return false
    end

    delete(node)
    self.i3dNodes[uniqueId] = nil
    self.i3dFilenames[uniqueId] = nil

    return true
end

---@diagnostic disable-next-line: lowercase-global
g_modI3DManager = ModI3DManager.new()
g_modI3DManager:loadInternalI3DFiles()
