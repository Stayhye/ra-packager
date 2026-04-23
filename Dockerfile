# Use the official PS2 development image as the base
FROM ps2dev/ps2dev:latest

# 1. Install standard Linux tools needed for MAME/RetroArch
# Using 'apk' because ps2dev is based on Alpine Linux
RUN apk add --no-cache build-base git bash cmake python3 patch

# 2. Set the environment variables permanently
# This makes sure ee-gcc is ALWAYS in the path
ENV PS2DEV=/usr/local/ps2dev
ENV PS2SDK=$PS2DEV/ps2sdk
ENV PATH=$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin:$PS2SDK/bin

# 3. Create a workspace directory
WORKDIR /src

# Set the default shell to bash (helps with your .sh scripts)
SHELL ["/bin/bash", "-c"]
