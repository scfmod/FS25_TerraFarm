---@class TFTerrainLayerElement : TerrainLayerElement
---@field imageColor number[]
---@field imageDisabledColor number[]
---@field imageSelectedColor? number[]
---@field terrainLayerTextureOverlay number
TFTerrainLayerElement = {}

local TFTerrainLayerElement_mt = Class(TFTerrainLayerElement, TerrainLayerElement)

function TFTerrainLayerElement.new(target)
    ---@type TFTerrainLayerElement
    local self = TerrainLayerElement.new(target, TFTerrainLayerElement_mt)

    self.imageColor = { 1, 1, 1, 1 }
    self.imageDisabledColor = { 1, 1, 1, 1 }

    return self
end

---@param src TFTerrainLayerElement
function TFTerrainLayerElement:copyAttributes(src)
    TerrainLayerElement.copyAttributes(self, src)

    self.imageColor = table.clone(src.imageColor)
    self.imageDisabledColor = table.clone(src.imageDisabledColor)

    if src.imageSelectedColor ~= nil then
        self.imageSelectedColor = table.clone(src.imageSelectedColor)
    end
end

---@param xmlFile number
---@param key string
function TFTerrainLayerElement:loadFromXML(xmlFile, key)
    TerrainLayerElement.loadFromXML(self, xmlFile, key)

    self.imageColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#imageColor'), self.imageColor)
    self.imageDisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#imageDisabledColor'), self.imageDisabledColor)
    self.imageSelectedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. '#imageSelectedColor'), self.imageSelectedColor)
end

---@param profile GuiProfile
---@param applyProfile any
function TFTerrainLayerElement:loadProfile(profile, applyProfile)
    TerrainLayerElement.loadProfile(self, profile, applyProfile)

    self.imageColor = GuiUtils.getColorArray(profile:getValue('imageColor'), self.imageColor)
    self.imageDisabledColor = GuiUtils.getColorArray(profile:getValue('imageDisabledColor'), self.imageDisabledColor)
    self.imageSelectedColor = GuiUtils.getColorArray(profile:getValue('imageSelectedColor'), self.imageSelectedColor)
end

function TFTerrainLayerElement:draw(...)
    if self.terrainLayerTextureOverlay ~= nil then
        local color = self.disabled and self.imageDisabledColor or self.imageColor

        if self.selected and not self.disabled and self.imageSelectedColor ~= nil then
            color = self.imageSelectedColor
            ---@cast color number[]
        end

        setOverlayColor(self.terrainLayerTextureOverlay, color[1], color[2], color[3], color[4])

        TerrainLayerElement.draw(self, ...)
    end
end

Gui.registerGuiElement('TFTerrainLayer', TFTerrainLayerElement)
