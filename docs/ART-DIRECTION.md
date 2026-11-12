# Quantum World: Avatar Art Direction (Draft v0.3)

This document sets the visual and animation target for avatars. Where it conflicts with the avatar lines in `GAMEPLAY-3D.md` section 4, this document wins. Production rules are in `ASSET-PIPELINE.md`.

## 1. Target Look

The target is a **detailed anime illustration style**, not a blocky or chubby look. Mood reference: a commercial stock pack of anime character portraits (clean line art, saturated hair colors, large expressive eyes with highlights, sharp layered hair strands, 2 to 3 tone cel shading, many different character types). It is a **mood reference only** (see section 8).

Key traits to carry into 3D:

- **Faces:** expressive eyes with a layered iris, highlights and upper lash line; small nose and mouth; clear brows. The **default expression is neutral to friendly**; strong joy appears only during celebrations.
- **Hair:** the signature element. Layered, angular strands and cards with colored highlight bands, bold colors, bangs that frame the face, ponytails, braids, short cuts, long hair.
- **Line and shading:** clean outline, flat two or three tone shading, soft rim light, a controllable face shadow so the face never looks muddy.
- **Variety, not one template:** a wide cast in look and build, different face shapes, skin tones, glasses, headphones, goggles, piercings, scars, facial hair, tech implants.
- **Tone:** cool, confident, expressive. Not childish, not sexualized.

## 2. Age Range

All playable avatars are **adults between 19 and 30**. Faces follow this: eyes somewhat smaller and calmer than in teen anime, a defined jaw (squarer for male, softer for female), mature brow shapes, no childlike proportions. Characters older than 30 may appear as unlockable presets later. The audience of the game starts at age 12; the content rules in section 7 apply regardless of the avatars' age.

## 3. Body: Natural Anatomy

Bodies use **natural, believable proportions** with a real joint structure, so they move convincingly. The details make it read as human.

**Skeleton and joints (all avatars):** hips, spine (waist), chest, neck, head; per arm shoulder (ball joint), elbow (hinge), wrist; per leg hip (ball joint), knee (hinge), ankle. Joints have overlapping joint volumes, so limbs bend without gaps. Rotation limits keep poses anatomically plausible.

**Proportions:** about 6.5 to 7 heads tall, long legs (roughly half of body height), natural limb segment ratios (thigh and shin about equal, upper arm slightly longer than forearm), slim neck and a natural shoulder line.

**Smooth silhouettes:** torso and limbs are built from smooth profile curves (waist, ribcage, shoulders; thigh, knee, calf bulge, ankle; upper arm, elbow, forearm, wrist), not from stacked blobs, so curves look natural and not clunky.

**Hands and feet:** hands have a palm, four fingers and a thumb with natural proportions; feet are shaped shoes or boots with toe box, heel and ankle. Extremities must look human at close range.

**Female build:** a natural silhouette with a defined waist, wider hips, softly rounded chest and legs, slimmer arms. Waist to hip ratio about 0.7. The "curve" slider is clamped to a moderate range.

**Male build:** broader shoulders and chest, visible pectoral and deltoid shape, defined biceps and forearms, stronger thighs and calves, thicker neck. The "muscle" slider scales definition within an athletic range; no extreme bodybuilder shapes.

**Sliders** are clamped to natural ranges. There are no options that exaggerate body features.

## 4. Translating Illustration into Real-Time 3D

| Element | Approach |
|---|---|
| Face | Clean head topology; eyes as shader-driven layers (iris gradient, pupil, highlights, lash line, lid); blendshapes for brows and mouth; about 8 to 10 expressions |
| Eyes | Multi-layer eye shader with blink and a "happy" closed-arc state for joy |
| Face shading | Controlled face shadow so shading stays clean |
| Hair | Hair strips with banded highlight shader, bone chains for secondary motion, strict triangle budget |
| Outline | Inverted hull outline with per-material thickness; fade with distance |
| Body | Articulated parts with joint volumes and smooth profiles; clothes as separate parts with simple cloth bones |
| Hands and feet | Fingers and thumb as small tubes, shaped shoes |
| Phone budget | Up to about 15k triangles per avatar at LOD0 (current generator: about 10k), LOD1 about 6k, billboard or impostor in the distance |

Faces are the hardest part of anime in 3D and the most important for appeal. Plan most of the art budget for the head, hair and eyes.

## 5. Animation and Emotes

**Locomotion** is joint-based: run cycle with hip, knee and ankle motion, counter-rotating hips and spine, bent elbows with arm swing opposite to the legs, head stabilization and body bob. Separate poses for jump rise and fall, glide, dash, landing squash, idle breathing and weight shift, blinking, hair sway.

**Emotes are earned, not random.** Characters celebrate only when the player achieves something, in three levels:

| Level | Trigger | Default animation |
|---|---|---|
| 1 (small) | A bronze result, every tenth shard | A friendly nod with a small gesture |
| 2 (medium) | A silver result | Cheer, or a twirl jump (female) or fist pump (male) |
| 3 (big) | A gold result, a level-up | Female: the **pirouette** (ballet-style spin on one leg on the toes, other leg in passe, arms overhead, two turns, open finish). Male: the double-biceps flex |

The player can also trigger the big celebration manually (G key or the HAPPY button). There are no random idle emotes. Any emote can be unlocked as a cosmetic for any avatar; the lists above are defaults. Other emotes: wave, cheer, twirl jump, fist pump.

**Style of motion:** graceful and expressive, never suggestive. Poses are reviewed against the content rules before release.

## 6. Character Creator Scope (first season)

- **Body type:** female or male build with clamped sliders (curve or muscle), height within a natural range.
- **Faces:** 6 to 8 face presets with sliders for eye size and spacing, brow shape, jaw, and a default expression (neutral or friendly).
- **Hair:** about 30 styles, hair and highlight colors, plus accessories (clips, bands, headphones, glasses, goggles).
- **Age feel:** within 19 to 30; skin tones and eye colors in a broad range.
- **Outfits:** streetwear, techwear, casual, fantasy, with variants: long, short or no sleeves, crop tops (bare midriff), tank tops, pants or shorts, coats, scarves. Every item follows the content rules.
- **Extras:** auras, tails or wings as optional cosmetics, emote and pose sets.

## 7. Content Rules (binding)

Avatars are always dressed: a top and trousers or shorts at minimum. **Sleeveless tops, tank tops, crop tops with a bare midriff, and shorts are allowed**; they are normal clothing and are not sexualized. Not allowed: nudity or underwear-only looks, transparent or revealing items, sexualized poses, expressions or camera angles, and any slider or option that exaggerates body features. Natural curves and muscle definition are fine; emphasis or exaggeration is not. The audience starts at age 12; the target rating is PEGI 12 / ESRB Teen or lower. Only approved parts exist in the kit; every new item and emote passes the review in `ASSET-PIPELINE.md` (automated check plus a human reviewer).

## 8. Licensing of the Reference

The reference is a third-party commercial asset pack. Do not copy, trace, import, or train or fine-tune any model on its art, and do not ship its images in the game. Use it only to communicate the style direction. For the final game, all character art must be original or properly licensed so the brand is protectable.

## 9. Implementation Status

A code-generated pass exists in the repository: `scripts/world3d/anime_avatar.gd` builds articulated avatars (about 10k triangles each) from the parameter presets in `scripts/world3d/avatar_presets.gd`: three female and two male characters between 20 and 27 years old, with natural proportions, smooth torso and limb profiles, fingers and shaped feet, outfit variants, friendly and neutral expressions, joint-based locomotion, the emotes above and anime eye, hair and toon shaders. `scenes/avatar_lineup.tscn` shows all five; press G to trigger the big celebration. This pass is meant for style and animation exploration, not as final art.

## 10. Production Paths (to evaluate)

1. **Commission a 3D character artist** for the base rigs, head, hair and eye shaders, then scale with AI-assisted textures and variants. Highest quality, most reliable.
2. **VRoid Studio as a bridge for prototyping:** quickly create anime characters as VRM files and import them into Godot with a VRM addon and a toon shader. Check the current license terms for commercial use, and expect to optimize for phones.
3. **Hybrid:** use the generator or VRoid-style outputs for early tests while an artist builds the production kit with a real skeleton and skin weights; the animation and emote logic carries over.

## 11. Open Questions

1. Which production path: commission, VRoid bridge, or hybrid?
2. Should emotes be free for all avatars at launch, or partly unlockable cosmetics?
3. Who is the art director who selects and approves concepts and reviews poses?
4. Budget for the head, hair and eye shader work and for a real skeleton with skin weights?
