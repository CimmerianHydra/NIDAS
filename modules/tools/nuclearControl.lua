local component      = require("component")
local serialization  = require("serialization")
local states         = require("server.entities.states")
local nuclearControl = {}

local nuclearControlData = {}

local redstone_address = nil
local transposer_addess = nil

local redstone_proxy = nil
local transposer_proxy = nil

local transposer_chamber_side = nil
local transposer_provider_side = nil

local coolant_cell_name = nil
local full_fuel_rod_name = nil
local depl_fuel_rod_name = nil

local coolant_cell_damage_threshold = nil

local enabled = false

local function save(data)
    local file = io.open("/home/NIDAS/settings/nuclearControlData", "w")
    transposer_chamber_side = tonumber(nuclearControlData.transposer_chamber_side)
    transposer_provider_side = tonumber(nuclearControlData.transposer_provider_side)
    coolant_cell_name = tostring(nuclearControlData.coolant_cell_name)
    full_fuel_rod_name = tostring(nuclearControlData.full_fuel_rod_name)
    depl_fuel_rod_name = tostring(nuclearControlData.depl_fuel_rod_name)
    coolant_cell_damage_threshold = tonumber(nuclearControlData.coolant_cell_damage_threshold)
    if _ then
        file:write(serialization.serialize(nuclearControlData))
        os.sleep()
        file:close()
    end
end

local function load()
    local file = io.open("/home/NIDAS/settings/nuclearControlData", "r")
    if file then
        nuclearControlData = serialization.unserialize(file:read("*a")) or {}
        if nuclearControlData == nil then nuclearControlData = {} end
        if nuclearControlData.redstone_address and nuclearControlData.transposer_address then 
            if nuclearControlData.redstone_address ~= "None" then redstone_proxy = component.proxy(component.get(nuclearControlData.redstone_address)) else
                redstone_proxy = nil
            end
            if nuclearControlData.transposer_address ~= "None" then transposer_proxy = component.proxy(component.get(nuclearControlData.transposer_address)) else
                transposer_proxy = nil
            end
            transposer_chamber_side = tonumber(nuclearControlData.transposer_chamber_side)
            transposer_provider_side = tonumber(nuclearControlData.transposer_provider_side)
            coolant_cell_name = tostring(nuclearControlData.coolant_cell_name)
            full_fuel_rod_name = tostring(nuclearControlData.full_fuel_rod_name)
            depl_fuel_rod_name = tostring(nuclearControlData.depl_fuel_rod_name)
            coolant_cell_damage_threshold = tonumber(nuclearControlData.coolant_cell_damage_threshold)
        end
        file:close()
    end
end

local function engage()
    if redstone_proxy then
        redstone_proxy.setOutput({15, 15, 15, 15, 15, 15})
    end
end

local function disengage()
    if redstone_proxy then
        redstone_proxy.setOutput({0, 0, 0, 0, 0, 0})
    end
end

local refresh = nil
local currentConfigWindow = {}
local function changeRedstone(redstoneAddress, data)
    if redstoneAddress == "None" then
        nuclearControlData.redstone_address = "None"
        redstone_proxy = nil
    else
        redstone_proxy = component.proxy(component.get(redstoneAddress))
        nuclearControlData.redstone_address = redstoneAddress
    end
    local x, y, gui, graphics, renderer, page = table.unpack(data)
    renderer.removeObject(currentConfigWindow)
    refresh(x, y, gui, graphics, renderer, page)
end
local function changeTransposer(transposerAddress, data)
    if transposerAddress == "None" then
        nuclearControlData.transposer_address = "None"
        transposer_proxy = nil
    else
        transposer_proxy = component.proxy(component.get(transposerAddress))
        nuclearControlData.transposer_address = transposerAddress
    end
    local x, y, gui, graphics, renderer, page = table.unpack(data)
    renderer.removeObject(currentConfigWindow)
    refresh(x, y, gui, graphics, renderer, page)
end

function nuclearControl.configure(x, y, gui, graphics, renderer, page)
    local renderingData = {x, y, gui, graphics, renderer, page}
    graphics.context().gpu.setActiveBuffer(page)

    -- Configuration options for the singular nuclear reactor.
    local globalAttributeChangeList = {
        {name = "Control Settings",         attribute = nil,                        type = "header",    defaultValue = nil},
        {name = "Reactor Chamber Side",     attribute = "transposer_chamber_side",  type = "number",    defaultValue = 0},
        {name = "Item Provider Side",       attribute = "transposer_provider_side", type = "number",    defaultValue = 1},
        {name = "Full Fuel Rod Name",       attribute = "full_fuel_rod_name",       type = "string",    defaultValue = "gregtech:gt.RodUranium4"},
        {name = "Depleted Fuel Rod Name",   attribute = "depl_fuel_rod_name",       type = "string",    defaultValue = "gregtech:gt.depletedRodUranium4"},
        {name = "Coolant Cell Name",        attribute = "coolant_cell_name",        type = "string",    defaultValue = "gregtech:gt.360k_Helium_Coolantcell"},
        {name = "Coolant Cell Damage",      attribute = "coolant_cell_damage_threshold", type = "number", defaultValue = 75},
}
    gui.multiAttributeList(x+3, y+3, page, currentConfigWindow, globalAttributeChangeList, nuclearControlData, nil, nil)

    -- Redstone input/output selection box.
    graphics.text(3, 5, "Redstone I/O:")
    local onActivation = {}
    for address, componentType in component.list() do
        if componentType == "redstone" then
            local displayName = address
            table.insert(onActivation, {displayName = displayName, value = changeRedstone, args = {address, renderingData}})
        end
    end
    table.insert(onActivation, {displayName = "None", value = changeRedstone, args = {"None", renderingData}})
    local _, ySize = graphics.context().gpu.getBufferSize(page)
    table.insert(currentConfigWindow, gui.smallButton(x+15, y+2, nuclearControlData.redstone_address or "None", gui.selectionBox, {x+16, y+2, onActivation}))
    
    -- Transposer selection box.
    graphics.text(3, 7, "Transposer:")
    local onActivation = {}
    for address, componentType in component.list() do
        if componentType == "transposer" then
            local displayName = address
            table.insert(onActivation, {displayName = displayName, value = changeTransposer, args = {address, renderingData}})
        end
    end
    table.insert(onActivation, {displayName = "None", value = changeTransposer, args = {"None", renderingData}})
    local _, ySize = graphics.context().gpu.getBufferSize(page)
    table.insert(currentConfigWindow, gui.smallButton(x+15, y+2, nuclearControlData.transposer_address or "None", gui.selectionBox, {x+16, y+2, onActivation}))
    
    table.insert(currentConfigWindow, gui.bigButton(x+2, y+tonumber(ySize)-4, "Save Configuration", save))
    renderer.update()
    return currentConfigWindow
end
refresh = nuclearControl.configure

load()

local DOWNTIME = 0.5
local REACTOR_INVENTORY_SIZE = 54

local checkingInterval = 20
local counter = checkingInterval

-- Pushes item from slot in reactor to first empty slot of provider inventory.
-- (Provider inventory can be ME Interface, chest, etc.)
local function push_item_to_provider(source_slot, item_name)
    local provider_inventory_size = transposer_proxy.getInventorySize(transposer_provider_side)

    for slot = 1, provider_inventory_size do
        local stack = transposer_proxy.getStackInSlot(transposer_provider_side, slot)
        if stack == nil then
            transposer_proxy.transferItem(transposer_chamber_side, transposer_provider_side, 1, source_slot, slot)
			break
        end
    end
end

-- Pulls named item from provider inventory and places it in the specified slot of the reactor. Does not stop until it has found the item.
-- (Provider inventory can be ME Interface, chest, etc.)
local function pull_item_from_provider(destination_slot, item_name)
    local provider_inventory_size = transposer_proxy.getInventorySize(transposer_provider_side)

    local found = false
    repeat 
        for slot = 1, provider_inventory_size do
            local stack = transposer_proxy.getStackInSlot(transposer_provider_side, slot)
            if stack then
                if stack.name == item_name then
                    transposer_proxy.transferItem(transposer_provider_side, transposer_chamber_side, 1, slot, destination_slot)
                    found = true
                    break
                end
            end
        end
    until found
end

function nuclearControl.update(data)
    if counter == checkingInterval then
        if not enabled then disengage() else
            for slot = 1, REACTOR_INVENTORY_SIZE do
                item = nuke_transposer.getStackInSlot(REACTOR_SIDE, slot)
                if item then
                    if item.name == nuclearControlData.coolant_cell_name then
                        if item.damage >= coolant_cell_damage_threshold then
                            disengage()
                            os.sleep(DOWNTIME)
                            push_item_to_provider(slot, nuclearControlData.coolant_cell_name)
                            pull_item_from_provider(slot, nuclearControlData.coolant_cell_name)
                            os.sleep(DOWNTIME)
                            engage()
                        end
                    end
                    if item.name == nuclearControlData.depl_fuel_rod_name then
                        disengage()
                        os.sleep(DOWNTIME)
                        push_item_to_provider(slot, nuclearControlData.depl_fuel_rod_name)
                        pull_item_from_provider(slot, nuclearControlData.full_fuel_rod_name)
                        os.sleep(DOWNTIME)
                        engage()
                    end
                end
            end
        end
        engage()
        counter = 1
    else
        counter = counter + 1
    end
end

return nuclearControl