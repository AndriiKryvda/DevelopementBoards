
tmr.alarm(0, 10000, 1, function() ShowWifiStatus() end )
tmr.alarm(1, 30000, 1, function() ReconnectWifi() end )


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
