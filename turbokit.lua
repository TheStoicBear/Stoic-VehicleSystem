local turbo = {}  -- Turbo state for each vehicle
-- Global table to keep track of door states
local doorStates = {}
local raisedCar = nil
local isRaised = false
local vehpos = nil
local flWheelStand = nil
local frWheelStand = nil
local rlWheelStand = nil
local rrWheelStand = nil
local bones = {
    ['door_dside_f'] = 0,
    ['door_pside_f'] = 1,
    ['door_dside_r'] = 2,
    ['door_pside_r'] = 3,
    ['bonnet'] = 4,
    ['boot'] = 5
}
local windowTintOptions = {
    { label = 'Stock', tint = 0 },        -- No tint
    { label = 'None', tint = 1 },         -- No tint
    { label = 'Limo', tint = 2 },         -- Very dark tint
    { label = 'Light Smoke', tint = 3 },  -- Light tint
    { label = 'Dark Smoke', tint = 4 },   -- Medium tint
    { label = 'Pure Black', tint = 5 }    -- Full black tint
}
-- Function to get the door index from the bone name
local function GetDoorIndexFromBoneName(boneName)
    return bones[boneName]
end
-- Function to enumerate entities
local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end

        local enum = { handle = iter, id = id }
        setmetatable(enum, entityEnumerator)

        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next

        disposeFunc(iter)
    end)
end

-- Function to enumerate vehicles
local function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

-- Function to calculate the distance between two points
function GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

-- Function to get the closest bone name from a list of bones to a specific position
function GetClosestBoneName(entity, coords, bones)
    local closestBone = nil
    local minDistance = math.huge

    for _, boneName in ipairs(bones) do
        local boneIndex = GetEntityBoneIndexByName(entity, boneName)
        if boneIndex ~= -1 then
            local boneCoords = GetWorldPositionOfEntityBone(entity, boneIndex)
            local distance = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, boneCoords.x, boneCoords.y, boneCoords.z)
            
            if distance < minDistance then
                minDistance = distance
                closestBone = boneName
            end
        end
    end

    return closestBone
end

-- Get the nearest vehicle function
function getNearestVeh()
    local pos = GetEntityCoords(GetPlayerPed(-1))
    local entityWorld = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 5.0, 0.0) -- Adjusted range
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, GetPlayerPed(-1), 0)
    local _, _, _, _, vehicleHandle = GetRaycastResult(rayHandle)
    return vehicleHandle
end

-- Function to get the closest vehicle to the player within a specified distance
function GetClosestVehicleToPlayer(playerPed, distance)
    local playerCoords = GetEntityCoords(playerPed)
    local closestVehicle = 0
    local closestDistance = distance

    for vehicle in EnumerateVehicles() do
        local vehicleCoords = GetEntityCoords(vehicle)
        local dist = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
        if dist < closestDistance then
            closestVehicle = vehicle
            closestDistance = dist
        end
    end

    return closestVehicle
end

-- Function to modify turbo
function addTurbo(vehicleId)
    local playerPed = PlayerPedId()
    local vehicle = GetClosestVehicleToPlayer(playerPed, 5.0)
    if vehicle ~= 0 then
        local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerEvent('raisecar', vehicle) -- Pass the vehicle entity when triggering the event
        Citizen.Wait(1000)

        -- Show the progress bar
        local success = lib.progressBar({
            duration = 25000, -- 25 seconds
            label = 'Installing turbo...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle'
            },
            prop = {
                model = `prop_ld_flow_bottle`,
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(0.0, 0.0, -1.5)
            },
        })

        if success then
            -- On successful completion of the progress bar
            turbo[vehicleId] = true -- Enable turbo
            SetVehicleModKit(vehicle, 0) -- Set the mod kit for the vehicle
            ToggleVehicleMod(vehicle, 18, true) -- Enable the turbo mod
            updateVehicleData(vehicleId)

            -- Show success UI
            lib.showTextUI('Turbo installed successfully', {
                position = "top-center",
                icon = 'check-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#48BB78',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
            TriggerEvent('lowercar', vehicle)
        else
            -- On cancellation of the progress bar
            -- Show cancellation UI
            lib.showTextUI('Turbo installation canceled', {
                position = "top-center",
                icon = 'times-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#e53e3e',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
        end

        -- Lower the car after progress bar is done or canceled
        TriggerEvent('lowercar', vehicle)
    else
        local dialogContent = "**You must be near the vehicle's engine to add a turbo!**"
        local alertData = {
            header = "Turbo Installation Error",
            content = dialogContent,
            size = 'sm',
            centered = true
        }
        local alert = lib.alertDialog(alertData)
        print(alert)
    end
end

-- Function to modify engine mods
function addEngineMod(vehicleId, stage)
    local playerPed = PlayerPedId()
    local vehicle = GetClosestVehicleToPlayer(playerPed, 5.0)
    if vehicle ~= 0 then
        local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerEvent('raisecar', vehicle) -- Pass the vehicle entity when triggering the event
        Citizen.Wait(1000)

        local modType = stage - 1 -- Engine mods are typically 0-3 for stages 1-4
        local modLabel = 'Stage ' .. stage .. ' Engine Kit'

        -- Show the progress bar
        local success = lib.progressBar({
            duration = 25000, -- 25 seconds
            label = 'Installing ' .. modLabel .. '...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle'
            },
            prop = {
                model = `prop_ld_flow_bottle`, -- Adjust the prop model as needed
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(0.0, 0.0, -1.5)
            },
        })

        if success then
            -- On successful completion of the progress bar
            SetVehicleMod(vehicle, 11, modType) -- Set the engine modification
            updateVehicleData(vehicleId)

            -- Show success UI
            lib.showTextUI(modLabel .. ' installed successfully', {
                position = "top-center",
                icon = 'check-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#48BB78',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
            TriggerEvent('lowercar', vehicle)
        else
            -- On cancellation of the progress bar
            -- Show cancellation UI
            lib.showTextUI(modLabel .. ' installation canceled', {
                position = "top-center",
                icon = 'times-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#e53e3e',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
        end

        -- Lower the car after progress bar is done or canceled
        TriggerEvent('lowercar', vehicle)
    else
        local dialogContent = "**You must be near the vehicle's engine to install an engine modification!**"
        local alertData = {
            header = "Engine Modification Error",
            content = dialogContent,
            size = 'sm',
            centered = true
        }
        local alert = lib.alertDialog(alertData)
        print(alert)
    end
end

-- Function to modify suspension
function addCoiloverSuspension(vehicleId, suspensionType)
    local playerPed = PlayerPedId()
    local vehicle = GetClosestVehicleToPlayer(playerPed, 5.0)
    if vehicle ~= 0 then
        local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerEvent('raisecar', vehicle) -- Pass the vehicle entity when triggering the event
        Citizen.Wait(1000)
        RemoveVehicleWheels(vehicle)
        local modType = suspensionType - 1 -- Suspension mods are typically 0-3 for OEM, Sport, and Race
        local modLabel = (suspensionType == 1 and 'OEM' or suspensionType == 2 and 'Sport' or suspensionType == 3 and 'Race') .. ' Coilovers'

        -- Show the progress bar
        local success = lib.progressBar({
            duration = 25000, -- 25 seconds
            label = 'Installing ' .. modLabel .. '...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle'
            },
            prop = {
                model = `prop_ld_flow_bottle`, -- Adjust the prop model as needed
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(0.0, 0.0, -1.5)
            },
        })

        if success then
            -- On successful completion of the progress bar
            SetVehicleMod(vehicle, 15, modType) -- Set the suspension modification
            updateVehicleData(vehicleId)

            -- Show success UI
            lib.showTextUI(modLabel .. ' installed successfully', {
                position = "top-center",
                icon = 'check-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#48BB78',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()

            TriggerEvent('lowercar', vehicle)
        else
            -- On cancellation of the progress bar
            -- Show cancellation UI
            lib.showTextUI(modLabel .. ' installation canceled', {
                position = "top-center",
                icon = 'times-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#e53e3e',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
        end

        -- Lower the car after progress bar is done or canceled
        TriggerEvent('lowercar', vehicle)

    else
        local dialogContent = "**You must be near the vehicle's suspension to install coilovers!**"
        local alertData = {
            header = "Suspension Installation Error",
            content = dialogContent,
            size = 'sm',
            centered = true
        }
        local alert = lib.alertDialog(alertData)
        print(alert)
    end
end

-- Function to modify transmission
function addTransmissionMod(vehicleId, transmissionType)
    local playerPed = PlayerPedId()
    local vehicle = GetClosestVehicleToPlayer(playerPed, 5.0)
    if vehicle ~= 0 then
        local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerEvent('raisecar', vehicle) -- Pass the vehicle entity when triggering the event
        Citizen.Wait(1000)

        local modType = transmissionType - 1 -- Transmission mods are typically 0-2 for OEM, Sport, and Race
        local modLabel = (transmissionType == 1 and 'OEM' or transmissionType == 2 and 'Sport' or 'Race') .. ' Transmission'

        -- Show the progress bar
        local success = lib.progressBar({
            duration = 25000, -- 25 seconds
            label = 'Installing ' .. modLabel .. '...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle'
            },
            prop = {
                model = `prop_ld_flow_bottle`, -- Adjust the prop model as needed
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(0.0, 0.0, -1.5)
            },
        })

        if success then
            -- On successful completion of the progress bar
            SetVehicleMod(vehicle, 13, modType) -- Set the transmission modification
            updateVehicleData(vehicleId)

            -- Show success UI
            lib.showTextUI(modLabel .. ' installed successfully', {
                position = "top-center",
                icon = 'check-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#48BB78',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
            TriggerEvent('lowercar', vehicle)
        else
            -- On cancellation of the progress bar
            -- Show cancellation UI
            lib.showTextUI(modLabel .. ' installation canceled', {
                position = "top-center",
                icon = 'times-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#e53e3e',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
        end

        -- Lower the car after progress bar is done or canceled
        TriggerEvent('lowercar', vehicle)
    else
        local dialogContent = "**You must be near the vehicle's transmission to install a transmission mod!**"
        local alertData = {
            header = "Transmission Installation Error",
            content = dialogContent,
            size = 'sm',
            centered = true
        }
        local alert = lib.alertDialog(alertData)
        print(alert)
    end
end

-- Function to remove a door associated with a specific bone
function removeDoor(data)
    local vehicleId = data.entity
    local boneName = data.boneName

    local vehicle = NetworkGetEntityFromNetworkId(vehicleId)

    -- Check if the vehicle exists and if the bone name is valid
    if DoesEntityExist(vehicle) and bones[boneName] then
        local doorIndex = bones[boneName]

        -- Check if the door exists
        if DoesVehicleHaveDoor(vehicle, doorIndex) then
            -- Break the selected door
            SetVehicleDoorBroken(vehicle, doorIndex, true)
            print("Removed door associated with bone " .. boneName .. " from vehicle " .. vehicleId)
        else
            print("Door associated with bone " .. boneName .. " does not exist on vehicle " .. vehicleId)
        end
    else
        print("Invalid vehicle or bone name")
    end
end

-- Function to replace a door
function replaceDoor(data)
    local vehicleId = data.entity
    local doorIndex = data.doorIndex

    local vehicle = NetworkGetEntityFromNetworkId(vehicleId)

    -- Check if the vehicle exists and if the door index is valid
    if DoesEntityExist(vehicle) and doorIndex >= 0 and doorIndex <= 5 then
        -- Check if the door is missing or damaged
        if IsVehicleDoorDamaged(vehicle, doorIndex) or not DoesVehicleHaveDoor(vehicle, doorIndex) then
            -- Fix the vehicle first
            SetVehicleFixed(vehicle)

            -- Restore the original state of the door
            SetVehicleDoorBroken(vehicle, doorIndex, true)
            print("Replaced door " .. doorIndex .. " on vehicle " .. vehicleId)
        else
            print("Door " .. doorIndex .. " is not missing or damaged on vehicle " .. vehicleId)
        end
    else
        print("Invalid vehicle or door index")
    end
end

-- Function to apply window tint
function applyWindowTint(vehicle, tintLevel)
    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        SetVehicleWindowTint(vehicle, tintLevel)
        print("Window tint applied successfully.")
    else
        print("Invalid vehicle.")
    end
end

-- Function to install brakes with a progress bar and feedback
function installBrakes(vehicleId, brakeType)
    local playerPed = PlayerPedId()
    local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0)
    
    if vehicle ~= 0 then
        local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerEvent('raisecar', vehicle) -- Pass the vehicle entity when triggering the event
        Citizen.Wait(1000)

        local modType, modLabel
        if brakeType == 'oem' then
            modType = 1
            modLabel = 'OEM Brakes'
        elseif brakeType == 'premium' then
            modType = 2
            modLabel = 'Premium Brakes'
        elseif brakeType == 'sport' then
            modType = 3
            modLabel = 'Sport Brakes'
        elseif brakeType == 'race' then
            modType = 4
            modLabel = 'Race Brakes'
        else
            print("Unknown brake type:", brakeType)
            return
        end

        -- Show the progress bar
        local success = lib.progressBar({
            duration = 25000, -- 25 seconds
            label = 'Installing ' .. modLabel .. '...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle'
            },
            prop = {
                model = `prop_ld_flow_bottle`, -- Adjust the prop model as needed
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(0.0, 0.0, -1.5)
            },
        })

        if success then
            -- On successful completion of the progress bar
            applyBrakeModification(vehicleId, modType)
            updateVehicleData(vehicleId)

            -- Show success UI
            lib.showTextUI(modLabel .. ' installed successfully', {
                position = "top-center",
                icon = 'check-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#48BB78',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
            TriggerEvent('lowercar', vehicle)
        else
            -- On cancellation of the progress bar
            -- Show cancellation UI
            lib.showTextUI(modLabel .. ' installation canceled', {
                position = "top-center",
                icon = 'times-circle',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#e53e3e',
                    color = 'white'
                }
            })
            Citizen.Wait(5000)
            lib.hideTextUI()
        end

        -- Lower the car after progress bar is done or canceled
        TriggerEvent('lowercar', vehicle)
    else
        local dialogContent = "**You must be near the vehicle's brakes to install a brake mod!**"
        local alertData = {
            header = "Brake Installation Error",
            content = dialogContent,
            size = 'sm',
            centered = true
        }
        local alert = lib.alertDialog(alertData)
        print(alert)
    end
end



-- Event handler to replace a door using ox_target
RegisterNetEvent("ox_target:replaceDoor")
AddEventHandler("ox_target:replaceDoor", function(data)
    local vehicleId = data.entity
    for _, doorIndex in ipairs(data.doorIndex) do
        replaceDoor({ entity = vehicleId, doorIndex = doorIndex })
    end
end)

-- Event handler to install a door using ox_target
RegisterNetEvent("ox_target:installDoor")
AddEventHandler("ox_target:installDoor", function(data)
    local vehicleId = data.entity
    for _, doorIndex in ipairs(data.doorIndex) do
        installDoor({ entity = vehicleId, doorIndex = doorIndex })
    end
end)

-- Event handler to add turbo using ox_target
RegisterNetEvent("ox_target:addTurbo")
AddEventHandler("ox_target:addTurbo", function(data)
    local vehicleId = data.entity
    addTurbo(vehicleId)
end)
-- Event handler to add engine modification using ox_target
RegisterNetEvent("ox_target:addEngineMod")
AddEventHandler("ox_target:addEngineMod", function(data, stage)
    local vehicleId = data.entity
    addEngineMod(vehicleId, stage)
end)

-- Event handler to add coilover suspension using ox_target
RegisterNetEvent("ox_target:addCoiloverSuspension")
AddEventHandler("ox_target:addCoiloverSuspension", function(data, suspensionType)
    local vehicleId = data.entity
    addCoiloverSuspension(vehicleId, suspensionType)
end)

-- Event handler to add transmission modification using ox_target
RegisterNetEvent("ox_target:addTransmissionMod")
AddEventHandler("ox_target:addTransmissionMod", function(data, transmissionType)
    local vehicleId = data.entity
    addTransmissionMod(vehicleId, transmissionType)
end)

-- Event handler to apply window tint using ox_target
RegisterNetEvent("ox_target:applyWindowTint")
AddEventHandler("ox_target:applyWindowTint", function(data)
    local vehicleId = data.entity
    local tintLevel = data.tint
    applyWindowTint(vehicleId, tintLevel)
end)

-- Event handler to install brakes
RegisterNetEvent("ox_target:installBrakes")
AddEventHandler("ox_target:installBrakes", function(vehicleId, brakeType)
    installBrakes(vehicleId, brakeType)
end)



-- Function to apply brake modification to the vehicle
function applyBrakeModification(vehicleId, brakeLevel)
    -- Assuming you have a function or a way to apply the brake modification to the vehicle
    -- This could involve setting vehicle handling data, changing visual components, etc.
    local vehicle = NetworkGetEntityFromNetworkId(vehicleId)
    if DoesEntityExist(vehicle) then
        SetVehicleModKit(vehicle, 0) -- Set mod kit to 0 (default)
        SetVehicleMod(vehicle, 12, brakeLevel, false) -- 12 is typically the mod type for brakes
        print("Applied brake modification level", brakeLevel, "to vehicle with ID:", vehicleId)
    else
        print("Vehicle does not exist for ID:", vehicleId)
    end
end

-- Event handler to raise the car
RegisterNetEvent('raisecar')
AddEventHandler('raisecar', function(vehicle)
    local ped = PlayerPedId() -- Retrieve the player's ped
    local veh = vehicle
    -- Debug: Print vehicle and player information
    print("Vehicle:", veh)
    print("Player Ped:", ped)

    if IsEntityAVehicle(veh) then
        print("Raise conditions met")
        isRaised = true
        raisedCar = veh
        vehpos = GetEntityCoords(veh)

        -- Send a notification to server.lua for raising the car
        local playerName = GetPlayerName(PlayerId())
        local model = 'xs_prop_x18_axel_stand_01a'

        FreezeEntityPosition(veh, true)
        vehpos = GetEntityCoords(veh)
        RequestModel(model)

        flWheelStand = CreateObject(GetHashKey(model), vehpos.x, vehpos.y, vehpos.z - 0.5, true, true, true)
        frWheelStand = CreateObject(GetHashKey(model), vehpos.x, vehpos.y, vehpos.z - 0.5, true, true, true)
        rlWheelStand = CreateObject(GetHashKey(model), vehpos.x, vehpos.y, vehpos.z - 0.5, true, true, true)
        rrWheelStand = CreateObject(GetHashKey(model), vehpos.x, vehpos.y, vehpos.z - 0.5, true, true, true)

        AttachEntityToEntity(flWheelStand, veh, 0, 0.5, 1.0, -0.8, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
        AttachEntityToEntity(frWheelStand, veh, 0, -0.5, 1.0, -0.8, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
        AttachEntityToEntity(rlWheelStand, veh, 0, 0.5, -1.0, -0.8, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
        AttachEntityToEntity(rrWheelStand, veh, 0, -0.5, -1.0, -0.8, 0.0, 0.0, 0.0, false, false, false, false, 0, true)

        -- Adjust the vehicle's Z-coordinate to visually raise it
        local raisedZ = vehpos.z + 0.19 -- Adjust the value to control the height
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, raisedZ, true, true, true)

        -- Debug: Print vehicle coordinates after raising
        local newVehPos = GetEntityCoords(veh)
        print("New Vehicle Position:", newVehPos)

    else
        print("Unable to raise the car. Conditions not met.")
    end

end)

-- Function to lower the car, stop animation, and repair the vehicle
RegisterNetEvent('lowercar')
AddEventHandler('lowercar', function(playerPed)
    local veh = raisedCar

    if isRaised then
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z + 0.175, true, true, true)

        Citizen.Wait(1000)
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z + 0.15, true, true, true)

        Citizen.Wait(1000)
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z + 0.125, true, true, true)

        Citizen.Wait(1000)
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z + 0.1, true, true, true)

        Citizen.Wait(1000)
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z + 0.075, true, true, true)

        Citizen.Wait(1000)
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z + 0.05, true, true, true)

        Citizen.Wait(1000)
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z + 0.025, true, true, true)
        Citizen.Wait(1000)
        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z + 0.01, true, true, true)

        SetEntityCoordsNoOffset(veh, vehpos.x, vehpos.y, vehpos.z, true, true, true)
        FreezeEntityPosition(veh, false)

        DeleteObject(flWheelStand)
        DeleteObject(frWheelStand)
        DeleteObject(rlWheelStand)
        DeleteObject(rrWheelStand)

        isRaised = false

        raisedCar = nil
        vehpos = nil
        flWheelStand = nil
        frWheelStand = nil
        rlWheelStand = nil
        rrWheelStand = nil

        -- Now that the car is lowered and stands are deleted, replace the wheels
        ReplaceVehicleWheels(veh)
    end
end)

-- Function to remove all wheels from the vehicle
function RemoveVehicleWheels(vehicle)
    local numWheels = GetVehicleNumberOfWheels(vehicle)
    for i = 0, numWheels - 1 do
        BreakOffVehicleWheel(vehicle, i, false, true, false, false)
    end
end

-- Function to replace all wheels on the vehicle
function ReplaceVehicleWheels(vehicle)
    print("Replacing vehicle wheels...")
    SetVehicleFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true)
    local numWheels = GetVehicleNumberOfWheels(vehicle)
    for i = 0, numWheels - 1 do
        SetVehicleTyreFixed(vehicle, i)
    end
    print("Vehicle wheels replaced.")
end

-- Initialize the script
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        -- Handle other events or tasks here if needed
    end
end)

