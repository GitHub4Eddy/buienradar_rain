-- Buienradar Rain childs

class 'brRainfall'(QuickAppChild)
function brRainfall:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("Buienradar brRainfall QuickappChild initiated, deviceId:",self.id)
end
function brRainfall:updateValue(data) 
  self:updateProperty("value",tonumber(rainfall))
  self:updateProperty("unit", translation["mm/h"])
  self:updateProperty("log", "")
end

 -- EOF