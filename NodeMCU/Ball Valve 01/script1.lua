-- init alarm
tmr.alarm(0, 10000, 1, function() DoAction() end ) 

opened = false;
pin_relay = 8;
gpio.mode(pin_relay, gpio.OUTPUT);

function DoAction()
  if (opened) then
    gpio.write(pin_relay, gpio.LOW);
    opened = false;
  else
    gpio.write(pin_relay, gpio.HIGH);
    opened = true;
  end
end
