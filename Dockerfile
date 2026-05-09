FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends fpc \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY main.pas .
RUN fpc main.pas

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /src/main /app/main
ENV REPORT_TITLE="Daily Run Summary" \
    GREETING="Hello, World!" \
    LOG_LEVEL="INFO" \
    ITEM_COUNT="5"
CMD ["/app/main"]
