# Quantum World: Engine Decision and AI-Assisted Asset Pipeline (Draft v0.1)

## 1. Decisions

1. **Engine: Godot 4.3.** Open source (MIT), no fees, small builds, Rust core through GDExtension, fits the decentralized and privacy-first concept. Unity, Unreal and Bevy were considered and rejected for this project.
2. **AI-assisted content production.** AI is used to speed up avatars, environments, textures, concept art, audio drafts, code and translation. Humans set the art direction, curate and finish.

Acceptable tradeoff to state openly: Godot has a smaller anime and VRM ecosystem than Unity, so more of the toon-shading and avatar tooling is built in-house, which the AI-assisted pipeline is meant to offset.

## 2. Principles

1. **AI drafts, humans decide.** Nothing ships without art-direction review.
2. **Closed avatar kit.** Avatars are assembled from approved parts on a few hand-prepared base rigs. Free-form generated avatars are not allowed, which also enforces the content rules.
3. **Provenance for every asset.** Tool, version, inputs, date, license terms and human changes are recorded.
4. **One style.** A written style bible and reference sheet keep AI output consistent.
5. **Budgets are gates.** Triangle, texture, bone and draw-call budgets are checked automatically.
6. **Safe by construction.** The fully-clothed, non-sexualized rule applies to every avatar item and is reviewed before release (`GAMEPLAY-3D.md` section 3).

## 3. What AI Does, Asset by Asset

| Asset | AI role | Human role | Notes |
|---|---|---|---|
| Concept art, style bible | Image generation for exploration and variations | Art direction, selection, repainting | Use own references; do not prompt with living artists or existing characters |
| Avatar base bodies and heads | Not generated freely | Artist builds 2 to 3 clean base rigs with blendshapes and a humanoid skeleton | Clean topology and rigging are where AI 3D tools are weakest |
| Hair, clothing, accessories | Draft meshes and texture variations from concepts | Retopology, UV cleanup, fitting to the base rig, skin weights | Modular parts, fitted per base rig |
| Textures and palettes | Tileable block textures, outfit patterns, icons, VFX textures | Cleanup, style check | Highest AI payoff |
| Animations | Text-to-motion or video-to-motion drafts | Retarget to the humanoid skeleton, polish, tune game feel | Jump, land, dash and glide need hand tuning |
| Environment and set pieces | Concept variations, props drafts, skyboxes | Modular kit, level layout, optimization | Hand-made set pieces stay a human design task |
| Music | Sketches, stems, moods | Composer or producer finishes and owns the result | Licensing and style-imitation risk, see section 6 |
| Sound effects | Generated or edited SFX | License check, mixing | Keep source and license |
| UI icons and art | Generation | Vector cleanup, consistency | |
| Code and tests | Assistant for implementation, refactoring, test writing | Review, tests required, no unreviewed merges | Determinism code (controller, replay) gets extra review |
| Localization | Draft translations | Native review for main languages | |
| Moderation | Classifier on item renders as a pre-check | Human sign-off | Catches accidental sexualized output |

## 4. Pipeline

1. Concept and variants (AI) -> art director selects.
2. Base asset: artist-made rig, or AI start mesh for props and accessories.
3. Retopology, UVs, rigging and skin weights (human, tool-assisted).
4. Export glTF, import into Godot with an import script that applies the toon material and outline.
5. Automated budget check (triangles, bones, texture sizes, blendshapes).
6. Render check and safety review (classifier plus human).
7. Provenance entry, then merge.

Automation to build: Godot import scripts, a CI check on glTF budgets, automatic turntable renders for review, a provenance validator.

## 5. Technical Budgets (starting values, tune on devices)

- Avatar: up to about 15k triangles, one main texture atlas up to 1024 px, a fixed humanoid skeleton, a defined list of facial blendshapes, LOD or billboard beyond a distance.
- At most about 8 detailed avatars on screen.
- Block textures in one atlas, mipmapped and compressed for mobile.
- Every asset passes a device test before it is accepted.

## 6. Legal and Policy (verify before release)

- **Tool terms:** only use tools whose terms allow commercial use of outputs. Store a snapshot of the terms with the provenance record.
- **Training data:** do not train or fine-tune on art you do not own or have licensed. A style model trained only on own or licensed art is the safe way to keep a consistent look.
- **Copyright of AI output:** in some jurisdictions, including the US, purely AI-generated material may not get copyright protection. Human-authored work, human modifications and trademarks are what protect the brand. This matters for `SUSTAINABILITY.md` section 5.4, which relies on proprietary art and brand.
- **Third-party likeness and franchises:** never prompt with real people, existing characters or franchises.
- **Music:** AI music services differ in commercial terms and in how they handle style imitation. Prefer a composer who finishes and owns the final tracks, with AI limited to sketches and stems.
- **Store and regulatory rules:** check current app store policies on AI-generated content and any disclosure or labelling duties (for example under EU rules on synthetic content) before release.
- **Minors:** the audience starts at age 12; the content rules and rating review apply to AI-assisted items exactly as to any other.

## 7. Repository Rules

- Only runtime-ready assets go in the repository (glTF, compressed textures, audio). Large binaries use Git LFS or a separate asset repository.
- Source files (Blender, Photoshop, project files) are kept outside the repository or in a private asset store.
- `assets/PROVENANCE.csv` lists, per asset: file, tool and version, inputs or prompt reference, date, terms snapshot reference, human changes, reviewer.
- Note for tooling: automated commits made through text-only APIs cannot add binary files; binary assets are pushed with normal git by the team.

## 8. Honest Expectations

- AI saves the most time on concept art, textures, icons, drafts and code assistance.
- It saves much less on rigged avatars, clean topology and animation quality. Plan for at least one experienced 3D or technical artist.
- Consistency and review are the real work: expect rejection and rework of a large share of generated drafts.

## 9. Open Questions

1. Which AI tools and what monthly budget, and who is the art director?
2. Who builds the base avatar rigs: a hired artist, an existing base, or both?
3. Music: composer-led with AI sketches, or a different approach?
4. How detailed should provenance records be (per file, or per batch)?
5. Binary asset storage: Git LFS or a separate asset repository?
