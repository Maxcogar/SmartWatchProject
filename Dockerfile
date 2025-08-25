FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get update && apt-get install -y \
    git curl wget python3 python3-pip xz-utils flex bison gperf \
    libffi-dev libssl-dev dfu-util cmake ninja-build ccache \
    libusb-1.0-0 && \
    rm -rf /var/lib/apt/lists/*

# Install PowerShell
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y powershell && \
    rm packages-microsoft-prod.deb && rm -rf /var/lib/apt/lists/*

# Install ESP-IDF
ENV IDF_PATH=/opt/esp/esp-idf
ENV IDF_TOOLS_PATH=/opt/esp/idf-tools
RUN git clone --recursive https://github.com/espressif/esp-idf.git $IDF_PATH && \
    bash $IDF_PATH/install.sh esp32s3 && \
    echo ". $IDF_PATH/export.sh" >> /etc/profile.d/esp-idf.sh

# Python requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

WORKDIR /workspace
SHELL ["/bin/bash", "-c"]
