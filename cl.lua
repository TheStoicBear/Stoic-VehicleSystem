local mileage = {} -- Mileage for each vehicle (indexed by license plate)
local oilLife = {} -- Oil life for each vehicle (indexed by license plate)

local lastTick = 0 -- Last tick time
local lastPosition = {} -- Last recorded position for each vehicle (indexed by license plate)
local lastSpeed = {} -- Last recorded speed for each vehicle (indexed by license plate)
local inVehicle = false -- Flag to indicate if the player is in a vehicle
local lastVehicleId = nil -- Store the last vehicle ID
local display = false -- Flag to control NUI display
local debug = true -- Toggle debug information

-- Function to get the license plate of the current vehicle
function GetVehicleLicensePlate(vehicle)
    return GetVehicleNumberPlateText(vehicle)
end

-- NUI Callbacks
RegisterNUICallback('close', function(data)
    if debug then print("NUICallback 'close' triggered") end
    SetDisplay(false)
    SetNuiFocus(false, false)
end)

RegisterNUICallback('open', function(data)
    if debug then print("NUICallback 'open' triggered") end
    SetDisplay(true)
    SetNuiFocus(false, false)
end)

-- Function to set NUI display
function SetDisplay(bool)
    if debug then print("SetDisplay called with", bool) end
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool
    })
end

-- Function to update the odometer and oil life UI
function updateOdometer(vehiclePlate)
    if debug then 
        print("updateOdometer called for vehiclePlate", vehiclePlate) 
        print("Current mileage:", mileage[vehiclePlate])
        print("Current oil life:", oilLife[vehiclePlate])
    end
    local miles = mileage[vehiclePlate] or 0
    local oil = oilLife[vehiclePlate] or 100
    SendNUIMessage({
        type = "updateOdometer",
        mileage = math.floor(miles),
        oilLife = math.floor(oil)
    })
end

-- Main loop to handle vehicle state and mileage calculation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(50) -- Adjust the interval as needed

        local currentTime = GetGameTimer()
        local deltaTime = (currentTime - lastTick) / 1000 -- Time elapsed since the last tick (in seconds)
        lastTick = currentTime

        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle ~= 0 then
            if debug then print("Player is in a vehicle") end

            local vehiclePlate = GetVehicleLicensePlate(vehicle)
            lastVehicleId = NetworkGetNetworkIdFromEntity(vehicle)

            -- Update oil life if not already known
            if not oilLife[vehiclePlate] then
                oilLife[vehiclePlate] = 100 -- Default to full oil life
            end

            -- Check if mileage exists in the database for this vehicle
            if not mileage[vehiclePlate] then
                if debug then print("Fetching mileage for vehiclePlate", vehiclePlate) end
                TriggerServerEvent("getMileage", vehiclePlate)
            end

            local currentPosition = GetEntityCoords(vehicle)
            local lastPos = lastPosition[vehiclePlate] or currentPosition
            local distance = Vdist(lastPos.x, lastPos.y, lastPos.z, currentPosition.x, currentPosition.y, currentPosition.z) -- Distance traveled since the last tick (in meters)
            local speed = GetEntitySpeed(vehicle) * 2.23694 -- Current speed (in mph)
            local acceleration = (speed - (lastSpeed[vehiclePlate] or speed)) / deltaTime -- Acceleration (in mph/s)
            local milesPerTick = (speed + 0.5 * acceleration * deltaTime) / 3600 -- Distance traveled in the current tick (in miles)
            local miles = mileage[vehiclePlate] or 0
            mileage[vehiclePlate] = miles + milesPerTick
            lastPosition[vehiclePlate] = currentPosition
            lastSpeed[vehiclePlate] = speed
            updateOdometer(vehiclePlate)
            inVehicle = true
        else
            if inVehicle and lastVehicleId then
                if debug then print("Player exited the vehicle") end
                local vehiclePlate = GetVehicleLicensePlate(NetworkGetEntityFromNetworkId(lastVehicleId))
                TriggerServerEvent("saveMileageToDatabase", vehiclePlate, mileage[vehiclePlate])
                inVehicle = false
                SetDisplay(false)
                display = false
                SetNuiFocus(false, false)
            end
        end

        if inVehicle and not display then
            if debug then print("Displaying UI") end
            SetDisplay(true)
            display = true
            SetNuiFocus(false, false)
        elseif not inVehicle and display then
            if debug then print("Hiding UI") end
            SetDisplay(false)
            display = false
            SetNuiFocus(false, false)
        end
    end
end)

-- Event handler for receiving updated mileage data
RegisterNetEvent("receiveMileage")
AddEventHandler("receiveMileage", function(newMileage)
    if debug then print("receiveMileage event triggered") end
    for vehiclePlate, miles in pairs(newMileage) do
        mileage[vehiclePlate] = miles
    end
end)
-- Event handler for updating oil life and mileage data
RegisterNetEvent("updateOilLifeAndMileage")
AddEventHandler("updateOilLifeAndMileage", function(vehiclePlate, miles, oil)
    mileage[vehiclePlate] = miles
    oilLife[vehiclePlate] = oil
    updateOdometer(vehiclePlate)
end)


-- Initial callback to fetch mileage and oil life for all vehicles
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Delay to ensure all scripts are loaded
    TriggerServerEvent("fetchVehicleData")
end)

RegisterCommand("savemileage", function(source, args, rawCommand)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        local vehiclePlate = GetVehicleLicensePlate(vehicle)
        local miles = mileage[vehiclePlate] or 0
        TriggerServerEvent("saveMileageToDatabase", vehiclePlate, miles)
        print("Saving mileage for vehicle plate", vehiclePlate)
    else
        print("You are not in a vehicle.")
    end
end, false)
