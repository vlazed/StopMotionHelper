Stop Motion Helper
==================
Stop Motion Helper is a tool for Garry's Mod designed to make stop motion animation easier and more manageable.
It can also be used for recorded animation, but it is mainly designed around stop motion.

## Fork Details

This unofficial version of SMH adds:
- Support for animating bonemerged entities
- Bone motion paths with offsetting
- Audio playback from this [fork](https://github.com/smg4tech/StopMotionHelper)
- Exit saves and auto saves
- Smoothing trick UI and concommand
- FPS, framecount, and timeline length convars to save between sessions
- Keyframe jumping
- Modifiers for environment editors and volumetric clouds
- Quality-of-life physics-recording indicators
- Entity names when hovered over

See this [tutorial](./TUTORIAL_2.md) for more information. These changes are unlikely to be added into the official SMH version. If these changes happen to be included in the official version, I'd recommend migrating from my fork.

### Installation

> [!IMPORTANT]
You must have a single Stop Motion Helper folder in your `garrysmod/addons` to properly see the new features. If you have installed different versions of Stop Motion Helper, such as the SMG4 audio fork, you must move these folders somewhere else.

1. Navigate to your garrysmod/addons folder.
2. Either a) download the zip file and extract the folder or b) open up a command terminal (with Git installed) and execute `git clone https://github.com/vlazed/StopMotionHelper.git`
3. If you did step 2b, execute change directories to the cloned folder (`cd StopMotionHelper`) and `git switch develop`

To stay updated to the latest version of this fork, either a) do step 2a again, or b) open the command terminal in the `StopMotionHelper` folder and perform `git pull`.

> [!TIP]
You do not need to unsubscribe from the workshop version of Stop Motion Helper. This fork will override the functionality of the workshop version with the new features from this fork.
