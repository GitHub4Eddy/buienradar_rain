# Buienradar_Rain

This QuickApp predicts the rain in a part of Europe with data from the Buienradar, two hours in advance. The value of this QuickApp represents the minutes until rain
If there is no rain expected, the value is set to 0. If it rains, the value is set to 999 and the amount of rain (mm/h) is shown

Buienradar updates every 5 minutes with intervals of 5 minutes until 2 hours in advance. If rain is expected within the first predicted 5 minutes or less, the QuickApp assumes it is raining. 

If rain is expected or it rains, the interval for checking the Buienradar data (default without rain 300 seconds, equal to the Buienradar updates) is speed up (default 60 seconds) so the QuickApp value is updated more often.

With the value updated in this QuickApp, you are able to build and use your own scenes to notify, to close or open sunscreens, to close or open windows, etcetera

Version 0.3 (26th September 2020)
- Build an extra check for an incomplete Buienradar response (sometimes less than two hours)
- Added global variable maxLines to arrange the maximum amount of lines to indicate the amount of rain (one line for every 0.10mm rain) to fit the screen of your mobile device
- Decreased the default lines from 25 to 23 to show it right on an iPhone

Version 0.2 (4th September 2020)
- Ready for the new Mobile App 1.9: Added visual level of rain (forecast) with thanks to @tinman from forum.fibaro.com
- Added warning for latitude and logitude settings where Buienradar Rain has (no) coverage

Version 0.1 (15th August 2020)
- Initial version

JSON data copyright: (C)opyright Buienradar / RTL. All rights reserved. 
JSON data terms: Deze feed mag vrij worden gebruikt onder voorwaarde van bronvermelding buienradar.nl inclusief een hyperlink naar https://www.buienradar.nl. Aan de feed kunnen door gebruikers of andere personen geen rechten worden ontleend.

The value 000 indicates no rain (dry), the value 255 indicates heavy rain. 
Used formula for converting to the rain intensity in the unit millimetre per hour (mm/h): Rain intensity = 10^(value-109)/32)
Example: a value of 77 is equal to a rain intensity of 0,1 mm/h.

Variables mandatory:
- intervalR = Number in seconds to update the data when rain expected or raining (must be different to IntervalD)
- intervalD = Number in seconds to update the data when no rain expected, Buienradar is updated every 300 seconds
- latitude = of your location (Default is the latitude of your HC3)
- longitude = of your location (Default is the longitude of your HC3)
