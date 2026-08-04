/*************************************************************************
  EndField_Uber.glsl
  —— Substance Painter GLSL 全功能移植版：Endfield 角色 Uber
  
  ============== 通道 / 贴图映射（统一槽位思路，按部位换语义） ==============
  引擎通道（所有部位共用）：
    basecolor → _BaseMap.rgb     opacity → _BaseMap.a
    metallic  → RMOS Metal(.r)   specularlevel → RMOS Spec(.g)
    roughness → 1-Smooth(.a)     AO → RMOS Shadow(.b) [H1]
    normal    → _BumpMap         emissive → _EmissionMap
    height    → _ParallaxTex (Standard 视差高度; 迁入 SP Height 通道, 可绘制/可烘焙)
  user 通道：
    user1 = Standard: ClearCoat Mask (.r, 可绘制)
  自定义贴图参数（LUT/视空间/SDF/滚动/RGB数据 等不可绘制，或 SP 对 RGB 通道强制色彩管理会篡改 → 保持参数）：
    _RampMap _SpecRampMap _ShadowLutTex _SDFMask _SDFLightmap _EmotionMap _HighlightMap
    _MatcapTex _SpecNormalMap _StrokeMap _LineMap _FurMap _FurDirMap _FurDyeMap _VFX* 系
    _VFXSpecialMainTex _VFXSpecialBlendTex (Fur烬火)
    _VFXMainTex _VFXMaskTex _VFXBlendTex _VFXDisturbTex _VFXNormalMap (VFX part)

  ============== 硬编码 / 无等价物清单 ==============
  [H1] RMOS.b 阴影遮罩(shadowMask) → SP AO 通道等价；无 AO 数据时返回 1.0（=Unity 无遮罩）。
  [H2] 主光源屏幕空间阴影：SP 无 → shadowAttenuation=1.0（全亮）。
  [H3] 主光源颜色：UI 参数 v_MainLightColor；方向 = SP 视口主灯 light_main 经 i_LightRotX/Y/Z 旋转。
  [H4] unity_ObjectToWorld：SP 模型即世界（无变换）→ 取单位矩阵；枢轴 originX/Z=0。
       Face/Hair/Eye 的对象轴 = 世界轴 (1,0,0)/(0,1,0)/(0,0,1)；SP 烘焙网格无需 FBX -90 旋转修正
       (已删该开关: 它把发丝各向异性轴转错 90°, 致刘海高光环消失)。
       Face SDF 基轴 (源=O2W 列0/列2) 直接由 _FaceRight/_FaceForward 以 SP 世界空间输入
       (±1, rip FBX 实测面朝 -Z ⇒ Unity .mat 轴 Z 取反)，faceUp=cross(right,fwd) 重建列1。
  [H5] ApplyCustomAO（Fix 沙盒自定义 AO）：跳过。
  [H6] 反射立方图 → SP 环境 envSampleLOD()。整条环境反射链与参考逐项一致
       (b423 对拍过: envBRDF 有理式、mip=log2(max(rough,0.001))*1.2+5、
        reflBoost=(1-dfg)/dfg、SpecRamp 后的 specColor 进 envBRDF), 但**输入源**
       不是一回事: 参考采的是引擎预积分、低分辨率、重度模糊的散射立方图,
       Painter 采的是真 HDRI —— 同一个 mip 号在它上面清晰得多, 于是周围环境
       会被实打实反射出来。这是 Painter 侧无法消除的结构差异, 不是移植误差。
       强度统一交给 _CubemapIntensity(默认 1 = 不改动参考结果), 它是纯 Painter
       侧旋钮(参考 8 份 .shader 都没有这个属性), 因此**不随导入被覆写**,
       调过一次就一直保留。Standard / Hair / ClearCoat 三条环境路径都受它控制。
  [H7] 引擎通道按 1:1 UV 绘制，不支持 _BaseMap_ST 平铺；_BaseMap_ST 参数只作用于
       自定义贴图参数的 UV 公式（与 Unity 一致）。默认 (1,1,0,0) 时两边完全一致。
  [H8] getTSNormal(sparse_coord)：取 SP 法线通道切线空间法线（替代 Unity DXT5nm 解码）。
  [H9] HG 后处理 tonemap (ACES_modified, 源 lutbuilder2d b4) 已内置: u_UseEndfieldTonemap
       默认开 + f_TonemapExposure。SP 显示设置的 Tone mapping 务必选 Linear 防二次映射;
       Bloom/调色 LUT 等其余后处理仍不在本 shader 内。另: sRGBTexture=1 的贴图参数
       (_ShadowLutTex/_EmotionMap/_MatcapTex/_ParallaxTex/Fur·VFX 系) 已补硬件 sRGB 解码。
  [H10] Fur 壳层挤出是顶点/多 pass：SP 不可能 → f_FurShellIdx 滑条预览任意单壳层的片元着色
       （0=底面，1=最外层）。clip(shellAlpha-0.003) 保留。
  [H11] Hair 皮肤高光的深度边缘检测(_CameraDepthTexture)：SP 无场景深度 →
       f_HairDepthEdgeMask 参数替代 depthSmooth（默认 1=始终生效）。
  [H12] VFX part：SP 无顶点色/UV2/粒子CustomData → vertColor=白、uv1=uv0、custom=0；
       _Time.y → f_VFXTime 手动滑条。混合状态固定 over（无法逐部位换 additive 状态）。
  [H13] OverlayShadow 眼白阴影是 `Blend Zero SrcColor` 乘法叠帧 pass。SP 无乘帧 → 用 over
       混合等价逼近：输出阴影染色 _BaseColor.rgb + alpha=变暗权重(texR·a²)，强制半透明
       (forceAlphaBlend, 否则该材质 _SurfaceType 非透明会被渲成挡眼的白色不透明面片)。
       眼白 fb≈1 时 over 与真乘法逐像素相等。顶点视空间偏移 _ShadowAngleRange 跳过。
  [H14] 丝袜湿身的湿润度参考里是 max(角色浸润, 雨量/255),来自自定义管线的天气系统。
        Painter 只有片元程序,拿不到那个逐帧状态 → 改成面板上的手动滑条
        f_SilkWetness / f_SilkWetStreak,**默认 0 = 干态**,想看湿身效果就手动
        往上拉,等价于模拟管线给的下雨程度。湿身链本身(色偏/高光强度/变光滑/
        透肉或压暗)全部按参考原样保留,只是驱动源换成滑条。
  [H15] 受击闪白的 Fresnel 项乘引擎全局曝光 _ExposureWithMiscParams.y → f_HitFlashExposure。
  [H16] 溶解取 max(_DissolveScheduleOffset, 引擎逐物体进度) → 只留材质那一半 + 滑条。
  [H17] VFX 屏幕 UV 需要 _ScreenParams → f_ScreenSize(默认 1920×1080)。
  [H18] 抖动球焦点是 _VFXParams0.xyz(角色位置)、抖动量是引擎逐物体量
        → f_DitherSphereFocus / f_DitherAmount。
  [H19] liquidag 液体附着的进度字节(_CharacterParams10 引擎逐实例)与平铺
        (_CharacterParams10.z) → f_LiquidProgress / f_LiquidTiling;液面轴取世界 Y。
  [H20] ShadowReceiver 的四个引擎量:主光级联阴影、_CharacterShadowmapTex 的 PCF、
        阴影强度 _f_0[34].x、_VisibilitySHRT 屏幕胶囊可见度 SH → 四根滑条;
        投影片原点 unity_ObjectToWorld[3].xyz → f_CircleFadeCenter。
  ====================================================================
*************************************************************************/

//----------------------------------------------------------------------region 面板 UI 参数
//- {
  //- region 部位
    //: param custom {
    //:   "default": 0,
    //:   "label": "角色部位 CharaPart",
    //:   "widget": "combobox",
    //:   "values": {
    //:     "0 Standard 衣物/身体": 0,
    //:     "1 Face 脸/皮肤": 1,
    //:     "2 Eyes 眼睛": 2,
    //:     "3 Hair 头发": 3,
    //:     "4 Fur 毛皮": 4,
    //:     "5 Eyebrow 眉毛": 5,
    //:     "6 VFX 特效": 6,
    //:     "7 OverlayShadow 眼白阴影": 7,
    //:     "8 ShadowReceiver 接影地面片": 8
    //:   },
    //:   "group": "0 部位"
    //: }
    uniform_specialization int u_CharaPart;
  //- endregion

  //- region 基础设置
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "基础色 BaseColor", "widget":"color", "group": "1 基础设置" }
    uniform vec4 _BaseColor;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "BaseMap_ST (xy=Tiling zw=Offset, 仅作用于自定义贴图UV)", "group": "1 基础设置" }
    uniform vec4 _BaseMap_ST;
    //: param custom { "default": true, "label": "使用法线贴图 _NORMALMAP", "group": "1 基础设置" }
    uniform bool u_UseBumpMap;
    //: param custom { "default": 1.0, "label": "法线强度 BumpScale", "min": 0.0, "max": 4.0, "group": "1 基础设置" }
    uniform float _BumpScale;
    //: param custom { "default": true, "label": "使用 RMOS 通道 _METALLICSPECGLOSSMAP", "group": "1 基础设置" }
    uniform bool u_UseMetallicGlossMap;
    //: param custom { "default": 0.0, "label": "金属度(无贴图时) Metallic", "min": 0.0, "max": 1.0, "group": "1 基础设置" }
    uniform float _Metallic;
    //: param custom { "default": 1.0, "label": "高光强度(无贴图时) Specular", "min": 0.0, "max": 1.0, "group": "1 基础设置" }
    uniform float _Specular;
    //: param custom { "default": 0.5, "label": "光滑度(无贴图时) Smoothness", "min": 0.0, "max": 1.0, "group": "1 基础设置" }
    uniform float _Smoothness;
    //: param custom { "default": true, "label": "使用漫反射 Ramp _DIFF_RAMP_ON", "group": "1 基础设置" }
    uniform bool u_UseDiffRamp;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "漫反射 Ramp (RGB:色调 A:明暗)", "usage": "texture", "group": "1 基础设置" }
    uniform sampler2D _RampMap;
    //: param custom { "default": [1.0, 1.0, 1.0], "label": "主光源颜色", "widget":"color", "group": "1 基础设置" }
    uniform vec3 v_MainLightColor;
    //: param custom { "default": 0, "label": "灯光旋转 X", "min": 0, "max": 360, "group": "1 基础设置" }
    uniform int i_LightRotX;
    //: param custom { "default": 0, "label": "灯光旋转 Y", "min": 0, "max": 360, "group": "1 基础设置" }
    uniform int i_LightRotY;
    //: param custom { "default": 0, "label": "灯光旋转 Z", "min": 0, "max": 360, "group": "1 基础设置" }
    uniform int i_LightRotZ;
    //: param custom { "default": 0.0, "label": "背面法线翻转 BackFaceNormalFlip (0=反向 1=保持)", "min": 0.0, "max": 1.0, "group": "1 基础设置" }
    uniform float _BackFaceNormalFlip;
  //- endregion

  //- region 阴影色
    //: param custom { "default": false, "label": "使用 Shadow LUT _SHADOW_LUT_TEX", "group": "2 阴影色" }
    uniform bool u_UseShadowLut;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "Shadow LUT (32切片 1024x32)", "usage": "texture", "group": "2 阴影色" }
    uniform sampler2D _ShadowLutTex;
    //: param custom { "default": 0.5, "label": "阴影色亮度 ShadowColorBrightness", "min": 0.0, "max": 1.0, "group": "2 阴影色" }
    uniform float _ShadowColorBrightness;
    //: param custom { "default": 1.0, "label": "阴影色饱和度 ShadowColorSaturation", "min": 0.0, "max": 2.0, "group": "2 阴影色" }
    uniform float _ShadowColorSaturation;
  //- endregion

  //- region 描边 (Pass1 CharacterOutline 的片元程序)
    // [H21] 描边是 `Cull Front` 的反壳 pass —— 它画的正是**背面**。
    //   顶点挤出(_OutlineWidth / _OutlineOffsetZ / _OutlineAverageNormal)Painter 做不到,
    //   但描边的**片元程序**可以 1:1 移植:参考 Pass1 只是把 albedo 换成
    //   ComputeOutlineAlbedo 的重映射,再走同一条光照链(_ShadowColorBrightness/
    //   Saturation 这些下游照旧生效)。开启后背面不再被 _Cull 丢掉,而是按描边色着色。
    //: param custom { "default": false, "label": "启用描边(背面着描边色)", "group": "6 描边 Outline" }
    uniform bool u_EnableOutline;
    //: param custom { "default": false, "label": "直接用描边颜色 OutlineTintEnable", "group": "6 描边 Outline" }
    uniform bool _OutlineTintEnable;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "描边颜色 OutlineTintColor", "widget":"color", "group": "6 描边 Outline" }
    uniform vec4 _OutlineTintColor;
    //: param custom { "default": 0.5, "label": "描边色亮度 OutlineColorBrightness", "min": 0.0, "max": 1.0, "group": "6 描边 Outline" }
    uniform float _OutlineColorBrightness;
    //: param custom { "default": 1.5, "label": "描边色饱和度 OutlineColorSaturation", "min": 0.0, "max": 2.0, "group": "6 描边 Outline" }
    uniform float _OutlineColorSaturation;
  //- endregion

  //- region 高光 Ramp / 反射
    //: param custom { "default": false, "label": "使用高光 Ramp _SPEC_RAMP_ON", "group": "3 高光Ramp与反射" }
    uniform bool u_UseSpecRamp;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "高光 Ramp 贴图", "usage": "texture", "group": "3 高光Ramp与反射" }
    uniform sampler2D _SpecRampMap;
    //: param custom { "default": 0.0, "label": "Iridescent 模式", "min": 0.0, "max": 1.0, "group": "3 高光Ramp与反射" }
    uniform float _SpecRampIridescentMode;
        // [H6] Painter 的环境比游戏那张预积分散射图锐利得多, 环境反射会偏强。
    // 这根是唯一的补偿旋钮, 且不会被导入覆写。
//: param custom { "default": 1.0, "label": "[H6] 环境反射强度 Cubemap", "min": 0.0, "max": 4.0, "group": "3 高光Ramp与反射" }
    uniform float _CubemapIntensity;
  //- endregion

  //- region 自发光
    //: param custom { "default": true, "label": "使用自发光 _EMISSION", "group": "4 自发光" }
    uniform bool u_UseEmission;
    //: param custom { "default": [0.0, 0.0, 0.0, 1.0], "label": "自发光颜色 EmissionColor", "widget":"color", "group": "4 自发光" }
    uniform vec4 _EmissionColor;
    //: param custom { "default": 1.0, "label": "自发光亮度 EmissionBrightness", "min": 0.0, "max": 16.0, "group": "4 自发光" }
    uniform float _EmissionBrightness;
    // 1.4.4 新增:Emission 呼吸。逐像素的"哪里会呼吸"来自 _EmissionMap.a,
    // 在 Painter 里进 user2 通道(emissive 通道只有 RGB)。
    //: param custom { "default": false, "label": "自发光呼吸 _EmissionAlphaBrightBreath", "group": "4 自发光" }
    uniform bool _EmissionAlphaBrightBreath;
    //: param custom { "default": 1.0, "label": "呼吸速度 BreathSpeed", "min": 0.0, "max": 20.0, "group": "4 自发光" }
    uniform float _EmissionAlphaBrightBreathSpeed;
    //: param custom { "default": 0.0, "label": "呼吸最小亮度 BreathScaleMin", "min": 0.0, "max": 8.0, "group": "4 自发光" }
    uniform float _EmissionAlphaBrightBreathScaleMin;
    //: param custom { "default": 1.0, "label": "呼吸最大亮度 BreathScaleMax", "min": 0.0, "max": 8.0, "group": "4 自发光" }
    uniform float _EmissionAlphaBrightBreathScaleMax;
    // [H7] 引擎通道按 1:1 UV 绘制,滚动 UV 不能作用在 basecolor/emissive 上
    // (Painter 的通道采样是 sparse_coord,不接受偏移的 UV);这两个速度因此
    // 只记录、不作用于引擎通道 —— 与 _BaseMap_ST 同一条既有限制。
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "[H7] BaseMap UV 速度(仅记录)", "group": "4 自发光" }
    uniform vec4 _BaseMapUVSpeed;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "[H7] EmissionMap UV 速度(仅记录)", "group": "4 自发光" }
    uniform vec4 _EmissionMapUVSpeed;
  //- endregion

  //- region 渲染设置
    //: param custom { "default": false, "label": "半透明混合 AlphaBlend", "group": "5 渲染设置" }
    uniform_specialization bool u_AlphaBlend;
    // 裁切只在 `_ALPHATEST_ON`(`_AlphaClip` 属性)开着时才咬。参考里 Pass0 的
    // clip 全部落在带该 keyword 的变体里:characternpr 51 处、_hair 15 处,
    // 而 _skin / _eye / _liquidag 的 Pass0 对 _AlphaClipThreshold **零引用** ——
    // 这几个部位的 _BaseMap.a 根本不是不透明度(眼睛那份是散射遮罩,见
    // shadeEyes 的 _EyeScatteringColor),拿它裁切会把眼球捅出窟窿。
    //: param custom { "default": false, "label": "开启透明裁切 AlphaClip", "group": "5 渲染设置" }
    uniform_specialization bool u_AlphaClip;
    // 参考的 _AlphaClipThreshold(Range(0,1) 默认 0.5)—— 是真材质属性,不是手填。
    //: param custom { "default": 0.5, "label": "透明裁切阈值 AlphaClipThreshold", "min": 0.0, "max": 1.0, "group": "5 渲染设置" }
    uniform float _AlphaClipThreshold;
    // ViewFade:掠射角按 |dot(N,V)| 淡出 alpha(参考 _1811/_1816/_1824)。
    //: param custom { "default": 0.0, "label": "视角淡出 ViewFade", "min": 0.0, "max": 1.0, "group": "5 渲染设置" }
    uniform float _ViewFade;
    // _Cull 在参考里是 pass 的渲染状态(`Cull [_Cull]`),没有任何 fragment 读它。
    // Painter 的渲染状态不归 shader 管 —— 但同样的**可见结果**在片元里做得到:
    // 按 uniform_facing 丢掉该剔除的那一面。0=Both 1=Back 2=Front,与参考枚举同序。
    //: param custom { "default": 2.0, "label": "剔除面 Cull (0 双面 / 1 背面 / 2 正面)", "min": 0.0, "max": 2.0, "group": "5 渲染设置" }
    uniform float _Cull;
    // DITHER_SPHERE:朝向"焦点方向"的部分按半径/羽化抖动剔除(镜头贴近时
    // 让挡住脸的头发/身体消失)。参考 Sub0_Pass0_Fragment_b1345 的 _2604/_2631。
    //: param custom { "default": false, "label": "球形抖动剔除 DITHER_SPHERE", "group": "5 渲染设置" }
    uniform bool u_DitherSphere;
    //: param custom { "default": 0.0, "label": "抖动球半径 DitherSphereRadius", "min": 0.0, "max": 1.0, "group": "5 渲染设置" }
    uniform float _DitherSphereRadius;
    //: param custom { "default": 0.1, "label": "抖动球羽化 DitherSphereSmoothness", "min": 0.001, "max": 1.0, "group": "5 渲染设置" }
    uniform float _DitherSphereSmoothness;
    // [H18] 焦点位置在游戏里是 _VFXParams0.xyz(角色位置),抖动量来自引擎逐物体
    //       常量;Painter 都没有 → 焦点做成可填坐标,抖动量做成滑条(1=全不透明)。
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "[H18] 抖动球焦点位置", "group": "5 渲染设置" }
    uniform vec4 f_DitherSphereFocus;
    //: param custom { "default": 1.0, "label": "[H18] 抖动量 (1=不剔除)", "min": 0.0, "max": 1.0, "group": "5 渲染设置" }
    uniform float f_DitherAmount;
    // 参考 _DisableRainEffectOnMaterial:材质级"不受雨"开关,门控整条浸润链路
    // (Painter 里唯一的浸润消费者就是丝袜的 f_SilkWetness [H14])。
    //: param custom { "default": 0.0, "label": "关闭材质受雨 DisableRainEffectOnMaterial", "min": 0.0, "max": 1.0, "group": "5 渲染设置" }
    uniform float _DisableRainEffectOnMaterial;
    // liquidag 的 _ALPHA_SCENE_DEPTH_FADE:靠近场景表面时淡出。
    //   fade  = 1 - exp2(-|sceneDepth - fragDepth| * DepthFadeExp)
    //   alpha = max(max(fade,0) * DepthFadeValue, baseAlpha)
    // [H11] 场景深度 Painter 完全没有(与发丝深度边缘同一堵墙)→ 用一根
    //       "接近程度"滑条代替 |sceneDepth - fragDepth| 那一项,其余数学不动。
    //: param custom { "default": false, "label": "场景深度淡出 _ALPHA_SCENE_DEPTH_FADE", "group": "5 渲染设置" }
    uniform bool u_AlphaSceneDepthFade;
    //: param custom { "default": 0.0, "label": "深度淡出量 DepthFadeValue", "min": 0.0, "max": 1.0, "group": "5 渲染设置" }
    uniform float _DepthFadeValue;
    //: param custom { "default": 1.0, "label": "深度淡出指数 DepthFadeExp", "min": 0.0, "max": 20.0, "group": "5 渲染设置" }
    uniform float _DepthFadeExp;
    //: param custom { "default": 1.0, "label": "[H11] 与场景表面的距离 (代替场景深度)", "min": 0.0, "max": 10.0, "group": "5 渲染设置" }
    uniform float f_SceneDepthDistance;
    // 视差用哪条法线建 TBN:开=法线贴图后的 N,关=几何法线(参考 _932/_936)。
    //: param custom { "default": false, "label": "视差使用法线贴图 ParallaxUseNormal", "group": "5 渲染设置" }
    uniform bool _ParallaxUseNormal;
    //: param custom { "default": 0.0, "label": "AlphaPremultiply", "min": 0.0, "max": 1.0, "group": "5 渲染设置" }
    uniform float _AlphaPremultiply;
    //: param custom { "default": true, "label": "EndField Tonemap ACES_modified (SP显示设置Tone mapping请选Linear)", "group": "5 渲染设置" }
    uniform bool u_UseEndfieldTonemap;
    //: param custom { "default": 1.0, "label": "Tonemap 前曝光", "min": 0.0, "max": 4.0, "group": "5 渲染设置" }
    uniform float f_TonemapExposure;
  //- endregion

  //- region ClearCoat (Standard)
    //: param custom { "default": false, "label": "启用清漆 _CLEARCOAT (mask=user1.r)", "group": "6 ClearCoat" }
    uniform bool u_ClearCoat;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "清漆颜色 ClearCoatColor", "widget":"color", "group": "6 ClearCoat" }
    uniform vec4 _ClearCoatColor;
    //: param custom { "default": 0.95, "label": "清漆光滑度 ClearCoatSmoothness", "min": 0.0, "max": 1.0, "group": "6 ClearCoat" }
    uniform float _ClearCoatSmoothness;
    //: param custom { "default": 0.0, "label": "清漆金属度 ClearCoatMetallic", "min": 0.0, "max": 1.0, "group": "6 ClearCoat" }
    uniform float _ClearCoatMetallic;
    //: param custom { "default": 0.0, "label": "清漆法线 (0=顶点 1=贴图)", "min": 0.0, "max": 1.0, "group": "6 ClearCoat" }
    uniform float _ClearCoatNormalMode;
  //- endregion

  //- region CharacterDissolve 角色溶解 (keyword VFX_CHARACTER_DISSOLVE)
    // 参考 Sub0_Pass0_Fragment_b1095 的 _2642/_2647/_3805。参考里这些属性都是
    // [HideInInspector] —— 运行时由 VFX 系统驱动的动画量,不是美术在材质面板
    // 里填的。Painter 没有那套调度,所以做成滑条,能预览任意进度。
    //: param custom { "default": false, "label": "启用溶解 VFX_CHARACTER_DISSOLVE", "group": "D CharacterDissolve 溶解" }
    uniform bool u_CharacterDissolve;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "溶解噪声图(R)", "usage": "texture", "group": "D CharacterDissolve 溶解" }
    uniform sampler2D _DissolveTex;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "溶解图 ST", "group": "D CharacterDissolve 溶解" }
    uniform vec4 _DissolveTex_ST;
    //: param custom { "default": false, "label": "使用溶解 UseDissolve", "group": "D CharacterDissolve 溶解" }
    uniform bool _UseDissolve;
    //: param custom { "default": false, "label": "溶解图用视空间 UV UseViewUV", "group": "D CharacterDissolve 溶解" }
    uniform bool _DissolveUseViewUV;
    // [H16] 参考取 max(_DissolveScheduleOffset, 引擎逐物体进度);Painter 没有
    //       后者 → 只用这个属性,滑条即进度(0=未溶解,1=全溶解)。
    //: param custom { "default": 0.0, "label": "[H16] 溶解进度 ScheduleOffset", "min": 0.0, "max": 1.0, "group": "D CharacterDissolve 溶解" }
    uniform float _DissolveScheduleOffset;
    //: param custom { "default": 1.0, "label": "溶解边缘锐利度 EdgeSharp", "min": 0.0, "max": 50.0, "group": "D CharacterDissolve 溶解" }
    uniform float _DissolveEdgeSharp;
    //: param custom { "default": 0.0, "label": "溶解边缘自发光宽度 EmissiveEdge", "min": 0.0, "max": 2.0, "group": "D CharacterDissolve 溶解" }
    uniform float _DissolveEmissiveEdge;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "溶解边缘自发光色", "widget":"color", "group": "D CharacterDissolve 溶解" }
    uniform vec4 _DissolveEmissiveColor;
    //: param custom { "default": false, "label": "使用切面 UseCutOff", "group": "D CharacterDissolve 溶解" }
    uniform bool _UseCutOff;
    //: param custom { "default": 0.0, "label": "切面位置 CutOffPosY", "min": -10.0, "max": 10.0, "group": "D CharacterDissolve 溶解" }
    uniform float _CutOffPosY;
    //: param custom { "default": [0.0, 1.0, 0.0, 0.0], "label": "切面方向 CutOffDirection", "group": "D CharacterDissolve 溶解" }
    uniform vec4 _CutOffDirection;
  //- endregion

  //- region RealisticLighting (Standard, keyword _REALISTIC_LIGHTING)
    // 参考 b403(ON) vs b369(OFF) 的规范化 diff:唯一差别是**去掉两处风格化的
    // 环境亮度重映射** —— brightMix(0.35L+0.65,再按 CP1.x 混向 clamp(L,1.25,1.75))
    // 与 brightFull(clamp(L,0,1.5))在 ON 变体里整个不存在,等价于两者都取 1。
    // 方向性环境包裹(nprNdotL)两条路径都有,不是它带来的。
    //: param custom { "default": false, "label": "写实光照 _REALISTIC_LIGHTING", "group": "5 渲染设置" }
    uniform bool u_RealisticLighting;
  //- endregion

  //- region Puppet 傀儡 (Standard/Skin, keyword _PUPPET / _PUPPET_PROCEDURAL_DCURVE)
    // 区域遮罩按 uv.y 上下两段羽化;关掉区域遮罩时退回 RMOS.g(参考 _426/_479)。
    // 两条上色路径共用这一个遮罩:pattern 图 或 程序化 DCurve。
    //: param custom { "default": false, "label": "启用傀儡 _PUPPET", "group": "C Puppet 傀儡" }
    uniform bool u_Puppet;
    //: param custom { "default": false, "label": "UV2 区域遮罩 PuppetUV2AreaMask", "group": "C Puppet 傀儡" }
    uniform bool _PuppetUV2AreaMask;
    //: param custom { "default": 0.1, "label": "遮罩下沿 MaskLocationDown", "min": 0.0, "max": 0.9, "group": "C Puppet 傀儡" }
    uniform float _PuppetMaskLocationDown;
    //: param custom { "default": 0.5, "label": "遮罩上沿 MaskLocationTop", "min": 0.0, "max": 0.9, "group": "C Puppet 傀儡" }
    uniform float _PuppetMaskLocationTop;
    //: param custom { "default": 0.1, "label": "遮罩羽化 MaskSmooth", "min": 0.01, "max": 0.25, "group": "C Puppet 傀儡" }
    uniform float _PuppetMaskSmooth;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,1.0], "label": "傀儡 Pattern 图", "usage": "texture", "group": "C Puppet 傀儡" }
    uniform sampler2D _PuppetPatternMap;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "Pattern 图 ST", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetPatternMap_ST;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "Pattern 滚动速度", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetPatternSpeed;
    //: param custom { "default": false, "label": "Pattern 直接用 RGB PatternMapUseRGB", "group": "C Puppet 傀儡" }
    uniform bool _PuppetPatternMapUseRGB;
    //: param custom { "default": [0.5, 0.65, 0.8, 1.0], "label": "傀儡 BaseColor", "widget":"color", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetBaseColor;
    //: param custom { "default": [0.4, 0.2, 0.94, 1.0], "label": "Pattern 染色 TintColor", "widget":"color", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetPatternTintColor;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "Pattern 边缘色 TintEdgeColor", "widget":"color", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetPatternTintEdgeColor;
    //: param custom { "default": 1.0, "label": "Pattern 边缘位置 (1=不用)", "min": 0.01, "max": 1.0, "group": "C Puppet 傀儡" }
    uniform float _PuppetPatternTintEdgeLocation;
    //: param custom { "default": 0.0, "label": "傀儡 Metallic", "min": 0.0, "max": 1.0, "group": "C Puppet 傀儡" }
    uniform float _PuppetMetallic;
    //: param custom { "default": 1.0, "label": "傀儡 Roughness", "min": 0.0, "max": 1.0, "group": "C Puppet 傀儡" }
    uniform float _PuppetRoughness;
    // --- 程序化 DCurve(_PUPPET_PROCEDURAL_DCURVE):7 段 cos 域扭曲 + 1/|sin| 脊线 ---
    //: param custom { "default": false, "label": "程序化 DCurve _PUPPET_PROCEDURAL_DCURVE", "group": "C Puppet 傀儡" }
    uniform bool u_PuppetProceduralDCurve;
    //: param custom { "default": [120.0, 12.0, 0.0, -0.06], "label": "DCurve UV 缩放(xy) 速度(zw)", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetPDCurveUVScaleSpeed;
    //: param custom { "default": 0.5, "label": "DCurve 扭曲速度 DistortSpeed", "min": -10.0, "max": 10.0, "group": "C Puppet 傀儡" }
    uniform float _PuppetPDCurveDistortSpeed;
    //: param custom { "default": 0.5, "label": "DCurve 周期速度 PeriodSpeed", "min": -10.0, "max": 10.0, "group": "C Puppet 傀儡" }
    uniform float _PuppetPDCurveDistortPeriodSpeed;
    //: param custom { "default": [0.39, 0.58, 0.7, 1.0], "label": "DCurve BaseColor", "widget":"color", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetPDCurveBaseColor;
    //: param custom { "default": [0.57, 0.3, 0.83, 0.5], "label": "DCurve LightColor (a=强度)", "widget":"color", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetPDCurveLightColor;
    //: param custom { "default": [0.45, 0.38, 0.73, 0.5], "label": "DCurve EdgeColor (a=强度)", "widget":"color", "group": "C Puppet 傀儡" }
    uniform vec4 _PuppetPDCurveEdgeColor;
    //: param custom { "default": 0.3, "label": "DCurve 边缘位置 (1=不用)", "min": 0.01, "max": 1.0, "group": "C Puppet 傀儡" }
    uniform float _PuppetPDCurveEdgeLocation;
  //- endregion

  //- region CharacterErosion 侵蚀 (Standard, keyword _CHARACTER_EROSION)
    // 1.4.4 新增。遮罩就是 RMOS.g(与各向异性同一位,但两个 keyword 互斥)。
    // 三段色按 UV.y 位置分层 + pattern 图着色,并接管 metallic / 粗糙度 / 法线。
    //: param custom { "default": false, "label": "启用侵蚀 _CHARACTER_EROSION", "group": "B CharacterErosion 侵蚀" }
    uniform bool u_CharacterErosion;
    //: param custom { "default": "", "default_color": [0.5,0.5,1.0,1.0], "label": "侵蚀法线(RG)+光滑度(B)", "usage": "texture", "group": "B CharacterErosion 侵蚀" }
    uniform sampler2D _ErosionNormalSmoothnessMap;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "侵蚀法线图 ST", "group": "B CharacterErosion 侵蚀" }
    uniform vec4 _ErosionNormalSmoothnessMap_ST;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,1.0], "label": "侵蚀 Pattern 图(R)", "usage": "texture", "group": "B CharacterErosion 侵蚀" }
    uniform sampler2D _ErosionPatternMap;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "侵蚀 Pattern 图 ST", "group": "B CharacterErosion 侵蚀" }
    uniform vec4 _ErosionPatternMap_ST;
    //: param custom { "default": 1.0, "label": "侵蚀法线强度 NormalScale", "min": 0.0, "max": 4.0, "group": "B CharacterErosion 侵蚀" }
    uniform float _ErosionNormalScale;
    //: param custom { "default": 0.5, "label": "侵蚀 Metallic", "min": 0.0, "max": 1.0, "group": "B CharacterErosion 侵蚀" }
    uniform float _ErosionMetallic;
    //: param custom { "default": 0.0, "label": "侵蚀光滑度 Bias", "min": -1.0, "max": 1.0, "group": "B CharacterErosion 侵蚀" }
    uniform float _ErosionSmoothnessBias;
    //: param custom { "default": [0.8, 0.4, 0.5, 1.0], "label": "侵蚀 BaseColor", "widget":"color", "group": "B CharacterErosion 侵蚀" }
    uniform vec4 _ErosionBaseColor;
    //: param custom { "default": false, "label": "启用 Root/Top 分段染色 UV2Tint", "group": "B CharacterErosion 侵蚀" }
    uniform bool _ErosionUV2Tint;
    //: param custom { "default": [0.1, 0.1, 0.1, 1.0], "label": "侵蚀 RootColor", "widget":"color", "group": "B CharacterErosion 侵蚀" }
    uniform vec4 _ErosionBaseRootColor;
    //: param custom { "default": 0.1, "label": "Root 位置", "min": 0.0, "max": 0.9, "group": "B CharacterErosion 侵蚀" }
    uniform float _ErosionBaseRootColorLocation;
    //: param custom { "default": 0.1, "label": "Root 羽化", "min": 0.0, "max": 0.25, "group": "B CharacterErosion 侵蚀" }
    uniform float _ErosionBaseRootColorSmooth;
    //: param custom { "default": [0.75, 0.75, 0.75, 1.0], "label": "侵蚀 TopColor", "widget":"color", "group": "B CharacterErosion 侵蚀" }
    uniform vec4 _ErosionBaseTopColor;
    //: param custom { "default": 0.7, "label": "Top 位置", "min": 0.0, "max": 0.9, "group": "B CharacterErosion 侵蚀" }
    uniform float _ErosionBaseTopColorLocation;
    //: param custom { "default": 0.1, "label": "Top 羽化", "min": 0.0, "max": 0.25, "group": "B CharacterErosion 侵蚀" }
    uniform float _ErosionBaseTopColorSmooth;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "Pattern 染色", "widget":"color", "group": "B CharacterErosion 侵蚀" }
    uniform vec4 _ErosionPatternTintColor;
  //- endregion

  //- region ExtraAlphaMask 额外遮罩 (Standard, 无 keyword)
    // 参考里没有开关属性:材质挂了图就采。R=Alpha G=Root B=Depth A=ID,
    // 反照率被 Root/Depth 两段 tint 各乘一次(参考 _391.._393)。
    // [H12] 参考在 UV1 上采(TEXCOORD_4),Painter 这套着色只有 UV0 → 退回 uv0,
    //       与 VFX 部位 uv1=uv0 是同一条既有约定。
    //: param custom { "default": false, "label": "启用额外遮罩(挂图自动开)", "group": "A ExtraAlphaMask 额外遮罩" }
    uniform bool u_ExtraAlphaMask;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "额外遮罩 R:Alpha G:Root B:Depth A:ID", "usage": "texture", "group": "A ExtraAlphaMask 额外遮罩" }
    uniform sampler2D _ExtraAlphaMask;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "Root Tint Color", "widget":"color", "group": "A ExtraAlphaMask 额外遮罩" }
    uniform vec4 _ExtraRootTintColor;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "Depth Tint Color", "widget":"color", "group": "A ExtraAlphaMask 额外遮罩" }
    uniform vec4 _ExtraDepthTintColor;

    // ---- liquidag 液体附着(_OutlineColorMap 在这份变体里不是描边贴图) ----
    // 参考 characternpr_liquidag b13 _970.._1026:按 UV*tiling 采 _OutlineColorMap,
    // RG 当细节法线、B 当高度,和液面轴坐标一起决定附着边界,再 TBN 变换覆盖法线。
    // 触发量 _434 是引擎按实例塞进 _CharacterParams10 的附着进度字节
    // (0..255,门限 >2.55),tiling 走 _CharacterParams10.z —— 材质里都没有对应
    // 属性 → [H19] 两根滑条代替,进度默认 0 就是参考里"没附着"的状态。
    //: param custom { "default": "", "default_color": [0.5,0.5,1.0,0.0], "label": "液体附着法线 RG + 高度 B(liquidag)", "usage": "texture", "group": "A 液体附着 liquidag" }
    uniform sampler2D _OutlineColorMap;
    //: param custom { "default": 0.0, "label": "[H19] 附着进度(引擎逐实例字节)", "min": 0.0, "max": 255.0, "group": "A 液体附着 liquidag" }
    uniform float f_LiquidProgress;
    //: param custom { "default": 1.0, "label": "[H19] 附着平铺(引擎 CharacterParams10.z)", "min": 0.01, "max": 32.0, "group": "A 液体附着 liquidag" }
    uniform float f_LiquidTiling;

    // ---- Part 8 ShadowReceiver:characternpr_shadowreceiver.shader 的全部 7 个属性 ----
    // 参考 b3 _582/_617/_1059.._1073。该 pass 是 `Blend Zero SrcColor` 的乘法叠帧,
    // 与 [H13] OverlayShadow 同一堵墙,输出改写成 (染色, 变暗权重) —— 见 shadeShadowReceiver。
    //: param custom { "default": [0.5, 0.5, 0.5, 1.0], "label": "阴影色 ShadowColor(A=强度)", "widget":"color", "group": "B ShadowReceiver 接影地面" }
    uniform vec4 _ShadowColor;
    //: param custom { "default": false, "label": "关闭高精度自阴影在地上的投射", "group": "B ShadowReceiver 接影地面" }
    uniform bool _DisableCharacterSelfShadow;
    //: param custom { "default": false, "label": "关闭主光阴影在地上的投射", "group": "B ShadowReceiver 接影地面" }
    uniform bool _DisableSceneShadow;
    //: param custom { "default": false, "label": "Circle Fade(中心点须移至角色脚下)", "group": "B ShadowReceiver 接影地面" }
    uniform bool _CircleFade;
    //: param custom { "default": 0.5, "label": "Circle Fade Distance", "min": 0.01, "max": 3.0, "group": "B ShadowReceiver 接影地面" }
    uniform float _CircleFadeDistance;
    //: param custom { "default": 0.0, "label": "Circle Fade Smoothness", "min": 0.0, "max": 3.0, "group": "B ShadowReceiver 接影地面" }
    uniform float _CircleFadeSmoothness;
    //: param custom { "default": [0.25, 0.25, 0.25, 1.0], "label": "Capsule AO Color", "widget":"color", "group": "B ShadowReceiver 接影地面" }
    uniform vec4 _CapsuleAoColor;
    // [H20] 参考这四项来自引擎:主光级联阴影查表、_CharacterShadowmapTex 的 PCF 循环、
    //       _f_0[34].x 阴影强度、_VisibilitySHRT 屏幕胶囊可见度 SH。Painter 一个都没有,
    //       换成滑条(1 = 全亮 / 0 = 全遮),取值域与参考一致。
    //: param custom { "default": 1.0, "label": "[H20] 主光阴影可见度(1=无阴影)", "min": 0.0, "max": 1.0, "group": "B ShadowReceiver 接影地面" }
    uniform float f_SceneShadow;
    //: param custom { "default": 1.0, "label": "[H20] 角色自阴影可见度(1=无阴影)", "min": 0.0, "max": 1.0, "group": "B ShadowReceiver 接影地面" }
    uniform float f_CharacterSelfShadow;
    //: param custom { "default": 1.0, "label": "[H20] 阴影强度(引擎 f_0[34].x)", "min": 0.0, "max": 1.0, "group": "B ShadowReceiver 接影地面" }
    uniform float f_ShadowStrength;
    //: param custom { "default": 0.0, "label": "[H20] 胶囊 AO 遮蔽量", "min": 0.0, "max": 1.0, "group": "B ShadowReceiver 接影地面" }
    uniform float f_CapsuleAO;
    // 参考取 unity_ObjectToWorld[3].xyz(投影片自身的原点)。Painter 没有对象矩阵。
    //: param custom { "default": [0.0, 0.0, 0.0], "label": "[H20] Circle Fade 中心(世界)", "min": -10.0, "max": 10.0, "group": "B ShadowReceiver 接影地面" }
    uniform vec3 f_CircleFadeCenter;
  //- endregion

  //- region CustomizeAvatar 换装染色 (Standard, keyword _CUSTOMIZE_AVATAR)
    // BaseMap 的 RGB 在这条路径下不是颜色而是三张遮罩:
    //   R = 明度  G = 选哪种 tint  B = 用 BaseColor 还是 tint
    //: param custom { "default": false, "label": "启用换装染色 _CUSTOMIZE_AVATAR", "group": "A CustomizeAvatar 换装染色" }
    uniform bool u_CustomizeAvatar;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "Customize BaseColor", "widget":"color", "group": "A CustomizeAvatar 换装染色" }
    uniform vec4 _CustomizeBaseColor;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "Customize BaseTintColor", "widget":"color", "group": "A CustomizeAvatar 换装染色" }
    uniform vec4 _CustomizeBaseTintColor;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "Customize AddTintColor", "widget":"color", "group": "A CustomizeAvatar 换装染色" }
    uniform vec4 _CustomizeAddTintColor;
  //- endregion

  //- region MatcapEnvReflection (Standard, keyword _MATCAP_ENV_REFLECTION_ON)
    // 与 Eyes 的 _MATCAP_ON 是**两条**不同路径:这条不是叠加一层高光,而是拿
    // Matcap 顶替环境反射的采样源。贴图/颜色沿用 Eyes 那组(参考里也是同两个
    // 属性 _MatcapTex / _MatcapColor)。
    //: param custom { "default": false, "label": "Matcap 作环境反射 _MATCAP_ENV_REFLECTION_ON", "group": "6 Anisotropy 各向异性" }
    uniform bool u_MatcapEnvReflection;
  //- endregion

  //- region EnemyHitFlash 受击闪白 (Standard/LiquidAg, keyword _ENEMY_HIT_FLASH)
    // 1.4.4 新增。球形扫描线(世界坐标到中心的距离 remap)+ 独立法线强度的菲涅尔。
    //: param custom { "default": false, "label": "启用受击闪白 _ENEMY_HIT_FLASH", "group": "9 EnemyHitFlash 受击闪白" }
    uniform bool u_EnemyHitFlash;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "扫描线亮色 BrightColor (a=强度)", "widget":"color", "group": "9 EnemyHitFlash 受击闪白" }
    uniform vec4 _EnemyHitFlashBrightColor;
    //: param custom { "default": 1.0, "label": "亮色调整 BrightColorAdjust", "min": 0.0, "max": 10.0, "group": "9 EnemyHitFlash 受击闪白" }
    uniform float _EnemyHitFlashBrightColorAdjust;
    //: param custom { "default": 0.0, "label": "羽化内半径 InnerRadius", "min": 0.0, "max": 10.0, "group": "9 EnemyHitFlash 受击闪白" }
    uniform float _EnemyHitFlashInnerRadius;
    //: param custom { "default": 2.0, "label": "羽化外半径 OuterRadius", "min": 0.0, "max": 10.0, "group": "9 EnemyHitFlash 受击闪白" }
    uniform float _EnemyHitFlashOuterRadius;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "覆盖中心 BrightCenter (w=1 用此坐标, w=0 用默认主角位置)", "group": "9 EnemyHitFlash 受击闪白" }
    uniform vec4 _EnemyHitFlashBrightCenter;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "菲涅尔颜色 FresnelColor (a=混合量)", "widget":"color", "group": "9 EnemyHitFlash 受击闪白" }
    uniform vec4 _EnemyHitFlashFresnelColor;
    //: param custom { "default": 1.0, "label": "菲涅尔颜色调整 FresnelColorAdjust", "min": 0.0, "max": 10.0, "group": "9 EnemyHitFlash 受击闪白" }
    uniform float _EnemyHitFlashFresnelColorAdjust;
    //: param custom { "default": 0.0, "label": "菲涅尔 Bias", "min": -1.0, "max": 2.0, "group": "9 EnemyHitFlash 受击闪白" }
    uniform float _EnemyHitFlashFresnelBias;
    //: param custom { "default": 1.0, "label": "菲涅尔影响不透明度 FresnelAffectOpacity", "min": 0.0, "max": 1.0, "group": "9 EnemyHitFlash 受击闪白" }
    uniform float _EnemyHitFlashFresnelAffectOpacity;
    //: param custom { "default": 1.0, "label": "法线强度 NormalScale", "min": 0.0, "max": 3.0, "group": "9 EnemyHitFlash 受击闪白" }
    uniform float _EnemyHitFlashNormalScale;
    // [H15] 参考里这一项乘 _ExposureWithMiscParams.y(引擎全局曝光,不是材质属性),
    // Painter 拿不到 → 滑条,默认 1.0 = 不额外缩放。
    //: param custom { "default": 1.0, "label": "[H15] 闪白曝光 HitFlashExposure", "min": 0.0, "max": 10.0, "group": "9 EnemyHitFlash 受击闪白" }
    uniform float f_HitFlashExposure;
  //- endregion

  //- region StylizedFresnel 风格化菲涅尔 (Standard, keyword _STYLIZED_FRESNEL)
    // 1.4.4 新增。菲涅尔用的是**几何法线**(TEXCOORD_2,顶点法线插值),
    // 不是法线贴图后的 N —— 参考 _394 就是这么取的。
    //: param custom { "default": false, "label": "启用风格化菲涅尔 _STYLIZED_FRESNEL", "group": "8 StylizedFresnel 风格化菲涅尔" }
    uniform bool u_StylizedFresnel;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "颜色 Color (a=自发光量)", "widget":"color", "group": "8 StylizedFresnel 风格化菲涅尔" }
    uniform vec4 _StylizedFresnelColor;
    //: param custom { "default": 2.0, "label": "Pow", "min": 0.0, "max": 10.0, "group": "8 StylizedFresnel 风格化菲涅尔" }
    uniform float _StylizedFresnelPow;
    //: param custom { "default": 2.0, "label": "Amount", "min": 0.0, "max": 10.0, "group": "8 StylizedFresnel 风格化菲涅尔" }
    uniform float _StylizedFresnelAmount;
    //: param custom { "default": 0.0, "label": "噪声速度 NoiseSpeed", "min": -5.0, "max": 5.0, "group": "8 StylizedFresnel 风格化菲涅尔" }
    uniform float _StylizedFresnelNoiseSpeed;
    //: param custom { "default": 1.0, "label": "噪声对比度 NoiseContrast", "min": 0.0, "max": 10.0, "group": "8 StylizedFresnel 风格化菲涅尔" }
    uniform float _StylizedNoiseContrast;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "噪声图 ST (xy=Tiling zw=Offset)", "group": "8 StylizedFresnel 风格化菲涅尔" }
    uniform vec4 _StylizedFresnelNoiseMap_ST;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "风格化菲涅尔噪声图", "usage": "texture", "group": "8 StylizedFresnel 风格化菲涅尔" }
    uniform sampler2D _StylizedFresnelNoiseMap;
  //- endregion

  //- region Anisotropy 各向异性高光 (Standard, keyword _ANISOTROPY_SPECULAR_ON)
    // 1.4.4 新增(1.3.3 的基础部位没有这套;Hair 的 _Anisotropy* 是另一套,别混)。
    // 两瓣:主瓣走可见项、第二瓣不走,方向都按 RMOS.g(specScale)加权。
    //: param custom { "default": false, "label": "启用各向异性 _ANISOTROPY_SPECULAR_ON", "group": "6 Anisotropy 各向异性" }
    uniform bool u_UseAnisotropy;
    //: param custom { "default": true, "label": "使用模型切线 UseGeometryTangent", "group": "6 Anisotropy 各向异性" }
    uniform bool _AnisotropyUseGeometryTangent;
    //: param custom { "default": 0.0, "label": "基础各向异性高光方向 DirectionMain", "min": -1.0, "max": 1.0, "group": "6 Anisotropy 各向异性" }
    uniform float _AnisotropyDirectionMain;
    //: param custom { "default": 1.0, "label": "基础各向异性高光强度系数 IntensityMultiplier", "min": 0.0, "max": 2.0, "group": "6 Anisotropy 各向异性" }
    uniform float _AnisotropyIntensityMultiplier;
    //: param custom { "default": 0.0, "label": "第二层各向异性方向 DirectionAdditional", "min": -1.0, "max": 1.0, "group": "6 Anisotropy 各向异性" }
    uniform float _AnisotropyDirectionAdditional;
    //: param custom { "default": 0.0, "label": "第二层各向异性位置偏移 OffsetAdditional", "min": -1.0, "max": 1.0, "group": "6 Anisotropy 各向异性" }
    uniform float _AnisotropyOffsetAdditional;
    //: param custom { "default": [0.2, 0.2, 0.2, 1.0], "label": "第二层各向异性颜色 ColorAdditional", "widget":"color", "group": "6 Anisotropy 各向异性" }
    uniform vec4 _AnisotropyColorAdditional;
  //- endregion

  //- region SilkStockings 丝袜 (Standard, keyword _SILK_STOCKINGS)
    // 1.4.4 的 _SilkStockings* 全套。1.3.3 的 _Pantyhose* 在参考里已 0 命中,
    // 整块被这套取代:多了干/湿偏色、覆盖 remap、遮罩贴图(R 各向异性强度 /
    // G 锐利度 / B 湿身光滑度 / A 透肉度)、高光干燥态最小值与透肉衰减、
    // 雨湿遮罩影响、以及"浸润时透肉 or 压暗"的二选一。
    //: param custom { "default": false, "label": "启用丝袜 _SILK_STOCKINGS", "group": "7 SilkStockings 丝袜" }
    uniform bool u_SilkStockings;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "常态偏色 DryColor", "widget":"color", "group": "7 SilkStockings 丝袜" }
    uniform vec4 _SilkStockingsDryColor;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "湿润偏色 WetColor", "widget":"color", "group": "7 SilkStockings 丝袜" }
    uniform vec4 _SilkStockingsWetColor;
    //: param custom { "default": [0.0, 0.0, 0.0, 1.0], "label": "边缘颜色 Color (a=透肉阈值)", "widget":"color", "group": "7 SilkStockings 丝袜" }
    uniform vec4 _SilkStockingsColor;
    //: param custom { "default": 0.05, "label": "最浅覆盖 MinAffect", "min": 0.0, "max": 0.49, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsMinAffect;
    //: param custom { "default": 0.9, "label": "最深覆盖 MaxAffect", "min": 0.5, "max": 0.9, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsMaxAffect;
    //: param custom { "default": 5.0, "label": "高光强度Remap SpecularInt", "min": 0.0, "max": 20.0, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsSpecularInt;
        // _949 = lerp(本值, 1, 湿润度) × SpecularInt。湿润度 0 时它**就是**丝袜
    // 各向异性高光的总强度;参考默认 0 = 干态无丝袜高光,要看效果得调它或调湿润度。
//: param custom { "default": 0.0, "label": "干态高光强度 SpecularMinAtMinWetness", "min": 0.0, "max": 1.0, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsSpecularMinAtMinWetness;
    //: param custom { "default": 0.8, "label": "高光透肉衰减 SpecularFalloff", "min": 0.0, "max": 1.0, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsSpecularFalloff;
    //: param custom { "default": 2.0, "label": "高光位置偏移 SpecularValue", "min": -2.0, "max": 2.0, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsSpecularValue;
    //: param custom { "default": 0.0, "label": "锐利度G AnisoDirection (简易模式)", "min": -1.0, "max": 1.0, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsAnisoDirection;
    //: param custom { "default": false, "label": "高级模式(使用遮罩贴图) Advance", "group": "7 SilkStockings 丝袜" }
    uniform bool _SilkStockingsAdvance;
    //: param custom { "default": 0.7, "label": "浸润内置遮罩影响 RainWetMaskScale", "min": 0.0, "max": 1.0, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsRainWetMaskScale;
    //: param custom { "default": 0.5, "label": "浸润时 透肉(>0) or 压暗(<0) AlbedoAffectType", "min": -0.9, "max": 0.5, "group": "7 SilkStockings 丝袜" }
    uniform float _SilkStockingsAlbedoAffectType;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "丝袜遮罩 R各向异性强度 G锐利度 B湿身光滑度 A透肉度", "usage": "texture", "group": "7 SilkStockings 丝袜" }
    uniform sampler2D _SilkStockingsMask;
    // [H14] 湿润度:游戏里来自天气/雨系统(_563 = max(角色浸润, 雨量/255)),
    // Painter 没有 → 一根滑条替代。参考里驱动"湿身遮罩"的光照项 (_1589) 与
    // 它只通过 max/smoothstep 合流,故同源。
    //: param custom { "default": 0.0, "label": "[H14] 湿润度 Wetness(0=干,手动模拟下雨)", "min": 0.0, "max": 1.0, "group": "7 SilkStockings 丝袜" }
    uniform float f_SilkWetness;
    // [H14] 湿身变光滑那一条链(参考 _2450/_2506/_2670)还要一张**引擎的 3D 雨痕体积图**
    //       (逐帧按 1/3 切片采三次)。Painter 没有,拿它的 .z 当滑条:0 = 没下雨、
    //       没有雨痕(引擎不下雨时的状态),1 = 整片湿透。参考的 "white" 默认是给
    //       材质贴图槽用的,这里是引擎全局,所以默认取干。
    //: param custom { "default": 0.0, "label": "[H14] 雨痕量(替代引擎 3D 雨痕体积图)", "min": 0.0, "max": 1.0, "group": "7 SilkStockings 丝袜" }
    uniform float f_SilkWetStreak;
  //- endregion

  //- region Parallax (Standard)
    //: param custom { "default": false, "label": "启用视差 _PARALLAX_MAP", "group": "8 Parallax" }
    uniform bool u_UseParallax;
    //- 视差高度图已迁入 SP 的 Height 通道 (可绘制/可烘焙; 见引擎通道区 height_tex)。
    //- _ParallaxTex_ST 平铺仍在 marching 时作用于采样 UV (与 Unity 一致); 高度数据按原 sRGB 字节解码。
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "ParallaxTex_ST", "group": "8 Parallax" }
    uniform vec4 _ParallaxTex_ST;
    //: param custom { "default": 2.0, "label": "步进次数 ParallaxMarchNum", "min": 1.0, "max": 5.0, "group": "8 Parallax" }
    uniform float _ParallaxMarchNum;
    //: param custom { "default": 0.3, "label": "视差强度 ParallaxScale (Eyes 也用)", "min": 0.0, "max": 1.0, "group": "8 Parallax" }
    uniform float _ParallaxScale;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "视差颜色 ParallaxColor", "widget":"color", "group": "8 Parallax" }
    uniform vec4 _ParallaxColor;
  //- endregion

  //- region Face (Part 1)
    // 1.4.4 新增:脸部贴花。参考 characternpr_skin b129 的 _425.._529 ——
    // 中心偏移 → 镜像模式 → 尺寸/翻转 → 旋转 → 亮度遮罩再叠上去。
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,0.0], "label": "脸部贴花 FaceDecalMap", "usage": "texture", "group": "A Face" }
    uniform sampler2D _FaceDecalMap;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "贴花染色 TintColor (a=强度)", "widget":"color", "group": "A Face" }
    uniform vec4 _FaceDecalTintColor;
    //: param custom { "default": 0.0, "label": "贴花中心 X", "min": -0.5, "max": 0.5, "group": "A Face" }
    uniform float _FaceDecalCenterX;
    //: param custom { "default": 0.0, "label": "贴花中心 Y", "min": -0.5, "max": 0.5, "group": "A Face" }
    uniform float _FaceDecalCenterY;
    //: param custom { "default": 0.0, "label": "贴花翻转 X", "min": 0.0, "max": 1.0, "group": "A Face" }
    uniform float _FaceDecalInvertX;
    //: param custom { "default": 0.0, "label": "贴花翻转 Y", "min": 0.0, "max": 1.0, "group": "A Face" }
    uniform float _FaceDecalInvertY;
    //: param custom { "default": 0.2, "label": "贴花尺寸 Size", "min": 0.05, "max": 2.0, "group": "A Face" }
    uniform float _FaceDecalSize;
    //: param custom { "default": 0.0, "label": "贴花旋转 Rotation (0..1 = 一圈)", "min": 0.0, "max": 1.0, "group": "A Face" }
    uniform float _FaceDecalRotation;
    //: param custom { "default": 0.0, "label": "贴花镜像模式 (0 单个 / 1 水平 / 2 垂直)", "min": 0.0, "max": 2.0, "group": "A Face" }
    uniform float _FaceDecalMirrorMode;
    //: param custom { "default": 0.5, "label": "贴花镜像分割线 MirrorSplit", "min": 0.0, "max": 1.0, "group": "A Face" }
    uniform float _FaceDecalMirrorSplit;
    //: param custom { "default": 0.7, "label": "贴花亮度遮罩 BrightnessMask", "min": 0.0, "max": 1.0, "group": "A Face" }
    uniform float _FaceDecalBrightnessMask;
    //: param custom { "default": false, "label": "使用 SDF Lightmap _SDFLIGHTMAP (mask=user0)", "group": "A Face" }
    uniform bool u_UseSDFLightmap;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,1.0], "label": "SDF Lightmap", "usage": "texture", "group": "A Face" }
    uniform sampler2D _SDFLightmap;
    //: param custom { "default": "", "default_color": [1.0,1.0,0.0,0.0], "label": "SDF Mask (rgba: rim/blend/body/ctrl)", "usage": "texture", "group": "A Face" }
    uniform sampler2D _SDFMask;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "皮肤边缘光色 SDFRimColor", "widget":"color", "group": "A Face" }
    uniform vec4 _SDFRimColor;
    //: param custom { "default": 0.5, "label": "皮肤边缘光强 SkinRimOffScale", "min": 0.0, "max": 1.5, "group": "A Face" }
    uniform float _SkinRimOffScale;
    //: param custom { "default": 1.0, "label": "脸部边缘光强 FaceRimOffScale (SDF区)", "min": 0.0, "max": 1.5, "group": "A Face" }
    uniform float _FaceRimOffScale;
    //- 源 shader 的脸基轴 = unity_ObjectToWorld 列0(右)/列2(前), 从不读 .mat 的 FaceForward/FaceRight。
    //- SP 模型烘死在世界空间无矩阵可读 → 这两个参数直接填"SP 世界空间"的脸轴, 支持负值
    //- (必须显式声明 min/max, 否则 SP UI 钳 0..1 输不进负数)。
    //- rip FBX 进 SP 实测面朝 -Z: Unity 轴 → SP 轴 = Z 取反 (X/Y 不变), 故默认 (0,0,-1)/(1,0,0)。
    //- 调试: 明暗随光前后扫掠反相 → FaceForward 整体取反; 阴影左右镜像取错边 → FaceRight 整体取反。
    //- 不需要第三个 FaceBack/FaceUp 参数: Up = cross 重建 (源列1, 仅 ~1e-4 权重), Back = -Forward。
    //- .mat 原值是 Unity 空间的 (0,0,1) / (1,0,0); 导出取反 X (保证模型正面朝向观察者),
    //- 所以同一个镜像也作用到这两根轴上 → (0,0,1) / (-1,0,0)。几何和方向用同一条规则。
    //- 曾经的 (0,0,0) 是把前后扫描整个关掉的回避手段, 代价是 SDF 不随光扫掠。
    //- 若 SDF 的前后或左右出现反相, 要翻的符号在这里, 不在网格转换里。
    //: param custom { "default": [0.0, 0.0, 1.0], "label": "脸正面朝向 FaceForward (SP世界轴; 全0=关前后SDF扫描)", "min": -1.0, "max": 1.0, "group": "A Face" }
    uniform vec3 _FaceForward;
    //: param custom { "default": [-1.0, 0.0, 0.0], "label": "脸右侧朝向 FaceRight (SP世界轴)", "min": -1.0, "max": 1.0, "group": "A Face" }
    uniform vec3 _FaceRight;
    //: param custom { "default": false, "label": "使用表情贴图 _EMOTION_MAP", "group": "A Face" }
    uniform bool u_UseEmotionMap;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,0.0], "label": "表情贴图 EmotionMap (2x2 grid)", "usage": "texture", "group": "A Face" }
    uniform sampler2D _EmotionMap;
    //: param custom { "default": 0, "label": "表情序号 EmotionIndex", "min": 0, "max": 3, "group": "A Face" }
    uniform int _EmotionIndex;
    //: param custom { "default": 1.0, "label": "表情混合 EmotionBlend", "min": 0.0, "max": 1.0, "group": "A Face" }
    uniform float _EmotionBlend;
    //: param custom { "default": false, "label": "使用高光贴图 _HIGHLIGHT_MAP", "group": "A Face" }
    uniform bool u_FaceHighlightMap;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,0.0], "label": "脸部高光贴图 HighlightMap", "usage": "texture", "group": "A Face" }
    uniform sampler2D _HighlightMap;
    //: param custom { "default": [0.04, -0.01, 0.0, 0.0], "label": "高光贴图偏移 HighlightMapVector", "group": "A Face" }
    uniform vec4 _HighlightMapVector;
  //- endregion

  //- region Eyes (Part 2 / 5)
    //: param custom { "default": false, "label": "使用 Matcap _MATCAP_ON", "group": "B Eyes" }
    uniform bool u_UseMatcap;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "Matcap 贴图", "usage": "texture", "group": "B Eyes" }
    uniform sampler2D _MatcapTex;
    //: param custom { "default": 1.0, "label": "Matcap 法线强度 MatcapNormalScale", "min": 0.0, "max": 1.5, "group": "B Eyes" }
    uniform float _MatcapNormalScale;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "Matcap 颜色 (HDR)", "widget":"color", "group": "B Eyes" }
    uniform vec4 _MatcapColor;
    // 1.4.4 新增:虹膜染色。参考 characternpr_eye b37 的 _393/_395 —— 用
    // frac(uv)-0.5 的半径判定,**圈内(虹膜)才染色**,圈外(眼白)乘 1 跳过。
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "虹膜染色 EyeTintColor", "widget":"color", "group": "B Eyes" }
    uniform vec4 _EyeTintColor;
    //: param custom { "default": false, "label": "眼睛高光 _EYE_HIGHLIGHT", "group": "B Eyes" }
    uniform bool u_EyeHighLight;
    //: param custom { "default": [2.0, 2.0, 2.0, 1.0], "label": "眼高光颜色 (HDR)", "widget":"color", "group": "B Eyes" }
    uniform vec4 _EyeHighLightColor;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "眼散射颜色 (HDR)", "widget":"color", "group": "B Eyes" }
    uniform vec4 _EyeScatteringColor;
    //: param custom { "default": 0.03, "label": "虹膜视差 EyeParallaxScale", "min": 0.0, "max": 0.15, "group": "B Eyes" }
    uniform float _EyeParallaxScale;
  //- endregion

  //- region Hair (Part 3)
    // 1.4.4 新增:发色两段染色。参考 characternpr_hair b117 的 _464/_493 ——
    // 遮罩 = baseTex.a * _BaseColor.a,albedo *= lerp(AddTint, BaseTint, 遮罩)。
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "发色 BaseTintColor", "widget":"color", "group": "C Hair" }
    uniform vec4 _HairBaseTintColor;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "发色 AddTintColor", "widget":"color", "group": "C Hair" }
    uniform vec4 _HairAddTintColor;
    //: param custom { "default": "", "default_color": [0.5,0.5,1.0,1.0], "label": "高光法线图 SpecNormalMap (标准OpenGL RGB; diffuse 法线请画在 SP 的 Normal 通道)", "usage": "texture", "group": "C Hair" }
    uniform sampler2D _SpecNormalMap;
    //: param custom { "default": true, "label": "启用高光法线 _SPECULAR_NORMALMAP (独立 SpecNormalMap)", "group": "C Hair" }
    uniform bool u_UseSpecBumpMap;
    //: param custom { "default": 1.0, "label": "高光法线强度 SpecBumpScale", "min": 0.0, "max": 4.0, "group": "C Hair" }
    uniform float _SpecBumpScale;
    //: param custom { "default": 0.7, "label": "各向异性1 AnisotropyValue", "min": 0.0, "max": 1.0, "group": "C Hair" }
    uniform float _AnisotropyValue;
    //: param custom { "default": 0.712, "label": "各向异性2 AnisotropyValue2", "min": 0.0, "max": 1.0, "group": "C Hair" }
    uniform float _AnisotropyValue2;
    //: param custom { "default": 0.0, "label": "各向异性方向X AnisotropyDirX", "min": -1.0, "max": 1.0, "group": "C Hair" }
    uniform float _AnisotropyDirX;
    //: param custom { "default": 2.0, "label": "各向异性强度 AnisotropyIntensity", "min": 0.0, "max": 3.0, "group": "C Hair" }
    uniform float _AnisotropyIntensity;
    //: param custom { "default": 3.0, "label": "边缘衰减 AnisotropyEdgeFade", "min": 0.01, "max": 10.0, "group": "C Hair" }
    uniform float _AnisotropyEdgeFade;
    //: param custom { "default": 0.5, "label": "高光2范围 AnisotropyRange2", "min": -1.0, "max": 1.0, "group": "C Hair" }
    uniform float _AnisotropyRange2;
    //: param custom { "default": [0.563, 0.283, 0.048, 1.0], "label": "高光2颜色 AnisotropyColor2", "widget":"color", "group": "C Hair" }
    uniform vec4 _AnisotropyColor2;
    //: param custom { "default": false, "label": "使用 Stroke Map _STROKE_ON", "group": "C Hair" }
    uniform bool u_StrokeOn;
    //: param custom { "default": "", "default_color": [0.5,0.5,0.5,1.0], "label": "Stroke Map (R)", "usage": "texture", "group": "C Hair" }
    uniform sampler2D _StrokeMap;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "StrokeMap_ST", "group": "C Hair" }
    uniform vec4 _StrokeMap_ST;
    //: param custom { "default": 1.0, "label": "Stroke 强度 StrokeScale", "min": -4.0, "max": 4.0, "group": "C Hair" }
    uniform float _StrokeScale;
    //: param custom { "default": true, "label": "高光线 _SPECULAR_LINE", "group": "C Hair" }
    uniform bool u_SpecularLine;
    //: param custom { "default": 1.0, "label": "使用 Line Map (0=程序线)", "min": 0.0, "max": 1.0, "group": "C Hair" }
    uniform float _UseLineMap;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,1.0], "label": "Line Map (R)", "usage": "texture", "group": "C Hair" }
    uniform sampler2D _LineMap;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "LineMap_ST", "group": "C Hair" }
    uniform vec4 _LineMap_ST;
    //: param custom { "default": 300.0, "label": "线数量 LineAmount", "min": 1.0, "max": 1000.0, "group": "C Hair" }
    uniform float _LineAmount;
    //: param custom { "default": 0.58, "label": "线位置 LineValue", "min": 0.0, "max": 1.0, "group": "C Hair" }
    uniform float _LineValue;
    //: param custom { "default": 0.93, "label": "线范围 LineRange", "min": -1.0, "max": 1.0, "group": "C Hair" }
    uniform float _LineRange;
    //: param custom { "default": 0.3, "label": "线强度 LineIntensity", "min": 0.0, "max": 1.0, "group": "C Hair" }
    uniform float _LineIntensity;
    //: param custom { "default": 1.7, "label": "线饱和度 LineSaturation", "min": 0.0, "max": 10.0, "group": "C Hair" }
    uniform float _LineSaturation;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "高度压暗 HairDarkenParams (x=offX y=darken z=offZ w=min)", "group": "C Hair" }
    uniform vec4 _HairDarkenParams;
    //: param custom { "default": 1.0, "label": "[H11] 皮肤高光深度边缘替代 HairDepthEdgeMask", "min": 0.0, "max": 1.0, "group": "C Hair" }
    uniform float f_HairDepthEdgeMask;
  //- endregion

  //- region Fur (Part 4)
    //: param custom { "default": 0.5, "label": "[H10] 壳层预览 FurShellIdx (0=底 1=外)", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float f_FurShellIdx;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "毛噪声 FurMap", "usage": "texture", "group": "D Fur" }
    uniform sampler2D _FurMap;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "FurMap_ST (各向同性: 仅 .x 用于双轴)", "group": "D Fur" }
    uniform vec4 _FurMap_ST;
    //: param custom { "default": 0.7, "label": "毛长 FurLengthIntensity (仅参与壳层公式)", "min": 0.001, "max": 6.0, "group": "D Fur" }
    uniform float _FurLengthIntensity;
    //: param custom { "default": 0.0, "label": "根部裁切 FurCutoffStart", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurCutoffStart;
    //: param custom { "default": 1.0, "label": "尖部裁切 FurCutoffEnd", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurCutoffEnd;
    //: param custom { "default": 1.0, "label": "根部AO FurAO", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurAO;
    //: param custom { "default": 0.4, "label": "边缘衰减 FurEdgeFade", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurEdgeFade;
    //: param custom { "default": 0.0, "label": "透光强度 FurTTIntensity", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurTTIntensity;
    //: param custom { "default": "", "default_color": [0.5,0.5,1.0,1.0], "label": "Fur Direction Map (RG=dir B=density A=length)", "usage": "texture", "group": "D Fur" }
    uniform sampler2D _FurDirMap;
    //: param custom { "default": 0.0, "label": "使用方向图 FurDirMapEnable", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurDirMapEnable;
    //: param custom { "default": 0.0, "label": "毛尖锐化 FurSharpen", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurSharpen;
    //: param custom { "default": 0.0, "label": "壳层噪声 FurNoise", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurNoise;
    //: param custom { "default": false, "label": "毛染色 _CHARACTER_FUR_DYE", "group": "D Fur" }
    uniform bool u_FurDyeEnable;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,1.0], "label": "染色贴图 FurDyeMap", "usage": "texture", "group": "D Fur" }
    uniform sampler2D _FurDyeMap;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "FurDyeMap_ST", "group": "D Fur" }
    uniform vec4 _FurDyeMap_ST;
    //: param custom { "default": 1.0, "label": "染色强度 FurDyeIntensity", "min": 0.0, "max": 1.0, "group": "D Fur" }
    uniform float _FurDyeIntensity;
  //- endregion

  //- region Fur 烬火 VFX (_CHARACTER_VFX_SPECIAL)
    //: param custom { "default": false, "label": "启用 Fur VFX _CHARACTER_VFX_SPECIAL", "group": "E Fur VFX" }
    uniform bool u_EnableCharacterVFX;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "VFX 颜色 (HDR)", "widget":"color", "group": "E Fur VFX" }
    uniform vec4 _VFXColor;
    //: param custom { "default": 1.0, "label": "VFX 颜色强度", "min": 1.0, "max": 100.0, "group": "E Fur VFX" }
    uniform float _VFXColorIntensity;
    //: param custom { "default": 1.0, "label": "VFX 颜色Alpha", "min": 0.0, "max": 10.0, "group": "E Fur VFX" }
    uniform float _VFXColorAlpha;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "VFX 主纹理 SpecialMainTex", "usage": "texture", "group": "E Fur VFX" }
    uniform sampler2D _VFXSpecialMainTex;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "VFXSpecialMainTex_ST", "group": "E Fur VFX" }
    uniform vec4 _VFXSpecialMainTex_ST;
    // 1.4.4 新增:VFX 主纹理取哪套 UV。0=UV1 1=UV2 2=屏幕空间。
    // [H12] Painter 这套着色只有 UV0,uv1=uv2=uv0,所以 0/1 之间的 lerp 是恒等;
    //       屏幕空间那档用 gl_FragCoord 真算(预览有意义)。
    //: param custom { "default": 0.0, "label": "VFX 主纹理 UV 组 (0/1=UV, 2=屏幕)", "min": 0.0, "max": 2.0, "group": "E Fur VFX" }
    uniform float _VFXMainUVSet;
    //: param custom { "default": 0.0, "label": "屏幕 UV 受相机距离影响 ScreenUVUseDepth", "min": 0.0, "max": 1.0, "group": "E Fur VFX" }
    uniform float _VFXScreenUVUseDepth;
    //: param custom { "default": 0.0, "label": "VFX 菲涅尔用法线贴图 FresnelUseNormalMap", "min": 0.0, "max": 1.0, "group": "E Fur VFX" }
    uniform float _VFXFresnelUseNormalMap;
    // [H17] 屏幕 UV 需要分辨率(参考取 _ScreenParams)。这版 Painter 的
    //       auto 参数表里没有可确认的 screen_size,不猜名字(猜错会整个
    //       shader 创建失败),做成可填的分辨率,数学与参考一致。
    //: param custom { "default": [1920.0, 1080.0], "label": "[H17] 屏幕分辨率 (VFX 屏幕 UV 用)", "group": "E Fur VFX" }
    uniform vec2 f_ScreenSize;
    //: param custom { "default": 0.0, "label": "主纹理R作Alpha UseVFXMainTexAsAlpha", "min": 0.0, "max": 1.0, "group": "E Fur VFX" }
    uniform float _UseVFXMainTexAsAlpha;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,0.0], "label": "VFX 混合纹理 SpecialBlendTex", "usage": "texture", "group": "E Fur VFX" }
    uniform sampler2D _VFXSpecialBlendTex;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "VFXSpecialBlendTex_ST", "group": "E Fur VFX" }
    uniform vec4 _VFXSpecialBlendTex_ST;
    //: param custom { "default": 1.0, "label": "混合纹理R扰动 BlendTexRForDisturb", "min": 0.0, "max": 1.0, "group": "E Fur VFX" }
    uniform float _VFXSpecialBlendTexRForDisturb;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "VFX 混合染色 BlendTint (HDR)", "widget":"color", "group": "E Fur VFX" }
    uniform vec4 _VFXBlendTint;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "VFX 滚动 SpecialParam (XY:Main ZW:Blend)", "group": "E Fur VFX" }
    uniform vec4 _VFXSpecialParam;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "VFX 菲涅尔色 (HDR)", "widget":"color", "group": "E Fur VFX" }
    uniform vec4 _VFXFresnelColor;
    //: param custom { "default": 0.0, "label": "菲涅尔偏置 FresnelBias", "min": -1.0, "max": 2.0, "group": "E Fur VFX" }
    uniform float _VFXFresnelBias;
    //: param custom { "default": 1.0, "label": "菲涅尔影响不透明度", "min": 0.0, "max": 1.0, "group": "E Fur VFX" }
    uniform float _VFXFresnelAffectOpacity;
    //: param custom { "default": 1.0, "label": "菲涅尔指数 FresnelPower", "min": 1.0, "max": 100.0, "group": "E Fur VFX" }
    uniform float _VFXFresnelPower;
    //: param custom { "default": 0.0, "label": "菲涅尔翻转 FresnelFlip", "min": 0.0, "max": 1.0, "group": "E Fur VFX" }
    uniform float _VFXFresnelFlip;
    //: param custom { "default": 0.0, "label": "溶解进度 DissolveScheduleOffset (1=隐藏)", "min": 0.0, "max": 1.0, "group": "E Fur VFX" }
    uniform float _SpecialDissolveScheduleOffset;
    //: param custom { "default": 0.0, "label": "[H12] VFX 时间 (替代 _Time.y)", "min": 0.0, "max": 100.0, "group": "E Fur VFX" }
    uniform float f_VFXTime;
  //- endregion

  //- region VFX Part (Part 6, HGRP_CharacterNPR_VFX_Fix)
    //: param custom { "default": 0.0, "label": "混合模式 BlendMode (0=Alpha 1=Additive)", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _BlendMode;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "TintColor (HDR)", "widget":"color", "group": "F VFX部位" }
    uniform vec4 _TintColor;
    //: param custom { "default": 1.0, "label": "Tint 强度", "min": 1.0, "max": 100.0, "group": "F VFX部位" }
    uniform float _TintColorIntensity;
    //: param custom { "default": 1.0, "label": "Tint Alpha", "min": 0.0, "max": 10.0, "group": "F VFX部位" }
    uniform float _TintColorAlpha;
    //: param custom { "default": 1.0, "label": "忽略后处理曝光 IgnorePostExposure", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _IgnorePostExposure;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "Main Tex", "usage": "texture", "group": "F VFX部位" }
    uniform sampler2D _VFXMainTex;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "MainTex_ST", "group": "F VFX部位" }
    uniform vec4 _VFXMainTex_ST;
    //: param custom { "default": 1.0, "label": "MainTex R作Alpha", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _UseMainTexAsAlpha;
    //: param custom { "default": 1.0, "label": "MainTex 受扰动", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _MainTexUseDisturb;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "MainTexUVSpeed (XY:Time)", "group": "F VFX部位" }
    uniform vec4 _MainTexUVSpeed;
    //: param custom { "default": 0.0, "label": "MainTexUVRotate (度)", "min": -180.0, "max": 180.0, "group": "F VFX部位" }
    uniform float _MainTexUVRotate;
    //: param custom { "default": false, "label": "使用 Mask _USE_MASK", "group": "F VFX部位" }
    uniform bool u_VFXUseMask;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "Mask Tex", "usage": "texture", "group": "F VFX部位" }
    uniform sampler2D _VFXMaskTex;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "MaskTex_ST", "group": "F VFX部位" }
    uniform vec4 _VFXMaskTex_ST;
    //: param custom { "default": 1.0, "label": "MaskTex R作Alpha", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _UseMaskTexAsAlpha;
    //: param custom { "default": 0.0, "label": "MaskTex 受扰动", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _MaskTexUseDisturb;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "MaskTexUVSpeed", "group": "F VFX部位" }
    uniform vec4 _MaskTexUVSpeed;
    //: param custom { "default": 0.0, "label": "MaskTexUVRotate (度)", "min": -180.0, "max": 180.0, "group": "F VFX部位" }
    uniform float _MaskTexUVRotate;
    //: param custom { "default": false, "label": "使用 Blend _USE_BLEND", "group": "F VFX部位" }
    uniform bool u_VFXUseBlend;
    //: param custom { "default": "", "default_color": [0.0,0.0,0.0,0.0], "label": "Blend Tex", "usage": "texture", "group": "F VFX部位" }
    uniform sampler2D _VFXBlendTex;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "BlendTex_ST", "group": "F VFX部位" }
    uniform vec4 _VFXBlendTex_ST;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "BlendTint (HDR)", "widget":"color", "group": "F VFX部位" }
    uniform vec4 _BlendTint;
    //: param custom { "default": 0.0, "label": "BlendTex 受扰动", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _BlendTexUseDisturb;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "BlendTexUVSpeed", "group": "F VFX部位" }
    uniform vec4 _BlendTexUVSpeed;
    //: param custom { "default": 0.0, "label": "BlendTexUVRotate (度)", "min": -180.0, "max": 180.0, "group": "F VFX部位" }
    uniform float _BlendTexUVRotate;
    //: param custom { "default": false, "label": "使用扰动 _USE_DISTURB", "group": "F VFX部位" }
    uniform bool u_VFXUseDisturb;
    //: param custom { "default": "", "default_color": [1.0,1.0,1.0,1.0], "label": "Disturb Tex 1", "usage": "texture", "group": "F VFX部位" }
    uniform sampler2D _VFXDisturbTex;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "DisturbTex_ST", "group": "F VFX部位" }
    uniform vec4 _VFXDisturbTex_ST;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "DisturbUVSpeed1", "group": "F VFX部位" }
    uniform vec4 _DisturbUVSpeed1;
    //: param custom { "default": 0.0, "label": "DisturbUVRotate1 (度)", "min": -180.0, "max": 180.0, "group": "F VFX部位" }
    uniform float _DisturbUVRotate1;
    //: param custom { "default": 0.0, "label": "双向扰动 Bi_Disturb", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _Bi_Disturb;
    //: param custom { "default": 0.0, "label": "扰动图为法线 DisturbTex1Normal", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _DisturbTex1Normal;
    //: param custom { "default": 0.0, "label": "扰动U强度 DisturbUIntensity1", "min": -2.0, "max": 2.0, "group": "F VFX部位" }
    uniform float _DisturbUIntensity1;
    //: param custom { "default": 0.0, "label": "扰动V强度 DisturbVIntensity1", "min": -2.0, "max": 2.0, "group": "F VFX部位" }
    uniform float _DisturbVIntensity1;
    //: param custom { "default": false, "label": "使用法线 _NORMAL_MAP", "group": "F VFX部位" }
    uniform bool u_VFXEnableNormalMap;
    //: param custom { "default": "", "default_color": [0.5,0.5,1.0,1.0], "label": "VFX Normal Map (DXT5nm布局)", "usage": "texture", "group": "F VFX部位" }
    uniform sampler2D _VFXNormalMap;
    //: param custom { "default": [1.0, 1.0, 0.0, 0.0], "label": "NormalMap_ST", "group": "F VFX部位" }
    uniform vec4 _VFXNormalMap_ST;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0], "label": "NormalMapUVSpeed", "group": "F VFX部位" }
    uniform vec4 _NormalMapUVSpeed;
    //: param custom { "default": 0.0, "label": "NormalMapUVRotate (度)", "min": -180.0, "max": 180.0, "group": "F VFX部位" }
    uniform float _NormalMapUVRotate;
    //: param custom { "default": 1.0, "label": "法线强度 NormalScale", "min": 0.0, "max": 3.0, "group": "F VFX部位" }
    uniform float _NormalScale;
    //: param custom { "default": 1.0, "label": "法线受扰动 NormalMapUseDisturb", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _NormalMapUseDisturb;
    //: param custom { "default": false, "label": "使用菲涅尔 _USE_FRESNEL", "group": "F VFX部位" }
    uniform bool u_VFXUseFresnel;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "FresnelColor (HDR)", "widget":"color", "group": "F VFX部位" }
    uniform vec4 _FresnelColor;
    //: param custom { "default": 0.0, "label": "FresnelBias", "min": -1.0, "max": 2.0, "group": "F VFX部位" }
    uniform float _FresnelBias;
    //: param custom { "default": 1.0, "label": "Fresnel影响不透明度", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _FresnelAffectOpacity;
    //: param custom { "default": 1.0, "label": "FresnelPower", "min": 1.0, "max": 10.0, "group": "F VFX部位" }
    uniform float _FresnelPower;
    //: param custom { "default": 0.001, "label": "FresnelFlip", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _FresnelFlip;
    //: param custom { "default": 0.0, "label": "近相机淡出 UseNearCameraFade", "min": 0.0, "max": 1.0, "group": "F VFX部位" }
    uniform float _UseNearCameraFade;
    //: param custom { "default": 0.001, "label": "Fade Start 1", "min": 0.001, "max": 3000.0, "group": "F VFX部位" }
    uniform float _NearCameraFadeDistanceStart;
    //: param custom { "default": 10.0, "label": "Fade End 1", "min": 0.001, "max": 3000.0, "group": "F VFX部位" }
    uniform float _NearCameraFadeDistanceEnd;
    //: param custom { "default": 100.0, "label": "Fade End 2", "min": 0.002, "max": 3000.0, "group": "F VFX部位" }
    uniform float _NearCameraFadeDistanceEnd2;
    //: param custom { "default": 120.0, "label": "Fade Start 2", "min": 0.001, "max": 3000.0, "group": "F VFX部位" }
    uniform float _NearCameraFadeDistanceStart2;
  //- endregion

  //- region OverlayShadow (Part 7)
    //: param custom { "default": 1.0, "label": "灰度作Alpha UseGrayAsAlpha", "min": 0.0, "max": 1.0, "group": "G OverlayShadow" }
    uniform float _UseGrayAsAlpha;
  //- endregion

  //- region 角色参数 CharacterParams
    //: param custom { "default": [0.0, 1.0, 0.7, 1.0],     "label": "CP0 (.y=diffuse .z=shadow .w=brightness)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams0;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0],     "label": "CP1 (.x=brightMix .y=shadowStr .z=shadowLerp .w=lightDirOverride)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams1;
    //: param custom { "default": [1.0, 1.0, 1.0, 0.0],     "label": "CP2 (ambient color, Standard/Hair/Fur/Eye)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams2;
    //: param custom { "default": [1.0, 1.0, 1.0, 0.0],     "label": "CP3 (ambient color, Face)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams3;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0],     "label": "CP4 (light color override, Face)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams4;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0],     "label": "CP5 (light color override, Standard/Hair/Fur/Eye)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams5;
    //: param custom { "default": [0.0, 1.0, 0.0, 0.0],     "label": "CP6 (ambient direction)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams6;
    //: param custom { "default": [0.15, 0.6, 1.0, 0.0],    "label": "CP7 (.x=offset .y=scale .z=bias)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams7;
    //: param custom { "default": [0.0, 0.0, 0.0, 1.0],     "label": "CP8 (skin spec rgb + .w=intensity)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams8;
    //: param custom { "default": [0.0, 1.0, 0.0, 0.4],     "label": "CP9 (skin spec .xy=dir .z=tint .w=width)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams9;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0],     "label": "CP10 (hair height darken)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams10;
    //: param custom { "default": [-0.433, 0.5, 0.75, 0.0], "label": "CP11 (light dir override xyz + .w=rampBias)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams11;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0],     "label": "CP12 (.x=rampOffset .y=lightColOverride .z=shadowGate .w=exposureBlend)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams12;
    //: param custom { "default": [0.0, 0.0, 0.0, 1.0],     "label": "CP13 (.xyz=eye direct .w=GGX toggle)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams13;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0],     "label": "CP14 (face 二级高光 rgb + .w=intensity)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams14;
    //: param custom { "default": [0.0, 0.0, 0.0, 0.0],     "label": "CP15 (.z=SDF 二级阈值)", "group": "H 角色参数" }
    uniform vec4 _CharacterParams15;
    //: param custom { "default": [1.67, 1.5, 1.0, 0.0],    "label": "EnvGlobalParams0", "group": "H 角色参数" }
    uniform vec4 _EnvironmentGlobalParams0;
    //: param custom { "default": [1.0, 0.0, 0.0, 0.0],     "label": "ExposureParams (.x=曝光)", "group": "H 角色参数" }
    uniform vec4 _ExposureParams;
  //- endregion

  //- region VFX 颜色调整
    //: param custom { "default": 0.0, "label": "启用 VFX 颜色调整", "min": 0.0, "max": 1.0, "group": "I VFX颜色调整" }
    uniform float _EnableVFXColorAdjustment;
    //: param custom { "default": 1.0, "label": "亮度 Brightness", "min": 0.5, "max": 1.5, "group": "I VFX颜色调整" }
    uniform float _ColorAdjustmentBrightness;
    //: param custom { "default": 1.0, "label": "饱和度 Saturation", "min": 0.0, "max": 2.0, "group": "I VFX颜色调整" }
    uniform float _ColorAdjustmentSaturation;
    //: param custom { "default": 1.0, "label": "对比度 Contrast", "min": 0.0, "max": 2.0, "group": "I VFX颜色调整" }
    uniform float _ColorAdjustmentContrast;
    //: param custom { "default": [1.0, 1.0, 1.0, 0.0], "label": "颜色混合 ColorBlend", "widget":"color", "group": "I VFX颜色调整" }
    uniform vec4 _ColorAdjustmentColorBlend;
    //: param custom { "default": 0.35, "label": "边缘光宽度 RimWidth", "min": 0.0, "max": 1.0, "group": "I VFX颜色调整" }
    uniform float _ColorAdjustmentRimWidth;
    //: param custom { "default": 4.0, "label": "边缘光强度 RimIntensity", "min": 0.0, "max": 10.0, "group": "I VFX颜色调整" }
    uniform float _ColorAdjustmentRimIntensity;
    //: param custom { "default": [1.0, 1.0, 1.0, 1.0], "label": "边缘光颜色 RimColor", "widget":"color", "group": "I VFX颜色调整" }
    uniform vec4 _ColorAdjustmentRimColor;
  //- endregion
//- }

//----------------------------------------------------------------------region SP 函数库导入
//- {
  import lib-pbr.glsl
  import lib-bent-normal.glsl
  import lib-emissive.glsl
  import lib-pom.glsl
  import lib-sss.glsl
  import lib-utils.glsl
  import lib-sparse.glsl
//- }

//----------------------------------------------------------------------region 渲染状态
//- {
  //: state cull_face off
  //: state blend over
//- }

//----------------------------------------------------------------------region 引擎通道纹理
//- {
  //: param auto channel_basecolor
  uniform SamplerSparse basecolor_tex;
  //: param auto channel_roughness
  uniform SamplerSparse roughness_tex;
  //: param auto channel_metallic
  uniform SamplerSparse metallic_tex;
  //: param auto channel_specularlevel
  uniform SamplerSparse specularlevel_tex;
  //: param auto channel_opacity
  uniform SamplerSparse opacity_tex;
  //: param auto channel_height
  uniform SamplerSparse height_tex;   // Standard 视差高度 (原 _ParallaxTex 迁来); 经 .tex 按 _ParallaxTex_ST 采样
  // emissive_tex 由 lib-emissive.glsl 提供

  //- user1 = Standard: ClearCoat Mask (.r, 可绘制)。
  //- 注: Face/Fur 的 RGB 数据图 (SDFMask/SDFLightmap/Highlight/Emotion/FurDir/FurDye) 无法做成
  //-     字节等价的 User 通道 —— SP 对"颜色(RGB)通道"强制色彩管理 (sRGB→linear), 会篡改线性的
  //-     SDF/数据值 (实测: SDF 变暗、鼻侧多出阴影), 且 Python/JS API 无法改源色彩空间。故这些回退为
  //-     sampler2D 参数: 参数走原始采样、零色彩管理 = 字节等价, 且参数自带 label 在 shader 面板可辨识。
  //: param auto channel_user1
  uniform SamplerSparse slot_user1_tex;

  //- user2 = Standard: Emission 呼吸遮罩 (_EmissionMap.a, 可绘制)。
  //- 参考的 Emission 呼吸按 _EmissionMap 的 ALPHA 逐像素选"哪里会呼吸"
  //- (_3797 = 1 + emis.a * (scale - 1)),而 Painter 的 emissive 通道只有 RGB,
  //- 所以这一位单独进 user2 —— 与 ClearCoat mask 进 user1 是同一套做法。
  //: param auto channel_user2
  uniform SamplerSparse slot_user2_tex;
//- }

//----------------------------------------------------------------------region 引擎 auto 属性
//- {
  //: param auto main_light
  uniform vec4 light_main;
  //: param auto facing
  uniform int uniform_facing;
  //: param auto camera_view_matrix
  uniform mat4 uniform_camera_view_matrix;
  //: param auto environment_max_lod
  uniform float environment_max_lod;
//- }

//----------------------------------------------------------------------region 类型宏 + HLSL→GLSL 兼容层
//- {
  #define float2 vec2
  #define float3 vec3
  #define float4 vec4
  #define half  float
  #define half2 vec2
  #define half3 vec3
  #define half4 vec4

  // HLSL 内置函数补齐
  float rsqrt(float x) { return 1.0 / sqrt(x); }
  #define frac fract
  #define ddx dFdx
  #define ddy dFdy

  half  saturate(half v)  { return max(0.0, min(1.0, v)); }
  half2 saturate(half2 v) { return max(half2(0.0), min(half2(1.0), v)); }
  half3 saturate(half3 v) { return max(half3(0.0), min(half3(1.0), v)); }
  half4 saturate(half4 v) { return max(half4(0.0), min(half4(1.0), v)); }

  half  lerp(half a, half b, half t)    { return (1.0 - t) * a + t * b; }
  half2 lerp(half2 a, half2 b, half t)  { return (1.0 - t) * a + t * b; }
  half3 lerp(half3 a, half3 b, half t)  { return (1.0 - t) * a + t * b; }
  half4 lerp(half4 a, half4 b, half t)  { return (1.0 - t) * a + t * b; }
  half3 lerp(half3 a, half3 b, half3 t) {
      return half3((1.0 - t.x) * a.x + t.x * b.x,
                   (1.0 - t.y) * a.y + t.y * b.y,
                   (1.0 - t.z) * a.z + t.z * b.z);
  }

  float  mad(float a, float b, float c)   { return a * b + c; }
  float2 mad(float2 a, float2 b, float2 c){ return a * b + c; }
  float3 mad(float3 a, float3 b, float3 c){ return a * b + c; }

  // Unity 纹理采样宏 → GLSL (sampler_* 参数被吞掉; cube → SP 环境)
  #define _DiffRampMap _RampMap
  #define SAMPLE_TEXTURE2D(tex, samp, uv)              texture(tex, uv)
  #define SAMPLE_TEXTURE2D_LOD(tex, samp, uv, lod)     textureLod(tex, uv, float(lod))
  #define SAMPLE_TEXTURECUBE_LOD(tex, samp, dir, lod)  envSampleLOD(dir, float(lod))
//- }

//----------------------------------------------------------------------region 共享常量 + 共享函数
//- {
  const float3 LUM = float3(0.2126729, 0.7152, 0.07217500);
  const float NEAR_ZERO_Y = 6.103515625e-05; // asfloat(947912704u)

  float LinearToSRGB_Custom(float c) {
      return (c <= 0.0031308) ? (c * 12.92)
          : (1.055 * pow(abs(c), 0.41666666) - 0.055);
  }

  // ---- Unity 硬件 sRGB 采样解码补偿 ----
  // 这些贴图资产在 Unity 端 .meta sRGBTexture=1 (实测全角色普查):
  //   _ShadowLutTex _EmotionMap _MatcapTex _ParallaxTex _FurDirMap _FurDyeMap
  //   _VFXMainTex _VFXMaskTex _VFXBlendTex _VFXDisturbTex _VFXSpecialMainTex _VFXSpecialBlendTex
  // Unity 采样器自动 sRGB→Linear; SP 自定义贴图参数为裸采样, 必须手动补同款解码
  // (alpha 通道不解码, 与硬件行为一致)。注: 解码在双线性过滤之后, 与硬件
  // "先解码后过滤"在 texel 间插值处有极小偏差, LUT 取 texel 中心时无差。
  float SRGBToLinear_Custom(float c) {
      return (c <= 0.04045) ? (c / 12.92)
          : pow(abs((c + 0.055) / 1.055), 2.4);
  }
  float3 SRGBToLinear3(float3 c) {
      return float3(SRGBToLinear_Custom(c.r), SRGBToLinear_Custom(c.g), SRGBToLinear_Custom(c.b));
  }
  float4 SampleSRGBTex(sampler2D tex, float2 uv) {
      float4 s = texture(tex, uv);
      return float4(SRGBToLinear3(s.rgb), s.a);
  }

  // ---- 主光方向旋转 (NPR_Uber.glsl 同款 YXZ 欧拉) ----
  mat3 efRotateX(float r) { float c = cos(r), s = sin(r); return mat3(1,0,0, 0,c,s, 0,-s,c); }
  mat3 efRotateY(float r) { float c = cos(r), s = sin(r); return mat3(c,0,-s, 0,1,0, s,0,c); }
  mat3 efRotateZ(float r) { float c = cos(r), s = sin(r); return mat3(c,s,0, -s,c,0, 0,0,1); }
  float3 GetMainLightDir() {
      mat3 rot = efRotateY(radians(float(i_LightRotY))) * efRotateX(radians(float(i_LightRotX))) * efRotateZ(radians(float(i_LightRotZ)));
      return normalize(rot * light_main.xyz);
  }

  // ---- 共享视角/相机量 ----
  //  V       : Unity 的 ortho-aware viewDir; SP 视口透视 → unity_OrthoParams.w=0 路径
  //  camFwd  : UNITY_MATRIX_I_V 第三列 (相机背向, Endfield 约定, 与 Unity 端同号)
  float3 GetCamFwd() {
      return normalize((inverse(uniform_camera_view_matrix) * float4(0.0, 0.0, 1.0, 0.0)).xyz);
  }

  // ---- Ramp 采样: 在着色器里复现 CLAMP 寻址 ----
  // [H10] ramp/LUT 是一维查表, u 必须按 CLAMP 取址, 但两件事都不成立:
  //   1. rampInput = sdfNdotL*0.5 + 0.5 = |smoothstep + halfCeil| ∈ [0, 1.5], 会越界;
  //   2. SP 给导入资源的取样器是 REPEAT, 而参数声明里的 addressing 键无效
  //      (实测加上它之后 u=0.0 仍读出 0.5, 而不是 texel[0] 的 0.0)。
  // 线性过滤下 u=0.0 与 u=1.0 都落在首尾接缝上, 取到 (texel[N-1] + texel[0])/2。
  // 对这张 ramp 就是 (1.000 + 0.000)/2 = 0.500 —— 真机 textureSize 探针确认贴图
  // 已正确绑定且尺寸正确, 读到的 0.50001 正是这个接缝均值, 不是贴图内容。
  // 这一条直接吃掉阴影: 全影时 rampInput 精确为 0, 于是 rampA 取到 0.5 而非 0,
  // 而 rampA 经 minShadow 正是本着色器的阴影遮罩。
  // 夹到半像素内缩即可精确等价于 CLAMP, 与实际寻址模式无关。
  //
  // ⚠ 注释里绝不能出现 SP 的指令前缀字面量 (两个斜杠加冒号): 解析器扫描行内任意
  //   位置, 会把该行当成参数声明 -> "Param type isn't valid", 整个着色器建不起来。
  float4 SampleRamp(float u) {
      float width = float(textureSize(_RampMap, 0).x);
      float halfTexel = 0.5 / max(width, 1.0);
      return textureLod(_RampMap, float2(clamp(u, halfTexel, 1.0 - halfTexel), 0.5), 0.0);
  }

  // 关 ramp 时各部位的程序化 ramp 都以这条三次曲线收尾 (源逐处均为 x*x*(3-2x))
  float RampSmooth(float t) {
      return (t * t) * (3.0 - 2.0 * t);
  }

  // ---- Unity uv (含 _BaseMap_ST) ----
  float2 GetBaseUV(V2F inputs) {
      return inputs.sparse_coord.tex_coord * _BaseMap_ST.xy + _BaseMap_ST.zw;
  }

  // ---- Shadow LUT 采样 (Skin/Cloth/Hair/Eye 共享公式, 逐行同源) ----
  float3 SampleShadowLutColor(float3 albedo) {
      float sR = saturate(LinearToSRGB_Custom(albedo.r));
      float sG = saturate(LinearToSRGB_Custom(albedo.g));
      float sB = saturate(LinearToSRGB_Custom(albedo.b));
      float bSlice = floor(sB * 31.0);
      float lutU = bSlice * 0.03125 + sR * 0.0302734375 + 0.00048828125;
      float lutV = sG * 0.96875 + 0.015625;
      // LUT 资产 sRGBTexture=1 → 补硬件解码 (这是"开 Shadow LUT 全身泛白"的根因)
      float3 lut0 = SRGBToLinear3(textureLod(_ShadowLutTex, float2(lutU, lutV), 0.0).rgb);
      float3 lut1 = SRGBToLinear3(textureLod(_ShadowLutTex, float2(lutU + 0.03125, lutV), 0.0).rgb);
      float bFrac = sB * 31.0 - bSlice;
      return lerp(lut0, lut1, bFrac);
  }

  // [H21] 描边 albedo —— 参考 Pass1 CharacterOutline 的 _311.._352 逐字:
  //   ob   = _BaseMap.rgb * _BaseColor.rgb * _OutlineColorBrightness
  //   lum  = dot(ob, LUM)
  //   out  = _OutlineTintEnable ? _OutlineTintColor.rgb
  //                             : _OutlineColorSaturation * (ob - lum) + lum
  // 与 ComputeShadowColorBrightSat 同构(参考自己也是同一套亮度/饱和重映射)。
  float3 ComputeOutlineAlbedo(float3 baseTimesColor) {
      float3 ob = baseTimesColor * _OutlineColorBrightness;   // _311.._313 * _318
      float oLum = dot(ob, LUM);                              // _323
      return _OutlineTintEnable ? _OutlineTintColor.rgb
                                : (_OutlineColorSaturation * (ob - oLum) + oLum);
  }

  // 亮度/饱和度阴影色 (LUT 关闭分支, Cloth/Face/Hair/Fur/Eye 全部同一公式)
  float3 ComputeShadowColorBrightSat(float3 albedo) {
      float3 shadBright = albedo * _ShadowColorBrightness;
      float shadLum = dot(shadBright, LUM);
      return _ShadowColorSaturation * (shadBright - shadLum) + shadLum;
  }

  // Environment BRDF rational approximation (HGRP Cloth/Fur 同一份, decompiled 2320-2328)
  void ComputeEnvBRDF(float NdotV, float roughSq, out float dfgX, out float dfgY) {
      float NdotV2 = NdotV * NdotV;
      float NdotV3 = NdotV * NdotV2;
      float roughSq6 = roughSq * roughSq * roughSq;

      float2 numX = float2(
          dot(float2(3.32707, 1.0), float2(NdotV, 0.0365463)),
          dot(float2(-9.04756, 1.0), float2(NdotV, 9.0632))
      );
      float3 denX = float3(
          dot(float3(3.59685, -1.36772, 1.0), float3(NdotV2, NdotV3, 1.0)),
          dot(float3(-16.3174, 1.0, 9.22949), float3(NdotV2, 9.04401, NdotV3)),
          dot(float3(1.0, 19.7886, -20.2123), float3(5.56589, NdotV2, NdotV3))
      );
      dfgX = dot(numX, float2(1.0, roughSq)) / dot(denX, float3(1.0, roughSq, roughSq6));

      float2 numY = float2(
          dot(float2(-1.28514, 1.0), float2(NdotV, 0.99044)),
          dot(float2(1.0, -0.755907), float2(1.29678, NdotV))
      );
      float3 denY = float3(
          dot(float3(2.92338, 59.4188, 1.0), float3(NdotV, NdotV3, 1.0)),
          dot(float3(1.0, -27.0302, 222.592), float3(20.3225, NdotV, NdotV3)),
          dot(float3(626.13, 316.627, 1.0), float3(NdotV, NdotV3, 121.563))
      );
      dfgY = dot(numY, float2(1.0, roughSq)) / dot(denY, float3(1.0, roughSq, roughSq6));
  }

  // ---- RMOS 读取 ([H1]: Unity _MetallicGlossMap RGBA=Metal/Spec/Shadow/Smooth → SP 通道) ----
  void SampleRMOS(V2F inputs, out float metallic, out float specScale, out float shadowMask, out float smoothness) {
      if (u_UseMetallicGlossMap) {
          metallic   = getMetallic(metallic_tex, inputs.sparse_coord);            // .r
          specScale  = getSpecularLevel(specularlevel_tex, inputs.sparse_coord);  // .g
          shadowMask = getAO(inputs.sparse_coord, true, use_bent_normal);         // .b → AO 通道 [H1]
          smoothness = 1.0 - getRoughness(roughness_tex, inputs.sparse_coord);    // .a = 1 - roughness
      } else {
          metallic   = _Metallic;
          specScale  = _Specular;
          shadowMask = 1.0;
          smoothness = _Smoothness;
      }
  }

  // ---- 法线 ([H8]: SP 法线通道 TS 法线 + Unity 的 TBN 组装公式, 逐行同源) ----
  float3 SampleBumpNormal(V2F inputs, float3 normalWS_raw, float4 tangentWS, float faceSign, float bumpScale) {
      if (u_UseBumpMap) {
          float3 tsN = getTSNormal(inputs.sparse_coord); // [-1,1]
          // Z 必须由"未乘 BumpScale"的 XY 重建, 之后才把 scale 只乘到 XY 上 —— 源码
          // characternpr_skin b113 逐指令为证:
          //     _462 = R*A*2-1 ; _464 = G*2-1                  // 未缩放
          //     _470 = max(sqrt(1 - min(dot(xy,xy),1)), 1e-16)  // ← 用未缩放 XY
          //     _474 = _462*_BumpScale ; _475 = _464*_BumpScale // scale 只作用于 XY
          // hair/fur/VFX 全部同一约定。先缩放会让 BumpScale>1 时 1-scaled² 被夹到 0,
          // Z 塌成 ~0 → 法线整片躺平; <1 时 Z 偏大 → 法线被压扁。==1 时两者恰好相同。
          float nrmZ = max(sqrt(1.0 - min(tsN.x*tsN.x + tsN.y*tsN.y, 1.0)), 1e-16);
          float nrmX = tsN.x * bumpScale;
          float nrmY = tsN.y * bumpScale;
          float3 nrmWS = normalize(normalWS_raw);
          float3 tanWS = normalize(tangentWS.xyz);
          float3 bitWS = cross(nrmWS, tanWS) * tangentWS.w;
          return faceSign * normalize(nrmX * tanWS + nrmY * bitWS + nrmZ * nrmWS);
      }
      return faceSign * normalize(normalWS_raw);
  }

  // 切线空间版本:侵蚀(_CHARACTER_EROSION)要在**切线空间**里做 RNM 混合,
  // 拿到世界空间就没法混了。数学与上面完全同源,只是不做 TBN 变换。
  float3 SampleBumpNormalTS(V2F inputs, float bumpScale) {
      if (u_UseBumpMap) {
          float3 tsN = getTSNormal(inputs.sparse_coord);
          float nrmZ = max(sqrt(1.0 - min(tsN.x*tsN.x + tsN.y*tsN.y, 1.0)), 1e-16);
          return float3(tsN.x * bumpScale, tsN.y * bumpScale, nrmZ);
      }
      return float3(0.0, 0.0, 1.0);
  }

  float3 TangentToWorld(float3 tsN, float3 normalWS_raw, float4 tangentWS, float faceSign) {
      float3 nrmWS = normalize(normalWS_raw);
      float3 tanWS = normalize(tangentWS.xyz);
      float3 bitWS = cross(nrmWS, tanWS) * tangentWS.w;
      return faceSign * normalize(tsN.x * tanWS + tsN.y * bitWS + tsN.z * nrmWS);
  }
//- }

//----------------------------------------------------------------------region Part 0 Standard — HGRP_CharacterNPR_Fix.shader computeNPRLighting 逐行移植
//- {
  // 与旧版 EndField_Uber 相同的逐行移植, 差异: ShadowLUT/SpecRamp/ClearCoat/SilkStockings/Parallax
  // 由 #ifdef 改为运行时 bool (数学逐位一致); 变量按 GLSL 作用域规则做了无副作用的提升声明。
  float3 shadeStandard(V2F inputs, float3 positionWS, float3 normalWS_raw, float4 tangentWS, float faceSign, float3 albedo, float baseAlpha, out float3 shadowColorOut) {
      float2 uv = GetBaseUV(inputs);
      // ---- Object-to-World origin ([H4]) ----
      float originX = 0.0;
      float originZ = 0.0;

      // ---- View direction ----
      float3 toCam = camera_pos - positionWS;
      float3 V = normalize(toCam);

      // ---- MetallicGlossMap ([H1]) ----
      float metallic, specScale, shadowMask, smoothness;
      SampleRMOS(inputs, metallic, specScale, shadowMask, smoothness);
      float roughnessRaw = 1.0 - smoothness;

      // ---- ExtraAlphaMask 的 Root/Depth 染色 (参考 _391.._393) ----
      // albedo *= lerp(RootTint, 1, mask.g) * lerp(DepthTint, 1, mask.b)
      if (u_ExtraAlphaMask) {
          float4 extraMask = texture(_ExtraAlphaMask, uv);                     // _349
          albedo *= mad(float3(extraMask.g), 1.0 - _ExtraRootTintColor.rgb, _ExtraRootTintColor.rgb)
                  * mad(float3(extraMask.b), 1.0 - _ExtraDepthTintColor.rgb, _ExtraDepthTintColor.rgb);
      }

      // ---- CustomizeAvatar 换装染色 (_CUSTOMIZE_AVATAR) ----
      // 参考 Sub0_Pass0_Fragment_b683 的 _362.._379:BaseMap 的 RGB 当遮罩用,
      // 反照率整个由三个颜色重建 —— 必须在阴影色推导之前做完(参考的
      // _397.._399 就是拿重建后的 _377.._379 算的)。
      if (u_CustomizeAvatar) {
          float3 customTint = lerp(_CustomizeAddTintColor.rgb, _CustomizeBaseTintColor.rgb,
                                   albedo.g);                                  // _362.._364
          albedo = albedo.r * lerp(customTint, _CustomizeBaseColor.rgb, albedo.b);  // _377.._379
      }

      // ---- SilkStockings 状态 (_SILK_STOCKINGS) ----
      // 参考: Sub0_Pass0_Fragment_b587 (ON) vs b503 (OFF), 逐条对应
      //   _563  湿润度 -> f_SilkWetness [H14]
      //   _949  高光强度 = lerp(MinAtMinWetness, 1, wet) * SpecularInt
      //   _1267 各向异性方向  _1268 高光强度  _1269 粗糙度  _1270 透肉覆盖
      float silk_anisoDir = 0.0;
      float silk_specInt = 0.0;
      float silk_coverage = 0.0;
      float3 silk_tint = float3(1.0);
      if (u_SilkStockings) {
          // _DisableRainEffectOnMaterial 门控整条浸润链路(参考 _775 的判定)
          float wet = (_DisableRainEffectOnMaterial > 0.99) ? 0.0
                    : clamp(f_SilkWetness, 0.0, 1.0);
          float alphaProduct = baseAlpha * _BaseColor.a;              // _351
          float specIntBase = mad(wet, 1.0 - _SilkStockingsSpecularMinAtMinWetness,
                                  _SilkStockingsSpecularMinAtMinWetness)
                              * _SilkStockingsSpecularInt;            // _949
          if (_SilkStockingsAdvance) {
              // R 各向异性强度 / G 锐利度 / B 湿身光滑度 / A 透肉度
              float4 sm = texture(_SilkStockingsMask, uv);            // _1105
              silk_anisoDir = clamp(mad(sm.y, 2.0, -1.0), -0.95, 0.95);
              silk_specInt = specIntBase * sm.x;
              roughnessRaw = mad(wet, (smoothness - 1.0) + (1.0 - sm.z), roughnessRaw);
              silk_coverage = clamp(mad(wet, mad(-baseAlpha, _BaseColor.a, sm.w), alphaProduct)
                                    + 1.0 - _SilkStockingsColor.a, 0.0, 1.0);
          } else {
              silk_anisoDir = -mad(clamp(alphaProduct * 0.5, 0.0, 1.0),
                                   0.5 - _SilkStockingsAnisoDirection,
                                   _SilkStockingsAnisoDirection);
              silk_specInt = specIntBase;
              silk_coverage = clamp(mad(baseAlpha, _BaseColor.a, 1.0)
                                    - _SilkStockingsColor.a, 0.0, 1.0);
          }
          silk_tint = lerp(_SilkStockingsDryColor.rgb, _SilkStockingsWetColor.rgb, wet);

      }

      // ---- EnemyHitFlash 受击闪白 (_ENEMY_HIT_FLASH) ----
      // 参考 Sub0_Pass0_Fragment_b475(ON) vs b373(OFF):
      //   _2536 闪白专用法线:用 NormalScale 重建(与 _BumpScale 无关的另一份)
      //   _2581 中心 = lerp(默认主角位置, BrightCenter.xyz, BrightCenter.w)
      //   _2598 t = saturate((|pos-center| - Outer) / (Inner - Outer))
      //   _2601 scan = smoothstep(t)
      //   _2622 albedo += BrightColorAdjust * BrightColor.rgb * scan
      //   _2650 fres = 1 - saturate(dot(V, faceSign*Nflash) + FresnelBias)
      //   _3528 w = lerp(1, fres, FresnelAffectOpacity) * saturate(BrightColor.a * scan)
      //   emission += w * lerp(albedo, FresnelColor.rgb*FresnelColorAdjust,
      //                        FresnelColor.a * fres) * 曝光 [H15]
      float hitFlashWeight = 0.0;
      float3 hitFlashEmissive = float3(0.0);
      if (u_EnemyHitFlash) {
          float3 flashN = normalWS_raw;
          if (u_UseBumpMap) {
              flashN = SampleBumpNormal(inputs, normalWS_raw, tangentWS, faceSign,
                                        _EnemyHitFlashNormalScale);
          } else {
              flashN = normalize(normalWS_raw);
          }
          // [H4] Painter 的模型即世界,没有"默认主角位置"这个引擎量 —— w=0 时退化
          // 为世界原点,与参考里 VFXParams0 未设置时同值。
          float3 flashCenter = _EnemyHitFlashBrightCenter.xyz * _EnemyHitFlashBrightCenter.w;
          float flashDist = length(positionWS - flashCenter);
          float flashT = clamp((flashDist - _EnemyHitFlashOuterRadius)
                               / (_EnemyHitFlashInnerRadius - _EnemyHitFlashOuterRadius),
                               0.0, 1.0);
          float flashScan = (flashT * flashT) * mad(flashT, -2.0, 3.0);          // _2601
          albedo += (_EnemyHitFlashBrightColorAdjust * flashScan) * _EnemyHitFlashBrightColor.rgb;
          float flashFres = 1.0 - clamp(dot(V, faceSign * flashN)
                                        + _EnemyHitFlashFresnelBias, 0.0, 1.0);  // _2650
          hitFlashWeight = mad(flashFres, _EnemyHitFlashFresnelAffectOpacity,
                               1.0 - _EnemyHitFlashFresnelAffectOpacity)
                           * clamp(_EnemyHitFlashBrightColor.a * flashScan, 0.0, 1.0);  // _3528
          hitFlashEmissive = lerp(albedo,
                                  _EnemyHitFlashFresnelColor.rgb * _EnemyHitFlashFresnelColorAdjust,
                                  _EnemyHitFlashFresnelColor.a * flashFres);      // _3500
      }

      // ---- StylizedFresnel (_STYLIZED_FRESNEL) ----
      // 参考 Sub0_Pass0_Fragment_b623(ON) vs b543(OFF), _422/_463..465/_3507:
      //   noise = tex(_NoiseMap, (uv + speed*time) * ST.xy + ST.zw).r
      //   fres  = saturate(pow(clamp(1 - dot(V, Ngeom), 1e-4, 1), Pow) * Amount)
      //   mask  = saturate((noise - 0.5) * Contrast + 0.5) * fres
      //   albedo    = lerp(albedo, Color.rgb, mask)
      //   emission += mask * Color.a * Color.rgb * alphaPremul
      // 注意 dot 用的是几何法线 (_394 = TEXCOORD_2),不是法线贴图后的 N。
      float stylizedFresnelMask = 0.0;
      if (u_StylizedFresnel) {
          float2 sfUV = (uv + _StylizedFresnelNoiseSpeed * f_VFXTime)
                        * _StylizedFresnelNoiseMap_ST.xy + _StylizedFresnelNoiseMap_ST.zw;
          float sfNoise = texture(_StylizedFresnelNoiseMap, sfUV).r;                 // _380.x
          float3 Ngeom = normalize(normalWS_raw);                                    // _394
          float sfFres = clamp(exp2(log2(clamp(1.0 - dot(V, Ngeom), 1e-4, 1.0)) * _StylizedFresnelPow)
                               * _StylizedFresnelAmount, 0.0, 1.0);
          stylizedFresnelMask = clamp(mad(sfNoise - 0.5, _StylizedNoiseContrast, 0.5), 0.0, 1.0) * sfFres;
          albedo = lerp(albedo, _StylizedFresnelColor.rgb, stylizedFresnelMask);     // _463.._465
      }

      // ---- Shadow color ----
      float3 shadowColor;
      if (u_UseShadowLut) {
          shadowColor = SampleShadowLutColor(albedo);
      } else {
          shadowColor = ComputeShadowColorBrightSat(albedo);
      }

      // ---- Normal map ----
      float3 N = SampleBumpNormal(inputs, normalWS_raw, tangentWS, faceSign, _BumpScale);

      // ---- CharacterDissolve 溶解 (VFX_CHARACTER_DISSOLVE) ----
      // _2642 = _UseCutOff*(CutOffPosY - dot(pos, CutOffDir))
      //       + _UseDissolve*(noise.r - (progress*2.02 - 1.01))
      // 低于阈值直接 discard(_2646),边缘按 EdgeSharp 出自发光(_3805)。
      float dissolveEdgeEmis = 0.0;
      if (u_CharacterDissolve) {
          float2 dUV = uv;
          if (_DissolveUseViewUV) {
              float3 vpos = mat3(uniform_camera_view_matrix) * positionWS;
              dUV = vpos.xy;
          }
          dUV = dUV * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
          float dNoise = texture(_DissolveTex, dUV).r;
          float dThreshold = mad(_DissolveScheduleOffset, 2.02, -1.01);        // [H16]
          float dAmount = (_UseCutOff
                           ? (_CutOffPosY - dot(positionWS, _CutOffDirection.xyz)) : 0.0)
                        + (_UseDissolve ? (dNoise - dThreshold) : 0.0);        // _2642
          if (clamp(dAmount * _DissolveEdgeSharp, 0.0, 1.0) - 0.01 < 0.0) {
              discard;                                                          // _2646
          }
          dissolveEdgeEmis = clamp((_DissolveEmissiveEdge - dAmount) * _DissolveEdgeSharp,
                                   0.0, 1.0);                                   // _3805
      }

      // ---- Puppet 傀儡 (_PUPPET / _PUPPET_PROCEDURAL_DCURVE) ----
      // 参考 Sub0_Pass0_Fragment_b611(_PUPPET)与 b1323(DCurve)。两条上色路径
      // 共用同一个区域遮罩 _426/_479;关掉区域遮罩时遮罩退回 RMOS.g。
      if (u_Puppet || u_PuppetProceduralDCurve) {
          float pTop = _PuppetMaskSmooth + _PuppetMaskLocationTop;               // _399
          float pDown = _PuppetMaskSmooth - _PuppetMaskLocationDown;             // _402
          float tTopP = clamp((uv.y - pTop)
                              / ((_PuppetMaskLocationTop - _PuppetMaskSmooth) - pTop), 0.0, 1.0);
          float tDownP = clamp((pDown + uv.y)
                               / (pDown + (_PuppetMaskSmooth + _PuppetMaskLocationDown)), 0.0, 1.0);
          float pMask = _PuppetUV2AreaMask
                      ? ((tDownP * tDownP) * mad(tDownP, -2.0, 3.0))
                        * ((tTopP * tTopP) * mad(tTopP, -2.0, 3.0))
                      : specScale;                                               // _426 / _479

          float3 pCol;
          if (u_PuppetProceduralDCurve) {
              // 7 段 cos 域扭曲(_507.._533),再取 0.1/|sin| 的脊线(_551)
              float t = f_VFXTime;
              float u0 = mad(_PuppetPDCurveUVScaleSpeed.z, t, uv.x) * _PuppetPDCurveUVScaleSpeed.x;
              float v0 = mad(_PuppetPDCurveUVScaleSpeed.w, t, uv.y) * _PuppetPDCurveUVScaleSpeed.y;
              float d = t * _PuppetPDCurveDistortSpeed;
              float x1 = mad(cos(mad(v0, 2.5, d)), 0.6, u0);
              float y1 = mad(cos(mad(x1, 1.5, d)), 0.6, v0);
              float x2 = mad(cos(mad(y1, 5.0, d)), 0.3, x1);
              float y2 = mad(cos(mad(x2, 3.0, d)), 0.3, y1);
              float x3 = mad(cos(mad(y2, 7.5, d)), 0.2, x2);
              float y3 = mad(cos(mad(x3, 4.5, d)), 0.2, y2);
              float x4 = mad(cos(mad(y3, 10.0, d)), 0.15, x3);
              float ridge = min(0.1 / abs(sin(mad(_PuppetPDCurveDistortPeriodSpeed, t, -x4)
                                               - mad(cos(mad(x4, 6.0, d)), 0.15, y3))), 1.0);
              float lit = clamp(ridge / _PuppetPDCurveEdgeLocation, 0.0, 1.0)
                          * _PuppetPDCurveLightColor.a;                          // _564
              pCol = lerp(_PuppetPDCurveBaseColor.rgb, _PuppetPDCurveLightColor.rgb, lit);
              if (_PuppetPDCurveEdgeLocation != 1.0) {
                  float edge = clamp((ridge - _PuppetPDCurveEdgeLocation)
                                     / (1.0 - _PuppetPDCurveEdgeLocation), 0.0, 1.0)
                               * _PuppetPDCurveEdgeColor.a;                      // _600
                  pCol = lerp(pCol, _PuppetPDCurveEdgeColor.rgb, edge);
              }
          } else {
              float2 patUV = float2(mad(_PuppetPatternSpeed.x, f_VFXTime, uv.x),
                                    mad(_PuppetPatternSpeed.y, f_VFXTime, uv.y))
                             * _PuppetPatternMap_ST.xy + _PuppetPatternMap_ST.zw;
              float4 pat = texture(_PuppetPatternMap, patUV);                    // _452
              if (_PuppetPatternMapUseRGB) {
                  pCol = pat.rgb;
              } else {
                  float e = clamp(pat.r / _PuppetPatternTintEdgeLocation, 0.0, 1.0);   // _463
                  pCol = lerp(_PuppetBaseColor.rgb, _PuppetPatternTintColor.rgb, e);   // _479
                  if (_PuppetPatternTintEdgeLocation != 1.0) {
                      float edge = clamp((pat.r - _PuppetPatternTintEdgeLocation)
                                         / (1.0 - _PuppetPatternTintEdgeLocation), 0.0, 1.0);
                      pCol = lerp(pCol, _PuppetPatternTintEdgeColor.rgb, edge);        // _486
                  }
              }
              // metallic / 粗糙度只在 pattern 路径接管(DCurve 变体不带这两条)
              metallic = lerp(metallic, _PuppetMetallic * (1.0 - pat.r), pMask);       // _554
              roughnessRaw = mad(pMask,
                                 (smoothness - 1.0) + lerp(_PuppetRoughness, 0.8, pat.r),
                                 1.0 - smoothness);                                    // _566
          }
          float3 puppetAlbedo = lerp(albedo, pCol, pMask);                       // _519 / _634
          shadowColor = lerp(shadowColor, puppetAlbedo * 0.5, pMask);            // _543
          albedo = puppetAlbedo;
      }

      // ---- CharacterErosion 侵蚀 (_CHARACTER_EROSION) ----
      // 参考 Sub0_Pass0_Fragment_b1289 的 _418.._707。遮罩 = RMOS.g(_343),
      // 与各向异性同一位;两个 keyword 在参考里互斥,不会同时生效。
      if (u_CharacterErosion) {
          float eMask = specScale;                                          // _343
          float2 eNrmUV = uv * _ErosionNormalSmoothnessMap_ST.xy + _ErosionNormalSmoothnessMap_ST.zw;
          float4 eNS = texture(_ErosionNormalSmoothnessMap, eNrmUV);        // _418
          float2 ePatUV = uv * _ErosionPatternMap_ST.xy + _ErosionPatternMap_ST.zw;
          float ePat = texture(_ErosionPatternMap, ePatUV).r;               // _549

          // 三段色:按 uv.y 的位置 + 羽化,root -> base -> top
          float dRoot = _ErosionBaseRootColorSmooth - _ErosionBaseRootColorLocation;   // _463
          float dTop = _ErosionBaseTopColorSmooth - _ErosionBaseTopColorLocation;      // _464
          float tRoot = clamp((dRoot + uv.y)
                              / (dRoot + (_ErosionBaseRootColorSmooth + _ErosionBaseRootColorLocation)),
                              0.0, 1.0);                                    // _473
          float tTop = clamp((dTop + uv.y)
                             / (dTop + (_ErosionBaseTopColorSmooth + _ErosionBaseTopColorLocation)),
                             0.0, 1.0);                                     // _474
          float sRoot = (tRoot * tRoot) * mad(tRoot, -2.0, 3.0);            // _481
          float sTop = (tTop * tTop) * mad(tTop, -2.0, 3.0);                // _482
          float3 eCol = lerp(_ErosionBaseRootColor.rgb, _ErosionBaseColor.rgb, sRoot);  // _506
          eCol = _ErosionUV2Tint ? lerp(eCol, _ErosionBaseTopColor.rgb, sTop)
                                 : _ErosionBaseColor.rgb;                   // _554
          eCol = lerp(eCol, _ErosionPatternTintColor.rgb, ePat);            // _588 内层

          float3 erodedAlbedo = lerp(albedo, eCol, eMask);                  // _588
          // 阴影色按同一遮罩混向被侵蚀反照率的一半(_614)
          shadowColor = lerp(shadowColor, erodedAlbedo * 0.5, eMask);
          albedo = erodedAlbedo;

          metallic = lerp(metallic, _ErosionMetallic * (1.0 - ePat), eMask);   // _624
          float eSmooth = clamp(eNS.b + _ErosionSmoothnessBias, 0.0, 1.0);     // _632
          roughnessRaw = mad(eMask,
                             (smoothness - 1.0) + mad(ePat, (eSmooth - 1.0) + 0.8, 1.0 - eSmooth),
                             1.0 - smoothness);                                // _640

          // 法线:切线空间里的 RNM(Reoriented Normal Mapping)混合 —— 参考
          // _664/_670/_671/_672 就是这个式子,底法线的 z 先 +1。
          float3 baseTS = SampleBumpNormalTS(inputs, _BumpScale);
          float eScale = eMask * _ErosionNormalScale;                        // _438
          float eNx = mad(eNS.r, 2.0, -1.0);
          float eNy = mad(eNS.g, 2.0, -1.0);
          float eNz = max(sqrt(1.0 - min(eNx * eNx + eNy * eNy, 1.0)), 1e-16);  // _432
          eNx *= eScale;
          eNy *= eScale;
          float3 n1 = float3(baseTS.x, baseTS.y, baseTS.z + 1.0);            // _396,_397,_641
          float3 n2 = float3(-eNx, -eNy, eNz);
          float d = dot(n1, n2);                                             // _664
          float3 blendedTS = float3(d * n1.x / n1.z + eNx,
                                    d * n1.y / n1.z + eNy,
                                    d - eNz);                               // _670,_671,_672
          N = TangentToWorld(blendedTS, normalWS_raw, tangentWS, faceSign);
      }

      // ---- liquidag 液体附着法线(参考 characternpr_liquidag b13 _970.._1026)----
      // 门限、系数、smoothstep、z 重建、背面清零全部照抄,只有两个引擎量换成
      // [H19] 滑条;液面轴参考里是 TEXCOORD_5.y(顶点管线送来的位置分量),
      // 这里取世界空间 Y。进度 0 时门限恒不成立 = 参考的"未附着"。
      if (f_LiquidProgress > 2.55) {
          float2 lqUV = GetBaseUV(inputs) * f_LiquidTiling;                    // _971,_972
          float4 lqT = texture(_OutlineColorMap, lqUV);                        // _976
          float lqW = clamp(((mad(positionWS.y, 0.65, lqT.z) + 0.35)
                             - mad(-f_LiquidProgress, 0.00392156886, 2.0))
                            * 2.85714364, 0.0, 1.0);                           // _998
          float lqS = (lqW * lqW) * mad(lqW, -2.0, 3.0);                       // _1001
          float lqNx = mad(lqT.x, 2.0, -1.0);                                  // _1002
          float lqNy = mad(lqT.y, 2.0, -1.0);                                  // _1003
          float2 lqN2 = float2(lqNx, lqNy);
          bool lqFront = (uniform_facing >= 0);
          float lqZ = lqFront ? mad(max(sqrt(1.0 - min(dot(lqN2, lqN2), 1.0)), 1e-16) - 1.0,
                                    lqS, 1.0)
                              : 1.0;                                           // _1019
          float3 lqTS = normalize(float3(lqFront ? (lqNx + lqNx) * lqS : 0.0,
                                         lqFront ? (lqNy + lqNy) * lqS : 0.0,
                                         lqZ));                                // _1023.._1026
          N = TangentToWorld(lqTS, normalWS_raw, tangentWS, faceSign);
      }

      // ---- ClearCoat setup (mask = user1.r; 通道未填充时回退 HGRP 默认 "white"=1) ----
      float ccMask = 0.0;
      float3 ccN = N;
      float ccPercRough = 1.0;
      float ccAlpha = 0.0078125;
      float3 ccF0 = float3(0.0);
      bool ccActive = false;
      if (u_ClearCoat) {
          ccMask = slot_user1_tex.is_set ? textureSparse(slot_user1_tex, inputs.sparse_coord).r : 1.0;
          ccN = lerp(faceSign * normalize(normalWS_raw), N, _ClearCoatNormalMode);
          ccPercRough = 1.0 - _ClearCoatSmoothness;
          ccAlpha = max(ccPercRough * ccPercRough, 0.0078125);
          float ccF0scalar = mad(_ClearCoatMetallic, 0.96, 0.04);
          ccF0 = ccF0scalar * _ClearCoatColor.rgb;
          ccActive = ccMask > 0.001;
      }

      // ---- SilkStockings 反照率 (_1285.._1335) ----
      // affect = lerp(MinAffect, MaxAffect, min(pow(1.05 - NdotV, 2*coverage), 1))
      // albedo = lerp(albedo * tint, Color.rgb, affect)   —— 越透肉指数越高,
      // 边缘色越集中在掠射角,就是丝袜边缘那圈。两份反照率(本体/阴影)同样处理。
      if (u_SilkStockings) {
          float3 albedo0 = albedo;              // _348.._350 未经丝袜处理的原反照率
          float3 shadowColor0 = shadowColor;    // _370.._372 同上,阴影侧那一份
          float silk_NdotV = clamp(dot(N, V), 0.0, 1.0);                       // _1290

          // ---- 湿身变光滑(参考 _2348/_2439/_2446/_2450/_2506/_2670)----
          // 丝袜关掉时这条链是"雨一来就 min(rough, 0.05)"的硬切;开了丝袜之后
          // 改成按权重插值,权重 = NdotV × max(雨痕羽化, 雨痕过阈值)。
          //   _2348 wetRamp = min(2*wet, 1)
          //   _2439 t       = min((coverage - 1) * -5, 1)
          //   _2446 edge    = saturate((smoothstep(t) + streak - 1) * 10)
          //   _2450         = wetRamp * smoothstep(edge)
          //   _2506 w       = NdotV * max(_2450, streak >= 1.01 - wet*(1 - 0.5*coverage))
          //   _2670 rough   = lerp(rough, min(rough, 0.05), w)
          // 必须放在 roughness = roughnessRaw² 之前,且此处 N 才成立。
          float silk_affect = mad(min(exp2(log2(1.05 - silk_NdotV) * (silk_coverage + silk_coverage)), 1.0),
                                  _SilkStockingsMaxAffect - _SilkStockingsMinAffect,
                                  _SilkStockingsMinAffect);                    // _1305
          float3 silkAlbedo = lerp(albedo0 * silk_tint, _SilkStockingsColor.rgb, silk_affect);       // _1321.._1323
          float3 silkShadow = lerp(shadowColor0 * silk_tint, _SilkStockingsColor.rgb, silk_affect);  // _1333.._1335

          // 浸润时的反照率处理:AlbedoAffectType > 0 透肉(整体压向 0),
          // <= 0 压暗(按同一权重混回原反照率)。参考:
          //   _2588 = _2537 ? (_2536 * _1321) : mad(_2536, _1321 - albedo, albedo)
          // [H14] 参考里 _1589(光照湿身项)/_529(雨量)/_561(角色浸润) 三者都没有,
          // 三处同源代入 f_SilkWetness,阈值与斜率保持参考原值不动。
          float wet = (_DisableRainEffectOnMaterial > 0.99) ? 0.0
                    : clamp(f_SilkWetness, 0.0, 1.0);
          float silkWetRamp = min(wet + wet, 1.0);                                  // _2348
          float silkT = min((silk_coverage - 1.0) * (-5.0), 1.0);                   // _2439
          float silkTS = (silkT * silkT) * mad(silkT, -2.0, 3.0);
          float silkEdge = clamp(mad(silkTS, 1.0, f_SilkWetStreak - 1.0) * 9.999998, 0.0, 1.0);   // _2446
          float silkWetMask = silkWetRamp * ((silkEdge * silkEdge) * mad(silkEdge, -2.0, 3.0));   // _2450
          float silkOver = (f_SilkWetStreak
                            >= mad(-mad(-silk_coverage, 0.5, 1.0), wet, 1.0099999)) ? 1.0 : 0.0;
          float silkGloss = silk_NdotV * max(silkWetMask, silkOver);                // _2506
          roughnessRaw = mad(silkGloss, min(roughnessRaw, 0.05) - roughnessRaw, roughnessRaw);    // _2670
          float t1 = clamp(((wet - 0.8) + clamp(wet * _SilkStockingsRainWetMaskScale, 0.0, 1.0)) * 3.3333333, 0.0, 1.0);  // _2517
          float t2 = clamp(((wet - 0.45) + min(wet, 1.0)) * 1.5384614, 0.0, 1.0);                                        // _2526
          float wetSmooth = max((t2 * t2) * mad(t2, -2.0, 3.0), (t1 * t1) * mad(t1, -2.0, 3.0));
          float albedoAffect = mad(wetSmooth, -abs(_SilkStockingsAlbedoAffectType), 1.0);  // _2536
          if (_SilkStockingsAlbedoAffectType > 0.0) {
              albedo = albedoAffect * silkAlbedo;
              shadowColor = albedoAffect * silkShadow;
          } else {
              albedo = lerp(albedo0, silkAlbedo, albedoAffect);
              shadowColor = lerp(shadowColor0, silkShadow, albedoAffect);
          }
      }
      shadowColorOut = shadowColor;

      // ---- Emission map ----
      float3 emissionTex = float3(0.0);
      if (u_UseEmission) {
          emissionTex = pbrComputeEmissive(emissive_tex, inputs.sparse_coord);
      }

      // ---- Steep Parallax Mapping (SampleGrad → textureGrad, 数学不变) ----
      float parallaxSample = 0.0;
      if (u_UseParallax && height_tex.is_set) {
          // _ParallaxUseNormal:参考 _936 在两条法线之间二选一
          float3 pxNrm = _ParallaxUseNormal ? N : normalize(normalWS_raw);
          float3 pxTan = normalize(tangentWS.xyz);
          float3 pxBit = cross(pxNrm, pxTan) * tangentWS.w;
          float3 tbnV = float3(dot(pxTan, V), dot(pxBit, V), dot(pxNrm, V));
          float tbnInvLen = rsqrt(max(dot(tbnV, tbnV), 1.175e-38));
          float2 pxUV = uv * _ParallaxTex_ST.xy + _ParallaxTex_ST.zw;
          float2 pxDxUV = ddx(pxUV);
          float2 pxDyUV = ddy(pxUV);
          float pxSteps = min(20.0, _ParallaxMarchNum);
          float pxStepSz = 1.0 / pxSteps;
          float pxViewZ = max(tbnInvLen * tbnV.z, 0.001);
          float2 pxUVStep = (tbnInvLen * tbnV.xy / pxViewZ) * (-_ParallaxScale);
          float2 pxUVDelta = pxStepSz * pxUVStep;
          float2 pxAccum = pxUVDelta;
          float2 pxPrevOff = float2(0.0);
          float pxPrevH = 0.0;
          float pxLayerH = 1.0 - pxStepSz;
          float pxPrevLayerH = 1.0;
          float pxHitH = 0.0;
          bool pxHit = false;
          for (float pxi = 0.0; pxi < pxSteps + 1.0; pxi += 1.0) {
              float pxTexH = SRGBToLinear_Custom(textureGrad(height_tex.tex, pxUV + pxAccum, pxDxUV, pxDyUV).r); // Height 通道 .tex, 原 sRGB 字节
              if (pxLayerH < pxTexH) { pxHitH = pxTexH; pxHit = true; break; }
              pxPrevOff = pxAccum;
              pxAccum += pxUVDelta;
              pxPrevH = pxTexH;
              pxPrevLayerH = pxLayerH;
              pxLayerH -= pxStepSz;
          }
          if (!pxHit) pxHitH = pxPrevH;
          float pxT = (pxPrevH - pxPrevLayerH)
                    / (-pxPrevLayerH + pxLayerH + pxPrevH - pxHitH);
          float2 pxFinalUV = pxUV + pxUVDelta * pxT + pxPrevOff;
          parallaxSample = SRGBToLinear_Custom(texture(height_tex.tex, pxFinalUV).r); // Height 通道 .tex
      }

      // ---- Flat direction ----
      float fX = positionWS.x - originX;
      float fZ = positionWS.z - originZ;
      float fLen = rsqrt(fX*fX + NEAR_ZERO_Y*NEAR_ZERO_Y + fZ*fZ);
      float3 flatDir = float3(fX*fLen, NEAR_ZERO_Y*fLen, fZ*fLen);

      // ---- Exposure ----
      float exposure = (_CharacterParams12.w * (1.0 - _EnvironmentGlobalParams0.x) + _EnvironmentGlobalParams0.x) * _ExposureParams.x;

      // ---- Ambient ----
      float ambInt = exposure;
      float3 ambCol = _CharacterParams2.xyz;

      // ---- Camera forward ----
      float3 camFwd = GetCamFwd();

      // ---- Metallic workflow ----
      // _ANISOTROPY_SPECULAR_ON 时介电层 F0 改由各向异性强度系数决定
      // (参考 _2565/_2566: 0.04 * lerp(1, IntensityMultiplier, mask)),
      // 而不是平时的 0.04 * specScale —— mask 就是 RMOS.g 本身。
      float anisoMask = specScale;                                  // _341 = RMOS.g
      float dielSpec = u_UseAnisotropy
                     ? 0.04 * mad(anisoMask, _AnisotropyIntensityMultiplier - 1.0, 1.0)
                     : specScale * 0.04;
      float oneMinusRefl = (1.0 - metallic) * 0.96;
      float3 diffColor = oneMinusRefl * albedo;
      float3 specColor = metallic * (albedo - dielSpec) + dielSpec;
      float3 shadowDiff = oneMinusRefl * shadowColor;

      float roughness = max(roughnessRaw * roughnessRaw, 0.0078125);

      // ---- Main light ([H2][H3]) ----
      float mainLightShadowAtten = 1.0;
      float3 mainLightDir = GetMainLightDir();
      float3 lightCol = v_MainLightColor.rgb;
      float lightInt = 1.0;

      // ---- Adjusted light direction ----
      float3 adjustedLightDir = lerp(mainLightDir, _CharacterParams11.xyz, _CharacterParams1.w);
      float adjXZLen = rsqrt(adjustedLightDir.x*adjustedLightDir.x + adjustedLightDir.z*adjustedLightDir.z + NEAR_ZERO_Y*NEAR_ZERO_Y);
      float adjXZ_x = adjXZLen * adjustedLightDir.x;
      float adjXZ_z = adjXZLen * adjustedLightDir.z;

      // ---- Light color blend (CP5) ----
      float3 blendedLightCol = lerp(lightCol, _CharacterParams5.xyz, _CharacterParams12.y);
      float blendedLightInt = lerp(lightInt, 1.0, _CharacterParams12.w);

      // ---- Camera-light facing ----
      float cfXZLen = rsqrt(camFwd.x * camFwd.x + camFwd.z * camFwd.z);
      float camLightDot = saturate(-(adjXZ_x * (cfXZLen * camFwd.x) + adjXZ_z * (cfXZLen * camFwd.z)));
      float camYFade = saturate(2.0 * (0.75 - abs(camFwd.y)));
      float camYSmooth = camYFade * camYFade * (3.0 - 2.0 * camYFade);

      // ==== DIFFUSE RAMP ====
      float geomNdotL = dot(N, adjustedLightDir);
      float wrapAdd = 0.5 - 0.5 * geomNdotL * geomNdotL;
      float camFadeFactor = (1.0 - _CharacterParams12.x) * (camLightDot * camYSmooth);
      float modNdotL = camFadeFactor * wrapAdd + geomNdotL;
      float3 rampCol; float rampA; float rampChroma; float rampChromaInv; float viewRampA;
      if (u_UseDiffRamp) {
          float rampInput = clamp(_CharacterParams11.w * _CharacterParams12.x + modNdotL, -1.0, 1.0) * 0.5 + 0.5;
          float4 rampSmp = SampleRamp(rampInput);
          rampCol = rampSmp.rgb;
          rampA = rampSmp.a;
          rampChroma = max(rampCol.r, max(rampCol.g, rampCol.b)) - min(rampCol.r, min(rampCol.g, rampCol.b));
          rampChromaInv = 1.0 - rampChroma;
          float viewRampU = dot(N, camFwd) * 0.5 + 0.5;
          float4 viewRampSmp = SampleRamp(viewRampU);
          viewRampA = viewRampSmp.a;
      } else {
          // 关 _DIFF_RAMP_ON 时参考不是软 lambert, 而是程序化硬 ramp:
          // 把 [0.25, 1] 重映射到 [0, 1] 再走三次曲线, 下面 5/8 段全暗。
          // 源 characternpr b363 _2862/_2865 (rampA) 与 _2875/_2878 (viewRampA)。
          rampCol = float3(1.0);
          rampA = RampSmooth(max((clamp(_CharacterParams11.w * _CharacterParams12.x + modNdotL, -1.0, 1.0) - 0.25)
                                 * 1.33333337306976318359375, 0.0));
          rampChroma = 0.0;
          rampChromaInv = 1.0;
          viewRampA = RampSmooth(clamp((dot(N, camFwd) - 0.25) * 1.33333337306976318359375, 0.0, 1.0));
      }

      // ---- Shadow terms ----
      float castShadow = lerp(smoothstep(0.0, 1.0, mainLightShadowAtten), 1.0, _CharacterParams1.z);
      float minShadow = min(rampA, shadowMask) * castShadow;
      float viewShadowProduct = viewRampA * shadowMask;

      // ==== NPR DIFFUSE COMPOSITION ====
      float3 albScaled = shadowDiff * _CharacterParams0.z;
      float diffColorLum = dot(diffColor, LUM);

      float nprNdotL = saturate(dot(N, _CharacterParams6.xyz) + _CharacterParams7.x) * _CharacterParams7.y + _CharacterParams7.z;
      float shadowStr = minShadow * _CharacterParams1.y;

      float3 shadAmb = nprNdotL * (shadowStr * (1.0 - ambCol) + ambCol);

      float bright065 = min(ambInt * 0.35 + 0.65, 1.5);
      // _REALISTIC_LIGHTING 把这两个风格化重映射整个去掉(参考 ON 变体里
      // _2837/_2829 根本不存在),等价于取 1。
      float brightFull = u_RealisticLighting ? 1.0 : clamp(ambInt, 0.0, 1.5);
      float brightMix = u_RealisticLighting
                      ? 1.0
                      : lerp(bright065, clamp(ambInt, 1.25, 1.75), _CharacterParams1.x);
      float3 brightAmb = brightMix * shadAmb * _CharacterParams0.w;

      float lightLum = dot(blendedLightCol * blendedLightInt, LUM);

      float oneMinus12y = 1.0 - _CharacterParams12.y;
      float3 lightBlend = blendedLightCol * _CharacterParams12.y + oneMinus12y;
      float3 fullDiff;
      fullDiff.r = (shadAmb.r * brightFull * lightBlend.r + minShadow * (blendedLightCol.r * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
      fullDiff.g = (shadAmb.g * brightFull * lightBlend.g + minShadow * (blendedLightCol.g * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
      fullDiff.b = (shadAmb.b * brightFull * lightBlend.b + minShadow * (blendedLightCol.b * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;

      float albScaledLum = dot(albScaled * 0.65, LUM);
      float3 desatShad = (albScaled * 0.65 - albScaledLum) * 1.2 + albScaledLum;

      float combWeight = saturate(viewShadowProduct + rampA);
      float3 weightedAmb = lerp(desatShad, albScaled, combWeight);
      float3 shadowBlended = lerp(weightedAmb, diffColor, minShadow);

      float3 viewDepShad = viewShadowProduct * ((diffColor - diffColorLum) * 1.2 + diffColorLum - albScaled) + albScaled;

      float3 rampTinted = shadowBlended * (rampCol * rampChroma + rampChromaInv);

      float shadowLumVal = dot(shadowBlended, LUM);
      float rampLum = dot(rampTinted, LUM);
      float lumRatio = clamp(shadowLumVal / max(rampLum, 0.001), 0.0, 1.5);

      float3 nprDiff = rampTinted * lumRatio;

      float ambDiffInt = minShadow * (1.0 - _CharacterParams0.z) + _CharacterParams0.z;
      float specAmbInt = ambDiffInt * (minShadow * 0.5 + 0.5);

      // ==== ALPHA PREMULTIPLY ====
      float alphaPremul = baseAlpha * _AlphaPremultiply + (1.0 - _AlphaPremultiply);

      // ==== GGX SPECULAR ====
      float NdotV_spec = saturate(dot(N, V));
      float mainLightY = adjustedLightDir.y;
      float3 camFwdMod = normalize(float3(camFwd.x, mainLightY, camFwd.z));
      float3 H = normalize(V * 3.0 + adjustedLightDir + camFwdMod * 2.0);
      float NdotH = dot(N, H);
      float roughSq = roughness * roughness;
      float denom = (NdotH * roughSq - NdotH) * NdotH + 1.0;
      float denomSq = denom * denom;
      float D_raw = (denomSq != roughSq) ? roughSq / denomSq : 1.0;

      // ---- Anisotropy 各向异性高光 (_ANISOTROPY_SPECULAR_ON) ----
      // 参考 Sub0_Pass0_Fragment_b375(ON) vs b369(OFF)。两瓣共用一套 TBN,
      // 方向都乘 mask(=RMOS.g):主瓣的 NDF 顶替各向同性 D 并照常过可见项
      // (_3100),第二瓣沿视线偏移半角向量、**不过**可见项,单独 clamp 后
      // 带自己的颜色加进高光(_3120)。
      float D_forVis = D_raw;
      float3 anisoAddSpec = float3(0.0);
      if (u_UseAnisotropy) {
          // 不勾"使用模型切线"时,切线由法线现场生成 (_505: 法线 XZ 投影的垂线)
          float3 anisoTanRaw = _AnisotropyUseGeometryTangent
                             ? tangentWS.xyz
                             : normalize(float3(-N.z, 0.0, N.x) *
                                         rsqrt(max(N.z * N.z + N.x * N.x, 6.103515625e-05)));
          float3 aT = normalize(anisoTanRaw - N * dot(anisoTanRaw, N));
          float3 aB = cross(N, aT) * tangentWS.w;

          float alphaT1 = roughness * mad(_AnisotropyDirectionMain, anisoMask, 1.0);   // _2599
          float alphaB1 = roughness * mad(-_AnisotropyDirectionMain, anisoMask, 1.0);  // _2601
          float alphaTB1 = alphaB1 * alphaT1;                                          // _3041
          float alphaT2 = roughness * mad(_AnisotropyDirectionAdditional, anisoMask, 1.0);  // _2600
          float alphaB2 = roughness * mad(-_AnisotropyDirectionAdditional, anisoMask, 1.0); // _2602
          float alphaTB2 = alphaB2 * alphaT2;                                          // _3042

          float3 v1 = float3(dot(aT, H) * alphaB1, dot(aB, H) * alphaT1, dot(N, H) * alphaTB1);
          float d1 = dot(v1, v1);
          float num1 = alphaTB1 * (alphaTB1 * alphaTB1);
          float den1 = d1 * d1;
          D_forVis = (den1 != num1) ? (num1 / den1) : 1.0;                             // 顶替 _3056/_3080

          float3 H2 = normalize(H + V * _AnisotropyOffsetAdditional);                  // _3071
          float3 v2 = float3(dot(aT, H2) * alphaB2, dot(aB, H2) * alphaT2, dot(N, H2) * alphaTB2);
          float d2 = dot(v2, v2);
          float num2 = alphaTB2 * (alphaTB2 * alphaTB2);
          float den2 = d2 * d2;
          float ndf2 = (den2 != num2) ? clamp(num2 / den2, 0.0, 20.0) : 1.0;           // _3120
          anisoAddSpec = ndf2 * anisoMask * _AnisotropyColorAdditional.rgb;
      }

      // 各向同性(或各向异性主瓣)GGX:可见项只作用在它身上(参考 _3551 / _3100)。
      float ggxTerm = clamp(D_forVis * 0.5 / (NdotV_spec * 2.0 + roughness + 1e-4) - NEAR_ZERO_Y, 0.0, 20.0);

      // ---- SilkStockings 各向异性高光 (_3025.._3557) ----
      // alphaT/alphaB 由 alpha(=roughness²) 按方向劈开,劈的幅度再乘透肉衰减;
      // 半角向量沿视线偏移 SpecularValue;这一瓣**不过**上面的可见项,而是
      // 单独 clamp 后与之相加(参考 _3572 = specColor * (_3551 + _3557)),
      // 与 1.3.3 把两瓣一起送进可见项的写法不同。
      if (u_SilkStockings) {
          float silk_falloff = 1.0 - clamp(silk_coverage * _SilkStockingsSpecularFalloff, 0.0, 1.0);  // _3025
          float silk_alphaT = roughness * mad(-silk_anisoDir, silk_falloff, 1.0);   // _3028
          float silk_alphaB = roughness * mad( silk_anisoDir, silk_falloff, 1.0);   // _3030
          float silk_alphaTB = silk_alphaB * silk_alphaT;                           // _3516
          float3 silk_rawTan = tangentWS.xyz;
          float3 silk_T = normalize(silk_rawTan - N * dot(silk_rawTan, N));
          float3 silk_B = cross(N, silk_T) * tangentWS.w;
          float3 silk_H = normalize(H + V * _SilkStockingsSpecularValue);           // _3518
          float3 silk_v = float3(silk_alphaB * dot(silk_T, silk_H),
                                 silk_alphaT * dot(silk_B, silk_H),
                                 silk_alphaTB * dot(N, silk_H));                    // _3538
          float silk_d = dot(silk_v, silk_v);                                       // _3539
          float silk_num = silk_alphaTB * (silk_alphaTB * silk_alphaTB);            // _3541
          float silk_den = silk_d * silk_d;                                         // _3542
          float silk_ndf = (silk_den != silk_num) ? clamp(silk_num / silk_den, 0.0, 20.0) : 1.0;
          ggxTerm += silk_ndf * silk_specInt;                                       // _3557
      }

      // ---- Spec Ramp ----
      float3 specRampColor = specColor;
      float3 specRampEnv = specColor;
      if (u_UseSpecRamp) {
          float specRampPartial = D_raw * (roughSq + 1e-4);
          float specRampU = lerp(specRampPartial, NdotV_spec * NdotV_spec, _SpecRampIridescentMode);
          float specRampV = (1.0 - metallic) * roughnessRaw;
          float3 specRampSmp = textureLod(_SpecRampMap, float2(specRampU, specRampV), 0.0).rgb;
          specRampColor = specColor * specRampSmp;
          specRampEnv = lerp(specColor, specRampColor, _SpecRampIridescentMode);
      }

      // ---- ClearCoat Specular (directional) ----
      float3 ccSpecDir = float3(0.0);
      float3 ccBaseScale = float3(1.0);
      float3 ccDiffScale = float3(1.0);
      if (u_ClearCoat && ccActive) {
          float ccNdotH = dot(ccN, H);
          float ccNdotV = saturate(dot(ccN, V));
          float VdotH = saturate(dot(V, H));
          float oneMinusVdotH = 1.0 - VdotH;
          float pow2 = oneMinusVdotH * oneMinusVdotH;
          float pow5 = pow2 * pow2 * oneMinusVdotH;
          float complement = 1.0 - pow5;
          float3 ccFresnel = ccF0 * complement + pow5;
          float3 ccMaskedF = ccMask * ccFresnel;
          ccBaseScale = 1.0 - ccMaskedF;
          ccDiffScale = 1.0 - ccMask * ccMaskedF;
          float ccAlphaSq = ccAlpha * ccAlpha;
          float ccDenom = (ccNdotH * ccAlphaSq - ccNdotH) * ccNdotH + 1.0;
          float ccDenomSq = ccDenom * ccDenom;
          float ccD = (ccDenomSq != ccAlphaSq) ? ccAlphaSq / ccDenomSq : 1.0;
          float ccV = 0.5 / (mad(ccNdotV, 2.0, ccAlpha) + 0.0001);
          ccSpecDir = clamp(ccV * ccD * ccMaskedF, 0.0, 20.0);
      }

      // Main lit composition
      // 各向异性第二瓣与主瓣共用 specColor:参考 _3143 =
      //   specAmb * F0 * (NDF1_vis + NDF2 * mask * ColorAdditional)
      float3 specLobes = ggxTerm + anisoAddSpec;
      float3 mainLit;
      if (u_ClearCoat) {
          mainLit = fullDiff * nprDiff * alphaPremul * ccDiffScale
                  + (specAmbInt * fullDiff) * (specLobes * specRampColor * ccBaseScale * ccBaseScale + ccSpecDir) * _CharacterParams13.w;
      } else {
          mainLit = fullDiff * nprDiff * alphaPremul + (specAmbInt * fullDiff) * (specLobes * specRampColor) * _CharacterParams13.w;
      }
      float mainLitLum = dot(mainLit, LUM);
      float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);

      // ==== SKIN SPECULAR CP8/CP9 ====
      float cp9x = _CharacterParams9.x;
      float cp9y = _CharacterParams9.y;
      float3 skinDir;
      skinDir.x = -cp9y * camFwd.z;
      skinDir.y = camFwd.z * cp9x;
      skinDir.z = camFwd.x * cp9y - cp9x * camFwd.y;
      skinDir = normalize(skinDir);

      float skinFresnel = 1.0 - abs(dot(V, N));
      float skinLow = _CharacterParams9.w * (-0.6) + 0.8;
      float skinHigh = _CharacterParams9.w * (-0.4) + 0.9;
      float skinT = saturate((skinFresnel - skinLow) / (skinHigh - skinLow));
      float skinSmooth = skinT * skinT * (3.0 - 2.0 * skinT);
      float skinNdotL = saturate(dot(flatDir, skinDir) + 1.0);
      float skinShadow = min(shadowMask, skinNdotL);
      float skinNdotBN = saturate(dot(skinDir, N));

      float3 skinSpec;
      skinSpec.r = skinShadow * skinSmooth * _CharacterParams8.x * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.r - 0.25) + 0.25);
      skinSpec.g = skinShadow * skinSmooth * _CharacterParams8.y * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.g - 0.25) + 0.25);
      skinSpec.b = skinShadow * skinSmooth * _CharacterParams8.z * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.b - 0.25) + 0.25);

      // ==== SUBSURFACE SPECULAR ====
      float mainNdotL_xz = dot(float3(adjXZ_x, adjXZLen * NEAR_ZERO_Y, adjXZ_z), N);
      float wrapNdotL = saturate(0.5 + mainNdotL_xz - 0.5 * mainNdotL_xz * mainNdotL_xz);
      float camLightFacing = (1.0 - _CharacterParams12.x) * camLightDot;
      float edgeT = saturate((-abs(dot(V, N)) + 0.4) * 5.0);
      float edgeFresnel = edgeT * edgeT * (3.0 - 2.0 * edgeT);
      float brightT = saturate((0.1 - diffColorLum) * 16.666);
      float brightnessGate = (brightT * brightT) * (3.0 - 2.0 * brightT);
      float3 subsurfLight = blendedLightCol * blendedLightInt;
      float3 subsurfSpec = brightnessGate * shadowMask * edgeFresnel * camLightFacing * wrapNdotL * subsurfLight * max(diffColor, 0.15);

      // ==== CUBEMAP REFLECTION ([H6]) ====
      float3 reflDir = reflect(-V, N);
      float cubeMip = log2(max(roughnessRaw, 0.001)) * 1.2 + 5.0;
      float3 cubeSample = envSampleLOD(reflDir, cubeMip).rgb;
      // _MATCAP_ENV_REFLECTION_ON:Matcap **顶替**环境采样本身,后面的 envBRDF /
      // reflBoost / cubeAmbInt 一字不动 —— 参考 Sub0_Pass0_Fragment_b473 的
      //   _3451 * (mad(_3440*_2541, _3181, _3181) * (matcap.rgb * _MatcapColor.rgb)) * _940
      // 里根本没有 cubeSample 这一项。UV 与 Eyes 那条 matcap 一样是视空间法线。
      // (注意:参考产物把 t16 的 _MatcapTex 标成了别的名字,这里按**用法**认 ——
      //  真正的 matcap 是那次 N_view.xy*0.5+0.5 的采样,而被标成 _MatcapTex 的
      //  那次其实是 DXT5nm 法线解码,即 _BumpMap。)
      if (u_MatcapEnvReflection) {
          float3 mcViewN = mat3(uniform_camera_view_matrix) * N;
          float mcLen = rsqrt(max(dot(mcViewN, mcViewN), 1.175e-38));
          float2 mcUV = float2(mcViewN.x * mcLen * 0.5 + 0.5, mcViewN.y * mcLen * 0.5 + 0.5);
          cubeSample = SampleSRGBTex(_MatcapTex, mcUV).rgb * _MatcapColor.rgb;
      }

      float dfgX, dfgY;
      ComputeEnvBRDF(NdotV_spec, roughness, dfgX, dfgY);
      float3 envBRDF = specRampEnv * dfgX + dfgY;
      float totalRefl = dfgX + dfgY;
      float reflBoost = (1.0 - totalRefl) / max(totalRefl, 1e-6);

      float cubeAmbInt = ambDiffInt * (clamp(exposure, 0.5, 1.5) * _CharacterParams0.w);
      float3 cubeRefl = cubeSample * envBRDF * (1.0 + reflBoost * specRampEnv);
      float3 cubemapContrib = cubeAmbInt * cubeRefl * ambCol * _CubemapIntensity;

      // ---- ClearCoat IBL ----
      if (u_ClearCoat && ccActive) {
          float3 ccReflDir = reflect(-V, ccN);
          float ccCubeMip = log2(max(ccPercRough, 0.001)) * 1.2 + 5.0;
          float3 ccCubeSmp = envSampleLOD(ccReflDir, ccCubeMip).rgb;
          float ccNdotV_ibl = saturate(dot(ccN, V));
          float ccDfgX, ccDfgY;
          ComputeEnvBRDF(ccNdotV_ibl, ccAlpha, ccDfgX, ccDfgY);
          float3 ccEnvBRDF = ccF0 * ccDfgX + ccDfgY;
          float ccTotalRefl = ccDfgX + ccDfgY;
          float ccReflBoost = (1.0 - ccTotalRefl) / max(ccTotalRefl, 1e-6);
          float3 ccCubeRefl = ccCubeSmp * ccEnvBRDF * (1.0 + ccReflBoost * ccF0);
          cubemapContrib += ccMask * ccCubeRefl * _CubemapIntensity;
      }

      // ==== EMISSION ====
      float3 emissionContrib = float3(0.0);
      if (u_UseEmission) {
          // _3797:呼吸只按 _EmissionMap.a(→ user2)逐像素生效,
          //   breath = 1 + mask * (lerp(Min, Max, sin(t*Speed)*0.5+0.5) - 1)
          float emisBreath = 1.0;
          if (_EmissionAlphaBrightBreath) {
              float breathMask = slot_user2_tex.is_set
                               ? textureSparse(slot_user2_tex, inputs.sparse_coord).r : 1.0;
              float breathPhase = mad(sin(f_VFXTime * _EmissionAlphaBrightBreathSpeed), 0.5, 0.5);
              float breathScale = mad(breathPhase,
                                      _EmissionAlphaBrightBreathScaleMax
                                      - _EmissionAlphaBrightBreathScaleMin,
                                      _EmissionAlphaBrightBreathScaleMin);
              emisBreath = mad(breathMask, breathScale - 1.0, 1.0);
          }
          emissionContrib = emissionTex * _EmissionColor.rgb * _EmissionBrightness
                            * emisBreath * alphaPremul;
      }
      if (u_UseParallax) {
          emissionContrib += baseAlpha * parallaxSample * _ParallaxColor.rgb * alphaPremul;
      }
      if (u_StylizedFresnel) {
          // _3507 * _457..459 * _3141 —— Color.a 就是"自发光量"那一位。
          emissionContrib += (stylizedFresnelMask * _StylizedFresnelColor.a)
                             * _StylizedFresnelColor.rgb * alphaPremul;
      }
      if (u_EnemyHitFlash) {
          emissionContrib += hitFlashWeight * hitFlashEmissive * f_HitFlashExposure;
      }
      if (u_CharacterDissolve) {
          emissionContrib += dissolveEdgeEmis * _DissolveEmissiveColor.rgb;   // _3805
      }

      // ==== FINAL ASSEMBLY ====
      float desatFactor = desatAmt * desatAmt + 1.0;
      float3 desatMainLit = desatFactor * (mainLit - mainLitLum) + mainLitLum;

      float3 litColor = desatMainLit + skinSpec + subsurfSpec + emissionContrib + cubemapContrib;

      // ==== VFX COLOR ADJUSTMENT ====
      if (_EnableVFXColorAdjustment > 0.5) {
          float litLum = dot(litColor, LUM);
          float3 adjusted;
          adjusted.r = _ColorAdjustmentContrast * (lerp(litLum, litColor.r, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          adjusted.g = _ColorAdjustmentContrast * (lerp(litLum, litColor.g, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          adjusted.b = _ColorAdjustmentContrast * (lerp(litLum, litColor.b, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          float caRimT = saturate((_ColorAdjustmentRimWidth - NdotV_spec) / max(_ColorAdjustmentRimWidth, 1e-5));
          float caRimSmooth = caRimT * caRimT * (3.0 - 2.0 * caRimT);
          float3 caBrightened = adjusted * _ColorAdjustmentBrightness;
          litColor = lerp(caBrightened, _ColorAdjustmentColorBlend.rgb, _ColorAdjustmentColorBlend.w)
                   + caRimSmooth * _ColorAdjustmentRimColor.rgb * _ColorAdjustmentRimIntensity;
      }

      float3 finalColor = litColor / _ExposureParams.x;
      return finalColor;
  }
//- }

//----------------------------------------------------------------------region Part 1 Face — HGRP_CharacterNPR_Skin_Fix.shader computeNPRLighting 逐行移植
//- {
  // SDF Mask / SDF Lightmap = 贴图参数 (RGBA 完整 + 镜像 UV 采样需任意 UV)。
  // castShadow: SDF on → 1.0 (HGRP 同); off → shadowAtten=1 [H2] 时 smoothstep(1)=1。
  float3 shadeFace(V2F inputs, float3 positionWS, float3 normalWS_raw, float4 tangentWS, float faceSign, float3 albedo, float baseAlpha) {
      float2 uv = GetBaseUV(inputs);

      // ---- FaceDecal 脸部贴花 (1.4.4 新增) ----
      // 参考 characternpr_skin b129 的 _425.._529,逐条对应:
      //   _428 镜像量 = saturate(MirrorMode - 1)   _458 1/Size   _474 = -2/Size
      //   _483 先减中心、再按镜像折返、再乘(翻转后的)缩放
      //   _495 旋转后采样,UV 夹到 [0,1]
      //   _507 亮度遮罩:只在反照率最暗通道低于阈值处生效
      //   _525 albedo = lerp(albedo, decal.rgb*Tint.rgb, Tint.a * decal.a)
      {
          bool mirrorOn = _FaceDecalMirrorMode > 0.5;
          float mirrorAmt = clamp(_FaceDecalMirrorMode - 1.0, 0.0, 1.0);          // _428
          float invSize = 1.0 / _FaceDecalSize;                                   // _458
          float invSizeNeg = invSize * -2.0;                                      // _474
          float rot = _FaceDecalRotation * 6.28318548;
          float sr = sin(rot), cr = cos(rot);

          float dx = abs(uv.x - _FaceDecalMirrorSplit);                           // _434
          float cx2 = mad(_FaceDecalCenterX, 0.5, -0.25);                         // _448
          float px = mirrorOn
                   ? (mad(mirrorAmt, (dx - 0.5) + uv.x, 0.5 - dx)
                      - mad(mirrorAmt, _FaceDecalCenterX - cx2, cx2))
                   : (uv.x - _FaceDecalCenterX);
          float dy = abs(uv.y - _FaceDecalMirrorSplit);
          float cy2 = mad(_FaceDecalCenterY, 0.5, -0.25);
          float py = mirrorOn
                   ? (mad(mirrorAmt, (0.5 - dy) - uv.y, uv.y)
                      - mad(mirrorAmt, cy2 - _FaceDecalCenterY, _FaceDecalCenterY))
                   : (uv.y - _FaceDecalCenterY);
          float2 dUV = float2((px - 0.5) * mad(_FaceDecalInvertX, invSizeNeg, invSize),
                              (py - 0.5) * mad(_FaceDecalInvertY, invSizeNeg, invSize));  // _483
          float2 decalUV = float2(clamp(dot(dUV, float2(cr, sr)) + 0.5, 0.0, 1.0),
                                  clamp(dot(dUV, float2(-sr, cr)) + 0.5, 0.0, 1.0));
          float4 decal = texture(_FaceDecalMap, decalUV);                         // _495
          if (_FaceDecalBrightnessMask >= min(albedo.b, min(albedo.g, albedo.r))) {
              float w = _FaceDecalTintColor.a * decal.a;                          // _511
              albedo = lerp(albedo, decal.rgb * _FaceDecalTintColor.rgb, w);      // _525
          }
      }

      // ---- Object-to-World ([H4]: 单位矩阵世界轴; SP 烘焙网格无需 FBX 旋转修正) ----
      float3 objectRight   = float3(1.0, 0.0, 0.0);
      float3 objectUp      = float3(0.0, 1.0, 0.0);
      float originX = 0.0;
      float originZ = 0.0;

      // ---- View direction ----
      float3 V = normalize(camera_pos - positionWS);

      // ---- Normal map ----
      float3 N = SampleBumpNormal(inputs, normalWS_raw, tangentWS, faceSign, _BumpScale);

      // ---- SDF Mask (sampler 参数, rgba 完整) ----
      float4 sdfMask = float4(1.0, 1.0, 0.0, 0.0);
      if (u_UseSDFLightmap) {
          sdfMask = texture(_SDFMask, uv);
      }

      // ---- Flat direction ----
      float fX = positionWS.x - originX;
      float fZ = positionWS.z - originZ;
      float fLen = rsqrt(fX*fX + NEAR_ZERO_Y*NEAR_ZERO_Y + fZ*fZ);
      float3 flatDir = float3(fX*fLen, NEAR_ZERO_Y*fLen, fZ*fLen);

      // ---- Camera forward ----
      float3 camFwd = GetCamFwd();

      // ---- 脸空间相机向量 (SDF rim gate + skin camGate; 无条件算, 关闭时不消费) ----
      // 源: faceRight = unity_ObjectToWorld 列0 (objLightX→lightSide 左右镜像),
      //     faceFwd   = unity_ObjectToWorld 列2 (objLightZ→sdfLightZ 前后/明暗扫描),
      //     faceUp    = 列1 — cross 重建, 无需第三参数。参数即 SP 世界轴原值 (±1),
      // 不再经过任何旋转/翻转重映射 (Unity↔SP 手性差是镜像, 纯旋转表达不了, 只能靠负分量)。
      // cross 取 right×fwd: 默认 ((1,0,0),(0,0,-1)) 给出 (0,1,0) 世界上方与源列1一致;
      // faceUp 仅以 NEAR_ZERO 权重进 SDF 法线重建, camFwdObj.y 无消费者, 符号无关紧要。
      float3 faceFwd = _FaceForward.xyz;
      float3 faceRight = _FaceRight.xyz;
      float3 faceUp = cross(faceRight, faceFwd);
      float3 camFwdObj = float3(
          dot(camFwd, faceRight),
          dot(camFwd, faceUp),
          dot(camFwd, faceFwd)
      );
      float camFwdObjLen = rsqrt(max(dot(camFwdObj, camFwdObj), 1.175494e-38));
      camFwdObj *= camFwdObjLen;
      // max(): faceFwd=(0,0,0) 退化时 camFwdObj.xz 可能全 0 → 防 rsqrt(0)=Inf→NaN
      float camFwdObj_xz_invLen = rsqrt(max(camFwdObj.x * camFwdObj.x + camFwdObj.z * camFwdObj.z, 1.175494e-38));

      // ---- Flat normal XZ ----
      float3 vertNFlatXZ = float3(N.x, NEAR_ZERO_Y, N.z);
      float vertNFlatLen = rsqrt(dot(vertNFlatXZ, vertNFlatXZ));
      vertNFlatXZ *= vertNFlatLen;

      float3 blendedDir;
      if (u_UseSDFLightmap) {
          blendedDir = normalize(lerp(flatDir, vertNFlatXZ, sdfMask.y));
      } else {
          blendedDir = vertNFlatXZ;
      }

      // ---- Exposure / Ambient (Face 用 CP3) ----
      float exposure = (_CharacterParams12.w * (1.0 - _EnvironmentGlobalParams0.x) + _EnvironmentGlobalParams0.x) * _ExposureParams.x;
      float ambInt = exposure;
      float3 ambCol = _CharacterParams3.xyz;

      // ---- Rim ----
      float rimModifier;
      if (u_UseSDFLightmap) {
          float camAngleBias = saturate(camFwdObj.z * camFwdObj_xz_invLen + 0.5);
          rimModifier = lerp(camAngleBias, 1.0, sdfMask.y) * sdfMask.x;
      } else {
          rimModifier = 1.0;
      }

      float rimOffScale;
      if (u_UseSDFLightmap) {
          rimOffScale = lerp(_FaceRimOffScale, _SkinRimOffScale, sdfMask.z);
      } else {
          rimOffScale = _SkinRimOffScale;
      }

      float NdotV = dot(N, V);
      float NdotV_sat = saturate(NdotV);
      float rimFresnel = 1.0 - (NdotV_sat * 0.85 + 0.15);
      float rimAmt = saturate(rimFresnel * rimModifier * rimOffScale);
      float rimInv = 1.0 - rimAmt;
      float3 rimFactor = _SDFRimColor.rgb * rimAmt + rimInv;
      float3 rimAlbedo = albedo * rimFactor;

      // ---- Metallic workflow (Face: 标量, 无 RMOS map — 与 Skin_Fix 一致) ----
      float specScale;
      if (u_UseSDFLightmap) {
          specScale = sdfMask.y * _Specular;
      } else {
          specScale = _Specular;
      }
      float roughnessRaw = 1.0 - _Smoothness;
      float oneMinusRefl = (1.0 - _Metallic) * 0.96;
      float3 diffColor = oneMinusRefl * rimAlbedo;
      float dielSpec = specScale * 0.04;
      float3 specColor = _Metallic * (rimAlbedo - dielSpec) + dielSpec;

      // ---- Shadow LUT / 阴影色 (与其余部位同一口径) ----
      // 源 characternpr_skin b129 _443/_447/_1383:
      //   _443 = albedo * _ShadowColorBrightness
      //   _447 = lerp(dot(_443, LUM), _443, _ShadowColorSaturation)
      //   _1383 = _447 * (0.96 - metallic*0.96)
      // b111(带 FaceDecal 的 _CUSTOMIZE_AVATAR 变体) _528/_533/_537 同序:
      // 贴花先混进 albedo, 阴影色再从混合后的 albedo 取。
      float3 shadowLut;
      if (u_UseShadowLut) {
          shadowLut = oneMinusRefl * SampleShadowLutColor(albedo);
      } else {
          shadowLut = oneMinusRefl * ComputeShadowColorBrightSat(albedo);
      }

      float roughness = max(roughnessRaw * roughnessRaw, 0.0078125);

      // ---- Main light ([H2][H3]) ----
      float mainLightShadowAtten = 1.0;
      float3 mainLightDir = GetMainLightDir();
      float3 lightCol = v_MainLightColor.rgb;
      float lightInt = 1.0;

      // ---- Adjusted light direction ----
      float3 adjustedLightDir = lerp(mainLightDir, _CharacterParams11.xyz, _CharacterParams1.w);
      float adjXZLen = rsqrt(adjustedLightDir.x*adjustedLightDir.x + adjustedLightDir.z*adjustedLightDir.z + NEAR_ZERO_Y*NEAR_ZERO_Y);
      float adjXZ_x = adjXZLen * adjustedLightDir.x;
      float adjXZ_z = adjXZLen * adjustedLightDir.z;

      // ---- Camera-light dot ----
      float cfXZLen = rsqrt(camFwd.x * camFwd.x + camFwd.z * camFwd.z);
      float camLightDot = -(adjXZ_x * (cfXZLen * camFwd.x) + adjXZ_z * (cfXZLen * camFwd.z));

      // ---- Light color blend (Face 用 CP4) ----
      float3 blendedLightCol;
      blendedLightCol.r = lightCol.r + _CharacterParams12.y * (_CharacterParams4.x - lightCol.r);
      blendedLightCol.g = lightCol.g + _CharacterParams12.y * (_CharacterParams4.y - lightCol.g);
      blendedLightCol.b = lightCol.b + _CharacterParams12.y * (_CharacterParams4.z - lightCol.b);
      float blendedLightInt = _CharacterParams12.w * (1.0 - lightInt) + lightInt;

      // ==== SDF LIGHTMAP ====
      float3 sdfBlendedN = N;
      float sdfValue = 0.0;
      float sdfNdotL = 0.0;
      if (u_UseSDFLightmap) {
          float objLightX = dot(adjustedLightDir, faceRight);
          float objLightZ = dot(adjustedLightDir, faceFwd);
          float objLight_invLen = rsqrt(objLightX * objLightX + NEAR_ZERO_Y * NEAR_ZERO_Y + objLightZ * objLightZ);
          float sdfLightZ = objLight_invLen * objLightZ;
          float lightSide = (objLight_invLen * objLightX > 0.0) ? 1.0 : 0.0;

          float mirrorU = 1.0 - uv.x;
          float2 sdfUV = float2(
              mad(lightSide, uv.x - mirrorU, mirrorU),
              uv.y
          );
          float4 sdfSample = textureLod(_SDFLightmap, sdfUV, 0.0);
          sdfValue = sdfSample.x + sdfSample.y;

          float sdfNx_base = 1.0 - 2.0 * sdfSample.z;
          float sdfNx = mad(lightSide, (2.0 * sdfSample.z - 1.0) - sdfNx_base, sdfNx_base);
          float sdfNz = 1.0 - abs(sdfNx);
          float3 sdfFlatN = normalize(float3(sdfNx, NEAR_ZERO_Y, sdfNz));

          float3 sdfNormalWS = normalize(sdfFlatN.x * faceRight + sdfFlatN.y * faceUp + sdfFlatN.z * faceFwd);
          sdfBlendedN = normalize(lerp(sdfNormalWS, N, sdfMask.y));

          float backlitFactor = saturate(camLightDot) * saturate(-sdfLightZ) * (1.0 - _CharacterParams12.x);
          float wrapTerm = 0.5 * (1.0 - sdfLightZ * sdfLightZ);
          float sdfWrapNdotL = sdfLightZ + backlitFactor * wrapTerm;

          float halfWrap = sdfWrapNdotL * 0.5;
          float sdfT = clamp(0.5 - halfWrap, 0.001, 0.999);
          float sdfLo = max(2.0 * sdfT - 1.0, 0.0);
          float sdfHi = min(2.0 * sdfT, 1.0);
          float sdfS = saturate((sdfValue * 0.5 - sdfLo) / (sdfHi - sdfLo));
          float sdfSS = sdfS * sdfS * (3.0 - 2.0 * sdfS);
          float halfCeil = ceil(halfWrap) * halfWrap;
          sdfNdotL = (sdfSS + halfCeil) * 2.0 - 1.0;
      }

      // ==== DIFFUSE RAMP ====
      float geomNdotL = dot(N, adjustedLightDir);
      float clampedNdotL = clamp(_CharacterParams11.w * _CharacterParams12.x + geomNdotL, -1.0, 1.0);

      float rampSelector;
      if (u_UseSDFLightmap) {
          rampSelector = lerp(sdfNdotL, clampedNdotL, sdfMask.y);
      } else {
          rampSelector = clampedNdotL;
      }
      float rampInput = rampSelector * 0.5 + 0.5;

      float3 rampCol; float rampA; float rampChroma; float rampChromaInv;
      if (u_UseDiffRamp) {
          float4 rampSmp = SampleRamp(rampInput);
          rampCol = rampSmp.rgb;
          rampA = rampSmp.a;
          rampChroma = max(rampCol.r, max(rampCol.g, rampCol.b)) - min(rampCol.r, min(rampCol.g, rampCol.b));
          rampChromaInv = 1.0 - rampChroma;
      } else {
          // 脸部的程序化 ramp 与身体不同口径: +0.5 后 saturate 再走三次曲线,
          // 过渡带更宽 (源 characternpr_skin b97 _2802/_2805)。
          // 参考没有 SDF 开 + ramp 关 的变体, 这里沿用同一个 selector。
          rampCol = float3(1.0);
          rampA = RampSmooth(saturate(rampSelector + 0.5));
          rampChroma = 0.0;
          rampChromaInv = 1.0;
      }

      // ==== NPR DIFFUSE COMPOSITION ====
      float3 albScaled = shadowLut * _CharacterParams0.z;
      float diffColorLum = dot(diffColor, LUM);
      float castShadow;
      if (u_UseSDFLightmap) {
          castShadow = 1.0;
      } else {
          castShadow = lerp(smoothstep(0.0, 1.0, mainLightShadowAtten), 1.0, _CharacterParams1.z);
      }
      float minShadow = min(rampA, baseAlpha) * castShadow;

      float nprNdotL = saturate(dot(blendedDir, _CharacterParams6.xyz) + _CharacterParams7.x) * _CharacterParams7.y + _CharacterParams7.z;
      float shadowStr = minShadow * _CharacterParams1.y;

      float3 shadAmb;
      shadAmb.r = nprNdotL * (shadowStr * (1.0 - ambCol.r) + ambCol.r);
      shadAmb.g = nprNdotL * (shadowStr * (1.0 - ambCol.g) + ambCol.g);
      shadAmb.b = nprNdotL * (shadowStr * (1.0 - ambCol.b) + ambCol.b);

      float bright065 = min(ambInt * 0.35 + 0.65, 1.5);
      float brightFull = clamp(ambInt, 0.0, 1.5);
      float brightMix = lerp(bright065, clamp(ambInt, 1.25, 1.75), _CharacterParams1.x);

      float lightLum = dot(blendedLightCol * blendedLightInt, LUM);

      float oneMinus12y = 1.0 - _CharacterParams12.y;
      float3 lightBlend = blendedLightCol * _CharacterParams12.y + oneMinus12y;
      float3 fullDiff;
      fullDiff.r = (shadAmb.r * brightFull * lightBlend.r + minShadow * (blendedLightCol.r * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
      fullDiff.g = (shadAmb.g * brightFull * lightBlend.g + minShadow * (blendedLightCol.g * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
      fullDiff.b = (shadAmb.b * brightFull * lightBlend.b + minShadow * (blendedLightCol.b * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;

      float albScaledLum = dot(albScaled * 0.65, LUM);
      float3 desatShad;
      desatShad.r = (albScaled.r * 0.65 - albScaledLum) * 1.2 + albScaledLum;
      desatShad.g = (albScaled.g * 0.65 - albScaledLum) * 1.2 + albScaledLum;
      desatShad.b = (albScaled.b * 0.65 - albScaledLum) * 1.2 + albScaledLum;

      float combWeight = saturate(baseAlpha + rampA);
      float3 weightedAmb = lerp(desatShad, albScaled, combWeight);
      float3 shadowBlended = lerp(weightedAmb, diffColor, minShadow);

      float3 rampTinted;
      rampTinted.r = shadowBlended.r * (rampCol.r * rampChroma + rampChromaInv);
      rampTinted.g = shadowBlended.g * (rampCol.g * rampChroma + rampChromaInv);
      rampTinted.b = shadowBlended.b * (rampCol.b * rampChroma + rampChromaInv);

      float shadowLumVal = dot(shadowBlended, LUM);
      float rampLum = dot(rampTinted, LUM);
      float lumRatio = clamp(shadowLumVal / max(rampLum, 0.001), 0.0, 1.5);

      float3 nprDiff = rampTinted * lumRatio;

      float attenFac = minShadow;
      float ambDiffInt = (attenFac * (1.0 - _CharacterParams0.z) + _CharacterParams0.z) * (attenFac * 0.5 + 0.5);

      float3 ambDiff = ambDiffInt * fullDiff;

      // ==== GGX SPECULAR ====
      float NdotV_spec = saturate(dot(N, V));
      float3 camFwdMod = normalize(float3(camFwd.x, adjustedLightDir.y, camFwd.z));
      float3 H = normalize(V * 3.0 + adjustedLightDir + camFwdMod * 2.0);
      float NdotH = dot(N, H);
      float roughSq = roughness * roughness;
      float denom = (NdotH * roughSq - NdotH) * NdotH + 1.0;
      float denomSq = denom * denom;
      float D_raw = (denomSq != roughSq) ? roughSq / denomSq : 1.0;
      float ggxTerm = clamp(D_raw * 0.5 / (NdotV_spec * 2.0 + roughness + 1e-4) - NEAR_ZERO_Y, 0.0, 20.0);

      // ==== HIGHLIGHT MAP ====
      float3 hlSample = float3(0.0);
      if (u_FaceHighlightMap) {
          float hlOffsetX = dot(V, objectRight) * _HighlightMapVector.x;
          float hlOffsetY = dot(V, objectUp) * _HighlightMapVector.y;
          hlSample = texture(_HighlightMap, float2(uv.x + hlOffsetX, uv.y + hlOffsetY)).rgb;
      }

      // Main lit composition
      float3 mainLit;
      mainLit.r = fullDiff.r * nprDiff.r + ambDiff.r * (specColor.r * ggxTerm * _CharacterParams13.w + hlSample.r);
      mainLit.g = fullDiff.g * nprDiff.g + ambDiff.g * (specColor.g * ggxTerm * _CharacterParams13.w + hlSample.g);
      mainLit.b = fullDiff.b * nprDiff.b + ambDiff.b * (specColor.b * ggxTerm * _CharacterParams13.w + hlSample.b);
      float mainLitLum = dot(mainLit, LUM);
      float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);

      // ==== SKIN SPECULAR (CP8/CP9) ====
      float3 skinDir;
      skinDir.x = -_CharacterParams9.y * camFwd.z;
      skinDir.y =  camFwd.z * _CharacterParams9.x;
      skinDir.z =  camFwd.x * _CharacterParams9.y - _CharacterParams9.x * camFwd.y;
      skinDir = normalize(skinDir);

      float skinNdotV = dot(V, sdfBlendedN);
      float skinFresnel = 1.0 - abs(skinNdotV);
      float skinLow = _CharacterParams9.w * (-0.6) + 0.8;
      float skinHigh = _CharacterParams9.w * (-0.4) + 0.9;
      float skinT = saturate((skinFresnel - skinLow) / (skinHigh - skinLow));
      float skinSmooth = skinT * skinT * (3.0 - 2.0 * skinT);

      float skinAmt;
      if (u_UseSDFLightmap) {
          float camAngleAbs = abs(camFwdObj.z * camFwdObj_xz_invLen);
          float camGateT = saturate((camAngleAbs - 0.9) * 10.0);
          float camGate = camGateT * camGateT * (3.0 - 2.0 * camGateT);
          float cp9wGate = saturate(_CharacterParams9.w * 10.0 - 3.0);
          float camFacingSkin = (dot(camFwd, skinDir) < -0.01) ? 1.0 : 0.0;
          skinAmt = lerp(camGate * skinSmooth, max(camGate, camFacingSkin) * sdfMask.w, cp9wGate);
      } else {
          skinAmt = skinSmooth;
      }

      float skinNdotL = saturate(dot(flatDir, skinDir) + 1.0);
      float skinShadow = min(baseAlpha, skinNdotL);
      float skinNdotBN = saturate(dot(skinDir, sdfBlendedN));

      // ==== SUBSURFACE SPECULAR ====
      float mainNdotL_xz = dot(float3(adjXZ_x, adjXZLen * NEAR_ZERO_Y, adjXZ_z), N);
      float wrapNdotL = saturate(0.5 + mainNdotL_xz - 0.5 * mainNdotL_xz * mainNdotL_xz);
      float camLightFacing = (1.0 - _CharacterParams12.x) * saturate(camLightDot);
      float edgeT = saturate((-abs(NdotV) + 0.4) * 5.0);
      float edgeFresnel = edgeT * edgeT * (3.0 - 2.0 * edgeT);
      float brightT = saturate((0.1 - diffColorLum) * 16.666);
      float brightnessGate = (brightT * brightT) * (3.0 - 2.0 * brightT);
      float3 subsurfLight = blendedLightCol * blendedLightInt;
      float3 subsurfSpec;
      subsurfSpec.r = brightnessGate * baseAlpha * edgeFresnel * camLightFacing * wrapNdotL * subsurfLight.r * max(diffColor.r, 0.15);
      subsurfSpec.g = brightnessGate * baseAlpha * edgeFresnel * camLightFacing * wrapNdotL * subsurfLight.g * max(diffColor.g, 0.15);
      subsurfSpec.b = brightnessGate * baseAlpha * edgeFresnel * camLightFacing * wrapNdotL * subsurfLight.b * max(diffColor.b, 0.15);

      // ==== CP14 SECONDARY SPECULAR ====
      float3 cp14Term = float3(0.0);
      if (u_UseSDFLightmap) {
          float halfCP15 = 0.5 * _CharacterParams15.z;
          float cp15T = clamp(0.5 - halfCP15, 0.001, 0.999);
          float cp15Lo = max(2.0 * cp15T - 1.0, 0.0);
          float cp15Hi = min(2.0 * cp15T, 1.0);
          float cp15S = saturate((sdfValue * 0.5 - cp15Lo) / (cp15Hi - cp15Lo));
          float cp15SS = cp15S * cp15S * (3.0 - 2.0 * cp15S);
          float cp15Ceil = ceil(halfCP15) * halfCP15;
          float cp15Raw = saturate((cp15SS + cp15Ceil) * 2.0 - 0.5);
          float cp15Smooth = cp15Raw * cp15Raw * (3.0 - 2.0 * cp15Raw);
          float cp14Spec = (1.0 - sdfMask.y) * cp15Smooth;
          cp14Term.r = diffColor.r * cp14Spec * _CharacterParams14.x * _CharacterParams14.w;
          cp14Term.g = diffColor.g * cp14Spec * _CharacterParams14.y * _CharacterParams14.w;
          cp14Term.b = diffColor.b * cp14Spec * _CharacterParams14.z * _CharacterParams14.w;
      }

      // ==== FINAL ASSEMBLY ====
      float desatFactor = desatAmt * desatAmt + 1.0;
      float3 term1;
      term1.r = desatFactor * (mainLit.r - mainLitLum) + mainLitLum;
      term1.g = desatFactor * (mainLit.g - mainLitLum) + mainLitLum;
      term1.b = desatFactor * (mainLit.b - mainLitLum) + mainLitLum;

      float3 skinTerm;
      skinTerm.r = skinShadow * skinAmt * _CharacterParams8.x * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.r - 0.25) + 0.25);
      skinTerm.g = skinShadow * skinAmt * _CharacterParams8.y * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.g - 0.25) + 0.25);
      skinTerm.b = skinShadow * skinAmt * _CharacterParams8.z * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.b - 0.25) + 0.25);

      float3 litColor = term1 + skinTerm + subsurfSpec + cp14Term;

      // ==== VFX COLOR ADJUSTMENT (Face: caRimAmt 带 rimModifier) ====
      if (_EnableVFXColorAdjustment > 0.5) {
          float litLum = dot(litColor, LUM);
          float3 adjusted;
          adjusted.r = _ColorAdjustmentContrast * (lerp(litLum, litColor.r, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          adjusted.g = _ColorAdjustmentContrast * (lerp(litLum, litColor.g, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          adjusted.b = _ColorAdjustmentContrast * (lerp(litLum, litColor.b, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          float caRimT = saturate((_ColorAdjustmentRimWidth - NdotV_sat) / max(_ColorAdjustmentRimWidth, 1e-5));
          float caRimSmooth = caRimT * caRimT * (3.0 - 2.0 * caRimT);
          float caRimAmt = rimModifier * caRimSmooth;
          float3 caBrightened = adjusted * _ColorAdjustmentBrightness;
          litColor = lerp(caBrightened, _ColorAdjustmentColorBlend.rgb, _ColorAdjustmentColorBlend.w)
                   + caRimAmt * _ColorAdjustmentRimColor.rgb * _ColorAdjustmentRimIntensity;
      }

      float3 finalColor = litColor / _ExposureParams.x;
      return finalColor;
  }
//- }

//----------------------------------------------------------------------region Part 2/5 Eyes — HGRP_CharacterNPR_Eye_Fix.shader EyeFrag 逐行移植
//- {
  // allowMatcap: Part2(Eyes)=u_UseMatcap, Part5(Eyebrow)=false (眉毛 = Eye shader 无 _MATCAP_ON 路径)。
  // 虹膜视差要在"任意偏移 UV"上重采基础色/不透明度 → 走通道裸 sampler (.tex) [见头部注释]。
  // 物体空间光投影: [H4] 单位矩阵 + FBX 修正。
  float3 shadeEyes(V2F inputs, float3 positionWS, float3 rawN_in, float4 tangentWS, bool isFrontFace, bool allowMatcap) {
      float2 uvBase = GetBaseUV(inputs);
      bool useMatcap = allowMatcap && u_UseMatcap;

      // ---- View direction ----
      float3 V = normalize(camera_pos - positionWS);

      // ---- Normal ----
      float3 rawN = rawN_in;
      float  nInvLen = rsqrt(dot(rawN, rawN));
      float  faceSign = isFrontFace ? 1.0 : (_BackFaceNormalFlip * 2.0 - 1.0);
      float3 N = faceSign * (nInvLen * rawN);

      // ---- Iris pipeline: TBN, parallax, iris mask, matcap normal ----
      float3 T = tangentWS.xyz;
      float  tSign = tangentWS.w;
      float3 B = cross(rawN, T) * tSign;

      float irisMask = 0.0;
      float scaledNx = 0.0;
      float scaledNy = 0.0;
      float matNz = 1.0;
      float2 sampleUV = uvBase;
      float3 lightN = N;
      float3 flatLightN = normalize(float3(N.x, NEAR_ZERO_Y, N.z));
      if (useMatcap) {
          float2 fracUV = frac(uvBase);
          float2 uvFromCenter = fracUV - 0.5;
          float distSq = dot(uvFromCenter, uvFromCenter);
          irisMask = (distSq >= 0.25) ? 1.0 : 0.0;

          float Tv = dot(nInvLen * T, V);
          float Bv = dot(nInvLen * (tSign * cross(rawN, T)), V);
          float Nv = dot(nInvLen * rawN, V);
          float tbvLen = rsqrt(max(Tv * Tv + Bv * Bv + Nv * Nv, 1.175494e-38));
          float parallaxRaw = saturate((distSq - 0.25) * (-5.0));
          float parallaxSmooth = parallaxRaw * parallaxRaw * (3.0 - 2.0 * parallaxRaw);
          sampleUV = float2(
              uvBase.x - (tbvLen * Tv * _EyeParallaxScale) * parallaxSmooth,
              uvBase.y - (tbvLen * Bv * _EyeParallaxScale * 0.25) * parallaxSmooth
          );

          float matNx = fracUV.x * 2.0 - 1.0;
          float matNy = fracUV.y * 2.0 - 1.0;
          matNz = max(sqrt(saturate(1.0 - dot(float2(matNx, matNy), float2(matNx, matNy)))), 1e-16);
          scaledNx = matNx * (-_MatcapNormalScale);
          scaledNy = matNy * (-_MatcapNormalScale);
          float maskFactor = 0.125 * (irisMask - 1.0); // -0.125 inside, 0 outside
          lightN = normalize(T * (scaledNx * maskFactor)
                           + B * (scaledNy * maskFactor)
                           + rawN * lerp(matNz, 1.0, irisMask));
          flatLightN = normalize(float3(lightN.x, NEAR_ZERO_Y, lightN.z));
      }

      // ---- Base color (视差偏移 UV → 通道裸采样) ----
      float4 baseSample;
      baseSample.rgb = basecolor_tex.is_set ? texture(basecolor_tex.tex, sampleUV).rgb : float3(1.0);
      baseSample.a   = opacity_tex.is_set   ? texture(opacity_tex.tex, sampleUV).r    : 1.0;
      float3 albedo = baseSample.rgb * _BaseColor.rgb;
      float  baseAlpha = baseSample.a * _BaseColor.a;

      // ---- 虹膜染色 _EyeTintColor (1.4.4 新增) ----
      // 参考 characternpr_eye b37 _393/_395:圈内(虹膜)才乘 tint,圈外(眼白)
      // 乘 1 —— 参考里这个判定是**无条件**算的,不跟 Matcap 绑定。
      float2 tintFromCenter = frac(uvBase) - 0.5;
      bool tintOutsideIris = dot(tintFromCenter, tintFromCenter) >= 0.25;
      albedo *= tintOutsideIris ? float3(1.0) : _EyeTintColor.rgb;

      // ---- Exposure ----
      float exposure = (_CharacterParams12.w * (1.0 - _EnvironmentGlobalParams0.x)
                       + _EnvironmentGlobalParams0.x) * _ExposureParams.x;

      // ---- Ambient (CP2) ----
      float3 ambCol = _CharacterParams2.xyz;

      // ---- Camera forward ----
      float3 camFwd = GetCamFwd();

      // ---- Metallic workflow ----
      float oneMinusRefl = (1.0 - _Metallic) * 0.96;
      float3 diffColor = oneMinusRefl * albedo;

      // ---- Shadow color ----
      float3 shadowColor;
      if (u_UseShadowLut) {
          shadowColor = oneMinusRefl * SampleShadowLutColor(albedo);
      } else {
          float3 albBright = albedo * _ShadowColorBrightness;
          float shadBright = dot(albBright, LUM);
          shadowColor = oneMinusRefl * (shadBright + _ShadowColorSaturation * (albBright - shadBright));
      }

      // ---- Main light ([H3], Eye 无阴影坐标) ----
      float3 mainLightDir = GetMainLightDir();

      // ---- Adjusted light direction ----
      float3 adjustedLightDir = lerp(mainLightDir, _CharacterParams11.xyz, _CharacterParams1.w);
      float adjXZLen = rsqrt(adjustedLightDir.x * adjustedLightDir.x
                           + adjustedLightDir.z * adjustedLightDir.z
                           + NEAR_ZERO_Y * NEAR_ZERO_Y);
      float adjXZ_x = adjXZLen * adjustedLightDir.x;
      float adjXZ_z = adjXZLen * adjustedLightDir.z;

      // ---- Light color blend (CP5) ----
      float3 blendedLightCol = lerp(v_MainLightColor.rgb, _CharacterParams5.xyz, _CharacterParams12.y);
      float lightLum = dot(blendedLightCol, LUM);

      // ---- Object-space light projection ([H4] 单位 o2w; SP 烘焙网格无需 FBX 旋转修正) ----
      float3 _otwC0 = float3(1.0, 0.0, 0.0);
      float3 _otwC1 = float3(0.0, 1.0, 0.0);
      float3 _otwC2 = float3(0.0, 0.0, 1.0);
      // HGRP 的 float3x3(C0.x,C1.x,C2.x / C0.y,... / C0.z,...) 行优先填充后, 矩阵的"列"恰为
      // otwC0/C1/C2 (基向量列) — GLSL mat3(v0,v1,v2) 按列构造, 直接传基向量即可得到同一矩阵。
      mat3 o2w3x3 = mat3(_otwC0, _otwC1, _otwC2);
      // HLSL mul(v, M) = M^T·v → transpose(M)*v; HLSL mul(M, v) = M·v → M*v
      float3 localLight = transpose(o2w3x3) * adjustedLightDir;
      float localLen = rsqrt(max(dot(localLight, localLight), 1.175494e-38));
      float3 normLocal = localLight * localLen;
      float3 projLight = o2w3x3 * float3(normLocal.x, 0.0, normLocal.z);
      float projLen = rsqrt(max(dot(projLight, projLight), 1.175494e-38));
      projLight *= projLen;

      // ---- Eye blend factor ----
      float3 eyeBlend = float3(1.0);
      if (useMatcap) {
          float insideMask = 1.0 - irisMask;
          float3 highlightTerm;
          if (u_EyeHighLight) {
              highlightTerm = _EyeHighLightColor.rgb * irisMask + insideMask;
          } else {
              highlightTerm = float3(insideMask);
          }
          float scatterBase = 1.0 - baseAlpha;
          eyeBlend = highlightTerm * (_EyeScatteringColor.rgb * baseAlpha + scatterBase);
      }

      // ==== DIFFUSE RAMP ====
      float3 rampCol; float rampA; float viewRampA;
      float rampNdotL = dot(lightN, projLight);
      if (u_UseDiffRamp) {
          float rampInput = clamp(_CharacterParams11.w * _CharacterParams12.x + rampNdotL, -1.0, 1.0) * 0.5 + 0.5;
          float4 rampSmp = SampleRamp(rampInput);
          rampCol = rampSmp.rgb;
          rampA = rampSmp.a;

          float viewRampInput = dot(lightN, camFwd) * 0.5 + 0.5;
          float4 viewRampSmp = SampleRamp(viewRampInput);
          viewRampA = viewRampSmp.a;
      } else {
          // 关 _DIFF_RAMP_ON 时参考走程序化硬 ramp, 与身体同口径但不带 wrap 项
          // (源 characternpr_eye b25 _1107/_1110 与 _1124/_1125·_1126)。
          rampCol = float3(1.0);
          rampA = RampSmooth(max((clamp(_CharacterParams11.w * _CharacterParams12.x + rampNdotL, -1.0, 1.0) - 0.25)
                                 * 1.33333337306976318359375, 0.0));
          viewRampA = RampSmooth(clamp((dot(lightN, camFwd) - 0.25) * 1.33333337306976318359375, 0.0, 1.0));
      }

      float rampChroma = max(rampCol.r, max(rampCol.g, rampCol.b))
                       - min(rampCol.r, min(rampCol.g, rampCol.b));
      float rampChromaInv = 1.0 - rampChroma;
      float minRampA = min(rampA, 1.0);

      // ==== NPR DIFFUSE COMPOSITION ====
      float nprNdotL = saturate(dot(flatLightN, _CharacterParams6.xyz) + _CharacterParams7.x)
                     * _CharacterParams7.y + _CharacterParams7.z;
      float shadowStr = minRampA * _CharacterParams1.y;
      float3 shadAmb = nprNdotL * (shadowStr * (1.0 - ambCol) + ambCol);

      float brightFull = clamp(exposure, 0.0, 1.5);
      float brightAlt = clamp(exposure, 1.25, 1.75);
      float brightness = lerp(brightFull, brightAlt, _CharacterParams1.x);

      float3 lightBlend = blendedLightCol * _CharacterParams12.y + (1.0 - _CharacterParams12.y);

      float3 fullDiff = (shadAmb * brightness * lightBlend
                        + minRampA * (blendedLightCol - lightLum) + lightLum)
                        * _CharacterParams0.y;

      // Shadow desaturation
      float3 albScaled = shadowColor * _CharacterParams0.z;
      float3 albScaled65 = albScaled * 0.65;
      float albScaledLum = dot(albScaled65, LUM);
      float3 desatShad = (albScaled65 - albScaledLum) * 1.2 + albScaledLum;

      float combWeight = saturate(rampA + viewRampA);
      float3 weightedAmb = lerp(desatShad, albScaled, combWeight);
      float3 shadowBlended = lerp(weightedAmb, diffColor * eyeBlend, minRampA);

      float3 rampTinted = shadowBlended * (rampCol * rampChroma + rampChromaInv);

      float shadowLum = dot(shadowBlended, LUM);
      float rampLum = dot(rampTinted, LUM);
      float lumRatio = clamp(shadowLum / max(rampLum, 0.001), 0.0, 1.5);

      float3 nprDiff = rampTinted * lumRatio;

      // ==== MATCAP SAMPLING & BLENDING ====
      float alphaPremult = lerp(1.0, baseAlpha, _AlphaPremultiply);

      float3 matcapContrib = float3(0.0);
      if (useMatcap) {
          float rampBlendFactor = minRampA;
          float matcapIntensity = (rampBlendFactor * (1.0 - _CharacterParams0.z) + _CharacterParams0.z)
                                * (rampBlendFactor * 0.5 + 0.5);

          float3 matcapFullN = normalize(T * scaledNx + B * scaledNy + rawN * matNz);
          // UNITY_MATRIX_V 三行 · v = mat3(view) * v
          float3 viewN = mat3(uniform_camera_view_matrix) * matcapFullN;
          float viewNLen = rsqrt(dot(viewN, viewN));
          float2 matcapUV = float2(viewN.x * viewNLen * 0.5 + 0.5, viewN.y * viewNLen * 0.5 + 0.5);
          float4 matcapSmp = SampleSRGBTex(_MatcapTex, matcapUV); // sRGBTexture=1
          float matcapA = matcapSmp.a;

          matcapContrib = (matcapSmp.rgb * _MatcapColor.a + matcapA * _MatcapColor.rgb)
                        * (matcapIntensity * fullDiff);
      }

      float3 mainLit = nprDiff * fullDiff * alphaPremult + matcapContrib;
      float mainLitLum = dot(mainLit, LUM);

      // Desaturation
      float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);
      float desatFactor = desatAmt * desatAmt + 1.0;
      float3 term1 = desatFactor * (mainLit - mainLitLum) + mainLitLum;

      // ==== SUBSURFACE SPECULAR ====
      float mainNdotL_xz = dot(float3(adjXZ_x, adjXZLen * NEAR_ZERO_Y, adjXZ_z), lightN);
      float wrapNdotL = saturate(0.5 + mainNdotL_xz - 0.5 * mainNdotL_xz * mainNdotL_xz);

      float cfXZLen = rsqrt(camFwd.x * camFwd.x + camFwd.z * camFwd.z);
      float camLightDot = -(adjXZ_x * (cfXZLen * camFwd.x) + adjXZ_z * (cfXZLen * camFwd.z));
      float camLightFacing = (1.0 - _CharacterParams12.x) * saturate(camLightDot);

      float NdotV = dot(V, lightN);
      float edgeT = saturate((-abs(NdotV) + 0.4) * 5.0);
      float edgeFresnel = edgeT * edgeT * (3.0 - 2.0 * edgeT);

      float diffColorLum = dot(diffColor, LUM);
      float brightT = saturate((0.1 - diffColorLum) * 16.666);
      float brightnessGate = brightT * brightT * (3.0 - 2.0 * brightT);

      float3 subsurfSpec = brightnessGate * edgeFresnel * camLightFacing * wrapNdotL
                         * blendedLightCol * max(diffColor, 0.15);

      // ==== CP13 EYE DIRECT TERM ====
      float3 eyeDirect = float3(0.0);
      if (useMatcap) {
          float3 highlightEmission;
          if (u_EyeHighLight) {
              highlightEmission = irisMask * _EyeHighLightColor.rgb;
          } else {
              highlightEmission = float3(0.0);
          }
          eyeDirect = (albedo * _CharacterParams13.x
                     + highlightEmission * _CharacterParams13.y
                     + (baseAlpha * _EyeScatteringColor.rgb) * _CharacterParams13.z)
                     * alphaPremult;
      }

      // ==== FINAL ASSEMBLY ====
      float3 finalColor = (eyeDirect + subsurfSpec + term1) / _ExposureParams.x;
      return finalColor;
  }
//- }

//----------------------------------------------------------------------region Part 3 Hair — HGRP_CharacterNPR_Hair_Fix.shader computeNPRLighting 逐行移植
//- {
  // Diffuse 法线 = SP Normal 通道 (原 _SplitNormalMap.RG 解包导入); Spec 法线 = _SpecNormalMap 参数 (原 .BA 解包); Stroke/Line = 贴图参数。
  // [H11] 皮肤高光的深度边缘检测 → f_HairDepthEdgeMask 直接替代 depthSmooth。
  // 注: HGRP Hair 的 minShadow 不乘 castShadow (charShadow=1 路径), 逐行保留。
  float3 shadeHair(V2F inputs, float3 positionWS, float3 normalWS_raw, float4 tangentWS, float faceSign, float3 albedo, float baseAlpha) {
      float2 uv = GetBaseUV(inputs);
      // ---- Object-to-World origin ([H4]) ----
      float originX = 0.0;
      float originZ = 0.0;

      // ---- View direction ----
      float3 V = normalize(camera_pos - positionWS);

      // ---- MetallicGlossMap ([H1]) ----
      float metallic, specScale, shadowMask, smoothness;
      SampleRMOS(inputs, metallic, specScale, shadowMask, smoothness);

      // ---- Shadow color ----
      float3 shadowColor;
      if (u_UseShadowLut) {
          shadowColor = SampleShadowLutColor(albedo);
      } else {
          shadowColor = ComputeShadowColorBrightSat(albedo);
      }

      // ---- 法线: diffuse 走 SP Normal 通道 (BuildSPInputs 把原 _SplitNormalMap.RG
      //      解包成标准 OpenGL 法线导入); spec 走独立 _SpecNormalMap 参数 (原 .BA 解包)。
      //      decode 与原打包版逐位一致 (dnZ/snZ 由"未缩放"XY 重建, X=R/Y=G 不乘 alpha),
      //      仅换数据来源 — 渲染结果不变, 但 diffuse 法线现在可在 SP 直接绘制/烘焙。----
      float3 nrmWS = normalize(normalWS_raw);
      float3 tanWS = normalize(tangentWS.xyz);
      float3 bitWS = cross(nrmWS, tanWS) * tangentWS.w;

      float3 N;
      float3 specN;
      if (u_UseBumpMap) {
          float3 dnTS = getTSNormal(inputs.sparse_coord); // SP 法线通道 = 解包后的 diffuse 切线法线 [-1,1]
          float dnRawX = dnTS.x;
          float dnRawY = dnTS.y;
          float dnZ = max(sqrt(1.0 - saturate(dnRawX*dnRawX + dnRawY*dnRawY)), 1e-16);
          float dnX = dnRawX * _BumpScale;
          float dnY = dnRawY * _BumpScale;
          N = faceSign * normalize(dnX * tanWS + dnY * bitWS + dnZ * nrmWS);
          if (u_UseSpecBumpMap) {
              float4 snSmp = texture(_SpecNormalMap, uv); // RG = spec 法线 XY (裸 [0,1], 蓝通道仅供 SP 预览)
              float snRawX = snSmp.x * 2.0 - 1.0;
              float snRawY = snSmp.y * 2.0 - 1.0;
              float snZ = max(sqrt(1.0 - saturate(snRawX*snRawX + snRawY*snRawY)), 1e-16);
              float snX = snRawX * _SpecBumpScale;
              float snY = snRawY * _SpecBumpScale;
              specN = normalize(snX * tanWS + snY * bitWS + snZ * nrmWS);
          } else {
              specN = N;
          }
      } else {
          N = faceSign * nrmWS;
          specN = N;
      }

      float3 geomN = faceSign * nrmWS;

      // ---- Flat direction ----
      float fX = positionWS.x - originX;
      float fZ = positionWS.z - originZ;
      float fLen = rsqrt(fX*fX + NEAR_ZERO_Y*NEAR_ZERO_Y + fZ*fZ);
      float3 flatDir = float3(fX*fLen, NEAR_ZERO_Y*fLen, fZ*fLen);

      // ---- Anisotropy tangent ([H4] 单位 o2w; SP 烘焙网格无需 FBX 旋转修正) ----
      // 注: FBX -90 修正会把 otwCol1(发丝方向=世界上方 0,1,0) 换成水平 → anisoDir 错 90°
      //     → 刘海各向异性高光环消失。SP 不需要, 已彻底删除该开关。
      float3 otwCol0 = float3(1.0, 0.0, 0.0);
      float3 otwCol1 = float3(0.0, 1.0, 0.0);
      float3 otwCol2 = float3(0.0, 0.0, 1.0);
      float3 anisoDir = normalize(otwCol0 * _AnisotropyDirX + otwCol1);
      float3 anisoBitan = cross(specN, anisoDir);
      float3 blendedBitan = lerp(anisoBitan, tangentWS.xyz, metallic);
      float tanSignScale = lerp(1.0, tangentWS.w, metallic);
      float3 modBitan = tanSignScale * cross(specN, blendedBitan);

      // ---- Edge fade ----
      float vDotC0 = dot(V, otwCol0);
      float vDotC2 = dot(V, otwCol2);
      float nDotC0 = dot(specN, otwCol0);
      float nDotC2 = dot(specN, otwCol2);
      float nXZLen = rsqrt(nDotC0*nDotC0 + nDotC2*nDotC2);
      float vXZLen = rsqrt(vDotC0*vDotC0 + vDotC2*vDotC2);
      float edgeDot = saturate(dot(float2(nXZLen*nDotC0, nXZLen*nDotC2), float2(vXZLen*vDotC0, vXZLen*vDotC2)));
      float edgeFade = exp2(log2(edgeDot) * _AnisotropyEdgeFade);

      // ---- Exposure / Ambient (CP2) ----
      float exposure = (_CharacterParams12.w * (1.0 - _EnvironmentGlobalParams0.x) + _EnvironmentGlobalParams0.x) * _ExposureParams.x;
      float ambInt = exposure;
      float3 ambCol = _CharacterParams2.xyz;

      // ---- CP10 Height Darken ----
      float darkenOffsetX = lerp(_HairDarkenParams.x, _CharacterParams10.y, _CharacterParams10.x);
      float darkenOffsetZ = lerp(_HairDarkenParams.z, _CharacterParams10.w, _CharacterParams10.x);
      float darkenY = lerp(_HairDarkenParams.y, 0.0, _CharacterParams10.x);
      float darkenMinW = _HairDarkenParams.w;

      float heightT = saturate(((darkenOffsetZ - positionWS.y) + 0.2) * 2.857143);
      float heightSmooth = heightT * heightT * (3.0 - 2.0 * heightT);
      float darkenFactor = max(heightSmooth * darkenY, darkenMinW);

      float darkenSum = darkenFactor + darkenOffsetX;
      float3 darkenedAlbedo;
      float3 darkenedShadowColor;
      float darkenedScale;
      if (0.01 < darkenSum) {
          float dMax = max(darkenFactor, darkenOffsetX);
          float dInv = 1.0 - dMax;
          float dMul = dMax * 0.8 + dInv;
          darkenedAlbedo = albedo * dMul;
          darkenedShadowColor = shadowColor * dMul;
          darkenedScale = dMax * 2.0 + dInv;
      } else {
          darkenedAlbedo = albedo;
          darkenedShadowColor = shadowColor;
          darkenedScale = 1.0;
      }

      // ---- Metallic workflow (Hair: metallic=0 简化) ----
      float3 diffColor = darkenedAlbedo * 0.96;
      float dielSpec = specScale * 0.04;
      float3 shadowDiff = darkenedShadowColor * 0.96;
      float diffColorLum = dot(diffColor, LUM);

      // ---- Main light ([H2][H3]) ----
      float mainLightShadowAtten = 1.0;
      float3 mainLightDir = GetMainLightDir();
      float3 lightCol = v_MainLightColor.rgb;

      // ---- Adjusted light direction ----
      float3 adjustedLightDir = lerp(mainLightDir, _CharacterParams11.xyz, _CharacterParams1.w);
      float adjXZLen = rsqrt(adjustedLightDir.x*adjustedLightDir.x + adjustedLightDir.z*adjustedLightDir.z + NEAR_ZERO_Y*NEAR_ZERO_Y);
      float adjXZ_x = adjXZLen * adjustedLightDir.x;
      float adjXZ_z = adjXZLen * adjustedLightDir.z;

      // ---- Light color blend (CP5) ----
      float3 blendedLightCol = lerp(lightCol, _CharacterParams5.xyz, _CharacterParams12.y);
      float blendedLightInt = lerp(1.0, 1.0, _CharacterParams12.w);

      // ---- Camera forward ----
      float3 camFwd = GetCamFwd();

      // ---- Camera-light facing ----
      float cfXZLen = rsqrt(camFwd.x * camFwd.x + camFwd.z * camFwd.z);
      float camLightDot = saturate(-(adjXZ_x * (cfXZLen * camFwd.x) + adjXZ_z * (cfXZLen * camFwd.z)));
      float camYFade = saturate(2.0 * (0.75 - abs(camFwd.y)));
      float camYSmooth = camYFade * camYFade * (3.0 - 2.0 * camYFade);

      // ==== DIFFUSE RAMP ====
      float geomNdotL = dot(N, adjustedLightDir);
      float wrapAdd = 0.5 - 0.5 * geomNdotL * geomNdotL;
      float camFadeFactor = (1.0 - _CharacterParams12.x) * (camLightDot * camYSmooth);
      float modNdotL = camFadeFactor * wrapAdd + geomNdotL;
      float3 rampCol; float rampA; float rampChroma; float rampChromaInv; float viewRampA;
      if (u_UseDiffRamp) {
          float rampInput = clamp(_CharacterParams11.w * _CharacterParams12.x + modNdotL, -1.0, 1.0) * 0.5 + 0.5;
          float4 rampSmp = SampleRamp(rampInput);
          rampCol = rampSmp.rgb;
          rampA = rampSmp.a;
          rampChroma = max(rampCol.r, max(rampCol.g, rampCol.b)) - min(rampCol.r, min(rampCol.g, rampCol.b));
          rampChromaInv = 1.0 - rampChroma;

          float viewRampU = dot(N, camFwd) * 0.5 + 0.5;
          float4 viewRampSmp = SampleRamp(viewRampU);
          viewRampA = viewRampSmp.a;
      } else {
          // 关 _DIFF_RAMP_ON 时参考走程序化硬 ramp, 与身体同一口径
          // (源 characternpr_hair b101 _2808/_2811 与 _2821/_2824)。
          rampCol = float3(1.0);
          rampA = RampSmooth(max((clamp(_CharacterParams11.w * _CharacterParams12.x + modNdotL, -1.0, 1.0) - 0.25)
                                 * 1.33333337306976318359375, 0.0));
          rampChroma = 0.0;
          rampChromaInv = 1.0;
          viewRampA = RampSmooth(clamp((dot(N, camFwd) - 0.25) * 1.33333337306976318359375, 0.0, 1.0));
      }

      // ---- Shadow terms (charShadow=1: minShadow 不乘 castShadow) ----
      float castShadow = lerp(smoothstep(0.0, 1.0, mainLightShadowAtten), 1.0, _CharacterParams1.z);
      float charShadowMask = shadowMask;
      float minShadow = min(rampA, shadowMask) * 1.0;
      float viewShadowProduct = viewRampA * charShadowMask;

      // ==== NPR DIFFUSE COMPOSITION ====
      float3 albScaled = shadowDiff * _CharacterParams0.z;
      float nprNdotL = saturate(dot(N, _CharacterParams6.xyz) + _CharacterParams7.x) * _CharacterParams7.y + _CharacterParams7.z;
      float shadowStr = minShadow * _CharacterParams1.y;
      float3 shadAmb = nprNdotL * (shadowStr * (1.0 - ambCol) + ambCol);

      float bright065 = min(ambInt * 0.35 + 0.65, 1.5);
      float brightFull = clamp(ambInt, 0.0, 1.5);
      float brightMix = lerp(bright065, clamp(ambInt, 1.25, 1.75), _CharacterParams1.x);
      float3 brightAmb = brightMix * shadAmb * _CharacterParams0.w;
      float lightLum = dot(blendedLightCol * blendedLightInt, LUM);

      float oneMinus12y = 1.0 - _CharacterParams12.y;
      float3 lightBlend = blendedLightCol * _CharacterParams12.y + oneMinus12y;
      float3 fullDiff;
      fullDiff.r = (shadAmb.r * brightFull * lightBlend.r + minShadow * (blendedLightCol.r * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
      fullDiff.g = (shadAmb.g * brightFull * lightBlend.g + minShadow * (blendedLightCol.g * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
      fullDiff.b = (shadAmb.b * brightFull * lightBlend.b + minShadow * (blendedLightCol.b * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;

      float albScaledLum = dot(albScaled * 0.65, LUM);
      float3 desatShad = (albScaled * 0.65 - albScaledLum) * 1.2 + albScaledLum;

      float combWeight = saturate(viewShadowProduct + rampA);
      float3 weightedAmb = lerp(desatShad, albScaled, combWeight);
      float3 shadowBlended = lerp(weightedAmb, diffColor, minShadow);

      float3 rampTinted = shadowBlended * (rampCol * rampChroma + rampChromaInv);

      float3 viewDepShad = viewShadowProduct * ((diffColor - diffColorLum) * 1.2 + diffColorLum - albScaled) + albScaled;

      float shadowLumVal = dot(shadowBlended, LUM);
      float rampLumVal = dot(rampTinted, LUM);
      float lumRatio = clamp(shadowLumVal / max(rampLumVal, 0.001), 0.0, 1.5);

      float3 nprDiff = rampTinted * lumRatio;

      float ambDiffInt = minShadow * (1.0 - _CharacterParams0.z) + _CharacterParams0.z;
      float specAmbInt = ambDiffInt * (minShadow * 0.5 + 0.5);

      // ==== KAJIYA-KAY ANISOTROPIC SPECULAR ====
      float anisoShift1;
      float anisoShift2;
      if (u_StrokeOn) {
          float2 strokeUV = uv * _StrokeMap_ST.xy + _StrokeMap_ST.zw;
          float strokeVal = texture(_StrokeMap, strokeUV).r * 2.0 - 1.0;
          anisoShift1 = strokeVal * _StrokeScale + _AnisotropyValue * 2.0 - 1.0;
          anisoShift2 = strokeVal * _StrokeScale + _AnisotropyValue2 * 2.0 - 1.0;
      } else {
          anisoShift1 = _AnisotropyValue * 2.0 - 1.0;
          anisoShift2 = _AnisotropyValue2 * 2.0 - 1.0;
      }

      float3 shiftedT1 = normalize(specN * anisoShift1 + modBitan);

      float3 worldContrib = otwCol0 * vDotC0 + otwCol1 * adjustedLightDir.y + otwCol2 * vDotC2;
      float3 modL = adjustedLightDir + worldContrib * 2.0;
      float3 H = normalize(normalize(modL) + V);

      float TdotH1 = dot(shiftedT1, H);
      float sinTH1 = max(sqrt(1.0 - TdotH1 * TdotH1), 0.0001);
      float strand1 = saturate(specScale * exp2(log2(sinTH1) * 200.0));

      float edgeFade2 = edgeFade * edgeFade;
      float3 strand1Spec;
      if (u_UseSpecRamp) {
          float specRampV = edgeFade2 * ((TdotH1 > 0.0) ? 1.0 : 0.0);
          float3 specRampSmp = textureLod(_SpecRampMap, float2(strand1, specRampV), 0.0).rgb;
          strand1Spec = edgeFade * (strand1 * specRampSmp);
      } else {
          strand1Spec = float3(1.0) * (edgeFade * strand1);
      }
      float strand1Max = max(strand1Spec.r, max(strand1Spec.g, strand1Spec.b));

      float3 shiftedT2 = normalize(specN * anisoShift2 + modBitan);
      float TdotH2 = dot(shiftedT2, H);
      float sinTH2 = max(sqrt(1.0 - TdotH2 * TdotH2), 0.0001);
      float strand2Exp = trunc(max(1.0 - _AnisotropyRange2, 0.0) * 200.0);
      float strand2Raw = edgeFade * exp2(log2(sinTH2) * strand2Exp);
      float3 strand2Spec = darkenedScale * (strand2Raw * (smoothness * _AnisotropyColor2.rgb));

      // ==== SPECULAR LINE ====
      float lineMod = 1.0;
      if (u_SpecularLine) {
          float2 lineUV = uv * _LineMap_ST.xy + _LineMap_ST.zw;
          float lineMapVal = texture(_LineMap, lineUV).x;

          float lineShift = _LineValue * 2.0 - 1.0;
          float3 shiftedTL = normalize(specN * lineShift + modBitan);
          float TdotHL = dot(shiftedTL, H);
          float sinTHL = max(sqrt(1.0 - TdotHL * TdotHL), 0.0001);

          float procLine = ceil(max(frac(uv.x * _LineAmount) - 0.5, 0.0));
          float lineBlend = (_UseLineMap * (-procLine + (1.0 - lineMapVal)) + procLine) * _LineIntensity + (1.0 - _LineIntensity);

          float lineExp = trunc(max(1.0 - _LineRange, 0.0) * 200.0);
          lineMod = specScale * ((lineBlend + (1.0 - lineBlend) * strand1Max - 1.0) * exp2(log2(sinTHL) * lineExp)) + 1.0;
      }

      // ==== MAIN LIT COMPOSITION ====
      float alphaPremul = mad(baseAlpha, _AlphaPremultiply, 1.0 - _AlphaPremultiply);
      float3 mainLit = fullDiff * nprDiff * alphaPremul;
      float3 lineSatLit = lineMod * mainLit;
      float lineSatLitLum = dot(lineSatLit, LUM);
      float lineSatFactor = lineMod * (1.0 - _LineSaturation) + _LineSaturation;
      float3 diffContrib = (lineSatFactor * (lineSatLit - lineSatLitLum) + lineSatLitLum);

      float3 anisoSpec;
      anisoSpec.r = darkenedScale * ((dielSpec * strand1Spec.r) * _AnisotropyIntensity) * 5.0 + lerp(strand2Spec.r, 0.0, strand1Max);
      anisoSpec.g = darkenedScale * ((dielSpec * strand1Spec.g) * _AnisotropyIntensity) * 5.0 + lerp(strand2Spec.g, 0.0, strand1Max);
      anisoSpec.b = darkenedScale * ((dielSpec * strand1Spec.b) * _AnisotropyIntensity) * 5.0 + lerp(strand2Spec.b, 0.0, strand1Max);
      float3 specContrib = (specAmbInt * fullDiff) * anisoSpec * _CharacterParams13.w;

      float3 combined = diffContrib + specContrib;
      float combinedLum = dot(combined, LUM);
      float desatAmt = clamp(combinedLum - 0.5, 0.0, 0.5);

      // ==== SKIN SPECULAR CP8/CP9 ([H11] 深度边缘 → f_HairDepthEdgeMask) ====
      float cp9x = _CharacterParams9.x;
      float cp9y = _CharacterParams9.y;
      float3 skinDir;
      skinDir.x = -cp9y * camFwd.z;
      skinDir.y = camFwd.z * cp9x;
      skinDir.z = camFwd.x * cp9y - cp9x * camFwd.y;
      skinDir = normalize(skinDir);

      float depthSmooth = f_HairDepthEdgeMask; // [H11] SP 无场景深度

      float skinNdotL = min(charShadowMask, min(shadowMask, saturate(dot(flatDir, skinDir) + 1.0)));
      float skinNdotBN = saturate(dot(skinDir, N));

      float3 skinSpec;
      skinSpec.r = skinNdotL * ((depthSmooth * _CharacterParams8.x) * _CharacterParams8.w) * skinNdotBN * (_CharacterParams9.z * (diffColor.r - 0.25) + 0.25);
      skinSpec.g = skinNdotL * ((depthSmooth * _CharacterParams8.y) * _CharacterParams8.w) * skinNdotBN * (_CharacterParams9.z * (diffColor.g - 0.25) + 0.25);
      skinSpec.b = skinNdotL * ((depthSmooth * _CharacterParams8.z) * _CharacterParams8.w) * skinNdotBN * (_CharacterParams9.z * (diffColor.b - 0.25) + 0.25);

      // ==== SUBSURFACE SPECULAR ====
      float mainNdotL_xz = dot(float3(adjXZ_x, adjXZLen * NEAR_ZERO_Y, adjXZ_z), N);
      float wrapNdotL = saturate(0.5 + mainNdotL_xz - 0.5 * mainNdotL_xz * mainNdotL_xz);
      float camLightFacing = (1.0 - _CharacterParams12.x) * camLightDot;
      float VdotN = dot(V, N);
      float edgeT2 = saturate((-abs(VdotN) + 0.4) * 5.0);
      float edgeFresnel = edgeT2 * edgeT2 * (3.0 - 2.0 * edgeT2);
      float brightT = saturate((diffColorLum - 0.1) * (-16.6667));
      float brightnessGate = brightT * brightT * (3.0 - 2.0 * brightT);
      float3 subsurfLight = blendedLightCol * blendedLightInt;
      float3 subsurfSpec = brightnessGate * (shadowMask * (edgeFresnel * (camLightFacing * (wrapNdotL * subsurfLight)))) * max(diffColor, 0.15);

      // ==== FINAL ASSEMBLY ====
      float desatFactor = desatAmt * desatAmt + 1.0;
      float3 desatCombined = desatFactor * (combined - combinedLum) + combinedLum;
      float3 litColor = desatCombined + skinSpec + subsurfSpec;

      // ==== VFX COLOR ADJUSTMENT ====
      if (_EnableVFXColorAdjustment > 0.5) {
          float NdotV_spec = saturate(dot(N, V));
          float litLum = dot(litColor, LUM);
          float3 adjusted;
          adjusted.r = _ColorAdjustmentContrast * (lerp(litLum, litColor.r, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          adjusted.g = _ColorAdjustmentContrast * (lerp(litLum, litColor.g, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          adjusted.b = _ColorAdjustmentContrast * (lerp(litLum, litColor.b, _ColorAdjustmentSaturation) - 0.5) + 0.5;
          float caRimT = saturate((_ColorAdjustmentRimWidth - NdotV_spec) / max(_ColorAdjustmentRimWidth, 1e-5));
          float caRimSmooth = caRimT * caRimT * (3.0 - 2.0 * caRimT);
          float3 caBrightened = adjusted * _ColorAdjustmentBrightness;
          litColor = lerp(caBrightened, _ColorAdjustmentColorBlend.rgb, _ColorAdjustmentColorBlend.w)
                   + caRimSmooth * _ColorAdjustmentRimColor.rgb * _ColorAdjustmentRimIntensity;
      }

      float3 finalColor = litColor / _ExposureParams.x;
      return finalColor;
  }
//- }

//----------------------------------------------------------------------region Part 4 Fur — HGRP_CharacterNPR_Fur_Fix.shader frag 逐行移植
//- {
  // [H10] 壳层挤出为顶点级多层网格 (UV1.x=层号), SP 不可能 → f_FurShellIdx 预览单壳层。
  // FurDirMap/FurMap/FurDyeMap = 贴图参数 (RGBA 完整 / 需 ST 偏移采样)。
  // Fur 源没有 Shadow LUT 选项 — 阴影色固定走 亮度/饱和度。
  // 反射: HGRP Fur 用 URP 探针 unity_SpecCube0 → SP 环境 envSampleLOD ([H6])。
  float3 shadeFur(V2F inputs, float3 positionWS, float3 normalWS_raw, float4 tangentWS, float faceSign, float3 albedoIn, out float shellAlphaOut) {
      float shellIdx = f_FurShellIdx;
      float2 uv = GetBaseUV(inputs);

      // ---- Object-to-World origin ([H4]) ----
      float originX = 0.0;
      float originZ = 0.0;

      // ---- View direction ----
      float3 V = normalize(camera_pos - positionWS);

      // ---- Base color ----
      float3 albedo = albedoIn;

      // ---- Fur Dye (screen blend) ----
      if (u_FurDyeEnable) {
          float2 dyeUV = float2(
              mad((uv.x - _BaseMap_ST.z) / max(0.001, abs(_BaseMap_ST.x)), _FurDyeMap_ST.x, _FurDyeMap_ST.z),
              mad((uv.y - _BaseMap_ST.w) / max(0.001, abs(_BaseMap_ST.y)), _FurDyeMap_ST.y, _FurDyeMap_ST.w)
          );
          float3 dyeSmp = SRGBToLinear3(texture(_FurDyeMap, dyeUV).rgb); // sRGBTexture=1
          float3 screenBlend = 1.0 - (1.0 - albedo) * (1.0 - dyeSmp);
          albedo = lerp(albedo, screenBlend, _FurDyeIntensity);
      }

      // ---- MetallicGlossMap ([H1]) ----
      float metallic, specScale, shadowMask, smoothness;
      SampleRMOS(inputs, metallic, specScale, shadowMask, smoothness);
      float roughnessRaw = 1.0 - smoothness;

      // ---- Shadow color (Fur: 仅亮度/饱和度) ----
      float3 shadBright = albedo * _ShadowColorBrightness;
      float shadLum = dot(shadBright, LUM);
      float3 shadowColor = _ShadowColorSaturation * (shadBright - shadLum) + shadLum;

      // ---- Normal map (保留 nrmZ_raw 给毛皮 AO) ----
      float nrmZ_raw = 1.0;
      float3 N;
      if (u_UseBumpMap) {
          float3 tsN = getTSNormal(inputs.sparse_coord); // [H8]
          float nrmX_raw = tsN.x;
          float nrmY_raw = tsN.y;
          nrmZ_raw = max(sqrt(1.0 - saturate(nrmX_raw * nrmX_raw + nrmY_raw * nrmY_raw)), 1e-16);
          float nrmX = nrmX_raw * _BumpScale;
          float nrmY = nrmY_raw * _BumpScale;
          float3 nrmWS = normalize(normalWS_raw);
          float3 tanWS = normalize(tangentWS.xyz);
          float3 bitWS = cross(nrmWS, tanWS) * tangentWS.w;
          N = faceSign * normalize(nrmX * tanWS + nrmY * bitWS + nrmZ_raw * nrmWS);
      } else {
          N = faceSign * normalize(normalWS_raw);
      }

      // ---- FurDirMap (sampler 参数, rgba 完整; HGRP 在 ST 后 uv 采样) ----
      float4 furDirSmp = SampleSRGBTex(_FurDirMap, uv); // sRGBTexture=1

      // ---- FurMap sampling ----
      float furShellNoise = (frac(sin(dot(float2(shellIdx, shellIdx), float2(12.9898, 78.233))) * 43758.5469) * 2.0 - 1.0) * _FurNoise * 0.05;
      float2 furDirOffset = float2(
          (furDirSmp.x * 2.0 - 1.0) * _FurDirMapEnable * 0.005 + furShellNoise,
          (furDirSmp.y * 2.0 - 1.0) * _FurDirMapEnable * 0.005 + furShellNoise
      );
      // FurMap UV: 各向同性平铺 (_FurMap_ST.x 用于双轴)
      float2 furSampleUV = float2(
          (uv.x - shellIdx * furDirOffset.x) * _FurMap_ST.x + _FurMap_ST.z,
          (uv.y - shellIdx * furDirOffset.y) * _FurMap_ST.x + _FurMap_ST.w
      );
      float furSample = texture(_FurMap, furSampleUV).x;
      float furDirZ = furDirSmp.z;

      // ---- Fur cutoff + alpha ----
      float cutoff = shellIdx * (_FurCutoffEnd - _FurCutoffStart) + _FurCutoffStart;
      float cutoffSharp = lerp(cutoff, sqrt(cutoff), _FurSharpen);
      float cutLo = max(cutoffSharp - 0.25, 0.0);
      float cutHi = min(cutoffSharp + 0.25, 1.0);
      float furRaw = saturate((furDirZ * furSample - cutLo) / (cutHi - cutLo));
      float furSmooth = furRaw * furRaw * (3.0 - 2.0 * furRaw);

      float isBase = (shellIdx <= 0.01) ? 1.0 : 0.0;
      float furAlphaRaw = isBase * (1.0 - furSmooth) + furSmooth;
      float3 geomN = normalize(normalWS_raw);
      float edgeFactor = (1.0 - shellIdx * shellIdx * shellIdx) + dot(geomN, V) - _FurEdgeFade;
      float shellAlpha = ceil(shellIdx) * (saturate(furAlphaRaw * edgeFactor) - 1.0) + 1.0;
      shellAlphaOut = shellAlpha; // clip(shellAlpha - 0.003) 由 shade() 执行

      // ---- Fur AO ----
      float nrmZ2 = min(nrmZ_raw * 2.0, 1.0);
      float nrmZ2sq = nrmZ2 * nrmZ2;
      float furAO = shellIdx * (1.0 - nrmZ2sq * _FurAO) + nrmZ2sq * _FurAO;
      float furShadowMask = furAO * shadowMask;

      // ---- Character VFX Special: 采样 + Fresnel ([H12] _Time.y → f_VFXTime) ----
      float4 vfxBlendSmp = float4(0.0);
      float vfxTexAlpha = 0.0;
      float3 vfxMainRGB = float3(0.0);
      float vfxFresnelFlipped = 0.0;
      float vfxAlphaBase = 0.0;
      float vfxDissolveDelta = 0.0;
      float vfxDissolveEdge = 0.0;
      if (u_EnableCharacterVFX) {
          float vfxTime = f_VFXTime;

          float2 vfxBlendUV = float2(
              mad(mad(_VFXSpecialParam.z, vfxTime, uv.x), _VFXSpecialBlendTex_ST.x, _VFXSpecialBlendTex_ST.z),
              mad(mad(_VFXSpecialParam.w, vfxTime, uv.y), _VFXSpecialBlendTex_ST.y, _VFXSpecialBlendTex_ST.w)
          );
          vfxBlendSmp = SampleSRGBTex(_VFXSpecialBlendTex, vfxBlendUV); // sRGBTexture=1

          // 参考 _2887:>1.5 走屏幕空间,否则在 UV1/UV2 之间 lerp([H12] 两者都是 uv0)
          float2 vfxBaseUV = uv;
          if (_VFXMainUVSet > 1.5) {
              float depthScale = mad(_VFXScreenUVUseDepth,
                                     max(-(positionWS.z), 0.0) - 1.0, 1.0);        // _2932
              float2 ndc = gl_FragCoord.xy / max(f_ScreenSize, float2(1.0));
              vfxBaseUV = depthScale * (ndc * 2.0 - 1.0);
          }
          float2 vfxDistortUV = vfxBaseUV + vfxBlendSmp.r * _VFXSpecialBlendTexRForDisturb;
          float2 vfxMainUV = float2(
              mad(mad(_VFXSpecialParam.x, vfxTime, vfxDistortUV.x), _VFXSpecialMainTex_ST.x, _VFXSpecialMainTex_ST.z),
              mad(mad(_VFXSpecialParam.y, vfxTime, vfxDistortUV.y), _VFXSpecialMainTex_ST.y, _VFXSpecialMainTex_ST.w)
          );
          float4 vfxMainSmp = SampleSRGBTex(_VFXSpecialMainTex, vfxMainUV); // sRGBTexture=1

          vfxTexAlpha = lerp(vfxMainSmp.a, vfxMainSmp.r, _UseVFXMainTexAsAlpha);
          vfxMainRGB = lerp(vfxMainSmp.rgb, float3(1.0), _UseVFXMainTexAsAlpha);

          // 参考 _3041:FresnelUseNormalMap < 0.5 用几何法线,否则用法线贴图后的 N
          float3 vfxGeomN = (_VFXFresnelUseNormalMap < 0.5) ? normalize(normalWS_raw) : N;
          float vfxFresnel = exp2(log2(saturate(dot(V, vfxGeomN) + _VFXFresnelBias)) * _VFXFresnelPower);
          vfxFresnelFlipped = lerp(1.0 - vfxFresnel, vfxFresnel, _VFXFresnelFlip);

          vfxAlphaBase = _VFXColorAlpha * _VFXColor.a;

          vfxDissolveDelta = vfxBlendSmp.r - (_SpecialDissolveScheduleOffset * 2.02 - 1.01);
          vfxDissolveEdge = saturate(-vfxDissolveDelta);
      }

      // ---- Flat direction ----
      float fX = positionWS.x - originX;
      float fZ = positionWS.z - originZ;
      float fLen = rsqrt(fX * fX + NEAR_ZERO_Y * NEAR_ZERO_Y + fZ * fZ);
      float3 flatDir = float3(fX * fLen, NEAR_ZERO_Y * fLen, fZ * fLen);

      // ---- Exposure / Ambient (CP2) ----
      float exposure = (_CharacterParams12.w * (1.0 - _EnvironmentGlobalParams0.x) + _EnvironmentGlobalParams0.x) * _ExposureParams.x;
      float ambInt = exposure;
      float3 ambCol = _CharacterParams2.xyz;

      // ---- Camera forward ----
      float3 camFwd = GetCamFwd();

      // ---- Metallic workflow ----
      float dielSpec = specScale * 0.04;
      float oneMinusRefl = (1.0 - metallic) * 0.96;
      float3 diffColor = oneMinusRefl * albedo;
      float3 specColor = metallic * (albedo - dielSpec) + dielSpec;
      float3 shadowDiff = oneMinusRefl * shadowColor;

      float roughness = max(roughnessRaw * roughnessRaw, 0.0078125);
      float roughSq4 = roughness * roughness;

      // ---- Main light ([H2][H3]) ----
      float mainLightShadowAtten = 1.0;
      float3 mainLightDir = GetMainLightDir();
      float3 lightCol = v_MainLightColor.rgb;
      float lightInt = 1.0;

      // ---- Adjusted light direction ----
      float3 adjustedLightDir = lerp(mainLightDir, _CharacterParams11.xyz, _CharacterParams1.w);
      float adjXZLen = rsqrt(adjustedLightDir.x * adjustedLightDir.x + adjustedLightDir.z * adjustedLightDir.z + NEAR_ZERO_Y * NEAR_ZERO_Y);
      float adjXZ_x = adjXZLen * adjustedLightDir.x;
      float adjXZ_z = adjXZLen * adjustedLightDir.z;

      // ---- Light color blend (CP5) ----
      float3 blendedLightCol = lerp(lightCol, _CharacterParams5.xyz, _CharacterParams12.y);
      float blendedLightInt = lerp(lightInt, 1.0, _CharacterParams12.w);

      // ---- Camera-light facing ----
      float cfXZLen = rsqrt(camFwd.x * camFwd.x + camFwd.z * camFwd.z);
      float camLightDot = saturate(-(adjXZ_x * (cfXZLen * camFwd.x) + adjXZ_z * (cfXZLen * camFwd.z)));
      float camYFade = saturate(2.0 * (0.75 - abs(camFwd.y)));
      float camYSmooth = camYFade * camYFade * (3.0 - 2.0 * camYFade);

      // ==== FUR NdotL MODIFICATION ====
      float geomNdotL = dot(N, adjustedLightDir);
      float furInv = saturate((1.0 - furSample) * 1.4286);
      float furInvSmooth = furInv * furInv * (3.0 - 2.0 * furInv);
      float furTT = furInvSmooth * camLightDot * _FurNoise * (1.15 - _FurTTIntensity) + _FurTTIntensity;
      float furModNdotL = clamp(furTT * shellIdx + geomNdotL, -1.0, 1.0);

      // ==== DIFFUSE RAMP (fur-modified NdotL) ====
      float wrapAdd = 0.5 - 0.5 * furModNdotL * furModNdotL;
      float camFadeFactor = (1.0 - _CharacterParams12.x) * (camLightDot * camYSmooth);
      float modNdotL = camFadeFactor * wrapAdd + furModNdotL;
      float3 rampCol; float rampA; float rampChroma; float rampChromaInv; float viewRampA;
      if (u_UseDiffRamp) {
          float rampInput = clamp(_CharacterParams11.w * _CharacterParams12.x + modNdotL, -1.0, 1.0) * 0.5 + 0.5;
          float4 rampSmp = SampleRamp(rampInput);
          rampCol = rampSmp.rgb;
          rampA = rampSmp.a;
          rampChroma = max(rampCol.r, max(rampCol.g, rampCol.b)) - min(rampCol.r, min(rampCol.g, rampCol.b));
          rampChromaInv = 1.0 - rampChroma;

          float viewRampU = dot(N, camFwd) * 0.5 + 0.5;
          float4 viewRampSmp = SampleRamp(viewRampU);
          viewRampA = viewRampSmp.a;
      } else {
          // Fur 的 48 个片元变体全部带 _DIFF_RAMP_ON, 参考没有 OFF 变体;
          // Fur 是 characternpr 的一个 keyword 分支, ramp 链结构与身体逐指令同形,
          // 故沿用同 shader 的 OFF 分支 (源 characternpr b363 _2862/_2865 与 _2875/_2878)。
          rampCol = float3(1.0);
          rampA = RampSmooth(max((clamp(_CharacterParams11.w * _CharacterParams12.x + modNdotL, -1.0, 1.0) - 0.25)
                                 * 1.33333337306976318359375, 0.0));
          rampChroma = 0.0;
          rampChromaInv = 1.0;
          viewRampA = RampSmooth(clamp((dot(N, camFwd) - 0.25) * 1.33333337306976318359375, 0.0, 1.0));
      }

      // ---- Shadow terms (charShadow=1, furShadowMask) ----
      float castShadow = lerp(smoothstep(0.0, 1.0, mainLightShadowAtten), 1.0, _CharacterParams1.z);
      float minShadow = min(rampA, furShadowMask) * castShadow;
      float viewShadowProduct = viewRampA * furShadowMask;

      // ==== NPR DIFFUSE COMPOSITION ====
      float3 albScaled = shadowDiff * _CharacterParams0.z;
      float diffColorLum = dot(diffColor, LUM);

      float nprNdotL = saturate(dot(N, _CharacterParams6.xyz) + _CharacterParams7.x) * _CharacterParams7.y + _CharacterParams7.z;
      float shadowStr = minShadow * _CharacterParams1.y;

      float3 shadAmb = nprNdotL * (shadowStr * (1.0 - ambCol) + ambCol);

      float bright065 = min(ambInt * 0.35 + 0.65, 1.5);
      float brightFull = clamp(ambInt, 0.0, 1.5);
      float brightMix = lerp(bright065, clamp(ambInt, 1.25, 1.75), _CharacterParams1.x);
      float3 brightAmb = brightMix * shadAmb * _CharacterParams0.w;

      float lightLum = dot(blendedLightCol * blendedLightInt, LUM);
      float oneMinus12y = 1.0 - _CharacterParams12.y;
      float3 lightBlend = blendedLightCol * _CharacterParams12.y + oneMinus12y;
      float3 fullDiff;
      fullDiff.r = (shadAmb.r * brightFull * lightBlend.r + minShadow * (blendedLightCol.r * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
      fullDiff.g = (shadAmb.g * brightFull * lightBlend.g + minShadow * (blendedLightCol.g * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
      fullDiff.b = (shadAmb.b * brightFull * lightBlend.b + minShadow * (blendedLightCol.b * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;

      float albScaledLum = dot(albScaled * 0.65, LUM);
      float3 desatShad = (albScaled * 0.65 - albScaledLum) * 1.2 + albScaledLum;

      float combWeight = saturate(viewShadowProduct + rampA);
      float3 weightedAmb = lerp(desatShad, albScaled, combWeight);
      float3 shadowBlended = lerp(weightedAmb, diffColor, minShadow);

      float3 viewDepShad = viewShadowProduct * ((diffColor - diffColorLum) * 1.2 + diffColorLum - albScaled) + albScaled;

      float3 rampTinted = shadowBlended * (rampCol * rampChroma + rampChromaInv);

      float shadowLum = dot(shadowBlended, LUM);
      float rampLum = dot(rampTinted, LUM);
      float lumRatio = clamp(shadowLum / max(rampLum, 0.001), 0.0, 1.5);

      float3 nprDiff = rampTinted * lumRatio;

      float ambDiffInt = minShadow * (1.0 - _CharacterParams0.z) + _CharacterParams0.z;
      float specAmbInt = ambDiffInt * (minShadow * 0.5 + 0.5);

      // ==== GGX SPECULAR ====
      float NdotV_spec = saturate(dot(N, V));
      float mainLightY = adjustedLightDir.y;
      float3 camFwdMod = normalize(float3(camFwd.x, mainLightY, camFwd.z));
      float3 H = normalize(V * 3.0 + adjustedLightDir + camFwdMod * 2.0);
      float NdotH = dot(N, H);
      float roughSq = roughness * roughness;
      float denom = (NdotH * roughSq - NdotH) * NdotH + 1.0;
      float denomSq = denom * denom;
      float D_raw = (denomSq != roughSq) ? roughSq / denomSq : 1.0;
      float ggxTerm = clamp(D_raw * 0.5 / (NdotV_spec * 2.0 + roughness + 1e-4) - NEAR_ZERO_Y, 0.0, 20.0);

      // ---- Spec Ramp ----
      float3 specRampColor = specColor;
      float3 specRampEnv = specColor;
      if (u_UseSpecRamp) {
          float specRampPartial = D_raw * (roughSq4 + 1e-4);
          float specRampU = lerp(specRampPartial, NdotV_spec * NdotV_spec, _SpecRampIridescentMode);
          float specRampV = (1.0 - metallic) * roughnessRaw;
          float3 specRampSmp = textureLod(_SpecRampMap, float2(specRampU, specRampV), 0.0).rgb;
          specRampColor = specColor * specRampSmp;
          specRampEnv = lerp(specColor, specRampColor, _SpecRampIridescentMode);
      }

      // AlphaPremultiply
      float alphaPremul = shellAlpha * _AlphaPremultiply + (1.0 - _AlphaPremultiply);

      // Main lit composition
      float3 mainLit = fullDiff * nprDiff * alphaPremul + (specAmbInt * fullDiff) * (ggxTerm * specRampColor) * _CharacterParams13.w;
      float mainLitLum = dot(mainLit, LUM);
      float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);

      // ==== SKIN SPECULAR CP8/CP9 ====
      float cp9x = _CharacterParams9.x;
      float cp9y = _CharacterParams9.y;
      float3 skinDir;
      skinDir.x = -cp9y * camFwd.z;
      skinDir.y = camFwd.z * cp9x;
      skinDir.z = camFwd.x * cp9y - cp9x * camFwd.y;
      skinDir = normalize(skinDir);

      float skinFresnel = 1.0 - abs(dot(V, N));
      float skinLow = _CharacterParams9.w * (-0.6) + 0.8;
      float skinHigh = _CharacterParams9.w * (-0.4) + 0.9;
      float skinT = saturate((skinFresnel - skinLow) / (skinHigh - skinLow));
      float skinSmooth = skinT * skinT * (3.0 - 2.0 * skinT);
      float skinNdotL = saturate(dot(flatDir, skinDir) + 1.0);
      float skinShadow = min(furShadowMask, skinNdotL);
      float skinNdotBN = saturate(dot(skinDir, N));

      float3 skinSpec;
      skinSpec.r = skinShadow * skinSmooth * _CharacterParams8.x * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.r - 0.25) + 0.25);
      skinSpec.g = skinShadow * skinSmooth * _CharacterParams8.y * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.g - 0.25) + 0.25);
      skinSpec.b = skinShadow * skinSmooth * _CharacterParams8.z * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.b - 0.25) + 0.25);

      // ==== SUBSURFACE SPECULAR ====
      float mainNdotL_xz = dot(float3(adjXZ_x, adjXZLen * NEAR_ZERO_Y, adjXZ_z), N);
      float wrapNdotL = saturate(0.5 + mainNdotL_xz - 0.5 * mainNdotL_xz * mainNdotL_xz);
      float camLightFacing = (1.0 - _CharacterParams12.x) * camLightDot;
      float edgeT = saturate((-abs(dot(V, N)) + 0.4) * 5.0);
      float edgeFresnel = edgeT * edgeT * (3.0 - 2.0 * edgeT);
      float brightT = saturate((0.1 - diffColorLum) * 16.666);
      float brightnessGate = (brightT * brightT) * (3.0 - 2.0 * brightT);
      float3 subsurfLight = blendedLightCol * blendedLightInt;
      float3 subsurfSpec = brightnessGate * furShadowMask * edgeFresnel * camLightFacing * wrapNdotL * subsurfLight * max(diffColor, 0.15);

      // ==== CUBEMAP REFLECTION (URP 探针 → SP 环境 [H6]) ====
      float3 reflDir = reflect(-V, N);
      float cubeMip = log2(max(roughnessRaw, 0.001)) * 1.2 + 5.0;
      float3 cubeSample = envSampleLOD(reflDir, cubeMip).rgb;

      float dfgX, dfgY;
      ComputeEnvBRDF(NdotV_spec, roughness, dfgX, dfgY);
      float3 envBRDF = specRampEnv * dfgX + dfgY;
      float totalRefl = dfgX + dfgY;
      float reflBoost = (1.0 - totalRefl) / max(totalRefl, 1e-6);

      float cubeAmbInt = ambDiffInt * (clamp(exposure, 0.5, 1.5) * _CharacterParams0.w);
      float3 cubeRefl = cubeSample * envBRDF * (1.0 + reflBoost * specRampEnv);
      float3 cubemapContrib = cubeAmbInt * cubeRefl * ambCol * _CubemapIntensity;

      // ==== FINAL ASSEMBLY ====
      float desatFactor = desatAmt * desatAmt + 1.0;
      float3 desatMainLit = desatFactor * (mainLit - mainLitLum) + mainLitLum;

      float3 finalColor = desatMainLit + skinSpec + subsurfSpec + cubemapContrib;

      // ---- Character VFX Special: additive color ----
      if (u_EnableCharacterVFX) {
          float vfxBlendFactor = saturate((vfxAlphaBase * vfxTexAlpha + vfxBlendSmp.a) * _VFXBlendTint.a);
          float3 vfxColorTerm = _VFXColorIntensity * _VFXColor.rgb * vfxMainRGB;
          float3 vfxTintTerm = _VFXBlendTint.rgb * _VFXColorIntensity;
          float vfxTintWeight = saturate(vfxBlendFactor * dot(vfxBlendSmp.rgb, float3(0.333)));
          float3 vfxMainColor = lerp(vfxColorTerm, vfxTintTerm, vfxTintWeight);
          float3 vfxDissolvedColor = lerp(vfxMainColor, vfxDissolveEdge * _VFXFresnelColor.rgb * _VFXColorIntensity, vfxDissolveEdge);
          float vfxFresnelAlpha = vfxFresnelFlipped * _VFXFresnelColor.a;
          float vfxDissolveVis = saturate(vfxDissolveDelta);
          float vfxOpacity = saturate(vfxDissolveVis * vfxAlphaBase * vfxTexAlpha)
                           * lerp(1.0, vfxFresnelFlipped, _VFXFresnelAffectOpacity);
          float3 vfxContrib = vfxOpacity * lerp(vfxDissolvedColor, _VFXFresnelColor.rgb, vfxFresnelAlpha);
          finalColor += vfxContrib * alphaPremul;
      }

      finalColor /= _ExposureParams.x;
      return finalColor;
  }
//- }

//----------------------------------------------------------------------region Part 6 VFX — HGRP_CharacterNPR_VFX_Fix.shader frag 逐行移植
//- {
  // [H12] SP 限制: 顶点色=白 / uv1=uv0 / 粒子 CustomData=0 / _Time.y=f_VFXTime /
  //       顶点相机偏移 _VertCameraOffset 为顶点级跳过 / 混合状态固定 over (Additive 无法逐实例切)。
  // UV 流水线 (computeVFXUV) 逐行复制; RotateMat 由角度参数现算 (数学同 Unity 端预计算矩阵)。
  float2 ComputeVFXUV(float2 uv0, float2 uv1, float4 speed,
                      float time, float customData, float rotDeg, float4 st,
                      float2 disturb, float useDisturb)
  {
      float2 uv = uv0 * 1.0 + uv1 * 0.0; // [H12] weights=(1,0): SP 无 UV1
      uv += speed.xy * time + speed.zw * customData;
      float rad = radians(rotDeg);
      float c = cos(rad);
      float s = sin(rad);
      float2 cc = uv - 0.5;
      uv.x = cc.x * c + cc.y * (-s) + 0.5;
      uv.y = cc.x * s + cc.y * c + 0.5;
      uv = uv * st.xy + st.zw;
      uv += disturb * useDisturb;
      return uv;
  }

  float3 shadeVFX(V2F inputs, float3 positionWS, float3 normalWS_raw, float4 tangentWS, bool isFrontFace, out float outAlpha) {
      float time = f_VFXTime;

      float custom1X = 0.0; // [H12]
      float custom1Y = 0.0; // [H12]
      float2 uv0 = inputs.sparse_coord.tex_coord; // VFX 用 raw texcoord0 (HGRP 不乘 _BaseMap_ST)
      float2 uv1 = uv0;     // [H12]
      float4 vertColor = float4(1.0); // [H12]

      // ==== DISTURB ====
      float2 disturb = float2(0.0);
      if (u_VFXUseDisturb) {
          float2 disturbUV = ComputeVFXUV(uv0, uv1, _DisturbUVSpeed1,
                                          time, custom1Y, _DisturbUVRotate1,
                                          _VFXDisturbTex_ST, float2(0.0), 0.0);
          float4 disturbSample = SampleSRGBTex(_VFXDisturbTex, disturbUV); // sRGBTexture=1
          float biDisturb = mad(disturbSample.x, 1.0 + _Bi_Disturb, -_Bi_Disturb);
          bool isNormalMode = (0.0 != _DisturbTex1Normal);
          disturb.x = isNormalMode
              ? mad(biDisturb * disturbSample.w, 2.0, -1.0) * _DisturbUIntensity1
              : biDisturb * _DisturbUIntensity1;
          disturb.y = isNormalMode
              ? mad(disturbSample.y, 2.0, -1.0) * _DisturbUIntensity1
              : biDisturb * _DisturbVIntensity1;
      }

      // ==== MAIN TEX ====
      float2 mainUV = ComputeVFXUV(uv0, uv1, _MainTexUVSpeed,
                                   time, custom1X, _MainTexUVRotate,
                                   _VFXMainTex_ST, disturb, _MainTexUseDisturb);
      float4 mainSample = SampleSRGBTex(_VFXMainTex, mainUV); // sRGBTexture=1

      float mainAlpha = lerp(mainSample.a, mainSample.r, _UseMainTexAsAlpha);
      float baseAlpha = vertColor.a * _TintColor.a * _TintColorAlpha * mainAlpha; // _DisableVertColor 语义=白 [H12]

      // ==== MASK ====
      float maskAlpha = 1.0;
      float3 maskColorFactor = float3(1.0);
      if (u_VFXUseMask) {
          float2 maskUV = ComputeVFXUV(uv0, uv1, _MaskTexUVSpeed,
                                       time, custom1Y, _MaskTexUVRotate,
                                       _VFXMaskTex_ST, disturb, _MaskTexUseDisturb);
          float4 maskSample = SampleSRGBTex(_VFXMaskTex, maskUV); // sRGBTexture=1
          maskAlpha = lerp(maskSample.a, maskSample.r, _UseMaskTexAsAlpha);
          maskColorFactor = lerp(maskSample.rgb, float3(1.0), _UseMaskTexAsAlpha);
      }

      // ==== BASE COLOR ====
      float3 vcAdj = vertColor.rgb; // [H12]
      float3 mainColorFactor = lerp(mainSample.rgb, float3(1.0), _UseMainTexAsAlpha);
      float3 color = vcAdj * _TintColor.rgb * _TintColorIntensity * mainColorFactor * maskColorFactor;

      // ==== BLEND ====
      float combinedAlpha = baseAlpha * maskAlpha;
      if (u_VFXUseBlend) {
          float2 blendUV = ComputeVFXUV(uv0, uv1, _BlendTexUVSpeed,
                                        time, custom1Y, _BlendTexUVRotate,
                                        _VFXBlendTex_ST, disturb, _BlendTexUseDisturb);
          float4 blendSample = SampleSRGBTex(_VFXBlendTex, blendUV); // sRGBTexture=1
          float blendFactor = saturate((combinedAlpha + blendSample.a) * vertColor.a * _BlendTint.a);
          color += blendFactor * blendSample.rgb * vertColor.rgb * _BlendTint.rgb;
      }

      // ==== NORMAL MAP (DXT5nm 解码, 与源一致 — 贴图请用同布局) ====
      float3 faceNormal = normalize(normalWS_raw);
      if (u_VFXEnableNormalMap) {
          float2 normalUV = ComputeVFXUV(uv0, uv1, _NormalMapUVSpeed,
                                         time, custom1Y, _NormalMapUVRotate,
                                         _VFXNormalMap_ST, disturb, _NormalMapUseDisturb);
          float4 nSample = texture(_VFXNormalMap, normalUV);
          float3 normalTS;
          normalTS.x = nSample.r * nSample.a * 2.0 - 1.0;
          normalTS.y = nSample.g * 2.0 - 1.0;
          normalTS.z = max(sqrt(1.0 - min(dot(normalTS.xy, normalTS.xy), 1.0)), 1e-16);
          normalTS.xy *= _NormalScale;
          normalTS = normalize(normalTS);
          float3 T = normalize(tangentWS.xyz);
          float3 Nv = faceNormal;
          float bSign = (tangentWS.w > 0.0) ? 1.0 : -1.0;
          float3 B = bSign * cross(Nv, T);
          faceNormal = normalize(normalTS.x * T + normalTS.y * B + normalTS.z * Nv);
      }
      faceNormal = isFrontFace ? faceNormal : -faceNormal;

      // ==== FRESNEL ====
      float fresnelTerm = 1.0;
      if (u_VFXUseFresnel) {
          float3 viewDir = normalize(camera_pos - positionWS);
          float NdotV = dot(viewDir, faceNormal) + _FresnelBias;
          float fresnel = pow(saturate(NdotV), _FresnelPower);
          float invFresnel = 1.0 - fresnel;
          fresnelTerm = mad(_FresnelFlip, fresnel - invFresnel, invFresnel);
          float fresnelBlend = fresnelTerm * _FresnelColor.a;
          color = lerp(color, _FresnelColor.rgb, fresnelBlend);
      }

      // ==== EXPOSURE ====
      float exposureScale = mad(_ExposureParams.x, _IgnorePostExposure, 1.0 - _IgnorePostExposure);
      color = clamp(color / exposureScale, 0.0, 1000.0);

      // ==== NEAR CAMERA FADE (视图矩阵第三行) ====
      float nearFade = 1.0;
      if (_UseNearCameraFade != 0.0) {
          float4 viewRow2 = float4(
              uniform_camera_view_matrix[0][2],
              uniform_camera_view_matrix[1][2],
              uniform_camera_view_matrix[2][2],
              uniform_camera_view_matrix[3][2]);
          float dist = abs(dot(viewRow2.xyz, positionWS) + viewRow2.w);
          nearFade = saturate((dist - _NearCameraFadeDistanceStart2)
                              / (_NearCameraFadeDistanceEnd2 - _NearCameraFadeDistanceStart2))
                   * saturate((dist - _NearCameraFadeDistanceStart)
                              / (_NearCameraFadeDistanceEnd - _NearCameraFadeDistanceStart));
      }

      // ==== FINAL ALPHA ====
      float fresnelOpacity = lerp(1.0, fresnelTerm, _FresnelAffectOpacity);
      float finalAlpha = saturate(saturate(combinedAlpha) * fresnelOpacity * nearFade);

      // [H12] 原版输出 premultiplied (finalAlpha*color, (1-_BlendMode)*finalAlpha) 配合可切换混合;
      //       SP 固定 over 混合 → 输出 straight color + finalAlpha 预览 (数学到此处为止逐位一致)。
      outAlpha = finalAlpha;
      return color;
  }
//- }

//----------------------------------------------------------------------region Part 7 OverlayShadow — HGRP_CharacterNPR_OverlayShadow_Fix.shader 逐行移植
//- {
  // [H13] 原版是 `Blend Zero SrcColor` 的乘法叠帧 pass (+顶点视空间光向偏移, 跳过):
  //       fb.rgb *= finalColor, 其中 finalColor = lerp(1, blended, finalIntensity)。
  //   SP 只有 over 混合, 无法直接乘帧。等价改写: over 的 lerp(fb, src, a) 要逼近 fb*乘子。
  //   令 src = blended(阴影染色), a = finalIntensity(变暗权重):
  //     over:  fb*(1-a) + blended*a
  //     真乘:  fb*(1 - a*(1-blended)) = fb*(1-a) + fb*blended*a
  //   眼白 fb≈1 → 两式相等 (正是本 pass 的目标区域)。无阴影处 texR=0 → a=0 全透,
  //   不再是挡住眼睛的白片。输出"染色+权重alpha"而非旧版直接吐乘子色。
  float3 shadeOverlayShadow(float3 baseColRGB, float baseAlphaTex, out float outAlpha) {
      float4 tex = float4(baseColRGB, baseAlphaTex);

      // _UseGrayAsAlpha: RGB → 1, Alpha → R
      float3 rgb;
      rgb.r = lerp(tex.r, 1.0, _UseGrayAsAlpha);
      rgb.g = lerp(tex.g, 1.0, _UseGrayAsAlpha);
      rgb.b = lerp(tex.b, 1.0, _UseGrayAsAlpha);
      float alpha = lerp(tex.a, tex.r, _UseGrayAsAlpha);

      float shadowAlpha = alpha * _BaseColor.a;
      float finalIntensity = shadowAlpha * _BaseColor.a; // 变暗权重 = texR·_BaseColor.a²
      float3 blended = rgb * _BaseColor.rgb;             // 阴影染色 (UseGrayAsAlpha=1 → _BaseColor.rgb)

      outAlpha = finalIntensity;
      return blended;
  }
//- }

//----------------------------------------------------------------------region Part 8 ShadowReceiver — characternpr_shadowreceiver.shader 逐行移植
//- {
  // 参考 Sub0_Pass0_Fragment_b3:
  //   sChar  = lerp(1, 角色自阴影可见度, 强度)                       _565
  //   sScene = lerp(1, 主光阴影可见度,   强度)                       _570
  //   t      = saturate(0.95 - min(lerp(sScene,1,关主光), lerp(sChar,1,关自阴影))) * _ShadowColor.a   _582
  //   e      = _CircleFadeSmoothness + _CircleFadeDistance           _590
  //   c      = saturate((|posWS - 片原点| - e) / (_CircleFadeDistance - e))  _610
  //   t      = _CircleFade ? smoothstep(c) * t : t                   _617
  //   M      = lerp(lerp(1, _ShadowColor.rgb, t), _CapsuleAoColor.rgb, ao)  _1059.._1073
  //   帧缓冲 *= M                                    (Blend Zero SrcColor)
  //
  // [H13] 同一条改写:SP 只有 over 混合。把乘子 M 精确拆成 (染色 B, 权重 w):
  //   w = 1 - min3(M),  B = (M - min3(M)) / w    ⇒  lerp(1, B, w) ≡ M(代数恒等,不是近似)
  // over 出来的 fb*(1-w) + B*w 在 fb=1(白地面)时与真乘完全相等,M=1 时 w=0 全透。
  float3 shadeShadowReceiver(float3 positionWS, out float outAlpha) {
      float sChar  = mad(f_ShadowStrength, f_CharacterSelfShadow - 1.0, 1.0);   // _565
      float sScene = mad(f_ShadowStrength, f_SceneShadow - 1.0, 1.0);           // _570
      float t = clamp(0.95 - min(mad(_DisableSceneShadow ? 1.0 : 0.0, 1.0 - sScene, sScene),
                                 mad(_DisableCharacterSelfShadow ? 1.0 : 0.0, 1.0 - sChar, sChar)),
                      0.0, 1.0) * _ShadowColor.a;                               // _582

      float edge = _CircleFadeSmoothness + _CircleFadeDistance;                 // _590
      float3 toCenter = positionWS - f_CircleFadeCenter;                        // _603
      float c = clamp((1.0 / (_CircleFadeDistance - edge)) * (length(toCenter) - edge),
                      0.0, 1.0);                                                // _610
      t = _CircleFade ? (((c * c) * mad(c, -2.0, 3.0)) * t) : t;                // _617

      float3 shadowMul = float3(mad(t, _ShadowColor.r - 1.0, 1.0),
                                mad(t, _ShadowColor.g - 1.0, 1.0),
                                mad(t, _ShadowColor.b - 1.0, 1.0));            // _1059.._1061
      float ao = clamp(f_CapsuleAO, 0.0, 1.0);                                  // _1073
      float3 mul = lerp(shadowMul, _CapsuleAoColor.rgb, ao);

      float lo = min(min(mul.r, mul.g), mul.b);
      float w = 1.0 - lo;
      outAlpha = clamp(w, 0.0, 1.0);
      return (w > 1e-5) ? ((mul - float3(lo)) / w) : float3(0.0);
  }
//- }

//----------------------------------------------------------------------region EndField 后处理 Tonemap (HGRP ACES_modified 1:1)
//- {
  // 源: HG lutbuilder2d Sub0_Pass0_Fragment_b4.hlsl L141-166, 经 AzureNihil
  // Ruri_PostProcess_LutBuilder.shader 的 EndFieldAcesModifiedTonemap 移植, 常量逐字。
  // 入参 = ACEScg/AP1 线性。输出 = sRGB 基线性 [0,1]。
  float3 EndfieldAcesModifiedTonemap(float3 acescg) {
      const float3 ap1LumaWeights = float3(0.2722289860248565673828125, 0.674081981182098388671875, 0.0536894984543323516845703125);

      // 高光去饱和系数 (源 L151: saturate((luma-0.5)*2/3))
      float highlightDesaturation = saturate((dot(acescg, ap1LumaWeights) - 0.5) * 0.666666686534881591796875);

      // 有理拟合曲线 (源 L152-154)
      float3 x = acescg;
      float3 numerator = x * (x * 2.7850849628448486328125 + 0.107772000133991241455078125);
      float3 denominator = x * (x * 2.9360449314117431640625 + 0.887121975421905517578125) + 0.806888997554779052734375;
      float3 fitted = min(max(1.0 / denominator, 9.9999997473787516355514526367188e-05) * numerator, 1.0);

      // ODT 去饱和 0.93 (源 L155-159)
      float fittedLuma = dot(fitted, ap1LumaWeights);
      float3 desaturated = (fitted - fittedLuma) * 0.930000007152557373046875 + fittedLuma;

      // AP1 → sRGB (源 L160-162, 矩阵常量逐字)
      float3 srgb;
      srgb.r = dot(float3(1.70505154132843017578125, -0.621790707111358642578125, -0.083258680999279022216796875), desaturated);
      srgb.g = dot(float3(-0.13025714457035064697265625, 1.140802860260009765625, -0.010548190213739871978759765625), desaturated);
      srgb.b = dot(float3(-0.02400326915085315704345703125, -0.128968775272369384765625, 1.15297162532806396484375), desaturated);

      // 高光向归一化色相收敛 (源 L163-166)
      float maxChannel = max(max(srgb.r, max(srgb.g, srgb.b)), 9.9999997473787516355514526367188e-06);
      return clamp(lerp(srgb, clamp(srgb / maxChannel, 0.0, 1.0), highlightDesaturation), 0.0, 1.0);
  }

  // 调色中性时 HG LutBuilder 链 = sRGB线性 → unity_to_ACES→ACEScg (合并即 sRGB_2_AP1)
  // → ACES_modified 尾段。此矩阵为上面 AP1→sRGB 的精确数值逆 (往返误差 ~1e-16)。
  float3 ApplyEndfieldTonemap(float3 srgbLinear) {
      if (!u_UseEndfieldTonemap) return srgbLinear;
      float3 c = srgbLinear * f_TonemapExposure;
      float3 acescg;
      acescg.r = dot(float3(0.6130973255536435, 0.3395228813214228, 0.0473793330068586), c);
      acescg.g = dot(float3(0.0701942176296659, 0.9163555605787149, 0.0134523438298940), c);
      acescg.b = dot(float3(0.0206156004863253, 0.1095698373575739, 0.8698151534347436), c);
      return EndfieldAcesModifiedTonemap(acescg);
  }
//- }

//----------------------------------------------------------------------region Shader 入口 — 按 u_CharaPart 分发
//- {
  void shade(V2F inputs)
  {
      // ---- 基础色 / Alpha (引擎通道, sparse 1:1 [H7]) ----
      float3 baseCol = getBaseColor(basecolor_tex, inputs.sparse_coord);
      float baseAlphaTex = getOpacity(opacity_tex, inputs.sparse_coord);

      // ---- 朝向 / TBN 手性 ----
      bool isFrontFace = (uniform_facing >= 0);
      // _Cull:参考里是 `Cull [_Cull]` 的 pass 状态,Painter 管不到渲染状态,
      // 但同一个可见结果在片元里做得到。值就是 Unity 的 Cull 枚举
      // (0=Off 1=Front 2=Back),inspector 上那三个标签说的是**渲染哪一面**,
      // 所以默认 2 = Cull Back = 只画正面。
      // [H21] 描边开着时,背面不再丢弃 —— 参考的 Pass1 正是 `Cull Front` 把背面
      //       画成描边,两个 pass 合起来两面都画。这里由同一个片元程序承担。
      bool outlineFrag = u_EnableOutline && !isFrontFace;
      if (!outlineFrag
          && ((_Cull > 0.5 && _Cull < 1.5 && isFrontFace)    // Cull Front
              || (_Cull >= 1.5 && !isFrontFace))) {          // Cull Back
          discard;
      }

      // DITHER_SPHERE:参考 _2581.._2631
      //   toFocus = normalize(camera - focus - (0,1,0))
      //   t       = saturate((1 - saturate(dot(N, toFocus)) - Radius) / Smoothness)
      //   a       = lerp(smoothstep(t), 1, ditherAmount)   [H18]
      //   a < 0.99 -> discard
      if (u_DitherSphere) {
          float3 dsFocus = f_DitherSphereFocus.xyz;
          float3 dsDir = normalize(float3(camera_pos.x - dsFocus.x,
                                          (camera_pos.y - dsFocus.y) - 1.0,
                                          camera_pos.z - dsFocus.z));           // _2585
          float dsT = clamp((1.0 - clamp(dot(normalize(inputs.normal), dsDir), 0.0, 1.0)
                             - _DitherSphereRadius) / max(_DitherSphereSmoothness, 1e-5),
                            0.0, 1.0);                                          // _2604
          float dsSmooth = (dsT * dsT) * mad(dsT, -2.0, 3.0);
          float dsAlpha = mad(1.0 - f_DitherAmount, 1.0 - dsSmooth, dsSmooth);  // _2631
          if (dsAlpha < 0.99) discard;
      }
      float faceSign = isFrontFace ? 1.0 : (_BackFaceNormalFlip * 2.0 - 1.0);
      float tSign = (dot(cross(normalize(inputs.normal), normalize(inputs.tangent)), normalize(inputs.bitangent)) < 0.0) ? -1.0 : 1.0;
      float4 tangentWS = float4(inputs.tangent, tSign);

      float3 color = float3(0.0);
      float outAlpha = 1.0;
      bool skipDefaultClip = false;
      bool forceAlphaBlend = false; // 部位本身就是半透明(如 OverlayShadow 乘法叠帧), 无视 u_AlphaBlend
      bool skipTonemap = false;     // 输出是乘子而非光照色的 pass 不过后处理

      if (u_CharaPart == 1) {
          // ---- Face: Emotion 混合在进光照前完成 (HGRP Skin frag L687-702) ----
          float3 albedo;
          if (u_UseEmotionMap) {
              float halfIdx = 0.5 * float(_EmotionIndex);
              float fracIdx = frac(halfIdx);
              float2 uvE = GetBaseUV(inputs);
              float2 emotionUV = float2(
                  uvE.x * 0.5 + fracIdx,
                  uvE.y * 0.5 + floor(halfIdx) * 0.5
              );
              float4 emotionSmp = SampleSRGBTex(_EmotionMap, emotionUV); // sRGBTexture=1
              float emotionT = emotionSmp.a * _EmotionBlend;
              albedo.r = mad(emotionT, emotionSmp.r - baseCol.r * _BaseColor.r, baseCol.r * _BaseColor.r);
              albedo.g = mad(emotionT, emotionSmp.g - baseCol.g * _BaseColor.g, baseCol.g * _BaseColor.g);
              albedo.b = mad(emotionT, emotionSmp.b - baseCol.b * _BaseColor.b, baseCol.b * _BaseColor.b);
          } else {
              albedo = baseCol * _BaseColor.rgb;
          }
          if (outlineFrag) albedo = ComputeOutlineAlbedo(baseCol * _BaseColor.rgb); // [H21]
          color = shadeFace(inputs, inputs.position, inputs.normal, tangentWS, faceSign, albedo, baseAlphaTex);
          outAlpha = 1.0; // HGRP Skin ForwardLit 输出 alpha=1
          skipDefaultClip = true; // characternpr_skin 的 Pass0 从不裁切
      }
      else if (u_CharaPart == 2 || u_CharaPart == 5) {
          // ---- Eyes / Eyebrow (Eyebrow = 无 Matcap 路径) ----
          color = shadeEyes(inputs, inputs.position, inputs.normal, tangentWS, isFrontFace, u_CharaPart == 2);
          outAlpha = 1.0; // HGRP Eye 输出 alpha=1
          // characternpr_eye 的 Pass0 从不裁切:_BaseMap.a 是虹膜散射遮罩,
          // 当不透明度用会把眼白/虹膜整片打穿(SV_Target.w 参考里根本没写)。
          skipDefaultClip = true;
      }
      else if (u_CharaPart == 3) {
          // ---- Hair ----
          float3 albedo = baseCol * _BaseColor.rgb;
          float baseAlpha = baseAlphaTex * _BaseColor.a;
          // 参考 characternpr_hair b117 _464/_493:两段发色染色,遮罩就是 baseAlpha
          albedo *= lerp(_HairAddTintColor.rgb, _HairBaseTintColor.rgb, baseAlpha);
          if (outlineFrag) albedo = ComputeOutlineAlbedo(baseCol * _BaseColor.rgb); // [H21]
          color = shadeHair(inputs, inputs.position, inputs.normal, tangentWS, faceSign, albedo, baseAlpha);
          outAlpha = u_AlphaBlend ? baseAlphaTex : 1.0; // 原: (_SurfaceType==1) ? baseSample.a : 1
      }
      else if (u_CharaPart == 4) {
          // ---- Fur ([H10] 单壳层预览) ----
          float3 albedo = baseCol * _BaseColor.rgb;
          float shellAlpha;
          color = shadeFur(inputs, inputs.position, inputs.normal, tangentWS, faceSign, albedo, shellAlpha);
          if (shellAlpha - 0.003 < 0.0) discard; // 原 clip(shellAlpha - 0.003)
          outAlpha = shellAlpha;
          skipDefaultClip = true;
      }
      else if (u_CharaPart == 6) {
          // ---- VFX ([H12]) ----
          color = shadeVFX(inputs, inputs.position, inputs.normal, tangentWS, isFrontFace, outAlpha);
          skipDefaultClip = true;
      }
      else if (u_CharaPart == 7) {
          // ---- OverlayShadow ([H13] 乘法叠帧 → over 近似; 强制半透明, 否则白片挡眼) ----
          color = shadeOverlayShadow(baseCol, baseAlphaTex, outAlpha);
          forceAlphaBlend = true;
          skipDefaultClip = true;
      }
      else if (u_CharaPart == 8) {
          // ---- ShadowReceiver (接影地面片; 同 [H13] 的乘法叠帧改写) ----
          color = shadeShadowReceiver(inputs.position, outAlpha);
          forceAlphaBlend = true;
          skipDefaultClip = true;
          skipTonemap = true; // 参考这个 pass 吐的是乘子, 不是被后处理的光照色
      }
      else {
          // ---- Standard (默认 / Part 0) ----
          float3 albedo = baseCol * _BaseColor.rgb;
          if (outlineFrag) albedo = ComputeOutlineAlbedo(albedo); // [H21]
          float3 shadowColorUnused;
          color = shadeStandard(inputs, inputs.position, inputs.normal, tangentWS, faceSign, albedo, baseAlphaTex, shadowColorUnused);
          // 参考 _1824:alpha = smoothstep(viewFade) * ExtraAlphaMask.a * _BaseColor.a
          float vfAlpha = 1.0;
          if (_ViewFade > 0.0) {
              float3 vfN = normalize(inputs.normal);
              float3 vfV = normalize(camera_pos - inputs.position);
              float vfBias = 0.2 - _ViewFade;                                  // _1811
              float vfT = clamp((vfBias + min(abs(dot(vfV, vfN)), 1.0))
                                / (vfBias + _ViewFade), 0.0, 1.0);             // _1816
              vfAlpha = (vfT * vfT) * mad(vfT, -2.0, 3.0);
          }
          if (u_ExtraAlphaMask) {
              vfAlpha *= texture(_ExtraAlphaMask, GetBaseUV(inputs)).a;         // _349.w
          }
          outAlpha = (u_AlphaBlend ? baseAlphaTex : 1.0) * vfAlpha; // 原: (_SurfaceType==1) ? baseSample.a : 1
          if (u_AlphaSceneDepthFade) {
              // 参考 _1874/_1881(liquidag)
              float sdFade = 1.0 - exp2(abs(f_SceneDepthDistance) * (-_DepthFadeExp));
              outAlpha = max(max(sdFade, 0.0) * _DepthFadeValue,
                             baseAlphaTex * _BaseColor.a);
          }
          // [H5] ApplyCustomAO: 跳过
      }

      // ---- Alpha 输出 / 裁切 (与旧版工作流一致) ----
      if (u_AlphaBlend || forceAlphaBlend) {
          alphaOutput(outAlpha);
      } else if (u_AlphaClip && !skipDefaultClip) {
          // 参考 characternpr_hair b*:clip(baseAlpha * _BaseColor.a - _AlphaClipThreshold)
          float clipA = baseAlphaTex * _BaseColor.a;
          if (clipA < _AlphaClipThreshold) discard;
      }

      // ---- EndField 后处理 tonemap (HGRP ACES_modified; 屏幕链对所有 part 一致) ----
      if (!skipTonemap) color = ApplyEndfieldTonemap(color);

      diffuseShadingOutput(color);
  }
//- }
