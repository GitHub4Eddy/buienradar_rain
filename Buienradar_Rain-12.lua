-- QuickApp BUIENRADAR RAIN 

-- This QuickApp predicts the rain in a part of Europe with data from the Buienradar, two hours in advance
-- The value of this QuickApp represents the minutes until rain
-- If there is no rain expected, the value is set to 0
-- If it rains, the value is set to 999 and the amount of rain (mm/h) is shown
-- Buienradar updates every 5 minutes with intervals of 5 minutes until 2 hours in advance. If rain is expected within the first predicted 5 minutes or less, the QuickApp assumes it is raining. 
-- If rain is expected or it rains, the interval for checking the Buienradar data (default without rain 300 seconds, equal to the Buienradar updates) is speed up (default 60 seconds) so the QuickApp value is updated more often
-- With the value updated in this QuickApp, you are able to build and use your own scenes to notify, to close or open sunscreens, to close or open windows, etcetera 


-- Version 1.2 (8th January 2022)
-- Buienradar change the response with decimals and without leading zero's. Added some code to handle that. 


-- Version 1.1 (19th March 2021)
-- Added Child Device for rainfall mm/h
-- Added Quickapp variable for debug level (1=some, 2=few, 3=all). Recommended default value is 1. debuglevel 4 = Rain expected simalation. debugLevel = 5 Raining simulation
-- Freed up some space (3 positions) in the presentation of the amount of rain 
-- Increased the default value of the maximum lines (maxLines) from 23 to 26
-- Changed the unit in case of rain to empty

-- Version 1.0 (25th October 2020)
-- Added the possibility to change the icon according to rain, rain expected or dry. Three not mandatory quickapp variables are added to fill in with the icon number for rain, rain expected and dry. 

-- Version 0.3 (26th September 2020)
-- Build an extra check for an incomplete Buienradar response (sometimes less than two hours)
-- Added global variable maxLines to arrange the maximum amount of lines to indicate the amount of rain (one line for every 0.10mm rain) to fit the screen of your mobile device
-- Decreased the default lines from 25 to 23 to show it right on an iPhone

-- Version 0.2 (4th September 2020)
-- Ready for the new Mobile App 1.9: Added visual level of rain (forecast) with thanks to @tinman from forum.fibaro.com
-- Added warning for latitude and logitude settings where Buienradar Rain has (no) coverage

-- Version 0.1 (15th August 2020)
-- Initial version

-- JSON data copyright: (C)opyright Buienradar / RTL. All rights reserved. 
-- JSON data terms: Deze feed mag vrij worden gebruikt onder voorwaarde van bronvermelding buienradar.nl inclusief een hyperlink naar https://www.buienradar.nl. Aan de feed kunnen door gebruikers of andere personen geen rechten worden ontleend.

-- The value 000 indicates no rain (dry), the value 255 indicates heavy rain. 
-- Used formula for converting to the rain intensity in the unit millimetre per hour (mm/h): Rain intensity = 10^(value-109)/32)
-- Example: a value of 77 is equal to a rain intensity of 0,1 ㎜/𝚑.

-- Variables mandatory:
-- intervalR = Number in seconds to update the data when rain expected or raining (must be different to IntervalD)
-- intervalD = Number in seconds to update the data when no rain expected, Buienradar is updated every 300 seconds
-- latitude = latitude of your location (Default is the latitude of your HC3)
-- longitude = longitude of your location (Default is the longitude of your HC3)
-- maxLines = number of | to indicate the amount of rain (one line for every 0.10mm rain)
-- iconR = icon number for rain
-- iconE = icon for rain expected
-- iconD = icon number for dry


-- Below here no changes are needed


class 'brRainfall'(QuickAppChild)
function brRainfall:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("Buienradar brRainfall QuickappChild initiated, deviceId:",self.id)
end
function brRainfall:updateValue(data) 
  self:updateProperty("value",tonumber(rainfall))
  self:updateProperty("unit", "mm/h")
  self:updateProperty("log", "")
end


local function getChildVariable(child,varName)
  for _,v in ipairs(child.properties.quickAppVariables or {}) do
    if v.name==varName then return v.value end
  end
  return ""
end


function QuickApp:logging(level,text) -- Logging function for debug
  if tonumber(debugLevel) >= tonumber(level) then 
      self:debug(text)
  end
end


function QuickApp:checkTestData() -- Test settings
  if debugLevel == 4 then
    apiResult = "000|23:45 077|23:50 099|23:55 110|00:00 130|00:05 087|00:10 012|00:15 000|00:20 077|00:25 077|00:30 086|00:35 099|00:40 110|00:45 254|00:50 130|00:55 125|01:00 110|01:05 087|01:10 077|01:15 000|01:20 000|01:25 000|01:30 000|01:35 077|01:40" -- Rain expected
  elseif debugLevel == 5 then
    apiResult = string.gsub(apiResult,"000","099") -- Raining
  end
end


function QuickApp:lines(response) -- Setup for rain forecast view in labels
  local mmh, amount, time, labelText, lines = "", "", "", "",""
  local pos, i, numLines = 0, 1, 0
  local text = response:gsub(" ", ", ")
  pos = string.find(text,"|")
  while pos ~= nil do -- Buienradar response covers sometimes less than 2 hours
    numLines = 0
    lines = ""
    amount = text:sub(pos-3,pos-1)
    time = text:sub(pos+1,pos+5)
    if amount == "000" then
       mmh = "0.00"
    else
      mmh = string.format("%.2f",10^((tonumber(amount)-109)/32)) -- Calculate rain in milimeters / hour
      self:logging(3,"mmh: " ..mmh)
    end
    numLines = math.floor(tonumber(mmh)*10)
    if tonumber(mmh) > (maxLines)/10 then
      if tonumber(mmh) > 9.9 then
        mmh = "9.9+"
      end
      numLines = maxLines+1
    end
    for i=1,numLines do
      lines = lines .."|"
    end
    if lines:len() > maxLines then -- Add a "+" if lines is longer than maxLines
      lines = lines:sub(1,maxLines) .."+"
    end
    labelText = labelText ..time .." "..mmh .." ㎜/𝚑 " ..lines .."\n"
    text = text:gsub(amount.."|", mmh .." ",1) 
    pos = string.find(text,"|")
  end
  return labelText
end


function QuickApp:processRainData()
  --local rainForecast = self:lines(apiResult)
  --self:logging(3,"rainForecast: " ..rainForecast)
  self:logging(3,"apiResult 1: " ..apiResult)
  apiResult = apiResult:gsub(",(.-)|", "|") -- Erase the komma and all decimals between the komma and pipeline character (Buienradar changed response since January 2022)
  self:logging(3,"apiResult 2: " ..apiResult)
  apiResult = apiResult:gsub("%s(%d%d)|", function(s) return " 0"..s.."|" end) -- Add a leading zero to all two digit rain data (Buienradar changed response since January 2022)
  if string.find(apiResult, "|" ) < 4 then -- Add a leading zero in the first value if needed (Buienradar changed response since January 2022)
    apiResult = "0" ..apiResult
  end
  self:logging(3,"apiResult 3: " ..apiResult)
  apiResult = apiResult:gsub("000|", "") -- Erase all non rain data
  self:logging(3,"apiResult 4: " ..apiResult)
  local rainForecast = self:lines(apiResult)
  self:logging(3,"rainForecast: " ..rainForecast)
  local pos = string.find(apiResult, "|" ) -- Search for remaining rain data
  if pos ~= nil then -- There is rain (expected)
    local rTime = apiResult:sub(pos+1,pos+5) -- Time expected rain
    local rTimeHour = tonumber(rTime:sub(1,2))
    local rTimeMinute = tonumber(rTime:sub(4,5))
    local currentTime = os.date("%H:%M")
    local cTimeHour = tonumber(currentTime:sub(1,2))
    local cTimeMinute = tonumber(currentTime:sub(4,5))
    rainfall = "0.00"
    rainIntensity = string.format("%.2f",10^((apiResult:sub(pos-4,pos-1)-109)/32)) -- Calculate rain intensity in milimeters / hour
    if rTimeHour < cTimeHour then -- Current time before and rain time after 24:00
      rTimeHour = rTimeHour + 24
    end
    local rMinute = (rTimeHour-cTimeHour)*60+(rTimeMinute-cTimeMinute) -- Minutes until rain
    interval = intervalR -- Speed up interval to intervalR when it rains
    if rMinute <= 5 then -- It is raining
      rainfall = rainIntensity
      self:logging(2, "It rains " ..rainIntensity .." ㎜/𝚑 (" ..rTime ..")")
      rainForecast = "It rains " ..rainIntensity .." ㎜/𝚑 (" ..rTime ..")\n\n" ..rainForecast
      self:updateView("labelRainInfo", "text", rainForecast)
      self:updateProperty("value", 999)
      self:updateProperty("unit", "")
      self:updateProperty("log", "Rain " ..rainIntensity .." ㎜/𝚑 (" ..rTime ..")")
      self:setIcon("rain")
    else -- Rain is expected
      rainfall = "0.00"
      self:logging(2, "Rain expected in " ..rMinute .." minutes at: " ..rTime)
      rainForecast = "Rain expected in " ..rMinute .." minutes at: " ..rTime .."\n\n" ..rainForecast
      self:updateView("labelRainInfo", "text", rainForecast)
      self:updateProperty("value", rMinute)
      self:updateProperty("unit", " min")
      self:updateProperty("log", "Rain at " ..rTime)
      self:setIcon("expected")
    end
  else -- No rain is expected
    rainfall = "0.00"
    if interval == intervalR then -- From rain (expected) to no rain expected
      self:logging(2, "No more rain expected")
    end
    interval = intervalD -- Decrease interval to intervalD when no rain expected 
    local lastTime = apiResult:sub(apiResult:len()-6,apiResult:len())
    self:updateView("labelRainInfo", "text", "No rain expected until " ..lastTime)
    self:updateProperty("value", 0)
    self:updateProperty("unit", "")
    self:updateProperty("log", "No rain until " ..lastTime)  
    self:setIcon("dry")
  end
  self:updateView("labelBuienradar", "text", "   Buienradar Rain - LAT: " ..latitude .." / " .."LON: " ..longitude) 
  self:logging(2, "Rainfall: " ..rainfall) 
  
  for id,child in pairs(self.childDevices) do -- Update Child Devices
    child:updateValue(data) 
  end
end


function QuickApp:getRainData()
  self.http:request(url, {
    options={
      headers = {Accept = "application/json"}, method = 'GET'}, success = function(response)
      self:logging(3, "response status:" ..response.status) 
      self:logging(3, "url: " ..url)
      apiResult = response.data
      self:logging(3, "apiResult: " ..apiResult) 
      
      if apiResult ~= nil and apiResult ~= "" then
        self:checkTestData() -- Check for test settings
        self:processRainData() -- Process the rain data in Views and Properties
      else
        self:warning("Temporarily no data from Buienradar Rain")
      end

    end,
    error = function(error)
    self:error('error: ' .. json.encode(error))
    self:updateProperty("log", "error: " ..json.encode(error))
  end
}) 
  fibaro.setTimeout(interval*1000, function() -- Checks every [interval] seconds for new data
  self:getRainData()
  end)
end


function QuickApp:getQuickAppVariables()
  url = "https://br-gpsgadget.azurewebsites.net/data/raintext"
  intervalR = tonumber(self:getVariable("intervalR"))
  intervalD = tonumber(self:getVariable("intervalD"))
  latitude = tonumber(self:getVariable("latitude"))
  longitude = tonumber(self:getVariable("longitude"))
  maxLines = tonumber(self:getVariable("maxLines"))
  iconR = tonumber(self:getVariable("iconR"))
  iconE = tonumber(self:getVariable("iconE"))
  iconD = tonumber(self:getVariable("iconD"))
  debugLevel = tonumber(self:getVariable("debugLevel"))

  if intervalR == "" or intervalR == nil then -- Check existence of the mandatory variables, if not, create them with default values
    intervalR = "60" -- Default intervalR (rain expected or raining) is 60 seconds
    self:setVariable("intervalR", intervalR)
    self:trace("Added QuickApp variable intervalR with default value " ..intervalR)
    intervalR = tonumber(intervalR)
  end
  if intervalD == "" or intervalD == nil then
    intervalD = "300" -- Default intervalD (dry, no rain) is 300 seconds
    self:setVariable("intervalD", intervalD)
    self:trace("Added QuickApp variable intervalD with default value " ..intervalD)
    intervalD = tonumber(intervalD)
  end
  if latitude == 0 or latitude == nil then 
    latitude = string.format("%.2f",api.get("/settings/location")["latitude"]) -- Default latitude of your HC3
    self:setVariable("latitude", latitude)
    self:trace("Added QuickApp variable latitude with default value " ..latitude)
  end  
  if longitude == 0 or longitude == nil then
    longitude = string.format("%.2f",api.get("/settings/location")["longitude"]) -- Default longitude of your HC3
    self:setVariable("longitude", longitude)
    self:trace("Added QuickApp variable longitude with default value " ..longitude)
  end
  if maxLines == 0 or maxLines == nil then
    maxLines = "26" -- Default maxLines is 26 lines
    self:setVariable("maxLines", maxLines)
    self:trace("Added QuickApp variable maxLines with default value " ..maxLines)
    maxLines = tonumber(maxLines)
  end
  if iconR == "" or iconR == nil then 
    iconR = "0" -- Default iconR (icon for rain) is 0 (no icon)
    self:setVariable("iconR", iconR)
    self:trace("Added QuickApp variable iconR with default value " ..iconR)
    iconR = tonumber(iconR)
  end
  if iconE == "" or iconE == nil then 
    iconE = "0" -- Default iconE (icon for rain expected) is 0 (no icon)
    self:setVariable("iconE", iconE)
    self:trace("Added QuickApp variable iconE with default value " ..iconE)
    iconE = tonumber(iconE)
  end
  if iconD == "" or iconD == nil then 
    iconD = "0" -- Default iconD (icon for dry, no rain) is 0 (no icon)
    self:setVariable("iconD", iconD)
    self:trace("Added QuickApp variable iconD with default value " ..iconD)
    iconD = tonumber(iconD)
  end
  if debugLevel == "" or debugLevel == nil then
    debugLevel = "1" -- Default value for debugLevel response in seconds
    self:setVariable("debugLevel",debugLevel)
    self:trace("Added QuickApp variable debugLevel")
    debugLevel = tonumber(debugLevel)
  end
  
  if maxLines > 99 then
    maxLines = 99 -- Maximum amount of lines is 99
  end

  interval = intervalD
  latitude = string.format("%.2f",latitude) -- double check, to prevent 404 response
  longitude = string.format("%.2f",longitude) -- double check, to prevent 404 response
  self:setIcon("dry")

  url = url .."?lat=" ..latitude .."&lon=" ..longitude -- Combine webaddress and location info

  if tonumber(latitude) < 50 or tonumber(latitude) > 54 or tonumber(longitude) < 1 or tonumber(longitude) > 10 then -- Check for coverage of Buitenradar Rain (latitude 50-54 and longitude 1-10)
    self:warning("Current latitude = "..latitude .." and longitude = " ..longitude)
    self:warning("Buienradar Rain only works for latitude 50-54 and longitude 1-10")
    self:warning("Check this url for response: "..url) 
  end
end


function QuickApp:setIcon(txt)
  if iconR ~= 0 and iconE ~= 0 and iconD ~= 0 then 
    if txt == "rain" then 
      self:updateProperty("deviceIcon", iconR) -- set icon to rain
    elseif txt == "expected" then
      self:updateProperty("deviceIcon", iconE) -- set icon to rain expected
    else 
      self:updateProperty("deviceIcon", iconD) -- set icon to dry
    end
  end
end


function QuickApp:setupChildDevices() -- Setup Child Devices
  local cdevs = api.get("/devices?parentId="..self.id) or {} -- Pick up all Child Devices
  function self:initChildDevices() end -- Null function, else Fibaro calls it after onInit()...

  if #cdevs == 0 then -- If no Child Devices, create them
    local initChildData = { 
      {className="brRainfall", name="Rainfall", type="com.fibaro.multilevelSensor", value=0, unit="mm/h"},
    }
    for _,c in ipairs(initChildData) do
      local child = self:createChildDevice(
        {name = c.name,
          type=c.type,
          value=c.value,
          unit=c.unit,
          initialInterfaces = {},
        },
        _G[c.className] -- Fetch class constructor from class name
      )
      child:setVariable("className",c.className)  -- Save class name so we know when we load it next time
    end   
  else 
    for _,child in ipairs(cdevs) do
      local className = getChildVariable(child,"className") -- Fetch child class name
      local childObject = _G[className](child) -- Create child object from the constructor name
      self.childDevices[child.id]=childObject
      childObject.parent = self -- Setup parent link to device controller 
    end
  end
end


function QuickApp:onInit()
  __TAG = fibaro.getName(plugin.mainDeviceId) .." ID:" ..plugin.mainDeviceId
  self:debug("OnInit") 
  
  self:setupChildDevices()
  
  if not api.get("/devices/"..self.id).enabled then
    self:warning("Device", fibaro.getName(plugin.mainDeviceId), "is disabled")
    return
  end
  
  self:getQuickAppVariables() 
  self.http = net.HTTPClient({8*1000})
  self:getRainData()
end
