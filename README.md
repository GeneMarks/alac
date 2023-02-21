# alac 🎧
Swift tool to ease the process of converting audio files to and from Apple's ALAC format via ffmpeg.

## Features
- Converts single files or whole folders recursively to flacs/m4as(alacs) using [ffmpeg](https://en.wikipedia.org/wiki/FFmpeg)
- Keeps embedded tags and album art
- Multi-threading to simultaneously convert groups of audio files (Useful for large collections)
- Moves src files to trash after conversion

## Prerequisites
- macOS (Developed on macOS 13.2.1)
- ffmpeg installed via [HomeBrew](https://formulae.brew.sh/formula/ffmpeg#default)

## Usage
`alac <input> [--threads <threads>] [--recursive] [--revert]`

### Examples
Convert single flac file to alac:

`alac "~/Music/Lesley Gore/Lesley Gore Sings Of Mixed-Up Hearts/6 - Sunshine, Lollipops And Rainbows.flac"`

Convert entire flac collection to alac using 4 threads:

`alac "~/Music" --threads 4 --recursive`

Convert an artist's albums to flac from m4a(alac)

`alac "~/Music/Lesley Gore/" --revert`

## Credits
- [ffmpeg](https://en.wikipedia.org/wiki/FFmpeg)
