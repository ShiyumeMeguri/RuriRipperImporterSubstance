# EndField_Uber vs HGRP/CharacterNPR 1.4.4 —— 对抗式差异清单

参考源：`E:\AllShader_1.4.4\Assets\packages\com.hg.render-pipelines\runtime\shaders\materials\characternpr`
（8 个 .shader + 3184 个逐变体编译产物）
被测：`shader/EndField_Uber.glsl` + `unity_material.py` 的属性映射表

## 判定方法

不看"GLSL 里有没有类似的东西",看**一份 1.4.4 的 .mat 交给这个插件,哪些属性会被丢掉**。
因为 `unity_material.py` 是按 Unity 属性名读 .mat 的,所以只要参考 shader 声明了某属性、
而它既不在 `CHANNEL_SOURCES` / `TEXTURE_PARAMS` / `FLOAT_IDENTITY` / `COLOR_IDENTITY` /
`BOOL_MAP` 里,也不是 `[HideInInspector]` 或纯 inspector 分节头,那它就是**实打实丢了**。

每个参考属性按此归类:channel / sampler / uniform / float·color / bool / ignored /
internal / section / **GAP**。逐变体统计:

| 变体 | 属性总数 | GAP | 未处理 keyword |
|---|---|---|---|
| characternpr | 254 | **123** | 10 |
| characternpr_skin | 131 | **48** | 2 |
| characternpr_liquidag | 109 | **25** | 4 |
| characternpr_hair | 115 | **20** | 2 |
| characternpr_eye | 78 | **9** | 2 |
| characternpr_shadowreceiver | 7 | **7** | 0 |
| characternpr_proxylod | 10 | **5** | 1 |
| characternpr_overlayshadow | 10 | **3** | 0 |

## 已验证的两个反直觉结论

**1. Hair 的 `_AnisotropyValue/_AnisotropyDirX/...` 不是过期名,不要动。**
它们属于 `characternpr_hair.shader`(1.4.4 里依然如此),GLSL 对 Hair 部位的实现是对的。
新出现的 `_AnisotropyDirectionMain / _AnisotropyIntensityMultiplier /
_AnisotropyDirectionAdditional / _AnisotropyOffsetAdditional / _AnisotropyColorAdditional /
_AnisotropyUseGeometryTangent` 是**基础 characternpr**(`_ANISOTROPY_SPECULAR_ON`,即
Standard 部位的各向异性高光)的另一套参数,GLSL 完全没有 —— 是新功能,不是改名。

**2. `_Pantyhose*` 在 1.4.4 参考里 0 命中。**
整块换成了 `_SilkStockings*`(18 个属性 + `_SilkStockingsMask` 贴图 + `_SILK_STOCKINGS`
keyword)。GLSL 现有的 `u_Pantyhose / _PantyhoseSpecularInt / _PantyhoseSpecularValue /
_PantyhoseAnisotropyDirection / _PantyhoseColor` 对 1.4.4 的 .mat **永远读不到值**,
等于该功能整体失效。

## 进度

已移植(每条都按"只差一个 keyword 的变体对"逐指令追出来,再逐条译成 GLSL,
默认值与取值范围一律取参考 Properties 原值):

- [x] `_SILK_STOCKINGS` 丝袜全套(替换掉对 1.4.4 材质永远读不到值的 `_Pantyhose*`)
- [x] `_ANISOTROPY_SPECULAR_ON` Standard 各向异性高光双瓣
- [x] `_STYLIZED_FRESNEL` 风格化菲涅尔
- [x] `_ENEMY_HIT_FLASH` 受击闪白
- [x] `_MATCAP_ENV_REFLECTION_ON` Matcap 顶替环境采样源
- [x] `_CUSTOMIZE_AVATAR` 换装染色(BaseMap RGB 当三张遮罩)
- [x] Emission 呼吸(遮罩 = `_EmissionMap.a` → user2 通道)
- [x] `_ExtraAlphaMask` 的 Root/Depth 两段染色
- [x] `_CHARACTER_EROSION` 侵蚀全套(三段色 + pattern + metallic/粗糙度 + RNM 法线)
- [x] `_PUPPET` + `_PUPPET_PROCEDURAL_DCURVE`(区域遮罩 + pattern 上色 / 7 段 cos 域扭曲脊线)
- [x] `_REALISTIC_LIGHTING`(去掉两处风格化环境亮度重映射)
- [x] `VFX_CHARACTER_DISSOLVE`(噪声/切面双路 + discard + 边缘自发光)
- [x] `_ViewFade`、`_AlphaClipThreshold`(裁切阈值改由材质属性驱动)、`_ParallaxUseNormal`
- [x] skin `FaceDecal` 全套 13 属性;hair 两段发色染色;eye 虹膜染色
- [x] VFX 的 `_VFXMainUVSet` / `_VFXScreenUVUseDepth` / `_VFXFresnelUseNormalMap`

**查证为空功能 / 无消费者(有证据,不是省事)**:
- `DITHER_SPHERE`:两个属性在全部 3184 份产物里只以 cbuffer 声明出现,没有任何
  fragment/vertex 读过。
- `_ResponsiveTransparency`:同上,0 处非声明引用。
- `_FurColorEnable` / `_FurColor`:1.4.4 里是死属性,零个编译产物引用。
- `_HairBrowMaskThreshold`:只在 Pass1 CharacterOutline / Pass2 DepthOnlyOutline /
  Pass3 PreGBuffer 里读,Pass0 ForwardLit(Painter 唯一渲染的 pass)从不读。
- `_FurGravityStrength`:只在 vertex 阶段(壳层挤出),[H10] 已说明。
- `_ALPHA_SCENE_DEPTH_FADE`(liquidag):读 `_CameraDepthTexture`,Painter 没有场景
  深度 —— 与 [H11] 同一堵墙。

顺带修掉的既有隐患:
- `_SRGB_COLOR_PROPS` 只按"名字以 Color 结尾"判断 Color 类型,而
  `_AnisotropyColorAdditional` 是 Color 类型却不以 Color 结尾 —— 会丢 gamma。
- 三个新贴图参数误写成 `//: param auto { ... }`,Painter 直接拒绝创建 shader。
  已修,并加了 `tools/check_shader_params.py` 静态校验(`param auto` 不能带
  JSON、`sampler2D` 必须有 `usage:texture`),复现即报错。

## 收官统计

再跑一次 `tools/shader_gap.py`(判定口径没变):

| 变体 | GAP 起 → 现 | 未处理 keyword 起 → 现 |
|---|---|---|
| characternpr | 123 → **34** | 10 → **0** |
| characternpr_skin | 48 → **15** | 2 → **0** |
| characternpr_hair | 20 → **16** | 2 → **0** |
| characternpr_eye | 9 → **7** | 2 → **0** |
| characternpr_liquidag | 25 → **15** | 4 → **1** |

剩下的 GAP 全部落在早就写明的三类:VAT 顶点动画、描边 pass、模板/深度序与引擎态。
不是"没做完",是这三类在 Painter 的片元着色里没有对应物。

## 要实现的清单（片元级,按影响排序）

### 基础 characternpr

| keyword / 属性块 | 内容 | 隔离变体对（OFF → ON） |
|---|---|---|
| `_SILK_STOCKINGS` | 丝袜:干/湿偏色、边缘色、覆盖 remap、Aniso 强度+锐利度贴图、湿身光滑度/透肉、高光 remap/衰减/偏移、雨湿遮罩、透肉 or 压暗 | b503 → b587 |
| `_ANISOTROPY_SPECULAR_ON` | Standard 各向异性高光:主方向/强度系数 + 第二层方向/偏移/颜色 + 是否用模型切线 | b369 → b375 |
| `_CHARACTER_EROSION` | 侵蚀:法线(RG)+光滑度(B)贴图、metallic、smoothness bias、法线强度、base/root/top 三段色 + 位置/羽化、pattern map + tint | Pass1 b1697 → b1709 |
| `_STYLIZED_FRESNEL` | 风格化菲涅尔:颜色(A=自发光)、Pow、Amount、噪声图 + 速度 + 对比度 | b543 → b623 |
| `_ENEMY_HIT_FLASH` | 受击闪白:扫描线亮色 + 内外羽化半径 + 覆盖中心、Fresnel 色/bias/影响透明度、法线强度、两个 color adjust | b373 → b475 |
| `_MATCAP_ENV_REFLECTION_ON` | Matcap 作为环境反射(与现有 `_MATCAP_ON` 是两条路径) | b373 → b473 |
| `_PUPPET` + `_PUPPET_PROCEDURAL_DCURVE` | 傀儡:UV2 区域遮罩(上下位置+羽化)、pattern map(RGB 模式)+速度+tint/edge 色、程序化 DCurve(UV2 缩放/速度、扭曲速度/周期、base/light/edge 色)、metallic/roughness 覆写 | b507 → b611 / b451 → b465 |
| `_REALISTIC_LIGHTING` | 写实光照分支 | Pass1 b1697 → b1705 |
| `VFX_CHARACTER_DISSOLVE` | 角色溶解(289 个变体带它,覆盖面最广) | 需同 pass 配对 |
| `_CUSTOMIZE_AVATAR` | `_CustomizeBaseColor / _CustomizeBaseTintColor / _CustomizeAddTintColor` 染色 | b683 |
| `DITHER_SPHERE` | 球形 dither 剔除半径 + 羽化 | — |
| `_ExtraAlphaMask` | UV1 的 Alpha/Root/Depth/ID 四通道 + `_ExtraRootTintColor` / `_ExtraDepthTintColor` | — |
| UV 动画 | `_BaseMapUVSpeed` / `_EmissionMapUVSpeed` + Emission 呼吸(开关/速度/最小/最大亮度) | — |
| 其它 | `_ParallaxUseNormal`、`_ViewFade`、`_AlphaClipThreshold`、`_ResponsiveTransparency`、`_Cull`/`_BackFaceNormalFlip` 联动 | — |

### characternpr_skin

| 属性块 | 内容 |
|---|---|
| **FaceDecal**(13 个属性) | 脸部贴花:贴图 + tint、中心 XY、翻转 XY、尺寸、旋转、镜像模式 + 分割线、亮度遮罩 |
| Puppet 全套 | 同基础(skin 也带 `_PUPPET`) |

### characternpr_hair / _eye

`_HairBaseTintColor`、`_HairAddTintColor`、`_HairBrowMaskThreshold`、`_EyeTintColor`。

### characternpr_liquidag（整份变体尚未移植）

`_ALPHA_SCENE_DEPTH_FADE` + `_DepthFadeValue/_DepthFadeExp`、`_ENEMY_HIT_FLASH`、
`_OutlineColorMap`。液体/黏液角色材质。

### 明确不做（记录理由,保持清单诚实）

- **顶点级**:`_AnimationTexture` / `_VATFrameIndex` / `_DebugVATFrameIndex`(VAT 顶点动画)、
  `_VertexAnimation*` 全套、Fur 壳层挤出(已有 [H10] 单壳层预览)。
- **独立 pass**:`_EnableOutline` 全套描边参数(Painter 无描边 pass)、
  `_PreZStencilRefOption` / `_EnablePreDepthPass` / `_TransparentDepthWrite`(模板/深度序)。
- **引擎态**:`_IsChildMaterial`、`_DisableRainEffectOnMaterial`、
  `TEXTURE_STREAMING_FEEDBACK_WAVE_OPS`、`HG_ENABLE_MV`、`SRP_INSTANCING_ON`。
- **characternpr_shadowreceiver**:地面接影片,不是角色表面材质,与贴图绘制无关。
- **SDF / PBR**:按要求保留现有的**故意偏离**,不对齐。

## 移植方法（每个功能都走同一条路,不猜）

参考产物每个 `.hlsl` 头部都带自己的 keyword 集合。用
`variant_index.py <dir> pair <KEYWORD>` 找出**只差这一个 keyword** 的两个变体,
diff 出来的增量就是该功能的真实实现 —— 逐条译成 GLSL,不做任何简化、不改采样数、
不动数学。上表"隔离变体对"列已经把每个功能的配对算好了。
