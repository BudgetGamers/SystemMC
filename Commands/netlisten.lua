local args = {...}
local filterProtocol = args[1]

print("Listening for Rednet messages...")
if filterProtocol then
    print("Filtering on protocol: " .. filterProtocol)
end
print("Press Ctrl+T to terminate.")

while true do
    local senderId, message, protocol = rednet.receive()
    
    if not filterProtocol or protocol == filterProtocol then
        local protoStr = protocol and (" [" .. protocol .. "]") or ""
        print("\nReceived from " .. senderId .. protoStr .. ":")
        
        if type(message) == "table" then
            print(textutils.serialize(message))
        else
            print(tostring(message))
        end
        
        -- Auto-reply to custom ping
        if protocol == "netping" and message == "ping" then
            rednet.send(senderId, "pong", "netping")
        end
    end
end
