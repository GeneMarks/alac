# alac 🎧
Swift tool to ease the process of converting audio files to and from Apple's ALAC format via ffmpeg.

https://user-images.githubusercontent.com/68919132/220812283-298bf10c-1546-4ef6-abc8-e01010afbbe7.mp4

## Features
- Converts single files or whole folders recursively to flacs/m4as(alacs) using [ffmpeg](https://en.wikipedia.org/wiki/FFmpeg)
- Keeps embedded tags and album art
- Multi-threading to simultaneously convert groups of audio files (Useful for large collections)
- Progress bar with ETA for batch conversions
- Moves src files to trash after conversion

## Prerequisites
- macOS (Developed on macOS 13.2.1)
- ffmpeg installed via [HomeBrew](https://formulae.brew.sh/formula/ffmpeg#default)

## Usage
`alac <input> [--threads <threads>] [--recursive] [--revert]`

### Examples
Convert single flac file to alac:

`alac "~/Music/Lesley Gore/Lesley Gore Sings Of Mixed-Up Hearts/6 - Sunshine, Lollipops And Rainbows.flac"`

Convert an album to alac:

`alac "~/Music/Lesley Gore/Lesley Gore Sings Of Mixed-Up Hearts"`

Convert entire flac collection to alac using 4 threads:

`alac "~/Music" --threads 4 --recursive`

Convert an artist's albums to flac from m4a(alac)

`alac "~/Music/Lesley Gore/" --recursive --revert`

## Notes
Alac and Flac are both lossless formats. You can convert back and forth without worrying about loss of quality, as shown here:

![spek-alac](https://user-images.githubusercontent.com/68919132/220459441-36bb3ef5-0f1b-49d8-a5db-f5ea5405f93d.png)
![spek-flac](https://user-images.githubusercontent.com/68919132/220459443-8832a581-5280-48a8-a1d9-94d3743987e4.png)

## Credits
- [ffmpeg](https://en.wikipedia.org/wiki/FFmpeg)
- [swift-tqdm](https://github.com/ebraraktas/swift-tqdm)
