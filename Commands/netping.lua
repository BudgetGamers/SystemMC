local args = {...}
if #args < 1 then
    print("Usage: netping <computer_id>")
    return
end

local targetId = tonumber(args[1])
if not targetId then
    printError("Target ID must be a number.")
    return
end

-- Ensure rednet is open on at least one modem
local isOpen = false
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "modem" and rednet.isOpen(name) then
        isOpen = true
        break
    end
end

if not isOpen then
    printError("No modems are open for Rednet. Run 'netopen' first.")
    return
end

print("Pinging computer " .. targetId .. "...")
local protocol = "netping"
rednet.send(targetId, "ping", protocol)

local id, message = rednet.receive(protocol, 3) -- 3 second timeout
if id == targetId and message == "pong" then
    print("Reply received from " .. id .. ".")
else
    print("Request timed out.")
end
