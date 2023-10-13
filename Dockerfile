# Set main arguments.
ARG ROS_DISTRO=humble
ARG LOCAL_WS_DIR=workspace

# ==== ROS Build Stages ====

# ==== Base ROS Build Image ====
FROM ros:${ROS_DISTRO}-ros-base AS build-base
LABEL component="com.invensense.cloud"
LABEL build_step="ROSBaseNode_Build"

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F42ED6FBAB17C654
RUN apt-get update && apt-get install python3-pip -y
RUN apt-get update && apt-get install ros-$ROS_DISTRO-example-interfaces
RUN python3 -m pip install awsiotsdk

# ==== Package 2: Greengrass Bridge Node ==== 
FROM build-base AS greengrass-bridge-package
LABEL component="com.invensense.cloud"
LABEL build_step="GreengrassBridgeROSPackage_Build"
ARG LOCAL_WS_DIR

COPY ${LOCAL_WS_DIR}/src /ws/src
WORKDIR /ws

# Cache the colcon build directory.
RUN --mount=type=cache,target=${LOCAL_WS_DIR}/build:/ws/build \
    . /opt/ros/$ROS_DISTRO/setup.sh && \
    colcon build \
     --install-base /opt/greengrass_bridge

# ==== ROS Runtime Image (with only the Greengrass package) ====
FROM build-base AS runtime-image
LABEL component="com.invensense.cloud"

COPY --from=greengrass-bridge-package /opt/greengrass_bridge /opt/greengrass_bridge

# Add the application source file to the entrypoint.
WORKDIR /
COPY app_entrypoint.sh /app_entrypoint.sh
RUN chmod +x /app_entrypoint.sh
ENTRYPOINT ["/app_entrypoint.sh"]