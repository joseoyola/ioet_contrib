require("cord")
require("storm")
sh = require("stormsh")


storm.io.set_mode(storm.io.INPUT, storm.io.D3)

cport = 49152

csock = storm.net.udpsocket(
  cport, function(payload, from, port) end)

local svc_manifest = {id="Motion-Sensor-One", channel="motion_sensor_one"}

local msg = storm.mp.pack(svc_manifest)
storm.os.invokePeriodically(
  5*storm.os.SECOND, 
  function() storm.net.sendto(csock, msg, "ff02::1", 1525) end)

service_sock = storm.net.udpsocket(1526, function(payload, from, port)
  end)


cord.new(function()
  storm.io.watch_all(storm.io.RISING, storm.io.D3, function()
    message = {"publishToChannel", {"motion_sensor_one", 1}}
    packed = storm.mp.pack(message)
    storm.net.sendto(service_sock, packed, "ff02::1", 1526)
  end)
end)

sh.start()
cord.enter_loop()
