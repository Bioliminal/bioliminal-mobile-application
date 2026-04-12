# BlazePose canonical 33-landmark order

This is the index → joint name mapping the server expects. Every `PoseFrame`
must have exactly 33 landmarks and they must be in this order. MediaPipe
Tasks and Google ML Kit both produce this exact ordering natively — no
remapping needed for those plugins. If you switch to a backend with a
different ordering (MoveNet uses a different set; YOLOv8-Pose uses yet
another), remap to this order before building the `PoseFrame`.

| Index | Joint |
|---:|---|
| 0  | nose |
| 1  | left_eye_inner |
| 2  | left_eye |
| 3  | left_eye_outer |
| 4  | right_eye_inner |
| 5  | right_eye |
| 6  | right_eye_outer |
| 7  | left_ear |
| 8  | right_ear |
| 9  | mouth_left |
| 10 | mouth_right |
| 11 | left_shoulder |
| 12 | right_shoulder |
| 13 | left_elbow |
| 14 | right_elbow |
| 15 | left_wrist |
| 16 | right_wrist |
| 17 | left_pinky |
| 18 | right_pinky |
| 19 | left_index |
| 20 | right_index |
| 21 | left_thumb |
| 22 | right_thumb |
| 23 | left_hip |
| 24 | right_hip |
| 25 | left_knee |
| 26 | right_knee |
| 27 | left_ankle |
| 28 | right_ankle |
| 29 | left_heel |
| 30 | right_heel |
| 31 | left_foot_index |
| 32 | right_foot_index |

Source: Google MediaPipe Pose Landmarker documentation. If Google changes
this in a future model version, update this file AND
`software/server/src/auralink/api/schemas.py` together — it's a breaking
contract change, not a config tweak.
