-- paq: An Unrestricted Github-Powered Package Manager for OpenOS
-- author: exploser (Pavel Vasilev)
-- exploser@exsdev.ru, explosere@ya.ru

local VERSION = "0.1.2"
local binname = "paq"
local configpath = "/etc/" .. binname .. "/"
local librarypath = "/lib/" .. binname .. "/"
local repositorypath = "/usr/" .. binname .. "/"

local component = require("component")
local fs = require("filesystem")
local internet = require("internet")
local shell = require("shell")
local text = require("text")
local serialization = require("serialization")
local installed = {}

local function usage()
  io.write("Usage: " .. binname .. " command [argument]\n")
  io.write("Commands:\n")
  io.write(" installpaq\t\t\tinstall this tool to system\n")
  io.write(" install user paqname\t\tinstall package <paqname> from Github user <user>\n")
  io.write(" version\t\t\tprint " .. binname .. " version\n")
end

local function init()
  if fs.exists(configpath .. "paqs.tb") then
    local f = io.open(configpath .. "paqs.tb", "r")
    local data = f:read("*all")
    installed = serialization.unserialize(data) or {}
    f:close()
  elseif not fs.exists(configpath) then
    fs.makeDirectory(configpath)
  end
end

local function get(authorname, paqname)
  authorname = authorname or "exploser"
  
  if(installed[authorname]) then
    if(installed[authorname][paqname]) then
      io.write(string.format("Package %s:%s is already installed! Use '%s delete %s %s' to remove it.\n", authorname, paqname, binname, authorname, paqname))
      return
    end
  end
  
  local masterurl = "https://raw.githubusercontent.com/" .. authorname .. "/" .. paqname .. "/master/"
  local infourl = masterurl .. "package.txt"
  io.write(string.format("Retrieving %s...\n", infourl))
  local result, response = pcall(internet.request, infourl)
  if result then
    local str = ""
    for chunk in response do
      str = str .. chunk
    end
    local t = serialization.unserialize(str)
    local binurl = masterurl .. t["binname"]
    local repo = repositorypath .. paqname .. "/"
    io.write("Creating local repo directory " .. repo .. "\n")
    fs.makeDirectory(repo)
    local index = string.find(t["binname"], "/[^/]*$") or 0
    local filename = string.sub(t["binname"], index + 1)
    
    if(fs.exists("/bin/" .. filename)) then
      io.stderr:write(string.format("File /bin/%s already exists! Try removing it by hand. %s does not delete existing files if it didn't install them.\n", filename, binname))
      return
    end
    
    os.execute(string.format("wget %s /bin/%s", binurl, filename))
    io.write("adding to table...\n")
    installed[authorname] = {}
    installed[authorname][paqname] = {}
    installed[authorname][paqname].bin = "/bin/" .. filename
    installed[authorname][paqname].repo = repo
    installed[authorname][paqname].version = 0
    
  end
end

local function install()
  get("exploser", "paq")
end

local function save()
  for k, v in pairs( installed ) do
    if(not v.bin and not v.repo) then
      installed[k] = nil
    end
  end
  
  f = io.open(configpath .. "paqs.tb", "w")
  outp = serialization.serialize(installed)
  
  f:write(outp)
  f:flush()
  f:close()
end

local function main(args)
  if not component.isAvailable("internet") then
    io.stderr:write("This program requires an internet card to run.\n")
    return
  end
  
  init()
  
  if #args < 1 then
    usage()
    return
  end
  
  if args[1] == "installpaq" then
    install()
    
  elseif args[1] == "install" then
    get(args[2], args[3])
    
  elseif args[1] == "version" then
    io.write(VERSION)
    
  elseif args[1] == "remove" or args[1] == "delete" then
    local authorname = args[2]
    local paqname = args[3]
    
    if installed[authorname][paqname]["bin"] then
      fs.remove(installed[authorname][paqname]["bin"])
      installed[authorname][paqname]["bin"] = nil
      io.write("Package " .. paqname .. " was successfully removed!")
    else
      io.write("Could not find binary for package " .. paqname .. "!")
    end
    
    if installed[authorname][paqname]["repo"] then
      fs.remove(installed[authorname][paqname]["repo"])
      installed[authorname][paqname]["repo"] = nil
    else
      io.write("Could not find repository for package " .. paqname .. "!")
    end
    
  elseif args[1] == "getdep" then
    if(installed[args[2]]) then
      io.write(installed[args[2]].repo)
    end
  elseif args[1] == "list" then
    for k, v in pairs( installed ) do
      print(k)
    end
  end
  
  
  save()
    
end

local args, options = shell.parse(...)
main(args)