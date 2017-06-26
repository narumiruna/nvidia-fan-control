#!/usr/bin/env ruby

SPEED_AUTO = -1
# Return a fan speed based on temp.
def get_next_fan_speed(temp)
  min_temp = config.min_temp
  max_temp = config.max_temp
  speed = SPEED_AUTO
  if temp >= min_temp
    min_speed = config.min_speed
    max_speed = config.max_speed

    ratio = (temp - min_temp) / (max_temp - min_temp).to_f
    speed = (min_speed + (max_speed - min_speed) * ratio).to_i
    speed = max_speed if speed > max_speed
  end

  speed
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
    `/usr/bin/nvidia-settings -a [gpu:0]/GPUFanControlState=1 -a [fan:0]/GPUTargetFanSpeed=#{speed}`
  end
end

private

def run
  last_temp = get_current_temp
  last_speed = get_next_fan_speed(last_temp)
  set_fan_speed(last_speed)

  puts "Start speed contorl. Temperature is #{last_temp}.  Setting fan speed to #{last_speed}."

  while true do
    sleep config.refresh_interval

    temp = get_current_temp
    if temp != last_temp
      next_speed = get_next_fan_speed(temp)
      puts "Current temperature is #{temp}.  Setting fan speed to #{next_speed} (from #{last_speed})."

      set_fan_speed(next_speed)
      last_speed = next_speed
    else
      puts "Current temperature is #{temp}.  No adjustments needed."
    end
  end
end

def config
  @config ||= Config.new
end

class Config
  require 'yaml'

  def initialize
    @config = YAML.load_file(File.join(__dir__, 'config.yml'))
  end

  def min_speed
    effective_config_in_time['min_speed']
  end

  def max_speed
    effective_config_in_time['max_speed']
  end

  def min_temp
    effective_config_in_time['min_temp']
  end

  def max_temp
    effective_config_in_time['max_temp']
  end

  def refresh_interval
    @config['refresh_interval'] || 5
  end

  private

  def effective_config_in_time
    cfg = {}
    base_keys = ['min_temp', 'max_temp', 'min_speed', 'max_speed']
    base_keys.each do |k|
      cfg[k] = @config['default'][k]
    end

    custom_keys = @config['default'].keys - base_keys
    custom_keys.each do |range|
      if current_time_falls_in_range?(range)
        base_keys.each do |k|
          v = @config['default'][range][k]
          cfg[k] = v if v
        end
      end
    end

    cfg
  end

  def current_time
    @time ||= Time.now.getlocal(@config['time_zone'])
  end

  def current_time_falls_in_range?(range)
    start_time, end_time = range.split('-')
    current = current_time.hour * 60 + current_time.min
    start_time = config_time_to_min(start_time)
    end_time = config_time_to_min(end_time)

    if start_time < end_time
      return current >= start_time && current <= end_time
    end

    # Handle the case like:
    # 11:00-2:00
    # 2:00 is the second day
    if start_time > end_time
      return current >= start_time || current <= end_time
    end
  end

  def config_time_to_min(str)
    h, m = str.split(':')
    h.to_i * 60 + m.to_i
  end
end

def shut_down
  puts 'Exiting program, restore fan control to AUTO'
  set_fan_speed(SPEED_AUTO)
end

# Trap ^C
Signal.trap('INT') do
  shut_down
  exit
end

# Trap `Kill `
Signal.trap('TERM') do
  shut_down
  exit
end

begin
  run()
ensure
  shut_down
end
