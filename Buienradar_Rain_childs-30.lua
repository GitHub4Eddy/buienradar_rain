-- Buienradar Rain childs

class 'rainfall'(QuickAppChild)
function rainfall:__init(dev)
  QuickAppChild.__init(self,dev)
end
function rainfall:updateValue() 
  self:updateProperty("value",tonumber(rainfall))
  self:updateProperty("unit", translation["mm/h"])
  self:updateProperty("log", " ")
end

class 'firsthour'(QuickAppChild)
function firsthour:__init(dev)
  QuickAppChild.__init(self,dev)
end
function firsthour:updateValue() 
  self:updateProperty("value",tonumber(firsthour))
  self:updateProperty("unit", translation["mm"])
  self:updateProperty("log", " ")
end

class 'secondhour'(QuickAppChild)
function secondhour:__init(dev)
  QuickAppChild.__init(self,dev)
end
function secondhour:updateValue() 
  self:updateProperty("value",tonumber(secondhour))
  self:updateProperty("unit", translation["mm"])
  self:updateProperty("log", " ")
end

 -- EOF