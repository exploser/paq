-- paq: An Unrestricted Package Manager for OpenOS
-- author: exploser (Pavel Vasilev)
-- exploser@exsdev.ru, explosere@ya.ru

local VERSION = "0.1a-test"
local binname = "paq"
local installpath = "/bin/" .. binname .. "/"
local librarypath = "/lib/" .. binname .. "/"
local repositorypath = "/usr/" .. binname .. "/"

local component = require("component")
local fs = require("filesystem")
local internet = require("internet")
local shell = require("shell")
local text = require("text")

if not component.isAvailable("internet") then
  io.stderr:write("This program requires an internet card to run.")
  return
end

local args, options = shell.parse(...)
options.q = options.q or options.Q

if #args < 1 then
  io.write("Usage: " .. binname .. " command [argument]\n")
  io.write("Commands:\n")
  io.write("\tinstall\tinstalls this tool to system\n")
  io.write("\tget package-name\tget package\n")
  io.write("\tversion\tprint " .. binname .. " version\n")
  return
end

if args[1] == "install" then
  local thisname = shell.resolve(binname, "lua")
  if thisname == installpath .. binname .. ".lua" then
    local version = os.execute(binname .. " version")
    io.stderr:write(binname .. " version " .. version .. " is already installed!")
  else
    fs.makeDirectory(installpath)
    os.execute("mv " .. thisname .. " " .. installpath .. binname .. ".lua")
    io.write(binname .. " version " .. VERSION .. " successfully installed!")
  end
  
elseif args[1] == "get" then
  local paqname = args[2]
  
elseif args[1] == "version" then
  io.write(VERSION)
  
elseif args[1] == "remove" then

end
