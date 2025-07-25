# Step 1: Building the game using Godot
FROM ubuntu:22.04 AS builder

ENV GODOT_VERSION=4.4.1
ENV EXPORT_NAME=monke-sim
ENV EXPORT_DIR=/export
ENV PROJECT_PATH=/project
ENV TEMPLATES_URL=https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz
ENV TEMPLATES_DIR=/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable

RUN apt-get update && \
    apt-get install -y wget unzip ca-certificates libx11-dev libxcursor-dev libxrandr-dev libxinerama-dev libgl1-mesa-glx libasound2 libfontconfig1 git

# Download Godot for Linux
RUN wget https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip && \
    unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip && \
    mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot && \
    chmod +x /usr/local/bin/godot

# Download and install export templates
RUN mkdir -p $TEMPLATES_DIR && \
    wget -qO /tmp/templates.tpz $TEMPLATES_URL && \
    unzip /tmp/templates.tpz -d /tmp/templates && \
    mv /tmp/templates/templates/* $TEMPLATES_DIR && \
    rm -rf /tmp/templates /tmp/templates.tpz

# Copy game files into image
WORKDIR $PROJECT_PATH
COPY . .

# Exporting the game server
RUN mkdir -p $EXPORT_DIR && \
    godot --headless --path /project --export-release "Linux" "$EXPORT_DIR/${EXPORT_NAME}.x86_64" 

# Step 2: Create minimal runtime image
FROM ubuntu:22.04

WORKDIR /app

# Install required runtime libs
RUN apt-get update && \
    apt-get install -y libx11-6 libxcursor1 libxrandr2 libxinerama1 libgl1-mesa-glx libasound2 libfontconfig1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy exported server binary from builder stage
COPY --from=builder /export/ /app/

# Make scripts/binaries executable
RUN chmod 755 /app/

EXPOSE 8698/udp

# Run the game server in headless mode
CMD ["./monke-sim.x86_64", "--headless", "--server"]
