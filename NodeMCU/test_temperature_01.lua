-- init global variables
m_temperature = {}
for i=0, 4 do
  m_temperature[i] = -273;
end

-- init alarms
tmr.alarm(2, 1000, 1, function() CheckCurrentTemperature() end )
tmr.alarm(3, 2000, 1, function() print(GetAverageTemperature()) end )
--tmr.alarm(0, 10000, 1, function() ShowWifiStatus() end )
--tmr.alarm(1, 30000, 1, function() ReconnectWifi() end )


function CheckCurrentTemperature()
  for i=1, 4 do
    m_temperature[i] = m_temperature[i-1];
  end
  m_temperature[0] = GetCurrentTemperature();
end

-- TODO
function GetCurrentTemperature()
  return 25;
end


function GetAverageTemperature()
  local temp_sum = 0;
  local temp_count = 0;
  for i=0, 4 do
    if m_temperature[i] > -273 then
      temp_sum = m_temperature[i] + temp_sum;
      temp_count = temp_count + 1;
    end
    if temp_count > 0 then
      return temp_sum / temp_count;
    else
      return -273.0;
    end
  end
end


function ShowWifiStatus()
  i = wifi.sta.getip()
  if i == nil then
    i = "no IP"
  end
  print(wifi.sta.status() .. "  " .. i)
end


function ReconnectWifi()
  if wifi.sta.getip() == nil then 
    print("Connecting to WiFi...")
    wifi.setmode(wifi.STATION)
    wifi.sta.config ( "ank3_samsung" , "t0937031624" ) 
    wifi.sta.connect()
  end
end
