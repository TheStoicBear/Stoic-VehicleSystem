local mileage = {} -- Mileage for each vehicle (indexed by license plate)
local oilLife = {} -- Oil life for each vehicle (indexed by license plate)
local lastTick = 0 -- Last tick time
local lastPosition = {} -- Last recorded position for each vehicle (indexed by license plate)
local lastSpeed = {} -- Last recorded speed for each vehicle (indexed by license plate)
local debug = true -- Toggle debug information

-- MySQL Configuration (Assuming you have MySQL-Async)

function Vdist(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Event handler for saving mileage to the database
RegisterServerEvent("saveMileageToDatabase")
AddEventHandler("saveMileageToDatabase", function(vehiclePlate, miles)
    saveMileageToDatabase(vehiclePlate, miles)
end)

-- Event handler to update vehicle state and calculate mileage
RegisterServerEvent("updateVehicleState")
AddEventHandler("updateVehicleState", function(vehiclePlate, currentPosition, speed)
    local currentTime = GetGameTimer()
    local deltaTime = (currentTime - lastTick) / 1000 -- Time elapsed since the last tick (in seconds)
    lastTick = currentTime
    
    local lastPos = lastPosition[vehiclePlate] or currentPosition
    local distance = Vdist(lastPos.x, lastPos.y, lastPos.z, currentPosition.x, currentPosition.y, currentPosition.z) -- Distance traveled since the last tick (in meters)
    local acceleration = (speed - (lastSpeed[vehiclePlate] or speed)) / deltaTime -- Acceleration (in mph/s)
    local milesPerTick = (speed + 0.5 * acceleration * deltaTime) / 3600 -- Distance traveled in the current tick (in miles)
    local miles = mileage[vehiclePlate] or 0
    mileage[vehiclePlate] = miles + milesPerTick
    lastPosition[vehiclePlate] = currentPosition
    lastSpeed[vehiclePlate] = speed
    
    -- Update mileage in MySQL database
    saveMileageToDatabase(vehiclePlate, mileage[vehiclePlate])
end)

-- Function to save mileage for a specific vehicle to MySQL storage
function saveMileageToDatabase(vehiclePlate, miles)
    local query = [[
        INSERT INTO oil_life (vehicle_plate, mileage)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE mileage = VALUES(mileage)
    ]]
    local parameters = {vehiclePlate, tonumber(miles) or 0}

    MySQL.Async.execute(query, parameters, function(affectedRows)
        if affectedRows > 0 then
            print("Mileage updated successfully for vehiclePlate:", vehiclePlate)
        else
            print("Failed to update mileage for vehiclePlate:", vehiclePlate)
        end
    end, function(errorMessage)
        print("Failed to execute MySQL query:", errorMessage)
        print("SQL Query:", query)
        print("Parameters:", json.encode(parameters))
    end)
end


-- Event handler for retrieving mileage data from the database
RegisterServerEvent("getMileage")
AddEventHandler("getMileage", function(vehiclePlate)
    local miles = mileage[vehiclePlate] or 0
    TriggerClientEvent("updateOdometer", source, miles)
end)

-- Event handler for updating oil life and mileage data
RegisterServerEvent("updateOilLifeAndMileage")
AddEventHandler("updateOilLifeAndMileage", function(vehiclePlate, miles)
    mileage[vehiclePlate] = miles
    saveMileageToDatabase(vehiclePlate, miles)
end)

-- Event handler for fetching initial vehicle data
RegisterServerEvent("fetchVehicleData")
AddEventHandler("fetchVehicleData", function()
    local query = [[
        SELECT * FROM oil_life
    ]]

    MySQL.Async.fetchAll(query, {}, function(rows)
        if rows then
            for _, row in ipairs(rows) do
                local vehiclePlate = row.vehicle_plate
                local miles = tonumber(row.mileage)
                local oil = tonumber(row.oil_life)

                if vehiclePlate and miles then
                    mileage[vehiclePlate] = miles
                    oilLife[vehiclePlate] = oil
                end
            end
            print("Vehicle data loaded successfully.")
        else
            print("Failed to fetch vehicle data from database.")
        end
    end)
end)


-- Initialize vehicle data on server start
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerEvent("fetchVehicleData")
    end
end)

-- Handle resource stop to save any remaining mileage
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for vehiclePlate, miles in pairs(mileage) do
            saveMileageToDatabase(vehiclePlate, miles)
        end
    end
end)

