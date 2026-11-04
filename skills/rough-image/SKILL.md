---
name: rough-image
description: "Turn a reference image of a character into a deliberately crude Japanese anime-style digital doodle (thick uneven black outlines, flat crayon/marker color blocks with gaps, sloppy white highlights, 1:1 white background) while keeping the character recognizable by hairstyle, hair color, eyes, outfit and accessories. Sends a fixed prompt plus the reference image to the available image generation tool, or outputs the prompt when no such tool exists. Use when the user supplies a character image and asks to make it look rough, scribbled or low-effort — e.g. 「ラフ画風にして」「落書き風にして」「雑に描いた感じにして」「クレヨンで描いたみたいに」 — or asks for the rough-image prompt itself. Not for clean or polished illustrations."
---

# rough-image

Redraws the character from a reference image as a crude Japanese anime doodle by giving an image model the prompt below together with that image.

## Procedure

1. Get the reference image. If the user has not attached one, ask for it. Do not invent a character from a text description, because the prompt's whole job is to preserve a specific character's look.
2. Send the prompt in the "Prompt" section verbatim to the image generation or editing tool your environment provides, with the reference image attached as an image input. Attach the image itself rather than describing the character in words; the model needs to see the original to keep hairstyle, colors and outfit intact.
3. If no image generation tool is available, output the prompt in a code block and tell the user to paste it, together with the reference image, into an image generation tool.

## Prompt

```text
Convert the character in the reference image into a rough Japanese anime-style digital doodle (rakugaki / 落書き).

Overall style:
An extremely rough, sloppy, childlike digital doodle of a Japanese moe anime character, as if quickly scribbled with the coarse crayon and marker brushes of a basic paint program. Keep what makes the original character recognizable: hairstyle, hair color, facial features, outfit, accessories, and signature expression.

Line art:
- Trace the figure with bold, rough black strokes.
- Line width is very uneven: suddenly thick in places, broken off in others.
- Contours are loose, inaccurate, and slightly distorted.
- Lines show clear hand-drawn grain and patchy ink.
- Do not aim for precise lines; allow misaligned, overlapping, and incomplete strokes.
- No fine, smooth vector line art.

Coloring:
- Large areas of opaque, simple flat color.
- Color spills past the outlines; missed spots and white gaps are fine.
- Shadows: only a few rough strokes of gray or a darker shade of the same hue.
- Highlights: short white strokes dabbed on carelessly.
- Keep a coarse mixed texture of crayon, pastel, and marker.
- No complex gradients, detailed lighting, or rich color layering.

Face:
- Keep the original eye color, eye shape, and signature expression.
- Simplify the facial features moderately; draw the eyes with thick black lines and simple blocks of color.
- Keep the mouth as simple as possible; the nose may be omitted.
- Add a few casual pink blush strokes on the cheeks.
- Keep the expression true to the original character; do not change their personality or mood.

Hair and outfit:
- Keep exactly the hairstyle and hair color that make the character most recognizable.
- Build the hair from a few large color blocks; do not draw many individual strands.
- Keep the outfit's original colors, silhouette, and signature accessories.
- Heavily simplify clothing folds and decorations.
- Do not change the outfit or add accessories that are not in the reference image.

Composition:
- 1:1 square canvas.
- Half-body portrait, with the head drawn slightly larger than normal proportions.
- Character centered, with natural white margins.
- Plain white background; no text, no complex scenery, no decorative frames.

Most important style constraint:
The image must look genuinely crude, messy, simple, and childlike, like a cute hand-drawn anime doodle. It must not be a polished illustration made to imitate a rough sketch.

No automatic cleanup or polishing, no fine line art, no complex hair structure, no subtle gradients, no 3D effects, no heavy lighting or shading, no added clothing details.

Final result: a low-finish Japanese anime digital doodle with thick black outlines, large flat color blocks, careless white highlights, and visible crayon grain.
```
