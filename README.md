# Stop Motion Helper

## DISCLAIMER

If you are looking for the version with extra features, [view it here](https://github.com/vlazed/StopMotionHelper/tree/develop).

This version contains modifiers for animating a group of physical bones (grouped bone timelines or GBTs). The list is as follows

- **Lower Body**: Animate lower body parts, including the root bone
- **Upper Body**: Aniamte upper body parts, excluding the root bone
- **Root Physics**: Animate root bones only.
- **Child Physics**: Animate child bones of root bones only, excluding the root bone
- **(Body Template)**: A modifier meant to be implemented by another modifier. The custom modifiers above all derive this modifier)

These differ from the `Physical Bones` modifier in that it does not record the transforms of **all** physics bones. Instead, it records the transforms of a **group** of physics bones. This allows animation

## Usage

### Enabling Ghosts

> [!TIP]
> If you are using my fork, you do not need to follow these steps

If you want to use this in your version of Stop Motion Helper, you need to do the following:

- In `lua/smh/server/ghosts_manager.lua`, make the following change:

```
-- Find lines that look like below:
if modname == "physbones" then ghost.Physbones = true end
-- and change it to
if SMH.Modifiers[modname].Ghost then ghost.Physbones = true end
```

Afterwards, ghosts will be enabled for your custom physical bone modifiers.

### Model compatibility

Unlike the `Physical Bone` modifier, the custom modifiers need explicit support for different models.

The custom modifiers search the following directories in your `garrysmod/data` folder:

- **Lower Body**: `smh_lowerbodies`
- **Upper Body**: `smh_upperbodies`
- **Root Physics**: `smh_rootphysics`
- **Child Physics**: `smh_childphysics`

These directories contain text files with a list of physical bone names. These bone names may be leaf bones: that is, bones without child bone. For example, read a snippet of the `smh_upperbodies/valve.txt` file:

```
bip_head
bip_hand_L
bip_hand_R
```

> [!NOTE]
> It is fine to specify a non-leaf bone. For instance, you can use `bip_foot_L` in addition to `bip_toe_L` for compatibility with different physics models

> [!WARNING]
> You may specify every bone in the text file. A custom modifier that reads all physical bones in the text file essentially mimics the original `Physical Bone` modifier

You can then specify the bones of your model to allow these modifiers to work on them.

The custom modifiers record the transforms starting from the leaf bone, and moves up to its parent bone (e.g. `bip_head` to `bip_neck` to `bip_spine_2`) until it reaches its root bone or the bone nearest to the root bone (depending on the modifier used).

## Rational

Individual bone timelines (IBTs) enables an animator to manipulate one or a set of bones independently from each frame. It allows for animations such as gestures layered on walk or run cycles. Current versions of Stop Motion Helper as of April 11, 2026 lack this feature. Hence, animators must refer to multiple workarounds to achieve this level of complexity. For instance, one would need to use another animation tool (such as Henry's Aniamtion Tool or Ragdoll Puppeteer) to allow for root motion animations. These methods has its own constraints and does not significantly increase animation flexibility.

To overcome this limitation, this solution instead exploits the knowledge that `Physical Bones` record all physical bone transforms and provides modifiers that only record a subset of all physical bones. The `Root Physics` and `Child Physics` modifier pair allows the animation to occur wholly in Stop Motion Helper, without reliance on external tools. The `Lower Body` and `Upper Body` modifier pair is based on a heuristic which assumes that actions on the lower body (e.g. walking) and actions on the upper body (head movements, arm poses, etc.) differ. 

These lack the features of true IBTs, where one can manipulate a single bone at a time. This can be achievable theoretically, but it is intractable to achieve this in SMH 4.0's UI without sacrificing ease of use. However, this al
