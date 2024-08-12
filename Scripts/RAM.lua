-- RAM.lua by HerrVincling, 05.06.2022

RAM = class( nil )
RAM.maxChildCount = -1
RAM.maxParentCount = -1
RAM.connectionInput = sm.interactable.connectionType.logic
RAM.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
RAM.colorNormal = sm.color.new(0x222222ff)
RAM.colorHighlight = sm.color.new(0x4A4A4Aff)
--GenericClass.poseWeightCount = 1

dofile("interface_controller.lua")

-- allows other mods to read the data in a Ram Block
local ramBlocks = {}
sm.QuickLogic = {}
---Returns the memory held in a Quick Ram Block.
---@param id number The interactable id of a Ram Block.
---@return table
sm.QuickLogic.GetRamBlockMemory = function(id)
    -- id exists
    if ramBlocks[id] == nil or not sm.exists(ramBlocks[id].shape) then
        return nil
    end
    -- copy ram table because lua passes by reference
    local mem = {}
    for k, v in pairs(ramBlocks[id].memory) do
        mem[k] = v
    end
    return mem
end

--[[ client ]]
function RAM.client_onCreate(self )
end

function RAM.client_onRefresh(self )
 self:client_onCreate()
end

function RAM.client_onUpdate(self, deltaTime )
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6 + self.var1)
    else
        self.interactable:setUvFrameIndex(0 + self.var1)
    end
end

function RAM.client_onInteract(self, character, state )
    if state then
        if character:isCrouching() then

        else

        end
        local bytes = 0
        for _, _ in pairs(self.memory) do
            bytes = bytes + 1
        end
        if bytes == 1 then
            sm.gui.chatMessage("RAM: " .. bytes .. " value stored")
        else
            sm.gui.chatMessage("RAM: " .. bytes .. " values stored")
        end
    end
end

--[[ server ]]
function RAM.partFunction(self, inputvalues)
    local address = inputvalues[self.colors.input[1]:getHexStr()]
    local input = inputvalues[self.colors.input[2]:getHexStr()]
    local write = inputvalues[self.colors.input[3]:getHexStr()]
    local read = inputvalues[self.colors.input[4]:getHexStr()]
    local reset = inputvalues[self.colors.input[5]:getHexStr()]

    if reset == 1 then
        self.memory = {}
    end

    if write == 1 then
        if input == 0 then
            self.memory[address] = nil
        else
            self.memory[address] = input
        end
    end

    local output = 0
    if read == 1 then
        output = self.memory[address]
        if output == nil then
            output = 0
        end
    end

    return {[self.colors.output[1]:getHexStr()] = output}
end

function RAM.server_onCreate(self )
    ramBlocks[self.interactable.id] = self
    if self.storage:load() ~= nil then
        self.memory = self.storage:load().memory
    else
        self.memory = {}
    end

    self.var1 = 0

    self.currentTick = 0
    self.interfacesRaw = {}
    self.colors = {}
    self.colors.input = {}
    self.colors.output = {}
    table.insert(self.colors.output, sm.color.new(0x7514EDff)) --PURPLE - Output

    table.insert(self.colors.input, sm.color.new(0xE2DB13ff)) --YELLOW - Address
    table.insert(self.colors.input, sm.color.new(0x0A3EE2ff)) --BLUE   - Input
    table.insert(self.colors.input, sm.color.new(0x2CE6E6ff)) --CYAN   - Write

    table.insert(self.colors.input, sm.color.new(0xCF11D2ff)) --PINK   - Read
    table.insert(self.colors.input, sm.color.new(0xD02525ff)) --RED    - Reset


    interface_signin(self, "RAM", RAM.partFunction, self.colors, true)
end

function RAM.server_onRefresh(self )
    self:server_onCreate()
end

function RAM.server_onFixedUpdate(self, deltaTime )
    if sm.game.getCurrentTick() % 10 == 0 then
        self.storage:save({memory = self.memory})
    end
end

function RAM.server_onDestroy(self )
    ramBlocks[self.interactable.id] = nil
    interface_signin(self, "RAM", RAM.partFunction, self.colors, false)
end