-- init constants
pin = 5
wifi_name = "ank"
wifi_pwd = "TanyaIraAndrey"
temperature_high = 26
temperature_low = 24

-- init global variables
cooler_is_active = false;
m_temperature = {}
m_humidity = {}
for i=0, 4 do
  m_temperature[i] = -273.0;
  m_humidity[i] = 0;
end

-- init alarms
tmr.alarm(1, 1000, 0, function() ReconnectWifi() end ) -- initial connect to WiFi
--tmr.alarm(2, 10000, 1, function() ShowWifiStatus() end )
tmr.alarm(3, 60000, 1, function() ReconnectWifi() end )
tmr.alarm(4, 1000, 1, function() CheckCurrentTemperature() end )
tmr.alarm(5, 10000, 1, function() RunCooler() end )


-- ****************************************************************
function RunCooler()
  local average_temperature = GetAverageTemperature();
  if average_temperature >= temperature_high and cooler_is_active == false then
    print("Cooler is ON, temperature "..average_temperature);
    cooler_is_active = true;
    return;
  end
  if average_temperature <= temperature_low and cooler_is_active == true then
    print("Cooler is OFF, temperature "..average_temperature);
    cooler_is_active = false;
    return;
  end
end


function CheckCurrentTemperature()
  for i=1, 4 do
    m_temperature[i] = m_temperature[i-1];
    m_humidity[i] = m_humidity[i-1];
  end
  GetCurrentTemperature();
end


function GetCurrentTemperature()
    status,temp,humi,temp_decimial,humi_decimial = dht.read(pin)
    if( status == dht.OK ) then
      --print("DHT Temperature:"..temp..";".."Humidity:"..humi)
      m_temperature[0] = temp;
      m_humidity[0] = humi;
    end
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
    wifi.sta.config (wifi_name, wifi_pwd ) 
    wifi.sta.connect()
  end
end
