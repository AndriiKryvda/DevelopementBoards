pin_motion = 8;
gpio.mode(pin_motion, gpio.INT, gpio.PULLUP);  -- attach interrupt to inpin
motion_number = 0;

pin_led = 5;
gpio.mode(pin_led, gpio.OUTPUT)


function motion()
  motion_number = motion_number + 1;
  print("Motion Detected - " .. motion_number);
  gpio.write(pin_led, gpio.HIGH)  -- Led ON - Motion detected
  tmr.delay(3000000)           -- delay time for marking the movement
  gpio.write(pin_led, gpio.LOW)   -- Led OFF
end

gpio.trig(pin_motion, "up", motion);
