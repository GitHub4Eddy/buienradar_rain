-- QuickApp BUIENRADAR RAIN 

-- This QuickApp predicts the rain in Europe with data from the Buienradar, two hours in advance
-- The value of this QuickApp represents the minutes until rain
-- If there is no rain expected, the value is set to 0
-- If it rains, the value is set to 999 and the amount of rain (mm/h) is shown
-- Buienradar updates every 5 minutes with intervals of 5 minutes until 2 hours in advance. If rain is expected within the first predicted 5 minutes or less, the QuickApp assumes it is raining. 
-- If rain is expected or it rains, the interval for checking the Buienradar data (default without rain 300 seconds, equal to the Buienradar updates) is speed up (default 60 seconds) so the QuickApp value is updated more often
-- With the value updated in this QuickApp, you are able to build and use your own scenes to notify, to close or open sunscreens, to close or open windows, etcetera

-- Version 0.1 (15th August 2020)
-- Initial version

-- JSON data copyright: (C)opyright Buienradar / RTL. All rights reserved. 
-- JSON data terms: Deze feed mag vrij worden gebruikt onder voorwaarde van bronvermelding buienradar.nl inclusief een hyperlink naar https://www.buienradar.nl. Aan de feed kunnen door gebruikers of andere personen geen rechten worden ontleend.

-- The value 000 indicates no rain (dry), the value 255 indicates heavy rain. 
-- Used formula for converting to the rain intensity in the unit millimetre per hour (mm/h): Rain intensity = 10^(value-109)/32)
-- Example: a value of 77 is equal to a rain intensity of 0,1 mm/h.

-- Variables mandatory:
-- IntervalR = Number in seconds to update the data when rain expected or raining (must be different to IntervalD)
-- IntervalD = Number in seconds to update the data when no rain expected, Buienradar is updated every 300 seconds
-- Latitude = of your location (Default is the latitude of your HC3)
-- Longitude = of your location (Default is the longitude of your HC3)


-- Below here no changes are needed


function QuickApp:onInit()

  __TAG = "BUIENRADAR_RAIN_"..plugin.mainDeviceId
  self:debug("OnInit") 

  url = "https://br-gpsgadget.azurewebsites.net/data/raintext?lat="
  intervalR = tonumber(self:getVariable("intervalR"))
  intervalD = tonumber(self:getVariable("intervalD"))
  latitude = tonumber(self:getVariable("latitude"))
  longitude = tonumber(self:getVariable("longitude"))

  -- Check existence of the mandatory variables, if not, create them with default values
  if intervalR == "" or intervalR == nil then
    intervalR = "60" -- Default intervalR (rain expected or raining) is 60 seconds
    self:setVariable("intervalR", intervalR)
    self:trace("Added QuickApp variable intervalR")
    intervalR = tonumber(intervalR)
  end
  if intervalD == "" or intervalD == nil then
    intervalD = "300" -- Default intervalD (dry, no rain) is 300 seconds
    self:setVariable("intervalD", intervalD)
    self:trace("Added QuickApp variable intervalD")
    intervalD = tonumber(intervalD)
  end
  if latitude == 0 or latitude == nil then 
    latitude = string.format("%.2f",api.get("/settings/location")["latitude"]) -- Default latitude of your HC3
    self:setVariable("latitude", latitude)
    self:trace("Added QuickApp variable latitude")
  end  
  if longitude == 0 or longitude == nil then
    longitude = string.format("%.2f",api.get("/settings/location")["longitude"]) -- Default longitude of your HC3
    self:setVariable("longitude", longitude)
    self:trace("Added QuickApp variable longitude")
  end
  interval = intervalD
  latitude = string.format("%.2f",latitude) -- double check, to prevent 404 response
  longitude = string.format("%.2f",longitude) -- double check, to prevent 404 response
  --self:debug("latitude: ", latitude)
  --self:debug("longitude: ", longitude)

  url = url ..latitude .."&lon=" ..longitude -- Combine webaddress and location info


  self.http = net.HTTPClient({8*1000})

  self:loop("")

end


function QuickApp:loop(text) 

  self.http:request(url, {
    options={
      headers = {Accept = "application/json"}, method = 'GET'}, success = function(response)
      --self:debug("response status:", response.status) 
      --self:debug("headers:", response.headers["Content-Type"])
      --self:debug("url: ", url)
      apiResult = response.data

      -- Test settings
      --apiResult = "000|00:45 000|00:50 000|00:55 000|01:00 000|01:05 000|01:10 012|01:15 000|01:20 000|01:25 000|01:30 000|01:35 000|01:40 000|01:45 030|01:50 023|01:55 010|02:00 000|02:05 000|02:10 000|02:15 000|02:20 000|02:25 000|02:30 000|02:35 000|02:40" -- Rain expected
      --apiResult = string.gsub(apiResult,"000","077") -- Test all rain
      --self:debug("apiResult: ",apiResult) 
      --self:debug("Interval: ", interval)

      apiResult = apiResult:gsub("000|", "") -- Erase all non rain data
      pos = string.find(apiResult, "|" ) -- Search for remaining rain data
      --self:debug("pos: ", pos)
      if pos ~= nil then -- There is rain (expected)
        local rTime = apiResult:sub(pos+1,pos+5) -- Time expected rain
        local rTimeHour = tonumber(rTime:sub(1,2))
        local rTimeMinute = tonumber(rTime:sub(4,5))
        local currentTime = os.date("%H:%M")
        local cTimeHour = tonumber(currentTime:sub(1,2))
        local cTimeMinute = tonumber(currentTime:sub(4,5))
        if rTimeHour < cTimeHour then -- Current time before and rain time after 24:00
          rTimeHour = rTimeHour + 24
        end
        local rMinute = (rTimeHour-cTimeHour)*60+(rTimeMinute-cTimeMinute) -- Minutes until rain
        if rMinute <= 5 then -- It is raining
          interval = intervalR -- Speed up interval to intervalR when it rains
          local rainIntensity = string.format("%.2f",10^((apiResult:sub(pos-4,pos-1)
-109)/32)) -- Calculate rain intensity in milimeters / hour
          self:debug("It rains " ..rainIntensity .." mm/h (" ..rTime ..")")
          self:updateView("label3", "text", "It rains " ..rainIntensity .." mm/h (" ..rTime ..")")
          self:updateView("label4", "text", "Interval: " ..interval)
          self:updateProperty("value", 999)
          self:updateProperty("unit", " min")
          self:updateProperty("log", "Rain " ..rainIntensity .." mm/h (" ..rTime ..")")
        else -- Rain is expected
          interval = intervalR -- Speed up interval to intervalR when rain expected
          self:debug("Rain expected in ", rMinute .." minutes at " ..rTime)
          self:updateView("label3", "text", "Rain expected in " ..rMinute .." minutes at: " ..rTime)
          self:updateView("label4", "text", "Interval: " ..interval)
          self:updateProperty("value", rMinute)
          self:updateProperty("unit", " min")
          self:updateProperty("log", "Rain at " ..rTime)
        end
      else -- No rain is expected
        if interval == intervalR then
          self:debug("No more rain expected")
        end
        interval = intervalD -- Decrease interval to intervalD when no rain expected 
        local lastTime = apiResult:sub(apiResult:len()-6,apiResult:len())
        self:updateView("label3", "text", "No rain expected until " ..lastTime)
        self:updateView("label4", "text", "Interval: " ..interval)
        self:updateProperty("value", 0)
        self:updateProperty("unit", "")
        self:updateProperty("log", "No rain until " ..lastTime)  
      end

      -- Update View
      self:updateView("label2", "text", "Latitude: " ..latitude .." | " .."Longitude: " ..longitude) 

      --self:debug("--------------------- END --------------------") 
      
    end,
    error = function(error)
    self:error('error: ' .. json.encode(error))
    self:updateProperty("log", "error: " ..json.encode(error))
  end
}) 

  fibaro.setTimeout(interval*1000, function() -- Checks every [interval] seconds for new data
  self:loop(text)
  end)

end

