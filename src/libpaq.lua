-- paq: An Unrestricted Github-Powered Package Manager for OpenOS
-- author: exploser (Pavel Vasilev)
-- exploser@exsdev.ru, explosere@ya.ru

local VERSION = "0.1.2"
local binname = "paq"
local configpath = "/etc/" .. binname .. "/"
local repositorypath = "/usr/" .. binname .. "/"
local installpath = "/usr/bin/"

local fs = require("filesystem")
local internet = require("internet")
local text = require("text")
local serialization = require("serialization")
local installed = {}

local paq = {}

function paq.usage()
  io.write("Usage: " .. binname .. " command [argument]\n")
  io.write("Commands:\n")
  io.write(" install [user] paqname\t\tinstall package <paqname> from Github user <user>\n")
  io.write(" if no user was specified, uses the author's repository (exploser)\n")
  io.write(" version\t\t\tprint " .. binname .. " version\n")
end

function paq.init()
  if fs.exists(configpath .. "paqs.tb") then
    local f = io.open(configpath .. "paqs.tb", "r")
    local data = f:read("*all")
    installed = serialization.unserialize(data) or {}
    f:close()
  elseif not fs.exists(configpath) then
    fs.makeDirectory(configpath)
  end
end

function paq.get(paqname, authorname)
  authorname = authorname or "exploser"
  
  if(installed[paqname]) then
    if(installed[paqname].author == authorname) then
      -- do something
    end
    io.write(string.format("Package %s:%s is already installed! Use '%s delete %s' to remove it.\n", installed[paqname].author, paqname, binname, paqname))
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
    
    if t then
      io.write(str.."\n")
      local repo = repositorypath .. paqname .. "/"
      
      io.write("Creating local directories...\n")
      fs.makeDirectory(repo)
      
      installed[paqname] = {}
      installed[paqname].files = {}
      installed[paqname].repo = repo
      installed[paqname].version = t.version
      installed[paqname].author = authorname
      installed[paqname].dependencies = t.dependencies
      
      for file, dest in pairs(t.files) do
        if(fs.exists(dest)) then
          io.stderr:write(string.format("File %s already exists! Try removing it by hand. %s does not delete existing files if it didn't install them.\n", dest, binname))
          io.write("Rolling back install...\n")
          paq.remove(paqname)
          return
        else
          fs.makeDirectory(fs.path(dest))
          os.execute(string.format("wget %s %s", masterurl .. file, dest))
          table.insert(installed[paqname].files, dest)
        end
      end
      
      if installed[paqname].dependencies then
        io.write("Installing dependencies...\n")
        for i, dep in pairs(installed[paqname].dependencies) do
          if not installed[dep.name] then
            paq.get(dep.name, dep.author)
          end
        end
      end
      
    else
      io.stderr:write("Could not parse package info!\n"..str.."\n")
    end
    
  else
    io.stderr:write("Could not find package info!\n")
  end
end

function paq.save()
  for k, v in pairs( installed ) do
    if(not v.main and not v.repo) then
      installed[k] = nil
    end
  end
  
  f = io.open(configpath .. "paqs.tb", "w")
  outp = serialization.serialize(installed)
  
  f:write(outp)
  f:flush()
  f:close()
end

function paq.remove(paqname)
  if installed[paqname] then
    for k,v in pairs(installed[paqname].files) do
      fs.remove(v)
    end
      
    if installed[paqname].repo then
      fs.remove(installed[paqname].repo)
    end
    
    io.write(string.format("Package %s:%s was successfully removed!\n", installed[paqname].author, paqname))
    installed[paqname] = nil
  else
    io.write("Package " .. paqname .. " is not installed.")
  end
end

return paq
