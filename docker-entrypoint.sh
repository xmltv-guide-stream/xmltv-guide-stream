#!/bin/sh
set -e

# Defaults if unset or empty (null)
: "${XMLTV_SRC:=http://localhost:8409/iptv/xmltv.xml}"
: "${XMLTV_TZ:=$(cat /etc/timezone 2>/dev/null || echo UTC)}"
: "${XMLTV_HOURS:=2}"
: "${XMLTV_RESOLUTION:=1280x720}"
: "${XMLTV_PORT:=8000}"
: "${XMLTV_VCODEC:=libx264}"
: "${XMLTV_BITRATE:=3000k}"
: "${XMLTV_MAXRATE:=${XMLTV_BITRATE}}"
: "${XMLTV_BUFSIZE:=6000k}"
: "${XMLTV_THEME:=classic}"
: "${XMLTV_THEME_FILE:=}"

# Build args safely
set -- python3 /xmltv_guide_stream.py \
  --xmltv "$XMLTV_SRC" \
  --tz "$XMLTV_TZ" \
  --hours "$XMLTV_HOURS" \
  --res "$XMLTV_RESOLUTION" \
  --http-port "$XMLTV_PORT" \
  --bitrate "$XMLTV_BITRATE" \
  --maxrate "$XMLTV_MAXRATE" \
  --bufsize "$XMLTV_BUFSIZE" \
  --font /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf

# Theme-file overrides theme if present
if [ -n "$XMLTV_THEME_FILE" ]; then
  if [ ! -f "$XMLTV_THEME_FILE" ]; then
    echo "ERROR: XMLTV_THEME_FILE set but file not found: $XMLTV_THEME_FILE" >&2
    exit 1
  fi
  set -- "$@" --theme-file "$XMLTV_THEME_FILE"
else
  set -- "$@" --theme "$XMLTV_THEME"
fi

case "$XMLTV_VCODEC" in
  h264_nvenc|hevc_nvenc)
    : "${XMLTV_NVPRESET:=p5}"
    : "${XMLTV_RC:=cbr}"
    set -- "$@" --vcodec "$XMLTV_VCODEC" --nvenc-preset "$XMLTV_NVPRESET" --rc "$XMLTV_RC"
    ;;
  *)
    # libx264 / other SW encoders
    set -- "$@" --vcodec "$XMLTV_VCODEC"
    ;;
esac

exec "$@"
