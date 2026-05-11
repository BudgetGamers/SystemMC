local modems = {peripheral.find("modem")}
if #modems == 0 then
    printError("No modems attached.")
    return
end

local opened = 0
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "modem" then
        if not rednet.isOpen(name) then
            rednet.open(name)
            opened = opened + 1
            print("Opened modem on " .. name)
        else
            print("Modem on " .. name .. " is already open.")
        end
    end
end

if opened > 0 then
    print("Successfully opened " .. opened .. " new modem(s) for Rednet.")
end
