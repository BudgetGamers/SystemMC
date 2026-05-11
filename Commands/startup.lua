local currentPath = shell.path()
local commandsDir = "/Commands"
local commandsDirNoSlash = "Commands"

-- Check if already in path
for path in string.gmatch(currentPath, "[^:]+") do
    if path == commandsDir or path == commandsDirNoSlash then
        print("Commands directory is already in the path.")
        return
    end
end

shell.setPath(currentPath .. ":" .. commandsDir)
print("Added " .. commandsDir .. " to shell path.")
print("You can now use commands like 'sysinfo', 'netopen', etc. from anywhere.")
