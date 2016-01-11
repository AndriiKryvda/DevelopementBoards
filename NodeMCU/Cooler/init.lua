-- init constants
wifi_name = "ank"
wifi_pwd = "TanyaIraAndrey"
temperature_high = 27
temperature_low = 25

pin_temperature = 5
pin_relay = 8
gpio.mode(pin_relay, gpio.OUTPUT);

config_filename = "cooler_config";
max_temperature_high = 40;
min_temperature_low = 10;

-- init global variables
cooler_is_active = false;
m_temperature = {}
m_humidity = {}
for i=0, 4 do
  m_temperature[i] = -273.0;
  m_humidity[i] = 0;
end


-- init alarms
tmr.alarm(0, 100, 0, function() ReadSettings() end ) 
tmr.alarm(1, 1000, 0, function() ReconnectWifi() end ) -- initial connect to WiFi
tmr.alarm(2, 60000, 1, function() ReconnectWifi() end )
--tmr.alarm(3, 10000, 0, function() ShowWifiStatus() end )
tmr.alarm(4, 1000, 1, function() CheckCurrentTemperature() end )
tmr.alarm(5, 5000, 1, function() RunCooler() end )
tmr.alarm(6, 3000, 0, function() StartHttpServer() end )  -- start HTTP server


-- ****************************************************************
function RunCooler()
  local average_temperature = GetAverageTemperature();
  if average_temperature >= temperature_high and cooler_is_active == false then
    print("Cooler is ON, temperature "..average_temperature);
    cooler_is_active = true;
    gpio.write(pin_relay, gpio.HIGH);
    return;
  end
  if average_temperature <= temperature_low and cooler_is_active == true then
    print("Cooler is OFF, temperature "..average_temperature);
    cooler_is_active = false;
    gpio.write(pin_relay, gpio.LOW);
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
    status,temp,humi,temp_decimial,humi_decimial = dht.read(pin_temperature)
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
  local myIP = wifi.sta.getip()
  if myIP == nil then
    myIP = "no IP"
  end
  print("WiFi status: " .. wifi.sta.status() .. " , IP:  " .. myIP .. " , MAC " .. wifi.sta.getmac())
end


function ReconnectWifi()
  if wifi.sta.getip() == nil then 
    print("Connecting to WiFi...")
    wifi.setmode(wifi.STATION)
    wifi.sta.config (wifi_name, wifi_pwd ) 
    wifi.sta.connect()
  end
  ShowWifiStatus();
end


function StartHttpServer()
    srv=net.createServer(net.TCP)
    srv:listen(80, function(conn)
        conn:on("receive", function(client,request)
            local buf = "";
            local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
            if(method == nil)then
                _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
            end
            local _GET = {}
            if (vars ~= nil)then
                for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                    _GET[k] = v
                end
            end
            
            if(_GET.btn == "HighIncrease" and temperature_high <= max_temperature_high and temperature_high > temperature_low) then
               temperature_high = temperature_high + 1;
               --print("Increase HIGH threshold value to ");
            elseif(_GET.btn == "HighReduce" and temperature_high <= max_temperature_high and temperature_high > temperature_low + 1) then
               temperature_high = temperature_high - 1;
               --print("Reduce HIGH threshold value to ");
            elseif(_GET.btn == "LowIncrease" and temperature_low >= min_temperature_low and temperature_high - 1 > temperature_low) then
               temperature_low = temperature_low + 1;
               --print("Increse LOW threshold value to ");
            elseif(_GET.btn == "LowReduce" and temperature_low >= min_temperature_low and temperature_high > temperature_low) then
               temperature_low = temperature_low - 1;
               --print("Reduce LOW threshold value to ");
            end

            buf = buf.."<html><h3><b><font color='#0000FF'>Current temperature: " .. GetAverageTemperature() .. " C</font></b>";
            buf = buf.."</br><a href=\"\"><button>Refresh</button></a></h3>";
            buf = buf.."<table border='0'><tr><td>High threshold</td> <td><b>&nbsp;" .. temperature_high ..  "&nbsp;</b></td>";
            buf = buf.."<td><a href=\"?btn=HighIncrease\"><button>+Increase</button></a>&nbsp;&nbsp;<a href=\"?btn=HighReduce\"><button>-Reduce</button></a></td></tr>";
            buf = buf.."<tr><td>Low threshold</td> <td><b>&nbsp;" .. temperature_low ..  "&nbsp;</b></td>";
            buf = buf.."<td><a href=\"?btn=LowIncrease\"><button>+Increase</button></a>&nbsp;&nbsp;<a href=\"?btn=LowReduce\"><button>-Reduce</button></a></td></tr></table>";
            buf = buf.."</br>Heap size:  " .. node.heap() .. " bytes";
            buf = buf.."</br>Uptime:  " .. math.floor(tmr.time() / 86400) .. " days " .. math.floor(tmr.time() / 3600) .. " hours " .. math.floor(tmr.time() / 60) .. " minutes";
            
            buf = buf.."</html>"
            
            client:send(buf);
            client:close();
            collectgarbage();

            --result = SaveSettings();
        end)
    end)
end


function SaveSettings()
  print ("Saving of settings ...");
  file.open(config_filename, 'w') -- you don't need to do file.remove if you use the 'w' method of writing
  file.writeline(temperature_high);
  file.writeline(temperature_low);
  file.close();
  print ("Settings were saved");
end


function ReadSettings()
  print ("Reading of settings ...");
  local f = file.open(config_filename);
  if (f == nil) then
    print ("Setting file '" .. config_filename .. "' doesn't exist.");
  else
    result = string.sub(file.readline(value), 1, -2) -- to remove newline character
    temperature_high = tonumber(result);
    print (result);
    
    result = string.sub(file.readline(value), 1, -2) -- to remove newline character
    temperature_low = tonumber(result);
    print (result);
    
    file.close();
    print ("Settings were read");
  end
end
