require("cord")
require("storm")
LCD = require("lcd")
sh = require("stormsh")


storm.io.set_mode(storm.io.INPUT, storm.io.D3)

print_motion_sensor_reading = true

cport = 49152

csock = storm.net.udpsocket(
  cport, function(payload, from, port) end)

pub_sub_server_ip = storm.os.getipaddrstring()
cord.new(function()
  lcd = LCD:new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)
  lcd:init(2, 1)
  lcd:setBackColor(0, 0, 0)
  movement = false
  blue_count = 0
  red_count = 0
  storm.io.watch_all(storm.io.RISING, storm.io.D3, function()
    blue_count = 255
  end)
  subscribe = storm.mp.pack({"subscribeToChannel", "motion_sensor_one"})
  storm.net.sendto(csock, subscribe, pub_sub_server_ip, 1526)
  service_sock = storm.net.udpsocket(1526, function(payload, from, port)
    message = storm.mp.unpack(payload)
    if from == pub_sub_server_ip and message[0] == "motion_sensor_one" then
      red_count = 255
    end
  end)
  while true do
    if blue_count > 0 then
      blue_count = blue_count - 1
    end
    if red_count > 0 then
      red_count = red_count - 1
    end
    lcd:setBackColor(red_count, 0, blue_count)
    cord.await(storm.os.invokeLater, storm.os.MILLISECOND * 10)
  end 
end)

sh.start()
cord.enter_loop()
