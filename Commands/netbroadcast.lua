local args = {...}
if #args < 1 then
    print("Usage: netbroadcast <message> [protocol]")
    return
end

local message = args[1]
local protocol = args[2]

rednet.broadcast(message, protocol)
if protocol then
    print("Message broadcasted on protocol '" .. protocol .. "'.")
else
    print("Message broadcasted.")
end
