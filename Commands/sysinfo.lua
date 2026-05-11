print("=== System Info ===")
print("Computer ID : " .. os.getComputerID())
local label = os.getComputerLabel()
print("Label       : " .. (label and label or "None"))

local day = os.day()
local time = os.time()
local formattedTime = textutils.formatTime(time, false)
print("Time        : Day " .. day .. ", " .. formattedTime)

print("\n--- Peripherals ---")
local peripherals = peripheral.getNames()
if #peripherals == 0 then
    print("No attached peripherals.")
else
    for _, name in ipairs(peripherals) do
        local pType = peripheral.getType(name)
        print(name .. " (" .. pType .. ")")
    end
end
