-- Buienradar i18n Translations


class "i18n"
function i18n:translation(language)
  translation = {
    en = {
      ["SIMULATION MODE"] = "SIMULATION MODE", 
      ["It rains"] = "It rains", 
      ["No rain expected until"] = "No rain expected until", 
      ["No rain until"] = "No rain until", 
      ["Rain expected in"] = "Rain expected in", 
      ["minutes at"] = "minutes at", 
      ["Rain at"] = "Rain at", 
      ["Rain"] = "Rain", 
      ["mm/h"] = "mm/h", 
      ["...."] = "...."}, 
    nl = {
      ["SIMULATION MODE"] = "SIMULATIE MODE", 
      ["It rains"] = "Het regent", 
      ["No rain expected until"] = "Geen regen verwacht tot", 
      ["No rain until"] = "Geen regen tot", 
      ["Rain expected in"] = "Regen verwacht in", 
      ["minutes at"] = "minuten om", 
      ["Rain at"] = "Regen om", 
      ["Rain"] = "Regen", 
      ["mm/h"] = "mm/u", 
      ["...."] = "...."}, 
    fr = {
      ["SIMULATION MODE"] = "MODE SIMULATION", 
      ["It rains"] = "Il pleut", 
      ["No rain expected until"] = "Pas de pluie prévue avant", 
      ["No rain until"] = "Pas de pluie jusqu'à", 
      ["Rain expected in"] = "Pluie attendue dans", 
      ["minutes at"] = "minutes à", 
      ["Rain at"] = "Pluie à", 
      ["Rain"] = "Pluie", 
      ["mm/h"] = "mm/h", 
      ["...."] = "...."},} 

    translation = translation[language] -- Shorten the table to only the current translation
  return translation
end

-- EOF