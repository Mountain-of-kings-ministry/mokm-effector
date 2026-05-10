# 2D Object Animatable Properties

## Transform

| Property    | Type  | Description         |
| ----------- | ----- | ------------------- |
| `positionX` | float | Horizontal position |
| `positionY` | float | Vertical position   |
| `rotation`  | float | Rotation in degrees |
| `scaleX`    | float | Horizontal scale    |
| `scaleY`    | float | Vertical scale      |
| `skewX`     | float | Horizontal skew     |
| `skewY`     | float | Vertical skew       |
| `anchorX`   | float | Pivot X             |
| `anchorY`   | float | Pivot Y             |

---

## Visibility & Rendering

| Property      | Type  | Description       |
| ------------- | ----- | ----------------- |
| `opacity`     | float | Transparency      |
| `visible`     | bool  | Visibility toggle |
| `zIndex`      | int   | Draw order        |
| `blendMode`   | enum  | Blend operation   |
| `clipEnabled` | bool  | Enable clipping   |
| `maskOpacity` | float | Mask strength     |

---

## Color & Effects

| Property        | Type  | Description     |
| --------------- | ----- | --------------- |
| `tintR`         | float | Red tint        |
| `tintG`         | float | Green tint      |
| `tintB`         | float | Blue tint       |
| `brightness`    | float | Brightness      |
| `contrast`      | float | Contrast        |
| `saturation`    | float | Saturation      |
| `blur`          | float | Blur amount     |
| `glowIntensity` | float | Glow strength   |
| `shadowOpacity` | float | Shadow alpha    |
| `shadowOffsetX` | float | Shadow offset X |
| `shadowOffsetY` | float | Shadow offset Y |

---
<!-- exclude -->
## Sprite / Image

| Property      | Type  | Description          |
| ------------- | ----- | -------------------- |
| `spriteFrame` | int   | Current sprite frame |
| `uvOffsetX`   | float | Texture offset X     |
| `uvOffsetY`   | float | Texture offset Y     |
| `uvScaleX`    | float | Texture scale X      |
| `uvScaleY`    | float | Texture scale Y      |

---

## Text Object

| Property        | Type  | Description       |
| --------------- | ----- | ----------------- |
| `fontSize`      | float | Text size         |
| `letterSpacing` | float | Character spacing |
| `lineSpacing`   | float | Line spacing      |
| `outlineWidth`  | float | Text outline      |
| `textOpacity`   | float | Text alpha        |

---

<!-- exclude -->
# 3D Object Animatable Properties

## Transform

| Property    | Type  | Description   |
| ----------- | ----- | ------------- |
| `positionX` | float | World/local X |
| `positionY` | float | World/local Y |
| `positionZ` | float | World/local Z |
| `rotationX` | float | Pitch         |
| `rotationY` | float | Yaw           |
| `rotationZ` | float | Roll          |
| `scaleX`    | float | Scale X       |
| `scaleY`    | float | Scale Y       |
| `scaleZ`    | float | Scale Z       |

---

## Visibility & Rendering

| Property         | Type  | Description            |
| ---------------- | ----- | ---------------------- |
| `visible`        | bool  | Visibility             |
| `opacity`        | float | Transparency           |
| `castShadows`    | bool  | Shadow casting         |
| `receiveShadows` | bool  | Shadow receiving       |
| `renderLayer`    | int   | Render grouping        |
| `wireframe`      | bool  | Wireframe mode         |
| `doubleSided`    | bool  | Double-sided rendering |

---

## Material

| Property         | Type  | Description          |
| ---------------- | ----- | -------------------- |
| `albedoR`        | float | Base color red       |
| `albedoG`        | float | Base color green     |
| `albedoB`        | float | Base color blue      |
| `metallic`       | float | Metallic factor      |
| `roughness`      | float | Surface roughness    |
| `emission`       | float | Glow emission        |
| `normalStrength` | float | Normal map intensity |
| `specular`       | float | Specular strength    |
| `refraction`     | float | Refraction index     |

---

## Camera Object

| Property        | Type  | Description          |
| --------------- | ----- | -------------------- |
| `fov`           | float | Field of view        |
| `nearClip`      | float | Near clipping plane  |
| `farClip`       | float | Far clipping plane   |
| `focusDistance` | float | Depth of field focus |
| `aperture`      | float | Camera aperture      |

---

## Light Object

| Property    | Type  | Description    |
| ----------- | ----- | -------------- |
| `intensity` | float | Light power    |
| `range`     | float | Light distance |
| `coneAngle` | float | Spotlight cone |
| `colorR`    | float | Light red      |
| `colorG`    | float | Light green    |
| `colorB`    | float | Light blue     |

