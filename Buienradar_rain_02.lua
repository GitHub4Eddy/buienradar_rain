-- QuickApp BUIENRADAR RAIN 

-- This QuickApp predicts the rain in a part of Europe with data from the Buienradar, two hours in advance
-- The value of this QuickApp represents the minutes until rain
-- If there is no rain expected, the value is set to 0
-- If it rains, the value is set to 999 and the amount of rain (mm/h) is shown
-- Buienradar updates every 5 minutes with intervals of 5 minutes until 2 hours in advance. If rain is expected within the first predicted 5 minutes or less, the QuickApp assumes it is raining. 
-- If rain is expected or it rains, the interval for checking the Buienradar data (default without rain 300 seconds, equal to the Buienradar updates) is speed up (default 60 seconds) so the QuickApp value is updated more often
-- With the value updated in this QuickApp, you are able to build and use your own scenes to notify, to close or open sunscreens, to close or open windows, etcetera 

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
-- latitude = of your location (Default is the latitude of your HC3)
-- longitude = of your location (Default is the longitude of your HC3)


-- Below here no changes are needed


function QuickApp:checkTestData() -- Test settings
  --apiResult = "000|23:45 077|23:50 099|23:55 110|00:00 130|00:05 087|00:10 012|00:15 000|00:20 077|00:25 077|00:30 087|00:35 099|00:40 110|00:45 254|00:50 130|00:55 125|01:00 110|01:05 087|01:10 077|01:15 000|01:20 000|01:25 000|01:30 000|01:35 000|01:40" -- Rain expected
  --apiResult = string.gsub(apiResult,"000","099") -- Raining
end


function QuickApp:lines(response) -- Setup for rain forecast view in labels
  local mmh, amount, time, labeltext, lines = "", "", "", "",""
  local pos, i, l, maxlines = 0, 1, 1, 0
  local text = response:gsub(" ", ", ")
  for i=1,24 do
    maxlines = 0
    lines = ""
    pos = string.find(text,"|")
    if pos == nil then 
      self:warning("Unexpected nil value in Buienradar response: "..i) -- Double check
      break 
    end 
    amount = text:sub(pos-3,pos-1)
    time = text:sub(pos+1,pos+5)
    if amount == "000" then
       mmh = "0.00"
    else
      mmh = string.format("%.2f",10^((tonumber(amount)-109)/32)) -- Calculate rain in milimeters / hour
    end
    maxlines = tonumber(mmh)*10
    if tonumber(mmh) > 2.5 then
      if tonumber(mmh) > 9.9 then
        mmh = "9.9+"
      end
      maxlines = 26
    end
    for l=1,maxlines do
      lines = lines .."|"
    end
    if lines:len() > 25 then -- Add a "+" if lines is longer than 25
      lines = lines:sub(1,25) .."+"
    end
    labeltext = labeltext ..time .." = "..mmh .." ㎜/𝚑 - " ..lines .."\n"
    text = text:gsub(amount.."|", mmh .." ",1) 
  end
  --self:debug("text: ", text)
  --self:debug("labeltext: ", labeltext)
  return labeltext
end


function QuickApp:getQuickAppVariables()
  url = "https://br-gpsgadget.azurewebsites.net/data/raintext"
  intervalR = tonumber(self:getVariable("intervalR"))
  intervalD = tonumber(self:getVariable("intervalD"))
  latitude = tonumber(self:getVariable("latitude"))
  longitude = tonumber(self:getVariable("longitude"))

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
  interval = intervalD
  latitude = string.format("%.2f",latitude) -- double check, to prevent 404 response
  longitude = string.format("%.2f",longitude) -- double check, to prevent 404 response
  --self:debug("latitude: " ..latitude .." longitude: ", longitude)

  url = url .."?lat=" ..latitude .."&lon=" ..longitude -- Combine webaddress and location info

  if tonumber(latitude) < 50 or tonumber(latitude) > 54 or tonumber(longitude) < 1 or tonumber(longitude) > 10 then -- Check for coverage of Buitenradar Rain (latitude 50-54 and longitude 1-10)
    self:warning("Current latitude = "..latitude .." and longitude = " ..longitude)
    self:warning("Buienradar Rain only works for latitude 50-54 and longitude 1-10")
    self:warning("Check this url for response: "..url) 
  end
end


function QuickApp:getRainData()
  self.http:request(url, {
    options={
      headers = {Accept = "application/json"}, method = 'GET'}, success = function(response)
      --self:debug("response status:", response.status) 
      --self:debug("headers:", response.headers["Content-Type"])
      --self:debug("url: ", url)
      apiResult = response.data
      --self:debug("apiResult: ",apiResult) 

      if apiResult ~= nil and apiResult ~= "" then
        self:checkTestData() -- Check for test settings
        self:processRainData() -- Process the rain data in Views and Properties
      else
        self:warning("Temporarily no data from Buienradar")
      end

      --self:debug("--------------------- END --------------------")
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


function QuickApp:processRainData()
  local rainForecast = self:lines(apiResult)
  --self:debug("rainForecast: ",rainForecast) 
  apiResult = apiResult:gsub("000|", "") -- Erase all non rain data
  --self:debug("apiResult only rain: ",apiResult) 
  local pos = string.find(apiResult, "|" ) -- Search for remaining rain data
  --self:debug("pos: ", pos)
  if pos ~= nil then -- There is rain (expected)
    local rTime = apiResult:sub(pos+1,pos+5) -- Time expected rain
    local rTimeHour = tonumber(rTime:sub(1,2))
    local rTimeMinute = tonumber(rTime:sub(4,5))
    local currentTime = os.date("%H:%M")
    local cTimeHour = tonumber(currentTime:sub(1,2))
    local cTimeMinute = tonumber(currentTime:sub(4,5))
    local rainIntensity = string.format("%.2f",10^((apiResult:sub(pos-4,pos-1)-109)/32)) -- Calculate rain intensity in milimeters / hour
    if rTimeHour < cTimeHour then -- Current time before and rain time after 24:00
      rTimeHour = rTimeHour + 24
    end
    local rMinute = (rTimeHour-cTimeHour)*60+(rTimeMinute-cTimeMinute) -- Minutes until rain
    interval = intervalR -- Speed up interval to intervalR when it rains
   if rMinute <= 5 then -- It is raining
      self:debug("It rains " ..rainIntensity .." ㎜/𝚑 (" ..rTime ..")")
      rainForecast = "It rains " ..rainIntensity .." ㎜/𝚑 (" ..rTime ..")\n\n" ..rainForecast
      self:updateView("labelRainInfo", "text", rainForecast)
      self:updateProperty("value", 999)
      self:updateProperty("unit", " min")
      self:updateProperty("log", "Rain " ..rainIntensity .." ㎜/𝚑 (" ..rTime ..")")
    else -- Rain is expected
      self:debug("Rain expected in ", rMinute .." minutes at: " ..rTime)
      rainForecast = "Rain expected in " ..rMinute .." minutes at: " ..rTime .."\n\n" ..rainForecast
      self:updateView("labelRainInfo", "text", rainForecast)
      self:updateProperty("value", rMinute)
      self:updateProperty("unit", " min")
      self:updateProperty("log", "Rain at " ..rTime)
    end
  else -- No rain is expected
    if interval == intervalR then -- From rain (expected) to no rain expected
      self:debug("No more rain expected")
    end
    interval = intervalD -- Decrease interval to intervalD when no rain expected 
    local lastTime = apiResult:sub(apiResult:len()-6,apiResult:len())
    self:updateView("labelRainInfo", "text", "No rain expected until " ..lastTime)
    self:updateProperty("value", 0)
    self:updateProperty("unit", "")
    self:updateProperty("log", "No rain until " ..lastTime)  
  end
  self:updateView("labelBuienradar", "text", "   Buienradar Rain - LAT: " ..latitude .." / " .."LON: " ..longitude) 
end


function QuickApp:onInit()
  __TAG = "BUIENRADAR_RAIN_"..plugin.mainDeviceId
  self:debug("OnInit") 
  self:getQuickAppVariables() 
  self.http = net.HTTPClient({8*1000})
  self:getRainData()
end
