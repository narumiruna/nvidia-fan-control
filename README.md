# Nvidia Fan Control
- Spoofs a display to control the fan speed of an NVIDIA GPU on a headless linux system.
- Supports a configuration file to set the max/min fan speed based on time

# Installation
```shell
sudo apt-get install ruby2.3

git clone https://github.com/narumiruna/nvidia-fan-control
cd nvidia-fan-control && sudo ./fan-control
```

# Configuration
```yaml
time_zone: '+08:00'
# Devices to be controlled
devices: [0, 1]
# The interval to check and set fan speed
refresh_interval: 5
# Config is in follow format:
# from_time-to_time:
#   min_temp: the script will only start working when min_temp is readched
#   max_temp: fan speed will always be max when reaching the max_temp
#   min_speed: the fan speed at min_temp
#   max_speed: the fan speed when temp is greater than max_temp
default:
  min_temp: 50
  max_temp: 85
  min_speed: 30
  max_speed: 60
  # Overwrite max_speed during 9:00 - 23:00
  9:00-23:00:
    max_speed: 60

  23:00-1:00:
    max_speed: 70

  1:00-8:00:
    max_speed: 80

  8:00-9:00:
    max_speed: 70
```
