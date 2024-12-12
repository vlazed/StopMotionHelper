---@meta

---@alias Set<T> {[T]: boolean}
---@alias Receiver fun(msgLength: integer, player: Player)

---@class NewState
---@field Entity {[Entity]: boolean}?
---@field Frame integer?
---@field Timeline integer?
---@field PlaybackRate integer?
---@field PlaybackLength integer?

---@class State
---@field Entity {[Entity]: boolean}
---@field Frame integer
---@field Timeline integer
---@field PlaybackRate integer
---@field PlaybackLength integer

---@class Settings
---@field FreezeAll boolean
---@field LocalizePhysBones boolean
---@field IgnorePhysBones boolean
---@field GhostPrevFrame boolean
---@field GhostNextFrame boolean
---@field GhostAllEntities boolean
---@field GhostTransparency number
---@field OnionSkin boolean
---@field TweenDisable boolean
---@field SmoothPlayback boolean
---@field EnableWorld boolean

---@class Playback
---@field StartFrame integer
---@field EndFrame integer
---@field PlaybackRate integer
---@field CurrentFrame integer
---@field PrevFrame integer
---@field Timer number
---@field Settings Settings

---@class SMHEntity: Entity
---@field SMHGhost boolean Is it a ghost?
---@field Entity Entity If the entity is an SMHGhost, select the pointed entity
---@field EyeVec Vector
---@field GetEyeVector fun(self: SMHEntity): Vector Returns where the entity is looking
---@field AttachedEntity Entity
---@field Frame integer
---@field Physbones boolean
---@field RagdollWeightData number[]

---@alias Modifiers
---| "advcamera"
---| "advlight"
---| "bodygroup"
---| "bones"
---| "color"
---| "eyetarget"
---| "flex"
---| "modelscale"
---| "physbones"
---| "poseparameter"
---| "position"
---| "skin"
---| "softlamps"
---| "ragdollpuppeteer"
---| "world"
---All known fields controlled by SMH, including the custom ragdollpuppeteer modifier

---@class TimelineMod An array of timeline modifiers
---@field ["1"] "bones"
---@field ["2"] "color"
---@field ["3"] "bodygroup"
---@field ["4"] "modelscale"
---@field ["5"] "softlamps"
---@field ["6"] "poseparameter"
---@field ["7"] "position"
---@field ["8"] "skin"
---@field ["9"] "eyetarget"
---@field ["10"] "advcamera"
---@field ["11"] "physbones"
---@field ["12"] "flex"
---@field ["13"] "advlights"
---@field ["14"] "ragdollpuppeteer"
---@field KeyColor Color

---@alias ModifierNames table<integer, Modifiers>

---@class FramePose A struct of the entity's pose at an SMH frame and metadata related to it
---@field Ang Angle
---@field Pos Vector
---@field LocalAng Angle?
---@field LocalPos Vector?
---@field RootAng Angle?
---@field RootPos Vector?
---@field Moveable boolean?
---@field Scale Vector

---@class ColorPose A struct of the entity's color at an SMH frame
---@field Color Color

---@class Modifier A struct of the entity's modifiers
---@field physbones FramePose[]?
---@field bones FramePose[]?
---@field color ColorPose?
---@field Console string?
---@field Push string?
---@field Release string?
---@field Pos Vector?
---@field Ang Angle?

---@class SerializedFrameData The data shown in the SMH Timeline for the selected entity
---@field EntityData Modifier
---@field EaseIn number|table<string, number> If stored as a number, then this is a legacy SMH save file, otherwise this is an new SMH save file.
---@field EaseOut number|table<string, number> If stored as a number, then this is an legacy SMH save file, otherwise this is an new SMH save file.
---@field Modifier Modifiers Legacy SMH save file feature
---@field Position number

---@class FrameData The data shown in the SMH Timeline for the selected entity
---@field ID integer
---@field Entity SMHEntity
---@field EaseIn number|table<string, number> If stored as a number, then this is a legacy SMH save file, otherwise this is an new SMH save file.
---@field EaseOut number|table<string, number> If stored as a number, then this is an legacy SMH save file, otherwise this is an new SMH save file.
---@field Modifiers table<Modifiers, Modifier> Legacy SMH save file feature
---@field Frame number

---@alias TimelineMods TimelineMod[]

---@class TimelineSetting
---@field Timelines integer
---@field TimelineMods TimelineMods

---@class Properties The animation properties of the entity
---@field TimelineMods TimelineMods? An array of timeline modifiers
---@field Class string? The entity class
---@field Timelines number? The count of timelines
---@field Name string? The unique name of the entity, different from the model name
---@field Model string? The model path of the entity
---@field IsWorld boolean?

---@class Data The animation data for each entity
---@field Frames SerializedFrameData[] An array of the data seen in the SMH timeline
---@field Model string The model path of the entity
---@field Properties Properties The animation properties of the entity
---@field IsWorld boolean?

---@class SMHFile The text file containing SMH animation data
---@field Map string The map where the animation takes place
---@field Entities Data[] The animation data for each entity

---@alias Entities table<integer, SMHEntity|Player>

---@class GhostDatum
---@field Entity table<SMHEntity>
---@field Ghosts table<SMHEntity>
---@field Nodes table
---@field PreviousName string
---@field LastEntity Entity
---@field Updated boolean

---@alias GhostData table<Player, GhostDatum>

---@class Pose
---@field Pos Vector
---@field Ang Angle
---@field LocalPos Vector
---@field LocalAng Angle
---@field Parent integer
---@field IsPhysBone boolean

---@alias PoseTree {[integer]: Pose}
---@alias PoseTrees {[string]: PoseTree}

---@class PlayerData
---@field Keyframes FrameData[]
---@field Entities {[Entity]: FrameData[]}

---@class KeyframeData
---@field Players {[Player]: PlayerData}
---@field NextKeyframeId integer

-- UI

---@class Node
---@field Pos Vector
---@field Frame integer

---@class SMHWorldClicker: SMHWorldClickerPanel
---@field MainMenu SMHMenu
---@field PhysRecorder SMHPhysRecord
---@field Settings SMHSettings
---@field SpawnMenu SMHSpawn

---@class SMHNumberWang: DNumberWang Extension of DNumberWang with customizable step and increment or decrement fields
---@field Step number
---@field Up number
---@field Down number