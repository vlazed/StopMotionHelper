# Stop Motion Helper Unofficial: UI development

This version branches off from [develop](https://github.com/vlazed/StopMotionHelper/tree/develop). The purpose is to provide a proof-of-concept of the [UI Change issue](https://github.com/vlazed/StopMotionHelper/issues/3), where I implement categorize and compress all related buttons together to allow SMH to scale to different resolutions without overlap from different features.

## Features

The following video showcases all new UI features

[![Video](https://img.youtube.com/vi/vadQObUfNdU/0.jpg)](https://www.youtube.com/watch?v=vadQObUfNdU)

The major change involves relocating UI around. Watch the video and view the list below to familiarize yourself with the new changes.

- Compressed buttons into categories
  - **File:** Saving and loading animations/audio
  - **Edit:** (Audio) keyframe manipulation and settings
    - Smooth menu and stretch menu are found under Keyframes
  - **Addons**: Features that do things on their own. I moved the physics recorder and motion paths here
  - **Properties and Record button are accessible directly to the user**
- Relocated easing and playback info into other places, to allow space for new UI
  - Easing is separated into its own window
  - Frame count and framerate are in the SMH settings
    - I might make this easier to change without requiring access to the settings or to the console
- Playback and navigation buttons
  - These buttons, along with the smooth and stretch menu, replace the **Keyframe Settings UI**
  - Playback and frame jumping buttons provide alternatives to console commands
- QoL features
  - The user can resize the scrollbar to zoom in and out of the timeline, rather than using the scroll wheel
  - Position label can cycle between `frame / framecount` and `00h:00m:00s.00f` formats

YMMV with these changes. Currently, some features may lack implementations. I will defer implementation until I receive further UI feedback.

Let me know what I can do to improve the UI/UX!

### 1280 x 720

![pic](/docs/smh_1280x720.jpg)

### 800 x 600

![pic](/docs/smh_800x600.jpg)

Notice the overlap between the position label and the playback. The aim is to reduce this overlap.
