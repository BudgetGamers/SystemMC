-- [[ SystemMC OS Installer v1.0 ]]
-- Author: Apollo
-- A premium TUI installer for ComputerCraft Floppy Disks.

local files = {
    -- Root Bootloader
    ["startup.lua"] = [[
-- SystemMC Bootloader
local programPath = shell.getRunningProgram()
local root = "/" .. fs.getDir(programPath)
local kernelPath = fs.combine(root, "scripts/systemMC/kernel.lua")
local logDir = fs.combine(root, "logs")
local recentLog = fs.combine(logDir, "recent_system.log")
local oldLog = fs.combine(logDir, "old_system.log")

-- 1. Cycle Logs (Recent -> Old)
if not fs.exists(logDir) then fs.makeDir(logDir) end
if fs.exists(recentLog) then
    if fs.exists(oldLog) then fs.delete(oldLog) end
    fs.move(recentLog, oldLog)
end

local function log(msg)
    local f = fs.open(recentLog, "a")
    f.writeLine("[" .. os.date() .. "] [BOOT] " .. msg)
    f.close()
end

log("SystemMC Boot Initialized")
log("Root detected: " .. root)

local systemPaths = {
    "libs/rom", "libs/local", "scripts/systemMC", 
    "scripts/apps", "scripts/games", "scripts/etc"
}

local newPaths = {}
for _, p in ipairs(systemPaths) do
    local full = fs.combine(root, p)
    if not full:match("^/") then full = "/" .. full end
    
    shell.setPath(shell.path() .. ":" .. full) -- Append to shell path
    table.insert(newPaths, full .. "/?.lua")
    table.insert(newPaths, full .. "/?/init.lua")
    log("Registered Path: " .. full)
end

-- Prepend our new paths to the global package path
package.path = table.concat(newPaths, ";") .. ";" .. package.path

term.clear()
term.setCursorPos(1,1)
print("SystemMC OS Loading...")
sleep(0.5)

if fs.exists(kernelPath) then
    log("Executing Kernel: " .. kernelPath)
    shell.run(kernelPath, root)
else
    log("CRITICAL ERROR: Kernel not found at " .. kernelPath)
    print("Error: Kernel not found!")
end
]],

    -- GUI Library
    ["libs/rom/gui.lua"] = [[
local logger = require("logger")

local function drawBox(win, x, y, w, h, title, bg, fg)
    win.setBackgroundColor(bg or colors.gray)
    win.setTextColor(fg or colors.white)
    win.clear()
    -- No border needed for full-screen, but title helps
    win.setCursorPos(1, 1)
    win.setBackgroundColor(colors.blue)
    win.write(" " .. title .. string.rep(" ", w - #title - 1))
end

local function menuBar(w, isMenuOpen, pocketMode)
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.blue)
    term.clearLine()
    
    -- Start Button
    term.setBackgroundColor(isMenuOpen and colors.lightBlue or colors.blue)
    term.setTextColor(colors.white)
    term.write(" [ START ] ")
    
    -- Centered Clock with Pocket Mode logic
    local dateStr = os.date("%Y-%m-%d %H:%M")
    if pocketMode then
        -- Remove first half of year (2026 -> 26) and leading zeros (05-03 -> 5-3)
        dateStr = os.date("%y-%m-%d %H:%M")
        dateStr = dateStr:gsub("-0", "-")
    end
    
    local xPos = math.floor(w/2 - #dateStr/2 + 1)
    if pocketMode then xPos = xPos + 4 end -- Move slightly right
    
    term.setCursorPos(xPos, 1)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.write(dateStr)
end

local function drawStartMenu(x, y, selected)
    local apps = {"1. Explorer  ", "2. Settings  ", "3. Disk Usage", "4. About      ", "5. Shutdown   "}
    for i, app in ipairs(apps) do
        term.setCursorPos(x, y + i)
        if i == selected then
            term.setBackgroundColor(colors.lightBlue)
            term.setTextColor(colors.white)
        else
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.white)
        end
        term.write(" " .. app .. " ")
    end
end

return { drawBox = drawBox, menuBar = menuBar, drawStartMenu = drawStartMenu }
]],

    -- Logger Library
    ["libs/rom/logger.lua"] = [[
local root = ...
local logPath = "/logs/recent_system.log"

local function setRoot(newRoot)
    root = newRoot
    logPath = fs.combine(root, "logs/recent_system.log")
end

local function log(msg, tag)
    if not root then return end
    tag = tag or "INFO"
    local f = fs.open(logPath, "a")
    if f then
        f.writeLine("[" .. os.date() .. "] [" .. tag .. "] " .. msg)
        f.close()
    end
end

return { log = log, setRoot = setRoot }
]],

    -- Core Libraries
    ["libs/rom/utils.lua"] = [[
local function center(text, y, color)
    local w, h = term.getSize()
    term.setCursorPos(math.floor(w/2 - #text/2 + 1), y)
    if color then term.setTextColor(color) end
    write(text)
end

return { center = center }
]],

    -- SystemMC Kernel (Desktop Manager)
    ["scripts/systemMC/kernel.lua"] = [[
local root = ...

-- Ensure package.path includes our libs even if run directly
if root then
    local libPath = fs.combine(root, "libs/rom")
    if not libPath:match("^/") then libPath = "/" .. libPath end
    package.path = libPath .. "/?.lua;" .. libPath .. "/?/init.lua;" .. package.path
end

local logger = require("logger")
local gui = require("gui")
logger.setRoot(root)

local w, h = term.getSize()
local running = true
local menuOpen = false
local selectedApp = 1
local settings = { pocketMode = false }

local function loadSettings()
    local path = fs.combine(root, "settings.cfg")
    if fs.exists(path) then
        local f = fs.open(path, "r")
        local content = f.readAll()
        f.close()
        for k, v in content:gmatch("([%w_]+)%s*=%s*([%w_]+)") do
            settings[k] = (v == "true")
        end
    end
end

local function drawDesktop()
    loadSettings()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.blue)
    term.clear()
    -- Dark blue grid texture
    for i = 2, h do
        if i % 2 == 0 then
            term.setCursorPos(1, i)
            term.blit(string.rep("\15", w), string.rep("b", w), string.rep("f", w))
        end
    end
    gui.menuBar(w, menuOpen, settings.pocketMode)
    if menuOpen then
        gui.drawStartMenu(1, 1, selectedApp)
    end
end

local function openApp(name, path)
    logger.log("Opening App: " .. name, "OS")
    -- Full screen window (below menu bar)
    local appWin = window.create(term.current(), 1, 2, w, h - 1, true)
    
    local oldTerm = term.redirect(appWin)
    shell.run(path, root)
    term.redirect(oldTerm)
    
    menuOpen = false
    drawDesktop()
end

drawDesktop()
logger.log("Desktop Environment Ready", "OS")

while running do
    local event, key = os.pullEvent("key")
    
    if not menuOpen then
        if key == keys.enter or key == keys.space then
            menuOpen = true
            drawDesktop()
        end
    else
        if key == keys.up then
            selectedApp = selectedApp > 1 and selectedApp - 1 or 5
            drawDesktop()
        elseif key == keys.down then
            selectedApp = selectedApp < 5 and selectedApp + 1 or 1
            drawDesktop()
        elseif key == keys.enter then
            if selectedApp == 1 then
                openApp("Explorer", fs.combine(root, "scripts/apps/explorer.lua"))
            elseif selectedApp == 2 then
                openApp("Settings", fs.combine(root, "scripts/apps/settings.lua"))
            elseif selectedApp == 3 then
                openApp("Usage", fs.combine(root, "scripts/apps/disk_usage.lua"))
            elseif selectedApp == 4 then
                openApp("About", fs.combine(root, "scripts/apps/help.lua"))
            elseif selectedApp == 5 then
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1, 1)
                running = false
            end
        elseif key == keys.backspace or key == keys.left or key == keys.space then
            menuOpen = false
            drawDesktop()
        end
    end
end
]],



    -- File Explorer App
    ["scripts/apps/explorer.lua"] = [[
local root = ...
local currentPath = root
local selected, scroll = 1, 0
local moveSrc = nil

local function pack(dir, output)
    local files = {}
    local function scan(p)
        for _, item in ipairs(fs.list(p)) do
            local full = fs.combine(p, item)
            if fs.isDir(full) then scan(full)
            else
                local f = fs.open(full, "r")
                files[full:sub(#dir + 2)] = f.readAll()
                f.close()
            end
        end
    end
    scan(dir)
    local f = fs.open(output, "w")
    f.write(textutils.serialize(files))
    f.close()
end

local function unpack(file, dir)
    local f = fs.open(file, "r")
    local data = f.readAll()
    f.close()
    local files = textutils.unserialize(data)
    if not files then return end
    for path, content in pairs(files) do
        local full = fs.combine(dir, path)
        local d = fs.getDir(full)
        if not fs.exists(d) then fs.makeDir(d) end
        local out = fs.open(full, "w")
        out.write(content)
        out.close()
    end
end

local function draw(list)
    local w, h = term.getSize()
    local maxVisible = h - 3
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clearLine()
    print(" Explorer: " .. currentPath)
    term.setBackgroundColor(colors.gray)
    
    if selected > scroll + maxVisible then scroll = selected - maxVisible
    elseif selected <= scroll then scroll = selected - 1 end

    for i = 1, maxVisible do
        local idx = i + scroll
        if list[idx] then
            term.setCursorPos(1, 1 + i)
            local item = list[idx]
            local full = fs.combine(currentPath, item)
            local isDir = item == "<<" or fs.isDir(full)
            
            if idx == selected then
                term.setBackgroundColor(colors.lightBlue)
                term.setTextColor(colors.white)
            elseif moveSrc == full then
                term.setBackgroundColor(colors.red)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.white)
            end
            
            local prefix = isDir and "[DIR] " or "      "
            term.write(" " .. prefix .. item .. string.rep(" ", w - #item - 7))
        end
    end
    term.setCursorPos(1, h)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" H:Help  Q:Quit")
end

local function showHelp()
    local w, h = term.getSize()
    local helpWin = window.create(term.current(), math.floor(w/2-10), math.floor(h/2-6), 21, 11)
    helpWin.setBackgroundColor(colors.white)
    helpWin.setTextColor(colors.black)
    helpWin.clear()
    local function writeAt(x, y, txt) helpWin.setCursorPos(x, y) helpWin.write(txt) end
    writeAt(2, 2, "Explorer Hotkeys")
    writeAt(2, 3, string.rep("-", 17))
    writeAt(2, 4, "E: Edit File")
    writeAt(2, 5, "R: Run .lua")
    writeAt(2, 6, "C: Pack Folder")
    writeAt(2, 7, "U: Unpack .tar")
    writeAt(2, 8, "M: Move Item")
    writeAt(2, 9, "K: Drop Item")
    writeAt(2, 11, "Any key to close")
    os.pullEvent("key")
end

while true do
    local list = fs.list(currentPath)
    if currentPath ~= "/" then table.insert(list, 1, "<<") end
    draw(list)
    local e, k = os.pullEvent("key")
    local item = list[selected]
    local fullPath = fs.combine(currentPath, item)
    if k == keys.up then selected = selected > 1 and selected - 1 or #list
    elseif k == keys.down then selected = selected < #list and selected + 1 or 1
    elseif k == keys.enter then
        if item == "<<" then
            currentPath = fs.getDir(currentPath)
            selected, scroll = 1, 0
        elseif fs.isDir(fullPath) then
            currentPath = fullPath
            selected, scroll = 1, 0
        end
    elseif k == keys.e and not fs.isDir(fullPath) then
        shell.run("edit", fullPath)
    elseif k == keys.r and not fs.isDir(fullPath) and item:match("%.lua$") then
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1,1)
        shell.run(fullPath)
        print("\nPress any key...")
        os.pullEvent("key")
    elseif k == keys.c and fs.isDir(fullPath) and item ~= "<<" then
        term.setCursorPos(1, term.getSize())
        term.write("Pack name: ")
        local out = read()
        if out ~= "" then pack(fullPath, fs.combine(currentPath, out .. ".tar")) end
    elseif k == keys.u and not fs.isDir(fullPath) and item:match("%.tar$") then
        term.setCursorPos(1, term.getSize())
        term.write("Folder name: ")
        local out = read()
        if out ~= "" then unpack(fullPath, fs.combine(currentPath, out)) end
    elseif k == keys.m and item ~= "<<" then
        moveSrc = fullPath
    elseif k == keys.k and moveSrc then
        fs.move(moveSrc, fs.combine(currentPath, fs.getName(moveSrc)))
        moveSrc = nil
    elseif k == keys.h then
        showHelp()
    elseif k == keys.q then break end
end
]],

    -- Help App
    ["scripts/apps/help.lua"] = [[
local root = ...
local selected, scroll = 1, 0
local groups = {
    { title = "System Info", expanded = true, items = {
        "SystemMC OS 0.0.5-a",
        "TempleOS-inspired TUI",
        "Alpha Release"
    }},
    { title = "General Hotkeys", expanded = false, items = {
        "Arrows  - Navigate Desktop",
        "Enter   - Open Start Menu",
        "Space   - Open Start Menu",
        "Ctrl+Q  - Close Application"
    }},
    { title = "Explorer Hotkeys", expanded = false, items = {
        "Enter   - Enter Folder / <<",
        "E       - Edit File",
        "R       - Run .lua File",
        "C       - Pack Folder to .tar",
        "U       - Unpack .tar File",
        "M       - Mark for Move",
        "K       - Drop Item Here",
        "H       - Show Keybind Popup"
    }}
}

local function getFlattened()
    local flat = {}
    for i, g in ipairs(groups) do
        table.insert(flat, { type = "group", data = g })
        if g.expanded then
            for _, item in ipairs(g.items) do
                table.insert(flat, { type = "item", data = item })
            end
        end
    end
    return flat
end

local function draw()
    local w, h = term.getSize()
    local maxVisible = h - 3
    local flat = getFlattened()
    
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clearLine()
    print(" Help & Documentation")
    
    if selected > #flat then selected = #flat end
    if selected > scroll + maxVisible then scroll = selected - maxVisible
    elseif selected <= scroll then scroll = selected - 1 end

    for i = 1, maxVisible do
        local idx = i + scroll
        if flat[idx] then
            local entry = flat[idx]
            term.setCursorPos(1, 1 + i)
            if idx == selected then
                term.setBackgroundColor(colors.lightBlue)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.white)
            end
            
            if entry.type == "group" then
                local prefix = entry.data.expanded and "[-] " or "[+] "
                term.write(" " .. prefix .. entry.data.title .. string.rep(" ", w - #entry.data.title - 6))
            else
                term.write("   " .. entry.data .. string.rep(" ", w - #entry.data - 4))
            end
        end
    end
    
    term.setCursorPos(1, h)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" Arrows:Nav  Enter:Toggle  Q:Quit")
end

while true do
    draw()
    local _, k = os.pullEvent("key")
    local flat = getFlattened()
    if k == keys.up then selected = selected > 1 and selected - 1 or #flat
    elseif k == keys.down then selected = selected < #flat and selected + 1 or 1
    elseif k == keys.enter then
        local entry = flat[selected]
        if entry and entry.type == "group" then
            entry.data.expanded = not entry.data.expanded
        end
    elseif k == keys.q then break end
end
]],

    -- Settings App
    ["scripts/apps/settings.lua"] = [[
local root = ...
local settingsPath = fs.combine(root, "settings.cfg")
local selected, scroll = 1, 0
local options = {
    { name = "Pocket Mode", key = "pocketMode", value = false }
}

local function load()
    if fs.exists(settingsPath) then
        local f = fs.open(settingsPath, "r")
        local content = f.readAll()
        f.close()
        for _, opt in ipairs(options) do
            opt.value = content:match(opt.key .. "%s*=%s*true") and true or false
        end
    end
end

local function save()
    local f = fs.open(settingsPath, "w")
    for _, opt in ipairs(options) do
        f.write(opt.key .. " = " .. tostring(opt.value) .. "\n")
    end
    f.close()
end

local function draw()
    local w, h = term.getSize()
    local maxVisible = h - 3
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clearLine()
    print(" Settings")
    
    if selected > scroll + maxVisible then scroll = selected - maxVisible
    elseif selected <= scroll then scroll = selected - 1 end

    for i = 1, maxVisible do
        local idx = i + scroll
        if options[idx] then
            local opt = options[idx]
            term.setCursorPos(1, 1 + i)
            if idx == selected then
                term.setBackgroundColor(colors.lightBlue)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.white)
            end
            local valStr = opt.value and "[ ENABLED ]" or "[ DISABLED ]"
            local padding = w - #opt.name - #valStr - 3
            term.write(" " .. opt.name .. string.rep(" ", padding) .. valStr .. " ")
        end
    end
    
    term.setCursorPos(1, h)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" Enter:Toggle  Q:Save & Quit")
end

load()
while true do
    draw()
    local _, k = os.pullEvent("key")
    if k == keys.up then selected = selected > 1 and selected - 1 or #options
    elseif k == keys.down then selected = selected < #options and selected + 1 or 1
    elseif k == keys.enter then
        options[selected].value = not options[selected].value
    elseif k == keys.q then
        save()
        break
    end
end
]],

    -- Disk Usage App
    ["scripts/apps/disk_usage.lua"] = [[
local root = ...
local scroll = 0

local function getDrives()
    local drives = {{ name = "Internal", path = "/" }}
    local attached = {peripheral.find("drive")}
    local diskUsedTotal = 0
    for _, d in ipairs(attached) do
        local side = peripheral.getName(d)
        local path = disk.getMountPath(side)
        if path then
            local diskUsed = fs.getCapacity(path) - fs.getFreeSpace(path)
            diskUsedTotal = diskUsedTotal + diskUsed
            table.insert(drives, { name = "Disk ("..side..")", path = path })
        end
    end
    drives[1].diskUsedTotal = diskUsedTotal
    return drives
end

while true do
    local drives = getDrives()
    local w, h = term.getSize()
    local maxVisible = math.floor((h - 5) / 3)
    
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clearLine()
    print(" Disk Usage Monitor")
    term.setBackgroundColor(colors.gray)
    print(string.rep("-", w))

    for i = 1, maxVisible do
        local idx = i + scroll
        local d = drives[idx]
        if d then
            local capacity = fs.getCapacity(d.path)
            local free = fs.getFreeSpace(d.path)
            local used = capacity - free
            if d.path == "/" then
                used = math.max(0, used - (d.diskUsedTotal or 0))
                free = capacity - used
            end
            
            local usedKB = math.floor(used / 1024)
            local freeKB = math.floor(free / 1024)
            local totalKB = math.floor(capacity / 1024)
            local pct = capacity > 0 and math.floor((used / capacity) * 100) or 0
            
            local y = 2 + (idx-scroll-1)*3 + 2
            term.setCursorPos(2, y)
            term.setTextColor(colors.white)
            term.write(d.name .. " [" .. d.path .. "]")
            
            term.setCursorPos(w - 10, y)
            term.setBackgroundColor(colors.gray)
            term.write(string.format("%3d%% Used", pct))

            term.setCursorPos(2, y + 1)
            term.setBackgroundColor(colors.black)
            term.write(string.rep(" ", w - 4))
            term.setCursorPos(2, y + 1)
            term.setBackgroundColor(colors.lime)
            term.write(string.rep(" ", math.floor((pct/100) * (w-4))))

            term.setCursorPos(2, y + 2)
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightGray)
            if w > 45 then
                term.write(string.format("Used: %d KB  Free: %d KB  Total: %d KB", usedKB, freeKB, totalKB))
            else
                term.write(string.format("%d/%d KB (%dK free)", usedKB, totalKB, freeKB))
            end
        end
    end

    term.setCursorPos(2, h)
    term.write("Arrows to Scroll, [Q] to Quit")
    
    local e, k = os.pullEvent("key")
    if k == keys.up then
        scroll = math.max(0, scroll - 1)
    elseif k == keys.down then
        if #drives > scroll + maxVisible then scroll = scroll + 1 end
    elseif k == keys.q then
        break
    end
end
]],


    -- Placeholder folders
    ["settings.cfg"] = "pocketMode = false",
    ["libs/local/.keep"] = "",
    ["scripts/games/.keep"] = "",
    ["scripts/apps/.keep"] = "",
    ["scripts/etc/.keep"] = "",
}

-- [[ UI & Installer Logic ]]

local w, h = term.getSize()
local driveSide = nil
local mountPath = nil

local function drawBackground()
    term.setBackgroundColor(colors.blue)
    term.clear()
    term.setBackgroundColor(colors.lightBlue)
    for i = 1, h, 2 do
        term.setCursorPos(1, i)
        term.clearLine()
    end
    -- Header
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clearLine()
    term.write(" SYSTEMMC INSTALLER v1.0")
    term.setCursorPos(w - 10, 1)
    term.write(os.date("%H:%M:%S"))
end

local function drawBox(x, y, width, height, title)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    for i = 0, height - 1 do
        term.setCursorPos(x, y + i)
        term.write(string.rep(" ", width))
    end
    term.setCursorPos(x + 1, y)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.write(" " .. title .. " " .. string.rep(" ", width - #title - 3))
end

local function centerText(text, y, bg, fg)
    term.setCursorPos(math.floor(w/2 - #text/2 + 1), y)
    if bg then term.setBackgroundColor(bg) end
    if fg then term.setTextColor(fg) end
    term.write(text)
end

local function findDrive()
    local drives = {peripheral.find("drive")}
    for _, d in ipairs(drives) do
        if d.hasData() then
            local side = peripheral.getName(d)
            local path = disk.getMountPath(side)
            if path then return side, path end
        end
    end
    return nil, nil
end

local function minimize(content)
    -- Remove multi-line comments
    content = content:gsub("%-%-%[%[.-%]%]", "")
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
        -- Keep lines that aren't empty and don't start with a comment
        if #trimmed > 0 and not trimmed:match("^%-%-") then
            -- Note: We avoid stripping end-of-line comments to prevent breaking strings containing '--'
            table.insert(lines, trimmed)
        end
    end
    return table.concat(lines, "\n")
end

local function install(isUpdate, doFormat)
    drawBackground()
    local title = doFormat and "Formatting & Installing..." or (isUpdate and "Updating SystemMC..." or "Installing SystemMC...")
    drawBox(4, 5, w - 6, 10, title)
    
    if doFormat then
        centerText("Wiping disk...", 8, colors.white, colors.red)
        local list = fs.list(mountPath)
        for _, item in ipairs(list) do
            fs.delete(fs.combine(mountPath, item))
        end
        sleep(0.5)
    end

    centerText("Minimizing System Files...", 8, colors.white, colors.blue)
    sleep(0.8)

    local total = 0
    for _ in pairs(files) do total = total + 1 end
    local current = 0

    for path, content in pairs(files) do
        current = current + 1
        local fullPath = fs.combine(mountPath, path)
        
        -- Progress Bar UI
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        term.setCursorPos(6, 8)
        term.write("Processing: " .. path .. string.rep(" ", w - #path - 15))
        
        local progress = math.floor((current / total) * (w - 10))
        term.setCursorPos(6, 10)
        term.setBackgroundColor(colors.gray)
        term.write(string.rep(" ", w - 10))
        term.setCursorPos(6, 10)
        term.setBackgroundColor(colors.lime)
        term.write(string.rep(" ", progress))

        -- Update Logic: Only write core files
        local dir = fs.getDir(fullPath)
        if not fs.exists(dir) then fs.makeDir(dir) end
        
        local f = fs.open(fullPath, "w")
        f.write(minimize(content))
        f.close()
        
        sleep(0.05)
    end

    centerText(doFormat and "Format & Install Complete!" or (isUpdate and "Update Complete!" or "Installation Complete!"), 12, colors.white, colors.green)
    centerText("Press any key to REBOOT", 14, colors.white, colors.gray)
    os.pullEvent("key")
    os.reboot()
end

-- Main Loop
while true do
    drawBackground()
    drawBox(5, 5, w - 8, 8, "Configuration")
    
    driveSide, mountPath = findDrive()
    
    if not driveSide then
        centerText("Insert a Floppy Disk", 8, colors.white, colors.red)
        centerText("Waiting for peripheral...", 10, colors.white, colors.black)
        sleep(1)
    else
        local isUpdate = fs.exists(fs.combine(mountPath, "scripts/systemMC/kernel.lua"))
        
        centerText("Floppy Detected: " .. driveSide .. " (" .. mountPath .. ")", 8, colors.white, colors.black)
        if isUpdate then
            centerText("Status: OS Found (Ready to Update)", 9, colors.white, colors.blue)
            centerText("[ENTER] Update  [F] Format & Wipe", 11, colors.white, colors.blue)
        else
            centerText("Status: Empty / New Disk", 9, colors.white, colors.gray)
            centerText("[ENTER] Install [F] Format & Wipe", 11, colors.white, colors.blue)
        end
        
        local event, key = os.pullEvent("key")
        if key == keys.enter then
            install(isUpdate, false)
            break
        elseif key == keys.f then
            install(false, true)
            break
        end
    end
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
print("Installer closed.")
