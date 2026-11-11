# Quantum World: Avatar Art Direction (Draft v0.1)

This document sets the visual target for avatars. Where it conflicts with the avatar lines in `GAMEPLAY-3D.md` section 4, this document wins. Production rules are in `ASSET-PIPELINE.md`.

## 1. Target Look

The target is a **detailed anime illustration style**, not a blocky or chubby look. Mood reference: a commercial stock pack of anime character portraits (clean line art, saturated hair colors, large expressive eyes with highlights, sharp layered hair strands, 2 to 3 tone cel shading, many different character types). It is a **mood reference only** (see section 6).

Key traits to carry into 3D:

- **Faces:** large, expressive eyes with a layered iris, highlights and upper lash line; small nose and mouth; clear brows; strong emotion range.
- **Hair:** the signature element. Layered, angular strands and cards with colored highlight bands, bold colors (blue, red, violet, green, silver, orange, black, brown, blonde), bangs that frame the face, plus ponytails, braids, short cuts, long hair.
- **Line and shading:** clean outline with slight thickness variation, flat two or three tone shading, soft rim light, a controllable face shadow so the face never looks muddy.
- **Variety, not one template:** a wide cast in look and age. Teens through adults and older characters, different face shapes, skin tones, glasses, headphones, piercings, scars, facial hair, tech implants. This variety is a selling point of the character creator.
- **Tone:** cool, confident, expressive. Not childish, not sexualized.

## 2. Translating Illustration into Real-Time 3D

| Element | Approach |
|---|---|
| Face | Hand-modeled head with a clean topology; blendshapes for brows, eyes, mouth and about 8 to 10 expressions (smile, grin, serious, surprised, angry, sad, smug, tired, determined) |
| Eyes | Multi-layer eye shader: iris gradient, pupil, highlight sprites, slight parallax; eyelids that follow the eye |
| Face shading | Face normals controlled by a shadow vector (a standard technique in anime games) so shading stays clean |
| Hair | Hair cards or strips with a banded highlight shader, bone chains for cheap secondary motion, strict triangle budget |
| Outline | Inverted hull or post-process outline with per-material thickness; fade with distance |
| Body | Slim, elegant proportions around 7 to 8 heads, a few base bodies, clothes as separate parts with simple cloth bones |
| Hands and feet | Simple but clean; no extra detail budget |
| Phone budget | About 15k triangles per avatar at LOD0, LOD1 about 6k, billboard or impostor in the distance; one atlas texture up to 1024 px per avatar part group |

Faces are the hardest part of anime in 3D and the most important for appeal. Plan most of the art budget for the head, hair and eyes.

## 3. Character Creator Scope (first season)

- **Faces:** 6 to 8 face presets with sliders for eye size and spacing, brow shape, jaw.
- **Hair:** about 30 styles, hair and highlight colors, plus accessories (clips, bands, headphones, glasses).
- **Age feel and build:** a young adult range as the default, plus selected older looks as unlockable presets.
- **Skin tones and eye colors:** broad range.
- **Outfits:** streetwear, techwear, casual, fantasy, with color variants. Every item follows the content rules below.
- **Extras:** auras, tails or wings as optional cosmetics, emote and pose sets.

## 4. Portraits and UI

Players are identified by a **portrait image** in the Nexus, crews, friend lists and chat. Portraits are **rendered from the player's 3D avatar** in a portrait scene with fixed lighting, camera and outline, so no separate 2D art is needed and every customization shows up automatically. Expressions are selectable. Portraits are generated locally; only avatar parameters travel over the network.

## 5. Content Rules (unchanged and binding)

All avatars and items are fully clothed. No sexualized outfits, poses, expressions or body options, no nudity, no exaggerated body features. The audience starts at age 12. Only approved parts exist in the kit; every new item passes the review in `ASSET-PIPELINE.md` (automated check plus a human reviewer).

## 6. Licensing of the Reference

The reference is a third-party commercial asset pack. Do not copy, trace, import, or train or fine-tune any model on its art, and do not ship its images in the game. Use it only to communicate the style direction. If its portraits are wanted as temporary UI placeholders for internal prototypes, check the exact license terms of that pack first (use in a shipped product, redistribution of source files, AI use), and replace them before release. For the final game, all character art must be original or properly licensed so the brand is protectable.

## 7. Production Paths (to evaluate)

1. **Commission a 3D character artist** for the base rigs, head, hair and eye shaders, then scale with AI-assisted textures and variants. Highest quality, most reliable.
2. **VRoid Studio as a bridge for prototyping:** quickly create anime characters as VRM files and import them into Godot with a VRM addon and a toon (MToon-like) shader. Check the current VRoid and preset-part license terms for commercial use, and expect to optimize triangle counts and materials for phones before shipping.
3. **Hybrid:** use VRoid-style outputs for early tests while an artist builds the production kit.

## 8. Next Steps

- Write a one-page style bible with 6 to 10 original character concepts in the target style (AI-assisted concepts, art director selection).
- Build a **character test scene** in Godot: toon shader, outline, eye shader, face shadow control and hair highlight on one imported test character, measured on real phones for frame rate and heat.
- Decide the production path in section 7.

## 9. Open Questions

1. Which production path: commission, VRoid bridge, or hybrid?
2. How wide should the age range of the cast be at launch?
3. Who is the art director who selects and approves concepts?
4. Budget for the head, hair and eye shader work?
