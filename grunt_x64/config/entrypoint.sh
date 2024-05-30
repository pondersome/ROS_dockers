#!/bin/bash
set -e

# Start dbus
if ! pgrep -x "dbus-daemon" > /dev/null; then
    service dbus start
fi

# Always start the services
service ssh start

# Start X server for display :0 if not already running
if ! pgrep -x "Xorg" > /dev/null; then
    Xvfb :0 -screen 0 1920x1080x16 &
fi

# Start X server for display :2 if not already running
if ! pgrep -x "Xvfb" > /dev/null; then
    Xvfb :2 -screen 0 1920x1080x16 &
fi

# Set DISPLAY variable and start Xfce session for display :0
export DISPLAY=:0
if ! pgrep -x "xfce4-session" > /dev/null; then
    dbus-launch startxfce4 &
fi

# Set DISPLAY variable and start Xfce session for display :2
export DISPLAY=:2
if ! pgrep -x "xfce4-session" > /dev/null; then
    dbus-launch startxfce4 &
fi

# Start XRDP
service xrdp start
service xrdp start --config /etc/xrdp/xrdp_display2.ini

# Keep the container running
#tail -f /dev/null

# Check if the first argument is 'bash'
if [ "$1" = 'bash' ]; then
  # Start an interactive shell
  exec /bin/bash
else
  # Run the provided command or fall back to an infinite loop
  exec "$@" || tail -f /dev/null
fi
