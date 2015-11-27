-- paq: An Unrestricted Github-Powered Package Manager for OpenOS
-- author: exploser (Pavel Vasilev)
-- exploser@exsdev.ru, explosere@ya.ru

local VERSION = "0.1.2"
local binname = "paq"

local component = require("component")
local paq = require("lib" .. binname)
local shell = require("shell")

local function main(args)
  if not component.isAvailable("internet") then
    io.stderr:write("This program requires an internet card to run.\n")
    return
  end
  
  paq.init()
  
  if #args < 1 then
    paq.usage()
    return
  end
  
  if args[1] == "install" then
    if (#args == 2) then
      paq.get(args[2])
    elseif(#args == 3) then
      paq.get(args[3], args[2])
    else
      paq.usage()
    end
    
  elseif args[1] == "version" then
    io.write(VERSION)
    
  elseif args[1] == "remove" or args[1] == "delete" then
    paq.remove(args[2])
       
  elseif args[1] == "workdir" then
    if(paq.installed[args[2]]) then
      io.write(paq.installed[args[2]].repo)
    end
    
  elseif args[1] == "list" then
    for k, v in pairs(paq.installed) do
      print(k.author .. ":" .. k)
    end
  
  elseif args[1] == "client" then
    io.write(paq.librarypath .. binname .. "client.lua")
  end
  
  paq.save()
    
end

local args, options = shell.parse(...)
main(args)