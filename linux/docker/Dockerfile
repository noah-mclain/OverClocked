FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Install necessary packages and Python dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing build-essential \
    lm-sensors \
    smartmontools \
    ifstat \
    sudo \
    sysstat \
    iproute2 \
    pciutils \
    systemd \
    bc \
    curl \
    gnome-terminal \
    zenity \
    mesa-utils \
    libnotify-bin \
    radeontop \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libssl-dev \
    libegl1 \
    libgl1 \
    sqlite3 \
    dbus-x11 \
    x11-apps \
    python3 \
    python3-pip \
    python3-venv \ 
    docker.io && \
    rm -rf /var/lib/apt/lists/*

# Run sensors-detect (no need for sudo in a Docker container)
RUN yes "" | sensors-detect || true

ARG HOST_OS
ARG ENTRYPOINT_DIR

# Set HOST_OS based on HOST_OS passed from environment variables
ENV HOST_OS=$HOST_OS
ENV ENTRYPOINT_DIR=$ENTRYPOINT_DIR

# Set the working directory
WORKDIR /app

# Create logs directory
RUN mkdir -p /app/logs

# Copy scripts, config, and requirements.txt into the container
COPY ./docker/entrypoint.sh /app/docker/entrypoint.sh   
COPY ./config/config.yaml /app/config/config.yaml  
COPY ./docs/requirements.txt /app/requirements.txt 
COPY ./templates /app/templates
COPY ./static/css/report_style.css /app/static/css/report_style.css
COPY ./scripts /app/scripts                      
COPY ./linux/collect_linux_metrics.sh /app/linux/collect_linux_metrics.sh  
COPY ./macos/collect_macos_metrics.sh /app/macos/collect_macos_metrics.sh

# Install Python dependencies
RUN pip install --no-cache-dir -r /app/requirements.txt

# Make entrypoint script executable
RUN chmod +x /app/docker/entrypoint.sh
RUN chmod +x /app/config/config.yaml
RUN chmod +x /app/requirements.txt
RUN chmod +x /app/scripts
RUN chmod +x /app/linux/collect_linux_metrics.sh
RUN chmod +x /app/macos/collect_macos_metrics.sh

# Expose port 5001 for the application (adjust if necessary)
EXPOSE 5001

RUN ls -l /app

# Set entry point using the environment variable for the entrypoint directory
ENTRYPOINT ["/app/docker/entrypoint.sh"]

# Command to run when starting the container
CMD ["bash", "scripts/gui.sh"]
