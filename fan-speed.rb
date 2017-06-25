#!/usr/bin/env ruby

SPEED_AUTO = -1
# Return a fan speed based on temp.
def get_next_fan_speed(temp)
  if temp <= 0
    SPEED_AUTO
  else
    temp - 5
  end
end

def get_current_temp
  info = `/usr/bin/nvidia-smi dmon -s p -c 1 | sort -n -k3 | tail -1`
  cols = info.split(' ') if info
  if cols[2]
    cols[2].to_i
  else
    -1
  end
end

def set_fan_speed(speed)
  if speed == SPEED_AUTO
    `/usr/bin/nvidia-settings -a '[gpu:0]/GPUFanControlState=0'`
    return
  end

  if speed > 0
    `/usr/bin/nvidia-settings -a '[gpu:0]/GPUFanControlState=1' -a '[fan:0]/GPUTargetFanSpeed=#{speed}'`
  end
end

def run
  last_temp = get_current_temp
  last_speed = get_next_fan_speed(last_temp)

  puts "Start speed contorl. Temperature is #{last_temp}.  Setting fan speed to #{last_speed}."

  while true do
    sleep 1

    temp = get_current_temp
    if temp != last_temp
      next_speed = get_next_fan_speed(temp)
      puts "Current temperature is #{temp}.  Setting fan speed to #{next_speed} (from #{last_speed})."
      last_speed = set_fan_speed(next_speed)
    else
      puts "Current temperature is #{temp}.  No adjustments needed."
    end
  end
end

begin
  run()
ensure
  set_fan_speed(SPEED_AUTO)
end
