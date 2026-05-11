-- Commands Library Installer
local repoBaseUrl = "https://raw.githubusercontent.com/BudgetGamers/SystemMC/main/Commands/"
local installDir = "/Commands"

local files = {
    "startup.lua",
    "netopen.lua",
    "netping.lua",
    "netsend.lua",
    "netlisten.lua",
    "netbroadcast.lua",
    "sysinfo.lua"
}

-- Basic minifier that removes leading/trailing whitespace, 
-- empty lines, and full-line comments. (Safe for strings)
local function minify(code)
    local minifiedLines = {}
    for line in string.gmatch(code, "([^\n]*)\n?") do
        -- Trim whitespace
        local trimmed = string.match(line, "^%s*(.-)%s*$")
        -- Keep line if it's not empty and not a full-line comment
        if trimmed ~= "" and not string.match(trimmed, "^%-%-") then
            table.insert(minifiedLines, trimmed)
        end
    end
    return table.concat(minifiedLines, "\n")
end

if not fs.exists(installDir) then
    fs.makeDir(installDir)
end

print("Installing Commands Library...")

for _, file in ipairs(files) do
    local url = repoBaseUrl .. file
    print("Downloading " .. file .. "...")
    local response = http.get(url)
    
    if response then
        local content = response.readAll()
        response.close()
        
        local minifiedContent = minify(content)
        
        local outFileName = string.gsub(file, "%.lua$", "")
        local filePath = fs.combine(installDir, outFileName)
        local f = fs.open(filePath, "w")
        f.write(minifiedContent)
        f.close()
        print("  -> Saved and minified as " .. outFileName)
    else
        printError("  -> Failed to download " .. file)
    end
end

print("Installation complete! Run '/Commands/startup' to add to path or call it from your main startup file.")
