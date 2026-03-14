---@type ButtonElement[]
local menuButton = g_inGameMenu.menuButton

local function addMenuButton()
    local numButtons = #menuButton
    local button = menuButton[1]:clone(menuButton[1].parent, false, true)
    button.id = string.format('menuButton[%d]', numButtons + 1)
    table.insert(menuButton, button)
end

if menuButton ~= nil and #menuButton < 8 then
    addMenuButton()
    addMenuButton()
end
