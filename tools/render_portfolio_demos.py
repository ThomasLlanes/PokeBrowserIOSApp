from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from moviepy import (
    AudioArrayClip,
    AudioFileClip,
    CompositeAudioClip,
    CompositeVideoClip,
    ImageClip,
    VideoFileClip,
    concatenate_videoclips,
)


ROOT = Path("/Users/codigodelsur/Documents/GitHub/Owners-Git/PokeBrowserIOSApp")
SOURCE = Path("/Users/codigodelsur/Desktop/Simulator Screen Recording - iPhone 17 Pro - 2026-05-16 at 13.29.11.mov")
OUT_DIR = ROOT / "demo_exports"
TMP_DIR = Path("/private/tmp/pokebrowser-demo-assets")


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def make_caption_image(
    text: str,
    width: int,
    *,
    title: bool = False,
    subtitle: str | None = None,
) -> Path:
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    image_width = int(width * 0.82)
    padding_x = 34
    padding_y = 22 if title else 18
    title_font = font(42 if title else 35, bold=True)
    subtitle_font = font(24, bold=False)

    lines = [text]
    text_heights = []
    probe = Image.new("RGBA", (image_width, 400), (0, 0, 0, 0))
    draw = ImageDraw.Draw(probe)
    for line in lines:
        box = draw.textbbox((0, 0), line, font=title_font)
        text_heights.append(box[3] - box[1])
    subtitle_height = 0
    if subtitle:
        box = draw.textbbox((0, 0), subtitle, font=subtitle_font)
        subtitle_height = box[3] - box[1] + 12

    image_height = padding_y * 2 + sum(text_heights) + subtitle_height
    image = Image.new("RGBA", (image_width, image_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    radius = 28
    draw.rounded_rectangle(
        [0, 0, image_width - 1, image_height - 1],
        radius=radius,
        fill=(14, 16, 22, 202),
    )

    y = padding_y
    for line in lines:
        box = draw.textbbox((0, 0), line, font=title_font)
        x = (image_width - (box[2] - box[0])) // 2
        draw.text((x, y), line, font=title_font, fill=(255, 255, 255, 255))
        y += box[3] - box[1]
    if subtitle:
        y += 12
        box = draw.textbbox((0, 0), subtitle, font=subtitle_font)
        x = (image_width - (box[2] - box[0])) // 2
        draw.text((x, y), subtitle, font=subtitle_font, fill=(228, 232, 240, 245))

    name = "".join(ch.lower() if ch.isalnum() else "_" for ch in (text + (subtitle or "")))[:64]
    path = TMP_DIR / f"{name}.png"
    image.save(path)
    return path


def caption_clip(
    text: str,
    start: float,
    duration: float,
    width: int,
    height: int,
    *,
    title: bool = False,
    subtitle: str | None = None,
    y: float = 0.79,
) -> ImageClip:
    image_path = make_caption_image(text, width, title=title, subtitle=subtitle)
    return (
        ImageClip(str(image_path), transparent=True)
        .with_duration(duration)
        .with_start(start)
        .with_position(("center", int(height * y)))
    )


def assemble_base() -> tuple[VideoFileClip, list[tuple[str, float, float]]]:
    source = VideoFileClip(str(SOURCE))
    segments = [
        ("intro", 0.0, 3.5, 1.25),
        ("browse", 5.0, 8.8, 1.40),
        ("detail", 15.0, 25.8, 1.60),
        ("refs", 30.0, 36.0, 2.00),
        ("favorites", 40.0, 45.0, 2.00),
        ("teams", 50.0, 80.1, 2.10),
    ]

    clips = []
    timeline = []
    cursor = 0.0
    for name, start, end, speed in segments:
        clip = source.subclipped(start, min(end, source.duration)).with_speed_scaled(speed)
        clips.append(clip)
        timeline.append((name, cursor, clip.duration))
        cursor += clip.duration

    final = concatenate_videoclips(clips, method="compose").resized(width=720).with_fps(30)
    return final, timeline


def make_music(duration: float, volume: float = 0.075) -> AudioArrayClip:
    sample_rate = 44100
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    chords = [
        (261.63, 329.63, 392.00),
        (220.00, 293.66, 349.23),
        (246.94, 311.13, 392.00),
        (196.00, 261.63, 329.63),
    ]
    audio = np.zeros_like(t)
    beat = 0.34
    for i in range(int(duration / beat) + 1):
        chord = chords[i % len(chords)]
        start = int(i * beat * sample_rate)
        end = min(start + int(beat * sample_rate), len(t))
        if start >= len(t):
            break
        local_t = t[: end - start]
        freq = chord[i % len(chord)]
        envelope = np.exp(-local_t * 4.2)
        audio[start:end] += np.sin(2 * math.pi * freq * local_t) * envelope
        audio[start:end] += 0.35 * np.sin(2 * math.pi * (freq * 2) * local_t) * envelope

    pad = int(sample_rate * 0.35)
    if pad > 0:
        fade_in = np.linspace(0, 1, pad)
        fade_out = np.linspace(1, 0, pad)
        audio[:pad] *= fade_in
        audio[-pad:] *= fade_out

    audio = np.clip(audio * volume, -1, 1)
    stereo = np.column_stack([audio, audio])
    return AudioArrayClip(stereo, fps=sample_rate).with_duration(duration)


def write_video(video: CompositeVideoClip, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    video.write_videofile(
        str(output),
        fps=30,
        codec="libx264",
        audio_codec="aac",
        preset="medium",
        bitrate="4800k",
        threads=4,
    )


def captions_music_version() -> Path:
    base, timeline = assemble_base()
    width, height = base.size
    starts = {name: (start, duration) for name, start, duration in timeline}
    overlays = [
        caption_clip("PokeBrowser", 0.1, 2.6, width, height, title=True, subtitle="SwiftUI Pokemon companion", y=0.72),
        caption_clip("Browse Pokemon", starts["browse"][0], starts["browse"][1], width, height),
        caption_clip("Inspect sprites, types, abilities, and stats", starts["detail"][0], starts["detail"][1], width, height),
        caption_clip("Items, berries, and favorites", starts["refs"][0], starts["refs"][1] + starts["favorites"][1], width, height),
        caption_clip("Build a team", starts["teams"][0], 4.0, width, height, title=True, y=0.72),
        caption_clip("Choose Pokemon and assign held items", starts["teams"][0] + 4.0, 5.0, width, height),
        caption_clip("Save your lineup", starts["teams"][0] + 9.0, 4.0, width, height),
        caption_clip("SwiftUI • MVVM • PokeAPI", max(0, base.duration - 2.8), 2.7, width, height, y=0.72),
    ]
    final = CompositeVideoClip([base, *overlays]).with_audio(make_music(base.duration, 0.085))
    output = OUT_DIR / "PokeBrowser_Portfolio_Captions_Music.mp4"
    write_video(final, output)
    return output


def voiceover_version() -> Path:
    base, timeline = assemble_base()
    width, height = base.size
    starts = {name: (start, duration) for name, start, duration in timeline}
    overlays = [
        caption_clip("PokeBrowser", 0.1, 2.7, width, height, title=True, subtitle="SwiftUI • MVVM • PokeAPI", y=0.72),
        caption_clip("Pokemon data", starts["detail"][0], starts["detail"][1], width, height, y=0.82),
        caption_clip("Team builder", starts["teams"][0], 5.5, width, height, title=True, y=0.72),
        caption_clip("Saved teams with held items", starts["teams"][0] + 7.0, 5.6, width, height, y=0.82),
    ]

    voice_path = TMP_DIR / "pokebrowser_voiceover.aiff"
    if not voice_path.exists():
        raise FileNotFoundError(
            "Generate the voiceover first with macOS say at "
            f"{voice_path}"
        )
    voice = AudioFileClip(str(voice_path)).with_volume_scaled(1.6)
    music = make_music(base.duration, 0.035)
    audio = CompositeAudioClip([music, voice.with_start(0.45)]).with_duration(base.duration)
    final = CompositeVideoClip([base, *overlays]).with_audio(audio)
    output = OUT_DIR / "PokeBrowser_Portfolio_Voiceover.mp4"
    write_video(final, output)
    return output


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    if target in ("all", "captions"):
        print(captions_music_version())
    if target in ("all", "voiceover"):
        print(voiceover_version())


if __name__ == "__main__":
    main()
