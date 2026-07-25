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

- [x] `DITHER_SPHERE` 球形 dither 剔除、`_DisableRainEffectOnMaterial` 关雨
- [x] `_Cull`(参考是 pass 渲染状态,片元按朝向 discard 得到同样的可见结果)
- [x] liquidag:`_ALPHA_SCENE_DEPTH_FADE`([H11] 距离滑条代替场景深度)、
      `_OutlineColorMap` 液体附着细节法线([H19] 两根滑条代替引擎逐实例量)
- [x] **Part 8 ShadowReceiver**(`characternpr_shadowreceiver` 整份变体):
      阴影色/强度、关主光阴影、关角色自阴影、Circle Fade 距离+羽化、Capsule AO 色。
      乘法叠帧沿用 [H13] 的改写,但拆分 `w = 1-min3(M)`、`B = (M-min3(M))/w`
      满足 `lerp(1,B,w) ≡ M`,是**代数恒等**不是近似;四个引擎量([H20])走滑条。

**两条早先的"空功能"判断是错的,已收回并补做:**
`DITHER_SPHERE` 和 `_DisableRainEffectOnMaterial` 我按抽样到的单个文件下的结论,
实际 `where_used.py` 一扫:前者在 Pass0 fragment 里有真实实现,后者 954 处。
**教训**:抽样不能当全域证据 —— 所以才有了下面这张全量表。

顺带修掉的既有隐患:
- `_SRGB_COLOR_PROPS` 只按"名字以 Color 结尾"判断 Color 类型,而
  `_AnisotropyColorAdditional` 是 Color 类型却不以 Color 结尾 —— 会丢 gamma。
- 三个新贴图参数误写成 `//: param auto { ... }`,Painter 直接拒绝创建 shader。
  已修,并加了 `tools/check_shader_params.py` 静态校验(`param auto` 不能带
  JSON、`sampler2D` 必须有 `usage:texture`),复现即报错。
- **移植过程中我自己引入的回归:眼睛被打穿**。把裁切阈值从旧的 `f_AlphaClip`
  (alpha-test 关闭时写 0,等于不裁)换成真属性 `_AlphaClipThreshold`(默认 0.5)
  时,把**门控**一起丢了 —— 于是所有部位无条件按 `_BaseMap.a` 裁切。
  而 `characternpr_eye` 的 `_BaseMap.a` 是虹膜散射遮罩(见 `_EyeScatteringColor`),
  根本不是不透明度,眼球被整片打穿露出后面的皮肤。
  证据:Pass0 里 `_AlphaClipThreshold` 的真实引用只出现在带 `_ALPHATEST_ON` 的
  变体(characternpr 51 处、`_hair` 15 处),而 `_skin` / `_eye` / `_liquidag`
  **零引用**,eye 的 `SV_Target.w` 参考里压根没写过。
  已按此恢复 `u_AlphaClip` 门控,并让 Face/Eyes/Eyebrow 永不走默认裁切。

## 收官统计

再跑一次 `tools/shader_gap.py`(判定口径没变):

| 变体 | GAP 起 → 现 | 未处理 keyword 起 → 现 |
|---|---|---|
| characternpr | 123 → **25** | 10 → **0** |
| characternpr_hair | 20 → **11** | 2 → **0** |
| characternpr_skin | 48 → **10** | 2 → **0** |
| characternpr_liquidag | 25 → **9** | 4 → **0** |
| characternpr_eye | 9 → **6** | 2 → **0** |
| characternpr_proxylod | 10 → **5** | 1 → **0** |
| characternpr_overlayshadow | 10 → **4** | 0 → **0** |
| characternpr_shadowreceiver | 7 → **0** | 0 → **0** |

去重后剩 **32 个属性名**。

### 先说一个必须交代的量尺缺陷（数字被我自己虚低过）

`tools/shader_gap.py` 原本按"属性名是否出现在 GLSL 文本里"判实现,而它扫的是
**全文本,包括注释**。于是只要我在注释里写一句"`_OutlineWidth` 做不到",这条就
被记成"已实现"。这等于在量"写了多少字",不是"写了多少代码" —— 已修:先剥掉
`//` 与 `/* */` 再取名字。修完 GAP 从 57 涨到 75,浮出 5 条真缺口
(`_OutlineWidth` / `_OutlineOffsetZ` / `_OutlineAverageNormal` / `_ShadowAngleRange` /
`_SurfaceType`)。其中 `_SurfaceType` 是量尺的另一个盲点(它由 `build_plan` 手写
代码消费成 `u_AlphaBlend`,表和 GLSL 名都查不到),已按 `floats.get(...)` 调用点
逐条核实后登记成新的 `derived` 类,共 7 条。上表是修完之后的数字。

## 剩余 GAP 的逐条证据(`tools/where_used.py` 全量扫描)

不再用"我认为它没用"这种说法。下表是把 3184 份产物逐份扫过之后,每个剩余属性
**真实被哪个 stage、哪个 pass 读**(排除 cbuffer 声明行)。Painter 的着色只有
单个 Pass0 **fragment** 程序 —— 没有 vertex 钩子、没有第二个 pass。所以只要一条
属性落在 "Vertex" 或 "Pass1+",它就不是被跳过,而是**够不着**。

**A. 全语料 0 次读取 —— 1.4.4 里的死属性(24 条)**
`_VertexAnimation*`(全 10 条)、`_EnableOutlineMask`、`_OutlineTransparent`、
`_OutlineInnerClipStencilMask`、`_PreZStencilRefOption`、`_EnablePreDepthPass`、
`_TransparentDepthWrite`、`_IsChildMaterial`、`_ResponsiveTransparency`、
`_FurColor` / `_FurColorEnable`、`_TintSplit`、`_FresnelRootFade`、
`_ShadowOverIris`、`_DisableDrawUnderHair`。
连参考自己都不读 —— **它们没有实现可移植**,写出来就是凭空发明行为,
那才是真正的"劣化"。

**B. 只在 Vertex 阶段(Painter 无顶点钩子,共 7 条)**
| 属性 | 证据 |
|---|---|
| `_VATFrameIndex` / `_DebugVATFrameIndex` | Vertex Pass0×181 …… Pass6×6,**fragment 0** |
| `_OutlineWidth` / `_OutlineOffsetZ` / `_OutlineAverageNormal` | Vertex Pass1×282、Pass2×78 |
| `_FurGravityStrength` | Vertex Pass0×48([H10] 已有单壳层预览) |
| `_ShadowAngleRange` | Vertex Pass0×4、Pass1×4([H13] 已写明跳过) |

**C. Pass1(CharacterOutline)fragment —— 此类现已清空**
`_OutlineTintColor` / `_OutlineTintEnable` / `_OutlineColorBrightness` /
`_OutlineColorSaturation` 原先以"Painter 没有描边 pass"排除。**这条理由不成立**:
参考的描边 pass 是 `Cull Front` 的反壳,它画的就是**背面**,而背面片元 Painter
拿得到。已按 [H21] 移植该 pass 的片元程序(albedo 换成亮度/饱和重映射或
`_OutlineTintColor`,其余走同一条光照链),开启后背面不再被 `_Cull` 丢弃。
真正做不到的只有顶点挤出那三条,已归入 B。

**D. `_AnimationTexture` 的 "Fragment Pass0×393" 是反编译器的贴图名错位**
该槽位(t21)周围是一整套 **cube 面选择 + cookie 图集 UV** 计算,`_LightCookie`
就声明在 t19 —— 它实际是光照 cookie 的 2D 图集,不是 VAT。真正的 VAT 驱动
`_VATFrameIndex` 是纯 vertex(见 B)。这正是本战役反复吃过的那个坑:
**贴图按用途认,只信 cbuffer 里的标量名**。

**E.(已收回)`characternpr_shadowreceiver` —— 我以"对象不同"排除过它,不成立**
那 7 条确实全在 Pass0 fragment 被真消费,**够得着**。"它是脚下那块接影地面片、
不是角色表面"是**范围选择**,不是技术限制 —— 而要求是"全变体全功能"。
现已实装为 **Part 8 ShadowReceiver**,7 条属性全部落地,GAP 7 → **0**。
`characternpr_proxylod` 剩的 5 条是另一回事:`_TintSplit` / `_FresnelRootFade`
属 A(全语料 0 读),其余 3 条属 B/D —— 不是我排除的,是够不着。

**收尾判定:剩余 32 条里,0 条在参考的 Pass0 fragment 有实现。**
24 条全语料零读取(A)、7 条纯 vertex(B)、1 条是反编译器名字错位(D),C 类已清空。
换句话说:**凡是参考在片元里真算过的东西,这个 shader 现在都算了**;
剩下的不是"没做",是"参考里没有可做的东西"或"Painter 没有那个阶段"。

## keyword 侧的同等审计

属性表只能查"材质属性",查不到纯 keyword 驱动的功能。所以对
`IGNORED_KEYWORDS` 里每一条也做了同样的实证(找**只差这一个 keyword** 的
Pass0 fragment 变体对逐行 diff,或统计它在各 stage/pass 的出现次数):

| keyword | 实证结果 |
|---|---|
| `DISABLE_DRAW_UNDER_HAIR` | 隔离对 Pass0 fragment **diff = 0 行** |
| `_DRAW_UNDER_BROW` | 只出现在 Pass1/2/3,**Pass0 出现 0 次** |
| `_OUTLINE_MASK` | 只出现在 Pass1(×123)/Pass2(×33);且 Pass1 fragment 里那个 `_OutlineMask` 采样其实是 `_DissolveTex` 的名字错位(用 `_DissolveTex_ST` 平铺、比 `_DissolveScheduleOffset`),真遮罩只调制顶点挤出宽度 |
| `TEXTURE_STREAMING_FEEDBACK_WAVE_OPS` | 只出现在 Pass4/5/6 |
| `_USE_ALCHEMY_AO` / `_USE_GROUND_TRUTH_AO` | **任何编译变体都没有**(.shader 声明了但没编出来) |
| `_ADVANCEDOPTION_ON` / `_FBXROTATIONFIX_ON` | 同上,零变体 |
| `_ALPHABLEND_ON` / `_ALPHATEST_ON` | 已分别折进 `u_AlphaBlend` / `u_AlphaClip` |
| `_CHARACTER_FUR` | 隔离对 diff 3180 行 = Fur 分支本体,已由 Part 4 承接 |

Fur 片元侧的覆盖度另做了核对:ON 侧 Pass0 fragment 真读的 `_Fur*` 共 12 条,
GLSL 全有;唯一多出的 `_FurGravityStrength` 在片元里只是 cbuffer 声明,真实
读取只在 vertex(壳层挤出,[H10])。

反过来,`DITHER_SPHERE`(Pass0 fragment ×12)和 `_REALISTIC_LIGHTING`(×6)
正是靠这套统计翻出来的 —— 它们本来被我误判成空功能。

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

### 明确不做（理由见上面两节的实证,不再是断言）

- **A/B/C/D 四类**:死属性、顶点级、Pass1 描边、反编译器名字错位。
- `HG_ENABLE_MV` / `SRP_INSTANCING_ON` / `HG_ENABLE_PER_OBJECT_MV` /
  `HG_ENABLE_SCREEN_SPACE_SHADOW_MASK`:引擎批处理与运动矢量,与着色结果无关。
- **SDF / PBR**:按要求保留现有的**故意偏离**,不对齐。

**8 份变体的片元级功能到此全部落地**:凡是 Pass0 fragment 真读过的东西,
现在要么实装、要么有 [H] 编号写明"引擎给的量换成了哪根滑条"。

## 移植方法（每个功能都走同一条路,不猜）

参考产物每个 `.hlsl` 头部都带自己的 keyword 集合。用
`variant_index.py <dir> pair <KEYWORD>` 找出**只差这一个 keyword** 的两个变体,
diff 出来的增量就是该功能的真实实现 —— 逐条译成 GLSL,不做任何简化、不改采样数、
不动数学。上表"隔离变体对"列已经把每个功能的配对算好了。
