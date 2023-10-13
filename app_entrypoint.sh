#!/bin/bash
set -e

# setup ros2 environment
source "/opt/greengrass_bridge/setup.bash"
exec "$@"