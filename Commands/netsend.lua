local args = {...}
if #args < 2 then
    print("Usage: netsend <computer_id> <message> [protocol]")
    return
end

local targetId = tonumber(args[1])
if not targetId then
    printError("Target ID must be a number.")
    return
end

local message = args[2]
local protocol = args[3]

rednet.send(targetId, message, protocol)
if protocol then
    print("Message sent to " .. targetId .. " on protocol '" .. protocol .. "'.")
else
    print("Message sent to " .. targetId .. ".")
end
