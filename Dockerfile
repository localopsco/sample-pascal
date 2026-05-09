# --- Build stage: install Free Pascal and compile the worker ---
FROM debian:bookworm-slim AS build

# Install the Free Pascal Compiler (fpc); clean apt cache to keep the layer small
RUN apt-get update && apt-get install -y --no-install-recommends fpc \
  && rm -rf /var/lib/apt/lists/*

# Working directory for the source files
WORKDIR /src

# Copy the Pascal source into the build stage
COPY main.pas .

# Compile the program; fpc emits a binary named after the source file ("main")
RUN fpc main.pas

# --- Runtime stage: ship only the compiled binary ---
FROM debian:bookworm-slim
WORKDIR /app

# Pull the compiled binary from the build stage; source and .o files stay behind
COPY --from=build /src/main /app/main

# Run the worker loop in the foreground so docker can stream logs and forward signals
CMD ["/app/main"]
