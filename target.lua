local bones = {
    ['door_dside_f'] = 0,
    ['door_pside_f'] = 1,
    ['door_dside_r'] = 2,
    ['door_pside_r'] = 3,
    ['bonnet'] = 4,
    ['boot'] = 5
}
local function displayOilLifeAndMileage(oilLife, mileage)
    local alert = lib.alertDialog({
        header = 'Vehicle Information',
        content = string.format("Oil Life: %s%%\nMileage: %s miles", oilLife, mileage),
        centered = true,
        cancel = true,
        size = 'md',
        overflow = false,
        labels = {
            cancel = 'Close',
            confirm = 'Ok'
        }
    })

    print(alert)  -- Prints 'confirm' if the player pressed the confirm button, 'cancel' otherwise
end

function checkOilLife(vehicleId)
    -- Request the oil life and mileage from the server
    TriggerServerEvent("getOilLife", vehicleId)
end

-- Listen for the server response with the oil life and mileage data
RegisterNetEvent("receiveOilLifeAndMileage")
AddEventHandler("receiveOilLifeAndMileage", function(oilLife, mileage)
    displayOilLifeAndMileage(oilLife, mileage)
end)
-- Function to get the door index from the bone name
local function GetDoorIndexFromBoneName(boneName)
    return bones[boneName]
end
---@param entity number
---@param coords vector3
---@param door number
---@param useOffset boolean?
---@return boolean?
local function canInteractWithDoor(entity, coords, door, useOffset)
    if not GetIsDoorValid(entity, door) or GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, door) then return end

    if useOffset then return true end

    local boneName = bones[door]

    if not boneName then return false end

    local boneId = GetEntityBoneIndexByName(entity, 'door_' .. boneName)

    if boneId ~= -1 then
        return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or
            #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_' .. boneName))) < 0.72
    end
end
-- Function to check if a specific wheel is broken off
local function isWheelBroken(entity, wheelIndex)
    return IsVehicleTyreBurst(entity, wheelIndex, false) -- Check if the tire is burst without popping it
end
exports.ox_target:addGlobalVehicle({
    {
        name = 'ox_target:changeEngineOil',
        icon = 'fas fa-wrench',
        label = 'Change Engine Oil',
        bones = { 'engine' },
        distance = 3,
        items = { 'oil_filter', 'oil', 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords)
            return true -- Always available for interaction
        end,
        onSelect = function(data)
            local items = { 'oil_filter', 'oil', 'wrench', 'socket_set' }
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
            changeEngineOil(data.entity)
        end
    },
    {
        name = 'ox_target:mileage',
        icon = 'fas fa-tachometer-alt',
        label = 'Check Mileage',
        bones = { 'steering' },
        distance = 2,
        canInteract = function(entity, distance, coords, name)
            return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'steering'))) < 0.5
        end,
        onSelect = function(data)
            checkMileage(data.entity)
        end
    },
    {
        name = 'ox_target:addTurbo',
        icon = 'fas fa-tachometer-alt',
        label = 'Install Turbo Charger',
        bones = { 'engine' },
        distance = 2,
        items = { 'intercooler', 'intercooler_piping', 'wrench', 'socket_set', 'turbocharger', 'bov', 'oilbung' },
        canInteract = function(entity, distance, coords, name)
            return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'engine'))) < 0.5
        end,
        onSelect = function(data)
            local items = { 'intercooler', 'intercooler_piping', 'wrench', 'socket_set', 'turbocharger', 'bov', 'oilbung' }
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
            addTurbo(NetworkGetNetworkIdFromEntity(data.entity))
        end
    },
    {
        name = 'ox_target:addEngineStage1',
        icon = 'fas fa-cogs',
        label = 'Install Stage 1 Engine Kit',
        bones = { 'engine' },
        distance = 2,
        items = { 'oil', 'camshaft_1', 'piston_1', 'lifter_1', 'rocker_1', 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords, name)
            return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'engine'))) < 0.5
        end,
        onSelect = function(data)
            local items = { 'oil', 'camshaft_1', 'piston_1', 'lifter_1', 'rocker_1', 'wrench', 'socket_set' }
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
            addEngineMod(NetworkGetNetworkIdFromEntity(data.entity), 1)
        end
    },
    {
        name = 'ox_target:addEngineStage2',
        icon = 'fas fa-cogs',
        label = 'Install Stage 2 Engine Kit',
        bones = { 'engine' },
        distance = 2,
        items = { 'oil', 'camshaft_2', 'piston_2', 'lifter_2', 'rocker_2', 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords, name)
            return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'engine'))) < 0.5
        end,
        onSelect = function(data)
            local items = { 'oil', 'camshaft_2', 'piston_2', 'lifter_2', 'rocker_2', 'wrench', 'socket_set' }
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
            addEngineMod(NetworkGetNetworkIdFromEntity(data.entity), 2)
        end
    },
    {
        name = 'ox_target:addTransmissionStage1',
        icon = 'fas fa-cogs',
        label = 'Install Stage 1 Transmission Kit',
        bones = { 'engine' },
        distance = 2,
        items = { 'trans_oil', 'shiftkit_1', 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords, name)
            return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'engine'))) < 0.5
        end,
        onSelect = function(data)
            local items = { 'trans_oil', 'shiftkit_1', 'wrench', 'socket_set' }
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
            addTransmissionMod(NetworkGetNetworkIdFromEntity(data.entity), 1)
        end
    },
    {
        name = 'ox_target:addTransmissionStage2',
        icon = 'fas fa-cogs',
        label = 'Install Stage 2 Transmission Kit',
        bones = { 'engine' },
        distance = 2,
        items = { 'trans_oil', 'shiftkit_2', 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords, name)
            return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'engine'))) < 0.5
        end,
        onSelect = function(data)
            local items = { 'trans_oil', 'shiftkit_2', 'wrench', 'socket_set' }
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
            addTransmissionMod(NetworkGetNetworkIdFromEntity(data.entity), 2)
        end
    },
    {
        name = 'ox_target:addOEMCoilovers',
        icon = 'fas fa-car',
        label = 'Install OEM Coilovers',
        bones = { 'engine' },
        distance = 2,
        items = { 'oem_coilovers', 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords, name)
            return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'engine'))) < 0.5
        end,
        onSelect = function(data)
            local items = { 'oem_coilovers', 'wrench', 'socket_set' }
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
            addCoiloverSuspension(NetworkGetNetworkIdFromEntity(data.entity), 1)
        end
    },
    {
        name = 'ox_target:addSportCoilovers',
        icon = 'fas fa-car',
        label = 'Install Sport Coilovers',
        bones = { 'engine' },
        distance = 2,
        items = { 'sport_coilovers', 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords, name)
        return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'engine'))) < 0.5
        end,
        onSelect = function(data)
        local items = { 'sport_coilovers', 'wrench', 'socket_set' }
        TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        addCoiloverSuspension(NetworkGetNetworkIdFromEntity(data.entity), 2)
        end
        },
        {
        name = 'ox_target:addRaceCoilovers',
        icon = 'fas fa-car',
        label = 'Install Race Coilovers',
        bones = { 'engine' },
        distance = 2,
        items = { 'race_coilovers', 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords, name)
        return #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'engine'))) < 0.5
        end,
        onSelect = function(data)
        local items = { 'race_coilovers', 'wrench', 'socket_set' }
        TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        addCoiloverSuspension(NetworkGetNetworkIdFromEntity(data.entity), 3)
        end
        },
        {
        name = 'ox_target:removeDoor',
        icon = 'fas fa-tools',
        label = 'Remove Door',
        bones = { 'door_dside_f', 'door_dside_r', 'door_pside_f', 'door_pside_r', 'bonnet', 'boot' },
        distance = 2,
        items = { 'wrench', 'socket_set' },
        canInteract = function(entity, distance, coords)
        return true -- Always available for interaction
        end,
        onSelect = function(data)
        local hit, entityHit, endCoords, surfaceNormal, materialHash = lib.raycast.cam()
        if hit and DoesEntityExist(entityHit) and IsEntityAVehicle(entityHit) then
            local direction = endCoords - GetGameplayCamCoord()
            local boneName = GetClosestBoneName(entityHit, endCoords, data.bones)

            if boneName then
                removeDoor({ entity = NetworkGetNetworkIdFromEntity(entityHit), boneName = boneName })
            else
                print("No valid bone found")
            end
        else
            print("No valid vehicle found")
        end
    end
},
{
    name = 'ox_target:replaceDoor',
    icon = 'fas fa-tools',
    label = 'Replace Door',
    bones = { 'door_dside_f', 'door_dside_r', 'door_pside_f', 'door_pside_r', 'bonnet', 'boot' },
    distance = 2,
    items = { 'vehicle_door', 'wrench', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true -- Always available for interaction
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        for _, boneName in ipairs(data.bones) do
            local doorIndex = GetDoorIndexFromBoneName(boneName)
            if doorIndex ~= nil then
                replaceDoor({ entity = vehicleId, doorIndex = doorIndex })
                TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
            else
                print("Unknown bone name:", boneName)
            end
        end
    end
},
{
    name = 'ox_target:windowTint1',
    icon = 'fas fa-sun',
    label = 'Stock Window Tint',
    distance = 2,
    options = windowTintOptions,
    bones = { 'window_lf1', 'window_lf2', 'window_lf3', 'window_rf1', 'window_rf2', 'window_rf3', 'window_lr1', 'window_lr2', 'window_lr3', 'window_rr1', 'window_rr2', 'window_rr3', 'window_lf', 'window_rf', 'window_lr', 'window_rr', 'window_lm', 'window_rm' },
    items = { 'heat_gun', 'squeegee', 'tint_stock', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true -- Always available for interaction
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        local selectedOption = data.option

        if selectedOption and selectedOption.tint then
            applyWindowTint(vehicleId, selectedOption.tint)
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        else
            print("Invalid window tint option.")
        end
    end
},
{
    name = 'ox_target:windowTint2',
    icon = 'fas fa-sun',
    label = 'Limo Window Tint',
    distance = 2,
    options = windowTintOptions,
    bones = { 'window_lf1', 'window_lf2', 'window_lf3', 'window_rf1', 'window_rf2', 'window_rf3', 'window_lr1', 'window_lr2', 'window_lr3', 'window_rr1', 'window_rr2', 'window_rr3', 'window_lf', 'window_rf', 'window_lr', 'window_rr', 'window_lm', 'window_rm' },
    items = { 'heat_gun', 'squeegee', 'tint_limo', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true -- Always available for interaction
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        local selectedOption = data.option

        if selectedOption and selectedOption.tint then
            applyWindowTint(vehicleId, selectedOption.tint)
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        else
            print("Invalid window tint option.")
        end
    end
},
{
    name = 'ox_target:windowTint3',
    icon = 'fas fa-sun',
    label = 'Light Smoke Window Tint',
    distance = 2,
    options = windowTintOptions,
    bones = { 'window_lf1', 'window_lf2', 'window_lf3', 'window_rf1', 'window_rf2', 'window_rf3', 'window_lr1', 'window_lr2', 'window_lr3', 'window_rr1', 'window_rr2', 'window_rr3', 'window_lf', 'window_rf', 'window_lr', 'window_rr', 'window_lm', 'window_rm' },
    items = { 'heat_gun', 'squeegee', 'tint_lightsmoke', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true -- Always available for interaction
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        local selectedOption = data.option
        if selectedOption and selectedOption.tint then
            applyWindowTint(vehicleId, selectedOption.tint)
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        else
            print("Invalid window tint option.")
        end
    end
},
{
    name = 'ox_target:windowTint4',
    icon = 'fas fa-sun',
    label = 'Dark Smoke Window Tint',
    distance = 2,
    options = windowTintOptions,
    bones = { 'window_lf1', 'window_lf2', 'window_lf3', 'window_rf1', 'window_rf2', 'window_rf3', 'window_lr1', 'window_lr2', 'window_lr3', 'window_rr1', 'window_rr2', 'window_rr3', 'window_lf', 'window_rf', 'window_lr', 'window_rr', 'window_lm', 'window_rm' },
    items = { 'heat_gun', 'squeegee', 'tint_darksmoke', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true -- Always available for interaction
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        local selectedOption = data.option
        if selectedOption and selectedOption.tint then
            applyWindowTint(vehicleId, selectedOption.tint)
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        else
            print("Invalid window tint option.")
        end
    end
},
{
    name = 'ox_target:windowTint5',
    icon = 'fas fa-sun',
    label = 'Pure Black Window Tint',
    distance = 2,
    options = windowTintOptions,
    bones = { 'window_lf1', 'window_lf2', 'window_lf3', 'window_rf1', 'window_rf2', 'window_rf3', 'window_lr1', 'window_lr2', 'window_lr3', 'window_rr1', 'window_rr2', 'window_rr3', 'window_lf', 'window_rf', 'window_lr', 'window_rr', 'window_lm', 'window_rm' },
    items = { 'heat_gun', 'squeegee', 'tint_pureblack', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true -- Always available for interaction
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        local selectedOption = data.option
        if selectedOption and selectedOption.tint then
            applyWindowTint(vehicleId, selectedOption.tint)
            TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        else
            print("Invalid window tint option.")
        end
    end
},
{
    name = 'ox_target:addOEMBrakes',
    icon = 'fas fa-car-brake',
    label = 'Install OEM Brakes',
    bones = { 'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr' },
    distance = 2,
    items = { 'oem_rotors', 'oem_brakepads', 'wrench', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        installBrakes(vehicleId, 'oem')
    end
},
{
    name = 'ox_target:addPremiumBrakes',
    icon = 'fas fa-car-brake',
    label = 'Install Premium Brakes',
    bones = { 'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr' },
    distance = 2,
    items = { 'premium_rotors', 'premium_brakepads', 'wrench', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true
    end,
    onSelect = function(data)
        TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        installBrakes(vehicleId, 'premium')
    end
},
{
    name = 'ox_target:addSportBrakes',
    icon = 'fas fa-car-brake',
    label = 'Install Sport Brakes',
    bones = { 'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr' },
    distance = 2,
    items = { 'sport_rotors', 'sport_brakepads', 'wrench', 'socket_set' },
    canInteract = function(entity, distance, coords)
        return true
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        items = { 'sport_rotors', 'sport_brakepads', 'wrench', 'socket_set' },
        TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        installBrakes(vehicleId, 'sport')
    end
},
{
    name = 'ox_target:addRaceBrakes',
    icon = 'fas fa-car-brake',
    label = 'Install Race Brakes',
    bones = { 'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr' },
    distance = 2,
    items = { 'race_rotors', 'race_brakepads', 'wrench', 'socket_set' },

    canInteract = function(entity, distance, coords)
        return true
    end,
    onSelect = function(data)
        local vehicleId = NetworkGetNetworkIdFromEntity(data.entity)
        local items = { 'race_rotors', 'race_brakepads', 'wrench', 'socket_set' }
        TriggerServerEvent('removeItems', items, GetPlayerServerId(PlayerId()))
        
        installBrakes(vehicleId, 'race')
    end
},
{
    name = 'ox_target:repairWheel',
    icon = 'fas fa-tools',
    label = 'Repair Wheel',
    bones = { 'engine'}, 
    distance = 2,
    items = { 'wrench', 'socket_set' }, 
    canInteract = function(entity, distance, coords)
        for wheelIndex = 0, 3 do
            if isWheelBroken(entity, wheelIndex) then
                print(isWheelBroken)
                print(wheelIndex)
                print(entity)
                return true 
            end
        end
        return false 
    end,
    onSelect = function(data)
        for wheelIndex = 0, 3 do
            if isWheelBroken(data.entity, wheelIndex) then
                local boneName = getWheelBoneName(wheelIndex)
                repairWheel({ entity = NetworkGetNetworkIdFromEntity(data.entity), boneName = boneName })
                print(isWheelBroken)
                print(wheelIndex)
                print(entity)
                break 
            end
        end
    end
}
})

