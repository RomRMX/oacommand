# OA Command

Native iPadOS showroom controller for Origin Acoustics audio streaming amplifiers.

## Features

- 🌙 Dark mode glassmorphism UI
- 📡 mDNS device discovery (Bonjour)
- 🎚️ Volume control with horizontal sliders
- ▶️ Play/Pause, Forward, Rewind, Mute controls
- 🟢 WiiM (Linkplay) device support
- 🔵 Bluesound architecture ready
- 📺 Landscape-optimized iPad layout

## Audio Zones

18 demo zones configured:
- Conference Room: MOS, 602, 802 Sub, 803
- Lobby: PS80, Pendants
- Showroom: Pendants, P10Sub (x4), Pro Pendants
- Planter Wall: ASM63, ALSB106, ALSB85, ALSB64, LSH80, LSH60, LSH40
- Hallway: Planter
- Front Yard: Bollards

## Requirements

- Xcode 15+
- iOS 17.0+ / iPadOS 17.0+
- Swift 5.9+

## Building

1. Open `OriginCommand.xcodeproj` in Xcode
2. Select iPad target
3. Build and Run (⌘R)

## API Integration

### WiiM (Linkplay) Commands
- `GET /httpapi.asp?command=getPlayerStatus` - Get status
- `GET /httpapi.asp?command=setPlayerCmd:vol:[0-100]` - Set volume
- `GET /httpapi.asp?command=setPlayerCmd:mute:[0|1]` - Toggle mute
- `GET /httpapi.asp?command=setPlayerCmd:onepause` - Play/Pause
- `GET /httpapi.asp?command=MCUKeyShortClick:1` - Preset 1

## License

Proprietary - Origin Acoustics
