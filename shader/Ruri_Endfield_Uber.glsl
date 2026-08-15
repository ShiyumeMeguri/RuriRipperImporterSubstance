//============================================================================
// Ruri_Endfield_Uber.glsl —— 生成物,勿手改(真源 = Ruri.RenderPipelines.Generator C# 材质模块)
// 风格 = Endfield;输入投影清单 = Ruri_Endfield_Uber.manifest.json(导入器与本文件同源同构)
//============================================================================

//----------------------------------------------------------------------region 面板参数(生成)
//: param custom { "default": 0, "label": "Endfield Part", "widget": "combobox", "values": { "0 Standard": 0, "1 Face": 1, "2 Eyes": 2, "3 Hair": 3, "4 Fur": 4, "5 Eyebrow": 5, "6 VFX": 6, "7 OverlayShadow": 7, "8 LiquidAg": 8 }, "group": "0 部位" }
uniform_specialization int _CharaPartID;
//: param custom { "default": false, "label": "_NORMALMAP", "group": "1 变体开关" }
uniform_specialization bool _NORMALMAP;
const float HALF_MIN = 6.1035156E-05;
//: param custom { "default": 0, "label": "Alpha Premultiply", "group": "参数" }
uniform float _AlphaPremultiply;
//: param custom { "default": [0, 0, 0, 1], "label": "Anisotropy Color2", "widget": "color", "group": "头发高光/描线" }
uniform float4 _AnisotropyColor2;
//: param custom { "default": 0, "label": "Anisotropy Direction X", "min": -1, "max": 1, "group": "头发高光/描线" }
uniform float _AnisotropyDirX;
//: param custom { "default": 1, "label": "Anisotropy Edge Fade", "min": 0.01, "max": 10, "group": "头发高光/描线" }
uniform float _AnisotropyEdgeFade;
//: param custom { "default": 1, "label": "Anisotropy Intensity", "min": 0, "max": 3, "group": "头发高光/描线" }
uniform float _AnisotropyIntensity;
//: param custom { "default": 0, "label": "Anisotropy Range2", "min": -1, "max": 1, "group": "头发高光/描线" }
uniform float _AnisotropyRange2;
//: param custom { "default": 0.35, "label": "Anisotropy Value", "min": 0, "max": 1, "group": "头发高光/描线" }
uniform float _AnisotropyValue;
//: param custom { "default": 0.4, "label": "Anisotropy Value2", "min": 0, "max": 1, "group": "头发高光/描线" }
uniform float _AnisotropyValue2;
//: param custom { "default": false, "label": "Avatar System Input", "group": "捏人染色" }
uniform bool _AvatarCustomizeEnable;
//: param custom { "default": 0, "label": "Back Face Normal Flip", "group": "参数" }
uniform float _BackFaceNormalFlip;
//: param custom { "default": [1, 1, 1, 1], "label": "Color", "widget": "color", "group": "参数" }
uniform half4 _BaseColor;
uniform half4 _BaseMap_ST;
//: param custom { "default": 0, "label": "Disturbe in 2 Direction", "group": "特效贴图/流动" }
uniform float _Bi_Disturb;
//: param custom { "default": 0, "label": "Blend Type", "group": "特效贴图/流动" }
uniform float _BlendMode;
//: param custom { "default": [1, 0, 0, 1], "label": "BlendTexUVRotateMat", "group": "特效贴图/流动" }
uniform float4 _BlendTexUVRotateMat;
//: param custom { "default": [0, 0, 0, 0], "label": "BlendTexUVSpeed(XY:By Time,ZW:By Custom1.Y)", "group": "特效贴图/流动" }
uniform float4 _BlendTexUVSpeed;
//: param custom { "default": [1, 0, 0, 0], "label": "'_BlendTexUVWeights'", "group": "特效贴图/流动" }
uniform float4 _BlendTexUVWeights;
//: param custom { "default": 0, "label": "Blend Tex Use Disturb", "min": 0, "max": 1, "group": "特效贴图/流动" }
uniform float _BlendTexUseDisturb;
uniform float4 _BlendTex_ST;
//: param custom { "default": [1, 1, 1, 1], "label": "BlendTint", "widget": "color", "group": "特效贴图/流动" }
uniform float4 _BlendTint;
//: param custom { "default": 1, "label": "Normal Scale", "group": "参数" }
uniform half _BumpScale;
//: param custom { "default": [0, 0.9, 0.8, 0.8], "label": "CP0 (.y=主光系数 .z=环境阴影系数 .w=环境光系数)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams0;
//: param custom { "default": [0, 0, 1, 0], "label": "CP1 (.x=brightMix .y=shadowStr .z=忽略主光阴影 .w=方向覆写量)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams1;
//: param custom { "default": [0, 0, 0, 0], "label": "CP10 (height darken control)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams10;
//: param custom { "default": [-0.433, 0.5, 0.75, -0.4], "label": "CP11 (方向覆写 xyz + .w=明暗交界线偏移)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams11;
//: param custom { "default": [1, 0, 0, 0], "label": "CP12 (.x=灯光手动控制 .y=主光色覆写量 .z=shadowGate .w=exposureBlend)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams12;
//: param custom { "default": [0, 0, 0, 1], "label": "CP13 (.w=GGX specular toggle)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams13;
//: param custom { "default": [0, 0, 0, 0], "label": "CP14 (secondary spec color rgb + .w=intensity)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams14;
//: param custom { "default": [0, 0, 0, 0], "label": "CP15 (.z=SDF secondary threshold)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams15;
//: param custom { "default": [0.7830188, 0.8293082, 1, 0], "label": "CP2 (阴影色倾向 rgb，皮肤以外)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams2;
//: param custom { "default": [1, 0.78114647, 0.68490565, 0], "label": "CP3 (阴影色倾向 rgb，皮肤)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams3;
//: param custom { "default": [1, 1, 1, 1], "label": "CP4 (主光自定义颜色 rgb，皮肤)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams4;
//: param custom { "default": [1, 1, 1, 1], "label": "CP5 (主光自定义颜色 rgb，皮肤以外)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams5;
//: param custom { "default": [0, 1, 4.371139E-08, 0], "label": "CP6 (环境光方向 = charGlobalAmbientParam0)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams6;
//: param custom { "default": [0.15, 1.5, 0.5, 0], "label": "CP7 (环境光系数 = charGlobalAmbientParam1)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams7;
//: param custom { "default": [0, 0, 0, 1], "label": "CP8 (skin spec color rgb + .w=intensity)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams8;
//: param custom { "default": [0, 1, 0, 0.4], "label": "CP9 (skin spec .xy=dir .z=tint .w=width)", "group": "引擎全局 CP" }
uniform float4 _CharacterParams9;
//: param custom { "default": false, "label": "ClearCoat Effect", "group": "清漆" }
uniform bool _ClearCoat;
//: param custom { "default": [1, 1, 1, 1], "label": "ClearCoat Color", "widget": "color", "group": "清漆" }
uniform float4 _ClearCoatColor;
//: param custom { "default": 0, "label": "ClearCoat Metallic", "min": 0, "max": 1, "group": "清漆" }
uniform float _ClearCoatMetallic;
//: param custom { "default": 0, "label": "ClearCoat Normal", "group": "清漆" }
uniform float _ClearCoatNormalMode;
//: param custom { "default": 0.95, "label": "ClearCoat Smoothness", "min": 0, "max": 1, "group": "清漆" }
uniform float _ClearCoatSmoothness;
//: param custom { "default": 1, "label": "Color Adjustment Brightness", "min": 0.5, "max": 1.5, "group": "特效调色" }
uniform float _ColorAdjustmentBrightness;
//: param custom { "default": [1, 1, 1, 0], "label": "Color Adjustment Color Blend", "widget": "color", "group": "特效调色" }
uniform float4 _ColorAdjustmentColorBlend;
//: param custom { "default": 1, "label": "Color Adjustment Contrast", "min": 0, "max": 2, "group": "特效调色" }
uniform float _ColorAdjustmentContrast;
//: param custom { "default": [1, 1, 1, 1], "label": "Color Adjustment Rim Color", "widget": "color", "group": "特效调色" }
uniform float4 _ColorAdjustmentRimColor;
//: param custom { "default": 4, "label": "Color Adjustment Rim Intensity", "min": 0, "max": 10, "group": "特效调色" }
uniform float _ColorAdjustmentRimIntensity;
//: param custom { "default": 0.35, "label": "Color Adjustment Rim Width", "min": 0, "max": 1, "group": "特效调色" }
uniform float _ColorAdjustmentRimWidth;
//: param custom { "default": 1, "label": "Color Adjustment Saturation", "min": 0, "max": 2, "group": "特效调色" }
uniform float _ColorAdjustmentSaturation;
//: param custom { "default": 1, "label": "Cubemap Intensity", "group": "参数" }
uniform float _CubemapIntensity;
//: param custom { "default": 0.5, "label": "Alpha Cutoff", "min": 0, "max": 1, "group": "参数" }
uniform half _Cutoff;
//: param custom { "default": 0, "label": "Disable VertColor", "group": "特效贴图/流动" }
uniform float _DisableVertColor;
//: param custom { "default": 0, "label": "Disturb Tex1 is Normal", "group": "特效贴图/流动" }
uniform float _DisturbTex1Normal;
uniform float4 _DisturbTex1_ST;
//: param custom { "default": 0, "label": "UIntensity1", "group": "特效贴图/流动" }
uniform float _DisturbUIntensity1;
//: param custom { "default": [1, 0, 0, 1], "label": "DisturbUVRotateMat", "group": "特效贴图/流动" }
uniform float4 _DisturbUVRotateMat1;
//: param custom { "default": [0, 0, 0, 0], "label": "DisturbUVSpeed(XY:By Time,ZW:By Custom1.Y)", "group": "特效贴图/流动" }
uniform float4 _DisturbUVSpeed1;
//: param custom { "default": [1, 0, 0, 0], "label": "'_DisturbTexUVWeights'", "group": "特效贴图/流动" }
uniform float4 _DisturbUVWeights1;
//: param custom { "default": 0, "label": "VIntensity1(Unused In Normal)", "group": "特效贴图/流动" }
uniform float _DisturbVIntensity1;
//: param custom { "default": 1, "label": "Emission Brightness", "group": "自发光" }
uniform float _EmissionBrightness;
//: param custom { "default": [0, 0, 0, 1], "label": "Emission Color", "widget": "color", "group": "参数" }
uniform float4 _EmissionColor;
//: param custom { "default": 1, "label": "Emotion Blend", "min": 0, "max": 1, "group": "脸部 SDF/表情" }
uniform half _EmotionBlend;
//: param custom { "default": 0, "label": "Emotion Index", "min": 0, "max": 3, "group": "脸部 SDF/表情" }
uniform half _EmotionIndex;
//: param custom { "default": false, "label": "Character VFX", "group": "角色 VFX" }
uniform bool _EnableCharacterVFX;
//: param custom { "default": 0, "label": "Foliage Normal Map Enable", "group": "参数" }
uniform half _EnableNormalMap;
//: param custom { "default": 0, "label": "VFX Color Adjustment", "group": "特效调色" }
uniform float _EnableVFXColorAdjustment;
uniform half4 _EnvironmentGlobalParams0;
//: param custom { "default": [1, 0, 0, 0], "label": "ExposureParams", "group": "引擎全局 CP" }
uniform float4 _ExposureParams;
//: param custom { "default": false, "label": "Eye High Light", "group": "眼睛 Matcap" }
uniform bool _EyeHighLight;
//: param custom { "default": [2, 2, 2, 1], "label": "High Light Color", "widget": "color", "group": "眼睛 Matcap" }
uniform float4 _EyeHighLightColor;
//: param custom { "default": [1, 1, 1, 1], "label": "Scattering Color", "widget": "color", "group": "眼睛 Matcap" }
uniform float4 _EyeScatteringColor;
//: param custom { "default": [1, 1, 1, 1], "label": "Eye Tint Color", "widget": "color", "group": "眼睛 Matcap" }
uniform float4 _EyeTintColor;
//: param custom { "default": 0, "label": "FBX -90 Z Rotation Fix (OTW col0/col1 swap)", "group": "参数" }
uniform float _FBXRotationFix;
//: param custom { "default": [0, 0, 1, 0], "label": "Face Forward (World)", "group": "朝向与压暗" }
uniform float4 _FaceForward;
//: param custom { "default": false, "label": "Use Face Highlight Map", "group": "脸部 SDF/表情" }
uniform bool _FaceHighlightMap;
//: param custom { "default": [1, 0, 0, 0], "label": "Face Right (World)", "group": "朝向与压暗" }
uniform float4 _FaceRight;
//: param custom { "default": 1, "label": "Face Rim Scale (SDF Area)", "min": 0, "max": 1.5, "group": "脸部 SDF/表情" }
uniform half _FaceRimOffScale;
//: param custom { "default": 1, "label": "菲涅尔影响透明度系数", "min": 0, "max": 1, "group": "参数" }
uniform half _FresnelAffectOpacity;
//: param custom { "default": 0, "label": "菲涅尔偏移", "min": -1, "max": 2, "group": "参数" }
uniform half _FresnelBias;
//: param custom { "default": [1, 1, 1, 1], "label": "Fresnel Color", "widget": "color", "group": "参数" }
uniform float4 _FresnelColor;
//: param custom { "default": 0.001, "label": "翻转菲涅尔区域", "group": "参数" }
uniform half _FresnelFlip;
//: param custom { "default": 1, "label": "Fresnel Power", "min": 1, "max": 100, "group": "参数" }
uniform half _FresnelPower;
//: param custom { "default": 1, "label": "发根AO", "min": 0, "max": 1, "group": "皮毛" }
uniform float _FurAO;
//: param custom { "default": 1, "label": "发尾CutOff", "min": 0, "max": 1, "group": "皮毛" }
uniform float _FurCutoffEnd;
//: param custom { "default": 0, "label": "发根CutOff", "min": 0, "max": 1, "group": "皮毛" }
uniform float _FurCutoffStart;
//: param custom { "default": 0, "label": "使用毛发方向贴图(RG)", "group": "皮毛" }
uniform float _FurDirMapEnable;
//: param custom { "default": false, "label": "使用皮毛染色功能", "group": "皮毛" }
uniform bool _FurDyeEnable;
//: param custom { "default": 1, "label": "染色强度", "min": 0, "max": 1, "group": "皮毛" }
uniform float _FurDyeIntensity;
uniform float4 _FurDyeMap_ST;
//: param custom { "default": 0, "label": "边缘平滑过度", "min": 0, "max": 1, "group": "皮毛" }
uniform float _FurEdgeFade;
uniform float4 _FurMap_ST;
//: param custom { "default": 0, "label": "皮毛叠加噪声", "group": "皮毛" }
uniform float _FurNoise;
//: param custom { "default": 0, "label": "皮毛尖锐", "group": "皮毛" }
uniform float _FurSharpen;
//: param custom { "default": 0.5, "label": "直射光透光强度", "min": 0, "max": 1, "group": "皮毛" }
uniform float _FurTTIntensity;
//: param custom { "default": [0, 0, 0, 0], "label": "Hair Darken (x=offsetX y=darken z=offsetZ w=minDarken)", "group": "朝向与压暗" }
uniform float4 _HairDarkenParams;
//: param custom { "default": [0.04, -0.01, 0, 0], "label": "HighlightMap Vector", "group": "脸部 SDF/表情" }
uniform float4 _HighlightMapVector;
//: param custom { "default": 1, "label": "Ignore Post Exposure", "group": "特效贴图/流动" }
uniform float _IgnorePostExposure;
//: param custom { "default": 1, "label": "Use In Particle", "group": "特效贴图/流动" }
uniform float _InParticle;
//: param custom { "default": 300, "label": "Line Amount", "group": "头发高光/描线" }
uniform float _LineAmount;
//: param custom { "default": 0, "label": "Line Intensity", "min": 0, "max": 1, "group": "头发高光/描线" }
uniform float _LineIntensity;
uniform float4 _LineMap_ST;
//: param custom { "default": 0, "label": "Line Range", "min": -1, "max": 1, "group": "头发高光/描线" }
uniform float _LineRange;
//: param custom { "default": 1, "label": "Line Saturation", "min": 0, "max": 10, "group": "头发高光/描线" }
uniform float _LineSaturation;
//: param custom { "default": 0, "label": "Line Value", "min": 0, "max": 1, "group": "头发高光/描线" }
uniform float _LineValue;
uniform uint _MainLightLayerMask;
//: param custom { "default": [1, 0, 0, 1], "label": "MainTexUVRotateMat", "group": "特效贴图/流动" }
uniform float4 _MainTexUVRotateMat;
//: param custom { "default": [0, 0, 0, 0], "label": "MainTexUVSpeed(XY:By Time,ZW:By Custom1.X)", "group": "特效贴图/流动" }
uniform float4 _MainTexUVSpeed;
//: param custom { "default": [1, 0, 0, 0], "label": "'_MainTexUVWeights'", "group": "特效贴图/流动" }
uniform float4 _MainTexUVWeights;
//: param custom { "default": 1, "label": "Main Tex Use Disturb", "min": 0, "max": 1, "group": "特效贴图/流动" }
uniform float _MainTexUseDisturb;
uniform float4 _MainTex_ST;
//: param custom { "default": [1, 0, 0, 1], "label": "MaskTexUVRotateMat", "group": "特效贴图/流动" }
uniform float4 _MaskTexUVRotateMat;
//: param custom { "default": [0, 0, 0, 0], "label": "MaskTaexUVSpeed(XY:By Time,ZW:By Custom1.Y)", "group": "特效贴图/流动" }
uniform float4 _MaskTexUVSpeed;
//: param custom { "default": [1, 0, 0, 0], "label": "'_MaskTexUVWeights'", "group": "特效贴图/流动" }
uniform float4 _MaskTexUVWeights;
//: param custom { "default": 0, "label": "Mask Tex Use Disturb", "min": 0, "max": 1, "group": "特效贴图/流动" }
uniform float _MaskTexUseDisturb;
uniform float4 _MaskTex_ST;
//: param custom { "default": [1, 1, 1, 1], "label": "Matcap Color", "widget": "color", "group": "眼睛 Matcap" }
uniform float4 _MatcapColor;
//: param custom { "default": 1, "label": "Matcap Normal Scale", "min": 0, "max": 1.5, "group": "眼睛 Matcap" }
uniform float _MatcapNormalScale;
uniform half _Metallic;
//: param custom { "default": 1, "label": "Metallic Intensity", "group": "参数" }
uniform half _MetallicIntensity;
//: param custom { "default": 10, "label": "出现距离1", "min": 0.001, "max": 3000, "group": "特效菲涅尔/近淡出" }
uniform float _NearCameraFadeDistanceEnd;
//: param custom { "default": 100, "label": "出现距离2", "min": 0.002, "max": 3000, "group": "特效菲涅尔/近淡出" }
uniform float _NearCameraFadeDistanceEnd2;
//: param custom { "default": 0.001, "label": "消失距离1", "min": 0.001, "max": 3000, "group": "特效菲涅尔/近淡出" }
uniform float _NearCameraFadeDistanceStart;
//: param custom { "default": 120, "label": "消失距离2", "min": 0.001, "max": 3000, "group": "特效菲涅尔/近淡出" }
uniform float _NearCameraFadeDistanceStart2;
//: param custom { "default": [1, 0, 0, 1], "label": "NormalMapUVRotateMat", "group": "特效贴图/流动" }
uniform float4 _NormalMapUVRotateMat;
//: param custom { "default": [0, 0, 0, 0], "label": "NormalMapUVSpeed(XY:By Time,ZW:By Custom1.Y)", "group": "特效贴图/流动" }
uniform float4 _NormalMapUVSpeed;
//: param custom { "default": [1, 0, 0, 0], "label": "'_NormalMapUVWeights'", "group": "特效贴图/流动" }
uniform float4 _NormalMapUVWeights;
uniform float _NormalMapUseDisturb;
uniform half4 _NormalMap_ST;
//: param custom { "default": 1, "label": "Normal Scale", "group": "参数" }
uniform float _NormalScale;
//: param custom { "default": 1, "label": "Occlusion Intensity", "group": "参数" }
uniform half _OcclusionIntensity;
//: param custom { "default": 0.5, "label": "Outline Color Brightness", "min": 0, "max": 1, "group": "描边" }
uniform half _OutlineColorBrightness;
//: param custom { "default": 1.5, "label": "Outline Color Saturation", "min": 0, "max": 2, "group": "描边" }
uniform half _OutlineColorSaturation;
//: param custom { "default": [1, 1, 1, 1], "label": "Outline Tint Color", "widget": "color", "group": "参数" }
uniform half4 _OutlineTintColor;
//: param custom { "default": false, "label": "Outline Tint Enable", "group": "参数" }
uniform bool _OutlineTintEnable;
//: param custom { "default": [0, 0, 0, 1], "label": "Parallax Color", "widget": "color", "group": "参数" }
uniform half4 _ParallaxColor;
uniform half _ParallaxMarchNum;
//: param custom { "default": 0.5, "label": "Parallax Scale", "min": 0, "max": 1, "group": "视差" }
uniform float _ParallaxScale;
uniform float4 _ParallaxTex_ST;
//: param custom { "default": 1, "label": "Roughness Intensity", "group": "参数" }
uniform half _RoughnessIntensity;
//: param custom { "default": [0, 0, 0, 0], "label": "环境效果量 (.x=雨 .y=水位量 .z=浸润 .w=雪)", "group": "引擎全局 CP" }
uniform float4 _RuriCharacterEnvironmentEffect;
//: param custom { "default": [0, 0, 0, 0], "label": "环境效果水面 (.x=世界高度)", "group": "引擎全局 CP" }
uniform float4 _RuriCharacterEnvironmentWater;
uniform bool _RuriOutlineShellGate;
//: param custom { "default": [1, 1, 1, 1], "label": "Skin Rim Color", "widget": "color", "group": "脸部 SDF/表情" }
uniform float4 _SDFRimColor;
//: param custom { "default": 0.5, "label": "Shadow Color Brightness", "min": 0, "max": 1, "group": "阴影色" }
uniform float _ShadowColorBrightness;
//: param custom { "default": 1, "label": "Shadow Color Saturation", "min": 0, "max": 2, "group": "阴影色" }
uniform float _ShadowColorSaturation;
//: param custom { "default": false, "label": "Silk Stockings", "group": "丝袜" }
uniform bool _SilkStockings;
//: param custom { "default": 0, "label": "丝袜高级模式(使用贴图)", "group": "丝袜" }
uniform float _SilkStockingsAdvance;
//: param custom { "default": 0, "label": "丝袜锐利度G", "min": -1, "max": 1, "group": "丝袜" }
uniform float _SilkStockingsAnisoDirection;
//: param custom { "default": [0, 0, 0, 1], "label": "丝袜边缘颜色", "widget": "color", "group": "丝袜" }
uniform float4 _SilkStockingsColor;
//: param custom { "default": [1, 1, 1, 1], "label": "丝袜常态偏色", "widget": "color", "group": "丝袜" }
uniform float4 _SilkStockingsDryColor;
//: param custom { "default": 0.9, "label": "丝袜最深覆盖", "min": 0.5, "max": 0.9, "group": "丝袜" }
uniform float _SilkStockingsMaxAffect;
//: param custom { "default": 0.05, "label": "丝袜最浅覆盖", "min": 0, "max": 0.49, "group": "丝袜" }
uniform float _SilkStockingsMinAffect;
//: param custom { "default": 0.8, "label": "丝袜高光透肉衰减值", "min": 0, "max": 1, "group": "丝袜" }
uniform float _SilkStockingsSpecularFalloff;
//: param custom { "default": 5, "label": "丝袜高光强度Remap", "group": "丝袜" }
uniform float _SilkStockingsSpecularInt;
//: param custom { "default": 0, "label": "丝袜高光干燥态最小值", "min": 0, "max": 1, "group": "丝袜" }
uniform float _SilkStockingsSpecularMinAtMinWetness;
//: param custom { "default": 2, "label": "丝袜高光位置偏移", "min": -2, "max": 2, "group": "丝袜" }
uniform float _SilkStockingsSpecularValue;
//: param custom { "default": [1, 1, 1, 1], "label": "丝袜湿润偏色", "widget": "color", "group": "丝袜" }
uniform float4 _SilkStockingsWetColor;
//: param custom { "default": 0.5, "label": "Skin Rim Scale", "min": 0, "max": 1.5, "group": "脸部 SDF/表情" }
uniform half _SkinRimOffScale;
//: param custom { "default": 0.5, "label": "Smoothness", "min": 0, "max": 1, "group": "PBR 基础" }
uniform half _Smoothness;
//: param custom { "default": 1, "label": "Spec Scale", "group": "头发高光/描线" }
uniform float _SpecBumpScale;
//: param custom { "default": 0, "label": "彩虹色模式(镭射塑料请勾选)", "group": "Ramp" }
uniform float _SpecRampIridescentMode;
//: param custom { "default": 0, "label": "Dissolve Schedule Offset", "min": 0, "max": 2, "group": "VFX 合成" }
uniform float _SpecialDissolveScheduleOffset;
//: param custom { "default": 0.5, "label": "Specular (Default 0.5)", "min": 0, "max": 1, "group": "参数" }
uniform half _Specular;
//: param custom { "default": 1, "label": "Specular Intensity", "group": "参数" }
uniform half _SpecularIntensity;
//: param custom { "default": false, "label": "SpecularLine", "group": "头发高光/描线" }
uniform bool _SpecularLine;
uniform float4 _StrokeMap_ST;
//: param custom { "default": false, "label": "Use Stroke Map", "group": "头发高光/描线" }
uniform bool _StrokeOn;
//: param custom { "default": 1, "label": "Stroke Scale", "group": "头发高光/描线" }
uniform float _StrokeScale;
//: param custom { "default": 0, "label": "Surface Type", "group": "参数" }
uniform int _SurfaceType;
//: param custom { "default": [1, 1, 1, 1], "label": "TintColor", "widget": "color", "group": "特效贴图/流动" }
uniform float4 _TintColor;
//: param custom { "default": 1, "label": "Tint Color Alpha (Default 1)", "min": 0, "max": 10, "group": "特效贴图/流动" }
uniform float _TintColorAlpha;
//: param custom { "default": 1, "label": "Tint Color Intensity (Default 1)", "min": 1, "max": 100, "group": "特效贴图/流动" }
uniform float _TintColorIntensity;
//: param custom { "default": false, "label": "Use Blend", "group": "VFX 合成" }
uniform bool _UseBlend;
//: param custom { "default": false, "label": "Use Normal Map", "group": "参数" }
uniform bool _UseBumpMap;
//: param custom { "default": false, "label": "Use Alpha Cutoff", "group": "参数" }
uniform bool _UseCutoff;
//: param custom { "default": false, "label": "Diffuse Ramp", "group": "Ramp" }
uniform bool _UseDiffRampMap;
//: param custom { "default": false, "label": "Use Disturb", "group": "VFX 合成" }
uniform bool _UseDisturb;
//: param custom { "default": true, "label": "Use Emission", "group": "参数" }
uniform bool _UseEmission;
//: param custom { "default": false, "label": "Use Emotion Map", "group": "脸部 SDF/表情" }
uniform bool _UseEmotionMap;
//: param custom { "default": 0, "label": "Use Fresnel", "group": "参数" }
uniform half _UseFresnel;
//: param custom { "default": 0, "label": "Use Gray As Alpha", "group": "特效杂项" }
uniform float _UseGrayAsAlpha;
//: param custom { "default": 0, "label": "Use Line Map", "group": "头发高光/描线" }
uniform float _UseLineMap;
//: param custom { "default": 1, "label": "UseMainTexAsAlpha", "group": "特效贴图/流动" }
uniform float _UseMainTexAsAlpha;
//: param custom { "default": false, "label": "Use Mask (只影响Alpha)", "group": "VFX 合成" }
uniform bool _UseMask;
//: param custom { "default": 1, "label": "UseMaskTexAsAlpha", "group": "特效贴图/流动" }
uniform float _UseMaskTexAsAlpha;
//: param custom { "default": false, "label": "Use Matcap", "group": "眼睛 Matcap" }
uniform bool _UseMatcap;
//: param custom { "default": false, "label": "Use MetallicGlossMap", "group": "PBR 基础" }
uniform bool _UseMetallicGlossMap;
//: param custom { "default": 0, "label": "Use Near Camera Fade", "group": "特效菲涅尔/近淡出" }
uniform float _UseNearCameraFade;
//: param custom { "default": false, "label": "Use Parallax", "group": "视差" }
uniform bool _UseParallax;
//: param custom { "default": false, "label": "Use RMOS Map", "group": "参数" }
uniform bool _UseRMOSMap;
//: param custom { "default": false, "label": "Use SDF Lightmap", "group": "脸部 SDF/表情" }
uniform bool _UseSDFLightmap;
//: param custom { "default": false, "label": "Use Shadow Color LUT Tex", "group": "阴影色" }
uniform bool _UseShadowLutTex;
//: param custom { "default": false, "label": "Split Diffuse / Specular Normal", "group": "头发高光/描线" }
uniform bool _UseSpecBumpMap;
//: param custom { "default": false, "label": "Specular Ramp", "group": "Ramp" }
uniform bool _UseSpecRampMap;
//: param custom { "default": 0, "label": "UseMainTexAsAlpha", "group": "VFX 合成" }
uniform float _UseVFXMainTexAsAlpha;
//: param custom { "default": [1, 1, 1, 1], "label": "BlendTint", "widget": "color", "group": "VFX 合成" }
uniform float4 _VFXBlendTint;
//: param custom { "default": [1, 1, 1, 1], "label": "VFX Color", "widget": "color", "group": "VFX 合成" }
uniform float4 _VFXColor;
//: param custom { "default": 1, "label": "VFX Color Alpha (Default 1)", "min": 0, "max": 10, "group": "VFX 合成" }
uniform float _VFXColorAlpha;
//: param custom { "default": 1, "label": "VFX Color Intensity (Default 1)", "min": 1, "max": 100, "group": "VFX 合成" }
uniform float _VFXColorIntensity;
//: param custom { "default": 1, "label": "Fresnel Affect Opacity", "min": 0, "max": 1, "group": "VFX 合成" }
uniform float _VFXFresnelAffectOpacity;
//: param custom { "default": 0, "label": "Fresnel Bias(Default:0)", "min": -1, "max": 2, "group": "VFX 合成" }
uniform float _VFXFresnelBias;
//: param custom { "default": [1, 1, 1, 1], "label": "Fresnel Color", "widget": "color", "group": "VFX 合成" }
uniform float4 _VFXFresnelColor;
//: param custom { "default": 0.001, "label": "Fresnel Flip", "group": "VFX 合成" }
uniform float _VFXFresnelFlip;
//: param custom { "default": 1, "label": "Fresnel Power(Default:1)", "min": 1, "max": 100, "group": "VFX 合成" }
uniform float _VFXFresnelPower;
//: param custom { "default": 1, "label": "Use Blend Tex R For Disturb", "min": 0, "max": 1, "group": "VFX 合成" }
uniform float _VFXSpecialBlendTexRForDisturb;
uniform float4 _VFXSpecialBlendTex_ST;
uniform float4 _VFXSpecialMainTex_ST;
//: param custom { "default": [0, 0, 0, 0], "label": "VFX Special Param(XY: MainTex, ZW: BlendTex)", "group": "VFX 合成" }
uniform float4 _VFXSpecialParam;
uniform float4 unity_SpecCube0_HDR;
//----------------------------------------------------------------------endregion

//----------------------------------------------------------------------region 宿主库
import lib-pbr.glsl
import lib-bent-normal.glsl
import lib-emissive.glsl
import lib-sss.glsl
import lib-utils.glsl
import lib-sparse.glsl
//----------------------------------------------------------------------endregion

//: state cull_face off
//: state blend over

//: param auto camera_view_matrix
uniform mat4 uniform_camera_view_matrix;
//: param auto environment_max_lod
uniform float environment_max_lod;
//: param auto facing
uniform int uniform_facing;
//: param auto main_light
uniform vec4 light_main;

//----------------------------------------------------------------------region 宿主输入(投影方案派生)
//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;
//: param auto channel_opacity
uniform SamplerSparse opacity_tex;
//: param custom { "default": "", "default_color": [0.0, 0.0, 0.0, 0.0], "label": "Blend Tex", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _BlendTex;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Cubemap", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _CharMaxCubemap;
//: param auto channel_user1
uniform SamplerSparse slot_user1_tex;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Diffuse Ramp", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _DiffRampMap;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Disturb Tex 1", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _DisturbTex1;
//: param auto channel_user2
uniform SamplerSparse slot_user2_tex;
//: param custom { "default": "", "default_color": [0.0, 0.0, 0.0, 0.0], "label": "Emotion Map", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _EmotionMap;
//: param custom { "default": "", "default_color": [0.5, 0.5, 1.0, 1.0], "label": "毛发方向(RG)疏密(B)长短(A)", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _FurDirMap;
//: param custom { "default": "", "default_color": [0.0, 0.0, 0.0, 0.0], "label": "皮毛染色", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _FurDyeMap;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Fur Noise", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _FurMap;
//: param custom { "default": "", "default_color": [0.0, 0.0, 0.0, 0.0], "label": "HighlightMap", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _HighlightMap;
//: param custom { "default": "", "default_color": [0.0, 0.0, 0.0, 0.0], "label": "Line Map", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _LineMap;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Main Tex", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _MainTex;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Mask Tex", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _MaskTex;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Matcap", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _MatcapTex;
//: param auto channel_metallic
uniform SamplerSparse metallic_tex;
//: param auto channel_specularlevel
uniform SamplerSparse specularlevel_tex;
//: param auto channel_roughness
uniform SamplerSparse roughness_tex;
//: param custom { "default": "", "default_color": [0.5, 0.5, 1.0, 1.0], "label": "法线图", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _NormalMap;
//: param auto channel_height
uniform SamplerSparse height_tex;
//: param custom { "default": "", "default_color": [0.0, 0.0, 0.0, 0.0], "label": "SDF Lightmap", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _SDFLightmap;
//: param custom { "default": "", "default_color": [0.0, 0.0, 0.0, 0.0], "label": "RimMask/SDFMask/FlatSHMask", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _SDFMask;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Shadow Color Lut", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _ShadowLutTex;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "丝袜遮罩", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _SilkStockingsMask;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Specular Ramp", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _SpecRampMap;
//: param custom { "default": "", "default_color": [0.5, 0.5, 0.5, 1.0], "label": "Stroke Map(R:anisotropy G:specular offset)", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _StrokeMap;
//: param custom { "default": "", "default_color": [0.0, 0.0, 0.0, 0.0], "label": "VFX Special Blend Tex", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _VFXSpecialBlendTex;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "VFX Special Main Tex", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _VFXSpecialMainTex;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "_BumpMap 余量(ba)", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _BumpMap_ba;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "_ClearCoatMask 余量(gba)", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _ClearCoatMask_gba;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "_ParallaxTex 余量(gba)", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _ParallaxTex_gba;
//: param custom { "default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "_SplitNormalMap 余量(ba)", "usage": "texture", "group": "2 贴图" }
uniform sampler2D _SplitNormalMap_ba;
//----------------------------------------------------------------------endregion

//----------------------------------------------------------------------region HLSL→GLSL 词法桥(生成物,勿手改)
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define half float
#define half2 vec2
#define half3 vec3
#define half4 vec4
#define float2x2 mat2
#define float3x3 mat3
#define float4x4 mat4
#define half3x3 mat3
#define half4x4 mat4
#define uint2 uvec2
#define uint3 uvec3
#define uint4 uvec4
#define int2 ivec2
#define int3 ivec3
#define int4 ivec4
#define bool2 bvec2
#define bool3 bvec3
#define bool4 bvec4

#define frac fract
#define ddx dFdx
#define ddy dFdy
#define fmod mod
#define atan2(y, x) atan(y, x)
#define rsqrt inversesqrt
#define asuint floatBitsToUint
#define asfloat uintBitsToFloat
#define asint floatBitsToInt
#define UNITY_BRANCH
#define UNITY_LOOP
#define UNITY_FLATTEN

float  saturate(float v)  { return clamp(v, 0.0, 1.0); }
vec2   saturate(vec2 v)   { return clamp(v, vec2(0.0), vec2(1.0)); }
vec3   saturate(vec3 v)   { return clamp(v, vec3(0.0), vec3(1.0)); }
vec4   saturate(vec4 v)   { return clamp(v, vec4(0.0), vec4(1.0)); }

float  lerp(float a, float b, float t) { return mix(a, b, t); }
vec2   lerp(vec2 a, vec2 b, float t)   { return mix(a, b, t); }
vec3   lerp(vec3 a, vec3 b, float t)   { return mix(a, b, t); }
vec4   lerp(vec4 a, vec4 b, float t)   { return mix(a, b, t); }
vec2   lerp(vec2 a, vec2 b, vec2 t)    { return mix(a, b, t); }
vec3   lerp(vec3 a, vec3 b, vec3 t)    { return mix(a, b, t); }
vec4   lerp(vec4 a, vec4 b, vec4 t)    { return mix(a, b, t); }

float  mad(float a, float b, float c) { return a * b + c; }
vec2   mad(vec2 a, vec2 b, vec2 c)    { return a * b + c; }
vec3   mad(vec3 a, vec3 b, vec3 c)    { return a * b + c; }
vec4   mad(vec4 a, vec4 b, vec4 c)    { return a * b + c; }

// HLSL mul 语义(矩阵按逻辑布局搬运:行构造经 ruriMatRows 转置,列语义两侧一致)。
vec3   mul(mat3 m, vec3 v)  { return m * v; }
vec4   mul(mat4 m, vec4 v)  { return m * v; }
vec3   mul(vec3 v, mat3 m)  { return v * m; }
vec4   mul(vec4 v, mat4 m)  { return v * m; }
mat3   mul(mat3 a, mat3 b)  { return a * b; }
mat4   mul(mat4 a, mat4 b)  { return a * b; }

mat3   ruriMat3Rows(vec3 r0, vec3 r1, vec3 r2) { return transpose(mat3(r0, r1, r2)); }
mat4   ruriMat4Rows(vec4 r0, vec4 r1, vec4 r2, vec4 r3) { return transpose(mat4(r0, r1, r2, r3)); }

float  rcp(float x) { return 1.0 / x; }
vec2   rcp(vec2 x)  { return vec2(1.0) / x; }
vec3   rcp(vec3 x)  { return vec3(1.0) / x; }
vec4   rcp(vec4 x)  { return vec4(1.0) / x; }

void clip(float x) { if (x < 0.0) discard; }
void clip(vec4 x)  { if (any(lessThan(x, vec4(0.0)))) discard; }

// 附加光循环(URP 非聚簇形;灯数经能力兑现,缺席=0 → 死循环体被编译器消除)。
#define LIGHT_LOOP_BEGIN(count) for (uint lightIndex = 0u; lightIndex < count; ++lightIndex) {
#define LIGHT_LOOP_END }

// sRGB 解码(宿主原样槽位的颜色纹理:裸采样无硬件解码,按声明补;alpha 不解码)。
float ruriSrgbToLinear(float c) {
    return (c <= 0.04045) ? (c / 12.92) : pow(abs((c + 0.055) / 1.055), 2.4);
}
vec4 ruriSampleSrgb(sampler2D t, vec2 uv) {
    vec4 s = texture(t, uv);
    return vec4(ruriSrgbToLinear(s.r), ruriSrgbToLinear(s.g), ruriSrgbToLinear(s.b), s.a);
}
vec4 ruriSampleSrgbLod(sampler2D t, vec2 uv, float lod) {
    vec4 s = textureLod(t, uv, lod);
    return vec4(ruriSrgbToLinear(s.r), ruriSrgbToLinear(s.g), ruriSrgbToLinear(s.b), s.a);
}

// CLAMP 寻址复现(ramp/LUT 声明为 Clamp 的纹理:钳到 texel 中心,双线性不吃边框)。
vec2 ruriUvClamp(sampler2D t, vec2 uv) {
    vec2 size = vec2(textureSize(t, 0));
    vec2 halfTexel = 0.5 / max(size, vec2(1.0));
    return clamp(uv, halfTexel, vec2(1.0) - halfTexel);
}
//----------------------------------------------------------------------endregion

#ifndef RURI_PRELUDE_RURILENGTH
#define RURI_PRELUDE_RURILENGTH
float ruriLength(float2 v) { return sqrt(dot(v, v)); }
float ruriLength(float3 v) { return sqrt(dot(v, v)); }
float ruriLength(float4 v) { return sqrt(dot(v, v)); }
#endif

#ifndef RURI_PRELUDE_RURINORMALIZE
#define RURI_PRELUDE_RURINORMALIZE
float2 ruriNormalize(float2 v) { return v / sqrt(dot(v, v)); }
float3 ruriNormalize(float3 v) { return v / sqrt(dot(v, v)); }
float4 ruriNormalize(float4 v) { return v / sqrt(dot(v, v)); }
#endif

//----------------------------------------------------------------------region 结构体
struct CharaVaryings {
    float2 uv;
    float3 positionWS;
    float3 normalWS;
    float4 tangentWS;
    float4 uv1;
    float2 uv0zw;
    float4 positionNDC;
    float4 color;
    float4 positionCS;
};

struct GBufferData {
    float3 baseColor;
    float smoothness;
    float3 specularColor;
    float occlusion;
    float3 normalWS;
    uint materialFlags;
    float depth;
    float4 shadowMask;
    uint meshRenderingLayers;
};

struct GBufferFragOutput {
    float4 gBuffer0;
    float4 gBuffer1;
    float4 gBuffer2;
    float4 color;
    float depth;
    float4 shadowMask;
    uint meshRenderingLayers;
};

struct Light {
    float3 direction;
    float3 color;
    float distanceAttenuation;
    float shadowAttenuation;
    uint layerMask;
};

struct RuriData {
    float alpha;
    half3 albedo;
    float roughness;
    float metallic;
    float occlusion;
    float specular;
    float3 normalTS;
    float3 positionWS;
    float4 positionCS;
    float3 normalWS;
    float3 viewDirectionWS;
    float4 shadowCoord;
    float3 bakedGI;
    float2 normalizedScreenSpaceUV;
    float4 shadowMask;
    float diffuse;
    float4 baseSample;
    float baseAlpha;
    float3 V;
    float3 L;
    float3 H;
    float3 camFwd;
    Light mainLight;
    float3 adjustedLightDir;
    float adjXZ_x;
    float adjXZ_z;
    float adjXZLen;
    float camLightDotRaw;
    float camLightDot;
    float camYSmooth;
    float exposure;
    float ambInt;
    float perObjectShadow;
    float useRampVal;
    float specScale;
    float base_weight;
    float3 base_color;
    float base_diffuse_roughness;
    float base_metalness;
    float specular_weight;
    float3 specular_color;
    float specular_roughness;
    float specular_ior;
    float specular_roughness_anisotropy;
    float subsurface_weight;
    float3 subsurface_color;
    float subsurface_radius;
    float3 subsurface_radius_scale;
    float subsurface_scatter_anisotropy;
    float fuzz_weight;
    float3 fuzz_color;
    float fuzz_roughness;
    float coat_weight;
    float3 coat_color;
    float coat_roughness;
    float coat_roughness_anisotropy;
    float coat_ior;
    float coat_darkening;
    float emission_luminance;
    float3 emission_color;
    float3 coat_normal;
};

struct RuriGBufferData {
    float alpha;
    float3 baseColor;
    float roughness;
    float metallic;
    float occlusion;
    float specular;
    float lightBlock;
    float lightSky;
    uint materialFlags;
    uint shadingModel;
    float4 customData;
    float3 normalWS;
    float depth;
    float4 shadowMask;
    uint meshRenderingLayers;
    float4 globalIllumination;
};

struct SceneVaryings {
    float2 uv;
    float3 positionWS;
    float3 positionOS;
    float3 normalWS;
    float4 tangentWS;
    float2 voxelUV;
    float3 voxelLitColor;
    float2 staticLightmapUV;
    float4 positionNDC;
    float4 color;
    float2 voxelSliceMaterial;
    float2 uv1;
    float2 uv2;
    float2 voxelBlockLight;
    float4 positionCS;
};

//----------------------------------------------------------------------endregion

//----------------------------------------------------------------------region 结构零值
CharaVaryings ruriZeroCharaVaryings() {
    CharaVaryings v;
    v.uv = float2(0.0);
    v.positionWS = float3(0.0);
    v.normalWS = float3(0.0);
    v.tangentWS = float4(0.0);
    v.uv1 = float4(0.0);
    v.uv0zw = float2(0.0);
    v.positionNDC = float4(0.0);
    v.color = float4(0.0);
    v.positionCS = float4(0.0);
    return v;
}

GBufferFragOutput ruriZeroGBufferFragOutput() {
    GBufferFragOutput v;
    v.gBuffer0 = float4(0.0);
    v.gBuffer1 = float4(0.0);
    v.gBuffer2 = float4(0.0);
    v.color = float4(0.0);
    v.depth = 0.0;
    v.shadowMask = float4(0.0);
    v.meshRenderingLayers = uint(0);
    return v;
}

Light ruriZeroLight() {
    Light v;
    v.direction = float3(0.0);
    v.color = float3(0.0);
    v.distanceAttenuation = 0.0;
    v.shadowAttenuation = 0.0;
    v.layerMask = uint(0);
    return v;
}

RuriData ruriZeroRuriData() {
    RuriData v;
    v.alpha = 0.0;
    v.albedo = half3(0.0);
    v.roughness = 0.0;
    v.metallic = 0.0;
    v.occlusion = 0.0;
    v.specular = 0.0;
    v.normalTS = float3(0.0);
    v.positionWS = float3(0.0);
    v.positionCS = float4(0.0);
    v.normalWS = float3(0.0);
    v.viewDirectionWS = float3(0.0);
    v.shadowCoord = float4(0.0);
    v.bakedGI = float3(0.0);
    v.normalizedScreenSpaceUV = float2(0.0);
    v.shadowMask = float4(0.0);
    v.diffuse = 0.0;
    v.baseSample = float4(0.0);
    v.baseAlpha = 0.0;
    v.V = float3(0.0);
    v.L = float3(0.0);
    v.H = float3(0.0);
    v.camFwd = float3(0.0);
    v.mainLight = ruriZeroLight();
    v.adjustedLightDir = float3(0.0);
    v.adjXZ_x = 0.0;
    v.adjXZ_z = 0.0;
    v.adjXZLen = 0.0;
    v.camLightDotRaw = 0.0;
    v.camLightDot = 0.0;
    v.camYSmooth = 0.0;
    v.exposure = 0.0;
    v.ambInt = 0.0;
    v.perObjectShadow = 0.0;
    v.useRampVal = 0.0;
    v.specScale = 0.0;
    v.base_weight = 0.0;
    v.base_color = float3(0.0);
    v.base_diffuse_roughness = 0.0;
    v.base_metalness = 0.0;
    v.specular_weight = 0.0;
    v.specular_color = float3(0.0);
    v.specular_roughness = 0.0;
    v.specular_ior = 0.0;
    v.specular_roughness_anisotropy = 0.0;
    v.subsurface_weight = 0.0;
    v.subsurface_color = float3(0.0);
    v.subsurface_radius = 0.0;
    v.subsurface_radius_scale = float3(0.0);
    v.subsurface_scatter_anisotropy = 0.0;
    v.fuzz_weight = 0.0;
    v.fuzz_color = float3(0.0);
    v.fuzz_roughness = 0.0;
    v.coat_weight = 0.0;
    v.coat_color = float3(0.0);
    v.coat_roughness = 0.0;
    v.coat_roughness_anisotropy = 0.0;
    v.coat_ior = 0.0;
    v.coat_darkening = 0.0;
    v.emission_luminance = 0.0;
    v.emission_color = float3(0.0);
    v.coat_normal = float3(0.0);
    return v;
}

RuriGBufferData ruriZeroRuriGBufferData() {
    RuriGBufferData v;
    v.alpha = 0.0;
    v.baseColor = float3(0.0);
    v.roughness = 0.0;
    v.metallic = 0.0;
    v.occlusion = 0.0;
    v.specular = 0.0;
    v.lightBlock = 0.0;
    v.lightSky = 0.0;
    v.materialFlags = uint(0);
    v.shadingModel = uint(0);
    v.customData = float4(0.0);
    v.normalWS = float3(0.0);
    v.depth = 0.0;
    v.shadowMask = float4(0.0);
    v.meshRenderingLayers = uint(0);
    v.globalIllumination = float4(0.0);
    return v;
}

//----------------------------------------------------------------------endregion

SparseCoord ruriSparseCoord;

//----------------------------------------------------------------------region 宿主胶水(配方)
//: param custom { "default": 0, "label": "灯光旋转 X", "min": 0, "max": 360, "group": "0 光照" }
uniform int i_LightRotX;
//: param custom { "default": 30, "label": "灯光旋转 Y", "min": 0, "max": 360, "group": "0 光照" }
uniform int i_LightRotY;
//: param custom { "default": 0, "label": "灯光旋转 Z", "min": 0, "max": 360, "group": "0 光照" }
uniform int i_LightRotZ;
//: param custom { "default": [1.0, 1.0, 1.0], "label": "主光颜色", "widget": "color", "group": "0 光照" }
uniform vec3 v_MainLightColor;
//: param custom { "default": 0.0, "label": "时间 Time", "min": 0.0, "max": 100.0, "group": "0 光照" }
uniform float f_RuriTime;
mat3 ruriRotX(float r) { float c = cos(r), s = sin(r); return mat3(1,0,0, 0,c,s, 0,-s,c); }
mat3 ruriRotY(float r) { float c = cos(r), s = sin(r); return mat3(c,0,-s, 0,1,0, s,0,c); }
mat3 ruriRotZ(float r) { float c = cos(r), s = sin(r); return mat3(c,s,0, -s,c,0, 0,0,1); }
vec3 ruriMainLightDir() {
    mat3 rot = ruriRotY(radians(float(i_LightRotY))) * ruriRotX(radians(float(i_LightRotX))) * ruriRotZ(radians(float(i_LightRotZ)));
    return normalize(rot * light_main.xyz);
}
// 单趟等价:F 腿回读的 gbuffer 就是本表面 G 腿写入的自身数据 —— 直接用本片元的表面态回声。
GBufferData ruriSelfGBuffer(RuriData rd) {
    GBufferData g;
    g.baseColor = rd.albedo;
    g.smoothness = 1.0 - rd.roughness;
    g.specularColor = vec3(rd.specular);
    g.occlusion = rd.occlusion;
    g.normalWS = rd.normalWS;
    g.materialFlags = 0u;
    g.depth = 0.0;
    g.shadowMask = vec4(1.0);
    g.meshRenderingLayers = 0u;
    return g;
}
//----------------------------------------------------------------------endregion

//----------------------------------------------------------------------region 引擎态兑现(配方)
#define UNITY_MATRIX_I_V (inverse(uniform_camera_view_matrix))
#define UNITY_MATRIX_M (mat4(1.0))
#define UNITY_MATRIX_V (uniform_camera_view_matrix)
#define _MainLightColor (vec4(v_MainLightColor, 1.0))
#define _MainLightPosition (vec4(ruriMainLightDir(), 0.0))
#define _ScaledScreenParams (vec4(1920.0, 1080.0, 1.0 + 1.0/1920.0, 1.0 + 1.0/1080.0))
#define _ScreenParams (vec4(1920.0, 1080.0, 1.0 + 1.0/1920.0, 1.0 + 1.0/1080.0))
#define _Time (vec4(0.05, 1.0, 2.0, 3.0) * f_RuriTime)
#define _WorldSpaceCameraPos (camera_pos)
#define _ZBufferParams (vec4(-999.0, 1000.0, -0.999, 1.0))
#define unity_LightData (vec4(0.0, 0.0, 1.0, 0.0))
#define unity_OrthoParams (vec4(0.0, 0.0, 0.0, 0.0))
//----------------------------------------------------------------------endregion

//----------------------------------------------------------------------region 投影读函数(源纹理 → 宿主输入重建;与清单同源)
// 宿主可绘制通道按网格参数化取值,uv 实参不参与(源侧 ST 平铺对这些通道无效 —— 清单已披露)。
float4 ruriRead_BaseMap(float2 uv) {
    return float4((getBaseColor(basecolor_tex, ruriSparseCoord)).x, (getBaseColor(basecolor_tex, ruriSparseCoord)).y, (getBaseColor(basecolor_tex, ruriSparseCoord)).z, getOpacity(opacity_tex, ruriSparseCoord));
}

float4 ruriRead_BumpMap(float2 uv) {
    return float4(((getTSNormal(ruriSparseCoord)).x * 0.5 + 0.5), ((getTSNormal(ruriSparseCoord)).y * 0.5 + 0.5), (texture(_BumpMap_ba, uv)).x, (texture(_BumpMap_ba, uv)).y);
}

float4 ruriRead_ClearCoatMask(float2 uv) {
    return float4(textureSparse(slot_user1_tex, ruriSparseCoord).r, (texture(_ClearCoatMask_gba, uv)).x, (texture(_ClearCoatMask_gba, uv)).y, (texture(_ClearCoatMask_gba, uv)).z);
}

float4 ruriRead_EmissionMap(float2 uv) {
    return float4((pbrComputeEmissive(emissive_tex, ruriSparseCoord)).x, (pbrComputeEmissive(emissive_tex, ruriSparseCoord)).y, (pbrComputeEmissive(emissive_tex, ruriSparseCoord)).z, textureSparse(slot_user2_tex, ruriSparseCoord).r);
}

float4 ruriRead_MetallicGlossMap(float2 uv) {
    return float4(getMetallic(metallic_tex, ruriSparseCoord), getSpecularLevel(specularlevel_tex, ruriSparseCoord), getAO(ruriSparseCoord, true, use_bent_normal), (1.0 - getRoughness(roughness_tex, ruriSparseCoord)));
}

float4 ruriRead_ParallaxTex(float2 uv) {
    return float4(textureSparse(height_tex, ruriSparseCoord).r, (texture(_ParallaxTex_gba, uv)).x, (texture(_ParallaxTex_gba, uv)).y, (texture(_ParallaxTex_gba, uv)).z);
}

float4 ruriRead_RMOSMap(float2 uv) {
    return float4(getRoughness(roughness_tex, ruriSparseCoord), getMetallic(metallic_tex, ruriSparseCoord), getAO(ruriSparseCoord, true, use_bent_normal), getSpecularLevel(specularlevel_tex, ruriSparseCoord));
}

float4 ruriRead_SplitNormalMap(float2 uv) {
    return float4(((getTSNormal(ruriSparseCoord)).x * 0.5 + 0.5), ((getTSNormal(ruriSparseCoord)).y * 0.5 + 0.5), (texture(_SplitNormalMap_ba, uv)).x, (texture(_SplitNormalMap_ba, uv)).y);
}

//----------------------------------------------------------------------endregion

float3 UnpackNormalScale(float4 packedNormal, float bumpScale)
{
    packedNormal.w *= packedNormal.x;
    float3 normal;
    normal.x = packedNormal.w * 2.0 - 1.0;
    normal.y = packedNormal.y * 2.0 - 1.0;
    normal.z = max(1.0e-16, sqrt(1.0 - saturate(normal.x * normal.x + normal.y * normal.y)));
    normal.x *= bumpScale;
    normal.y *= bumpScale;
    return normal;
}

half3 SampleNormal(float2 uv, sampler2D bumpMap, half scale)
{
    if (_NORMALMAP)
    {
        half4 n = half4(texture(bumpMap, uv));
        return half3(UnpackNormalScale(n, scale));
    }
    else
    {
        return half3(0.0, 0.0, 1.0);
    }
}

float3 NormalizeNormalPerPixel(float3 n)
{
    return ruriNormalize(n);
}

float3 mul(float4x4 m, float3 v)
{
    return mul(((float3x3)m), v);
}

float3 mul(float3 v, float3x3 m)
{
    return float3(dot(v, m[0].xyz), dot(v, m[1].xyz), dot(v, m[2].xyz));
}

float4 mul(float4 v, float4x4 m)
{
    return float4(dot(v, m[0]), dot(v, m[1]), dot(v, m[2]), dot(v, m[3]));
}

float3 TransformTangentToWorld(float3 directionTS, float3x3 tangentToWorld)
{
    return mul(directionTS, tangentToWorld);
}

half3 ResolveNormalWS(half3 normalTS, float3 positionWS, half3 vertexNormalWS, half4 tangentWS, float2 uv)
{
    half3 N = half3(NormalizeNormalPerPixel(vertexNormalWS));
    float3 dp1 = ddx(positionWS);
    float3 dp2 = ddy(positionWS);
    float2 duv1 = ddx(uv);
    float2 duv2 = ddy(uv);
    half3 T;
    half3 B;
    if (dot(tangentWS.xyz, tangentWS.xyz) > 1e-4)
    {
        T = tangentWS.xyz;
        B = tangentWS.w * cross(N, T);
    }
    else
    {
        float3 dp2perp = cross(dp2, N);
        float3 dp1perp = cross(N, dp1);
        float3 Td = dp2perp * duv1.x + dp1perp * duv2.x;
        float3 Bd = dp2perp * duv1.y + dp1perp * duv2.y;
        float invmax = rsqrt(max(dot(Td, Td), dot(Bd, Bd)) + 1e-8);
        T = half3(Td * invmax);
        B = half3(Bd * invmax);
    }
    return half3(NormalizeNormalPerPixel(TransformTangentToWorld(normalTS, ruriMat3Rows(T, B, N))));
}

bool IsPerspectiveProjection()
{
    return unity_OrthoParams.w == 0.0;
}

float3 GetCameraPositionWS()
{
    return _WorldSpaceCameraPos;
}

float3 GetCurrentViewPosition()
{
    return GetCameraPositionWS();
}

float3 GetViewForwardDir()
{
    float3 row2 = float3(UNITY_MATRIX_V[0].z, UNITY_MATRIX_V[1].z, UNITY_MATRIX_V[2].z);
    return -row2;
}

float3 GetWorldSpaceNormalizeViewDir(float3 positionWS)
{
    if (IsPerspectiveProjection())
    {
        float3 V = GetCurrentViewPosition() - positionWS;
        return ruriNormalize(V);
    }
    return -GetViewForwardDir();
}

float4 GetScaledScreenParams()
{
    return _ScaledScreenParams;
}

float2 GetNormalizedScreenSpaceUV(float2 positionCS)
{
    float2 normalizedScreenSpaceUV = positionCS * (GetScaledScreenParams().zw - 1.0);
    return normalizedScreenSpaceUV;
}

float2 GetNormalizedScreenSpaceUV(float4 positionCS)
{
    return GetNormalizedScreenSpaceUV(positionCS.xy);
}

void RURI_INIT_COMMON(CharaVaryings input, out RuriData outRuriData)
{
    outRuriData = ruriZeroRuriData();
    float4 albedoAlpha = ruriRead_BaseMap(input.uv);
    outRuriData.alpha = albedoAlpha.w;
    outRuriData.albedo = albedoAlpha.xyz;
    outRuriData.normalTS = SampleNormal(input.uv, _BumpMap, _BumpScale);
    outRuriData.positionCS = input.positionCS;
    outRuriData.positionWS = input.positionWS;
    outRuriData.normalWS = ResolveNormalWS(outRuriData.normalTS, input.positionWS, input.normalWS, input.tangentWS, input.uv);
    outRuriData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    outRuriData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    outRuriData.shadowMask = float4(1.0, 1.0, 1.0, 1.0);
}

void RURI_INIT_COMMON(SceneVaryings input, out RuriData outRuriData)
{
    outRuriData = ruriZeroRuriData();
    outRuriData.alpha = 1.0;
    outRuriData.albedo = half3(1.0, 1.0, 1.0);
    outRuriData.normalTS = float3(0.0, 0.0, 1.0);
    outRuriData.positionCS = input.positionCS;
    outRuriData.positionWS = input.positionWS;
    outRuriData.normalWS = ResolveNormalWS(outRuriData.normalTS, input.positionWS, input.normalWS, input.tangentWS, input.uv);
    outRuriData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    outRuriData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    outRuriData.shadowMask = float4(1.0, 1.0, 1.0, 1.0);
}

void RURI_SHADOW_COORD(inout RuriData outRuriData)
{
    outRuriData.shadowCoord = vec4(0.0);
}

void InitializeCharaData(CharaVaryings input, out RuriData outRuriData)
{
    RURI_INIT_COMMON(input, outRuriData);
    if (_UseRMOSMap)
    {
        half4 rmosMap = ruriRead_RMOSMap(input.uv);
        outRuriData.roughness = rmosMap.x;
        outRuriData.metallic = rmosMap.y;
        outRuriData.occlusion = rmosMap.z;
        outRuriData.specular = rmosMap.w;
    }
    RURI_SHADOW_COORD(outRuriData);
    outRuriData.bakedGI = half3(0, 0, 0);
}

float ComputeExposure()
{
    return (_CharacterParams12.w * (1.0 - _EnvironmentGlobalParams0.x) + _EnvironmentGlobalParams0.x) * _ExposureParams.x;
}

// ---- 主光 ----

Light GetMainLight()
{
    Light light = ruriZeroLight();
    light.direction = _MainLightPosition.xyz;
    light.distanceAttenuation = unity_LightData.z;
    light.shadowAttenuation = 1.0;
    light.color = _MainLightColor.xyz;
    light.layerMask = _MainLightLayerMask;
    return light;
}

float MainLightRealtimeShadow(float4 shadowCoord) {
    return 1.0;
}

// 下两个重载不是能力，是 **两条能力的合成**（主光 × 阴影衰减）——普通数学，照常编译。
// 必须与 0 参形那个住同一个类：C# 的 using static **不跨类合并方法组**，
// 拆开会让 0 参形重载被整个遮蔽（实锤：七个调用点 CS1501）。
Light GetMainLight(float4 shadowCoord)
{
    Light light = GetMainLight();
    light.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
    return light;
}

float GetPerObjectShadowAttenuation(float2 normalizedScreenSpaceUV)
{
    return 1.0;
}

void ResolveAdjustedLight(float3 mainLightDir, out float3 adjustedLightDir, out float adjXZ_x, out float adjXZ_z, out float adjXZLen)
{
    adjustedLightDir = lerp(mainLightDir, _CharacterParams11.xyz, _CharacterParams1.w);
    adjXZLen = rsqrt(adjustedLightDir.x * adjustedLightDir.x + adjustedLightDir.z * adjustedLightDir.z + HALF_MIN * HALF_MIN);
    adjXZ_x = adjXZLen * adjustedLightDir.x;
    adjXZ_z = adjXZLen * adjustedLightDir.z;
}

void ComputeCamLightFactors(float3 camFwd, float adjXZ_x, float adjXZ_z, out float camLightDot, out float camYSmooth)
{
    float cfXZLen = rsqrt(camFwd.x * camFwd.x + camFwd.z * camFwd.z);
    camLightDot = -(adjXZ_x * (cfXZLen * camFwd.x) + adjXZ_z * (cfXZLen * camFwd.z));
    float camYFade = saturate(2.0 * (0.75 - abs(camFwd.y)));
    camYSmooth = camYFade * camYFade * (3.0 - 2.0 * camYFade);
}

void Endfield_Setup(inout RuriData ruriData, CharaVaryings input)
{
    ruriData.baseSample = ruriRead_BaseMap(input.uv);
    ruriData.baseAlpha = ruriData.baseSample.a;
    ruriData.V = GetWorldSpaceNormalizeViewDir(ruriData.positionWS);
    ruriData.camFwd = float3(UNITY_MATRIX_I_V[2].x, UNITY_MATRIX_I_V[2].y, UNITY_MATRIX_I_V[2].z);
    ruriData.exposure = ComputeExposure();
    ruriData.ambInt = ruriData.exposure;
    if (_UseMetallicGlossMap)
    {
        half4 mg = ruriRead_MetallicGlossMap(input.uv);
        ruriData.roughness = 1 - mg.w;
        ruriData.metallic = mg.x;
        ruriData.occlusion = mg.z;
        ruriData.specScale = mg.y;
    }
    else
    {
        ruriData.roughness = 1 - _Smoothness;
        ruriData.metallic = _Metallic;
        ruriData.occlusion = _OcclusionIntensity;
        ruriData.specScale = _Specular;
    }
    ruriData.mainLight = GetMainLight(ruriData.shadowCoord);
    ruriData.mainLight.shadowAttenuation = min(ruriData.mainLight.shadowAttenuation, GetPerObjectShadowAttenuation(ruriData.normalizedScreenSpaceUV));
    ResolveAdjustedLight(ruriData.mainLight.direction, ruriData.adjustedLightDir, ruriData.adjXZ_x, ruriData.adjXZ_z, ruriData.adjXZLen);
    ComputeCamLightFactors(ruriData.camFwd, ruriData.adjXZ_x, ruriData.adjXZ_z, ruriData.camLightDotRaw, ruriData.camYSmooth);
    ruriData.camLightDot = saturate(ruriData.camLightDotRaw);
}

void ApplyEndfieldOutlineAlbedo(inout half3 albedo)
{
    half3 LUM = half3(0.2126729, 0.7152, 0.07217500);
    if (_OutlineTintEnable)
    {
        albedo = _OutlineTintColor.rgb;
    }
    else
    {
        half3 scaled = albedo * _OutlineColorBrightness;
        half lum = dot(scaled, LUM);
        albedo = lum + _OutlineColorSaturation * (scaled - lum);
    }
}

float mad(float a, float b, float c)
{
    return a * b + c;
}

float3 mad(float3 a, float3 b, float3 c)
{
    return a * b + c;
}

float3 mad(float3 a, float b, float3 c)
{
    return a * b + c;
}

float2 mad(float2 a, float2 b, float2 c)
{
    return a * b + c;
}

float3 SampleNormalMap(float2 uv, float3 normalWS_raw, float4 tangentWS, float faceSign)
{
    if (_UseBumpMap)
    {
        float4 s = ruriRead_BumpMap(uv);
        float nx = (s.x * s.w * 2.0 - 1.0) * _BumpScale;
        float ny = (s.y * 2.0 - 1.0) * _BumpScale;
        float nz = max(sqrt(1.0 - saturate(nx * nx + ny * ny)), 1e-16);
        float3 N = ruriNormalize(normalWS_raw);
        float3 T = ruriNormalize(tangentWS.xyz);
        float3 B = cross(N, T) * tangentWS.w;
        return faceSign * ruriNormalize(nx * T + ny * B + nz * N);
    }
    return faceSign * ruriNormalize(normalWS_raw);
}

float3 GetObjectFlatDir(float3 positionWS)
{
    float fX = positionWS.x - UNITY_MATRIX_M[3].x;
    float fZ = positionWS.z - UNITY_MATRIX_M[3].z;
    float fLen = rsqrt(fX * fX + HALF_MIN * HALF_MIN + fZ * fZ);
    return float3(fX * fLen, HALF_MIN * fLen, fZ * fLen);
}

float LinearToSRGB(float c)
{
    return ((c <= 0.0031308) ? (c * 12.9232102) : (1.055 * pow(abs(c), 1.0 / 2.4) - 0.055));
}

float3 LinearToSRGB(float3 c)
{
    return LinearToSRGB(c);
}

float3 SampleShadowLut(float3 albedo)
{
    float sR = saturate(LinearToSRGB(albedo.r));
    float sG = saturate(LinearToSRGB(albedo.g));
    float sB = saturate(LinearToSRGB(albedo.b));
    float bSlice = floor(sB * 31.0);
    float lutU = bSlice * 0.03125 + sR * 0.0302734375 + 0.00048828125;
    float lutV = sG * 0.96875 + 0.015625;
    float4 lut0 = ruriSampleSrgbLod(_ShadowLutTex, ruriUvClamp(_ShadowLutTex, float2(lutU, lutV)), 0.0);
    float4 lut1 = ruriSampleSrgbLod(_ShadowLutTex, ruriUvClamp(_ShadowLutTex, float2(lutU + 0.03125, lutV)), 0.0);
    float bFrac = sB * 31.0 - bSlice;
    return lerp(lut0.rgb, lut1.rgb, bFrac);
}

float Luminance(float3 linearRgb)
{
    return dot(linearRgb, float3(0.2126729, 0.7151522, 0.0721750));
}

float3 ComputeShadowColor(float3 albedo)
{
    if (_UseShadowLutTex)
    {
        return SampleShadowLut(albedo);
    }
    float3 shadBright = albedo * _ShadowColorBrightness;
    float shadLum = Luminance(shadBright);
    return _ShadowColorSaturation * (shadBright - shadLum) + shadLum;
}

void Endfield_ApplyScreenSpaceShadowBlur(inout Light mainLight, float4 shadowCoord, float2 normalizedScreenSpaceUV)
{
    mainLight.shadowAttenuation = min(mainLight.shadowAttenuation, GetPerObjectShadowAttenuation(normalizedScreenSpaceUV));
}

float3 ComputeNPRDiffuse(float3 hemisphereN, float3 ambCol, float brightness, float3 blendedLightCol, float blendedLightInt, float minShadow, float combWeight, float3 albScaled, float3 diffColor, float3 rampCol, float rampChroma, float rampChromaInv, out float3 fullDiff, out float ambDiffInt)
{
    float nprNdotL = saturate(dot(hemisphereN, _CharacterParams6.xyz) + _CharacterParams7.x) * _CharacterParams7.y + _CharacterParams7.z;
    float shadowStr = minShadow * _CharacterParams1.y;
    float3 shadAmb = nprNdotL * (shadowStr * (1.0 - ambCol) + ambCol);
    float lightLum = Luminance(blendedLightCol * blendedLightInt);
    float oneMinus12y = 1.0 - _CharacterParams12.y;
    float3 lightBlend = blendedLightCol * _CharacterParams12.y + oneMinus12y;
    fullDiff.r = (shadAmb.r * brightness * lightBlend.r + minShadow * (blendedLightCol.r * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
    fullDiff.g = (shadAmb.g * brightness * lightBlend.g + minShadow * (blendedLightCol.g * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
    fullDiff.b = (shadAmb.b * brightness * lightBlend.b + minShadow * (blendedLightCol.b * blendedLightInt - lightLum) + lightLum) * _CharacterParams0.y;
    float albScaledLum = Luminance(albScaled * 0.65);
    float3 desatShad = (albScaled * 0.65 - albScaledLum) * 1.2 + albScaledLum;
    float3 weightedAmb = lerp(desatShad, albScaled, combWeight);
    float3 shadowBlended = lerp(weightedAmb, diffColor, minShadow);
    float3 rampTinted = shadowBlended * (rampCol * rampChroma + rampChromaInv);
    float shadowLumVal = Luminance(shadowBlended);
    float rampLum = Luminance(rampTinted);
    float lumRatio = clamp(shadowLumVal / max(rampLum, 0.001), 0.0, 1.5);
    ambDiffInt = minShadow * (1.0 - _CharacterParams0.z) + _CharacterParams0.z;
    return rampTinted * lumRatio;
}

float D_GGX_Float(float NdotH, float alpha2)
{
    float d = (NdotH * alpha2 - NdotH) * NdotH + 1.0;
    float d2 = d * d;
    float D = ((d2 != alpha2) ? alpha2 / d2 : 1.0);
    return min(D, 2048.0);
}

float V_Kelemen_Endfield(float NoV, float roughness)
{
    return 0.5 / (NoV * 2.0 + roughness + 1e-4);
}

float BRDF_GGX_Stylized_Endfield(float3 N, float3 V, float3 adjustedLightDir, float3 camFwd, float roughness, out float D_raw, out float NdotV_spec, out float3 H, out float NdotH)
{
    NdotV_spec = saturate(dot(N, V));
    float3 camFwdMod = ruriNormalize(float3(camFwd.x, adjustedLightDir.y, camFwd.z));
    H = ruriNormalize(V * 3.0 + adjustedLightDir + camFwdMod * 2.0);
    NdotH = dot(N, H);
    float alpha2 = roughness * roughness;
    D_raw = D_GGX_Float(NdotH, alpha2);
    float V_term = V_Kelemen_Endfield(NdotV_spec, roughness);
    return clamp(D_raw * V_term - HALF_MIN, 0.0, 20.0);
}

float3 ComputeSkinDir(float3 camFwd)
{
    float cp9x = _CharacterParams9.x;
    float cp9y = _CharacterParams9.y;
    float3 d;
    d.x = -cp9y * camFwd.z;
    d.y = camFwd.z * cp9x;
    d.z = camFwd.x * cp9y - cp9x * camFwd.y;
    return ruriNormalize(d);
}

float ComputeSkinSmoothFalloff(float NdotV)
{
    float skinFresnel = 1.0 - abs(NdotV);
    float skinLow = _CharacterParams9.w * (-0.6) + 0.8;
    float skinHigh = _CharacterParams9.w * (-0.4) + 0.9;
    float skinT = saturate((skinFresnel - skinLow) / (skinHigh - skinLow));
    return skinT * skinT * (3.0 - 2.0 * skinT);
}

float3 ComputeSkinSpec(float3 skinDir, float3 N, float3 diffColor, float skinShadow, float skinAmt)
{
    float skinNdotBN = saturate(dot(skinDir, N));
    float3 s;
    s.r = skinShadow * skinAmt * _CharacterParams8.x * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.r - 0.25) + 0.25);
    s.g = skinShadow * skinAmt * _CharacterParams8.y * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.g - 0.25) + 0.25);
    s.b = skinShadow * skinAmt * _CharacterParams8.z * _CharacterParams8.w * skinNdotBN * (_CharacterParams9.z * (diffColor.b - 0.25) + 0.25);
    return s;
}

half Fd_Wrap(half NdotL)
{
    return saturate(0.5 + NdotL - 0.5 * NdotL * NdotL);
}

half Subsurf_EdgeGate(half NdotV, half range)
{
    half t = saturate((-abs(NdotV) + range) * 5.0);
    return t * t * (3.0 - 2.0 * t);
}

float3 BRDF_SubsurfaceSpec_Endfield(float3 N, float3 V, float adjXZ_x, float adjXZ_z, float adjXZLen, float camLightFacing, float mask, float diffColorLum, float3 diffColor, float3 subsurfLight)
{
    float mainNdotL_xz = dot(float3(adjXZ_x, adjXZLen * HALF_MIN, adjXZ_z), N);
    float wrapNdotL = Fd_Wrap(mainNdotL_xz);
    float edgeFresnel = Subsurf_EdgeGate(dot(V, N), 0.4);
    float brightT = saturate((0.1 - diffColorLum) * 16.666);
    float brightnessGate = brightT * brightT * (3.0 - 2.0 * brightT);
    return brightnessGate * mask * edgeFresnel * camLightFacing * wrapNdotL * subsurfLight * max(diffColor, 0.15);
}

float3 DesaturateAroundLuma(float3 color, float refLum, float desatAmt)
{
    float f = desatAmt * desatAmt + 1.0;
    return f * (color - refLum) + refLum;
}

float3 VFXColorAdjust(float3 litColor, float NdotV, float rimMod)
{
    float litLum = Luminance(litColor);
    float3 adjusted;
    adjusted.r = _ColorAdjustmentContrast * (lerp(litLum, litColor.r, _ColorAdjustmentSaturation) - 0.5) + 0.5;
    adjusted.g = _ColorAdjustmentContrast * (lerp(litLum, litColor.g, _ColorAdjustmentSaturation) - 0.5) + 0.5;
    adjusted.b = _ColorAdjustmentContrast * (lerp(litLum, litColor.b, _ColorAdjustmentSaturation) - 0.5) + 0.5;
    float caRimT = saturate((_ColorAdjustmentRimWidth - NdotV) / max(_ColorAdjustmentRimWidth, 1e-5));
    float caRimSmooth = caRimT * caRimT * (3.0 - 2.0 * caRimT);
    return lerp(adjusted * _ColorAdjustmentBrightness, _ColorAdjustmentColorBlend.rgb, _ColorAdjustmentColorBlend.w) + (rimMod * caRimSmooth) * _ColorAdjustmentRimColor.rgb * _ColorAdjustmentRimIntensity;
}

void Endfield_Face(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, float faceSign)
{
    float2 uv = input.uv;
    float4 baseSample = ruriData.baseSample;
    float baseAlpha = baseSample.a;
    float3 albedo;
    if (_UseEmotionMap)
    {
        float halfIdx = 0.5 * _EmotionIndex;
        float2 emotionUV = float2(uv.x * 0.5 + frac(halfIdx), uv.y * 0.5 + floor(halfIdx) * 0.5);
        float4 e = ruriSampleSrgb(_EmotionMap, emotionUV);
        float t = e.a * _EmotionBlend;
        albedo.r = mad(t, e.r - baseSample.r * _BaseColor.r, baseSample.r * _BaseColor.r);
        albedo.g = mad(t, e.g - baseSample.g * _BaseColor.g, baseSample.g * _BaseColor.g);
        albedo.b = mad(t, e.b - baseSample.b * _BaseColor.b, baseSample.b * _BaseColor.b);
    }
    else
    {
        albedo = baseSample.rgb * _BaseColor.rgb;
    }
    float3 objectRight = float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[0].z);
    float3 objectUp = float3(UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[1].z);
    if (_FBXRotationFix > 0.5)
    {
        float3 tmp = objectRight;
        objectRight = objectUp;
        objectUp = -tmp;
    }
    float3 faceUp = cross(_FaceForward.xyz, _FaceRight.xyz);
    float3 N = SampleNormalMap(uv, input.normalWS, input.tangentWS, faceSign);
    float3 flatDir = GetObjectFlatDir(input.positionWS);
    float4 sdfMask = (_UseSDFLightmap ? texture(_SDFMask, ruriUvClamp(_SDFMask, uv)) : float4(1, 1, 0, 0));
    float3 camFwdObj = float3(dot(ruriData.camFwd, _FaceRight.xyz), dot(ruriData.camFwd, faceUp), dot(ruriData.camFwd, _FaceForward.xyz));
    camFwdObj *= rsqrt(max(dot(camFwdObj, camFwdObj), 1.175494e-38));
    float camFwdObj_xz_invLen = rsqrt(camFwdObj.x * camFwdObj.x + camFwdObj.z * camFwdObj.z);
    float3 vertNFlatXZ = ruriNormalize(float3(N.x, HALF_MIN, N.z));
    float3 blendedDir = (_UseSDFLightmap ? ruriNormalize(lerp(flatDir, vertNFlatXZ, sdfMask.y)) : vertNFlatXZ);
    float rimModifier = (_UseSDFLightmap ? (lerp(saturate(camFwdObj.z * camFwdObj_xz_invLen + 0.5), 1.0, sdfMask.y) * sdfMask.x) : 1.0);
    float rimOffScale = (_UseSDFLightmap ? lerp(_FaceRimOffScale, _SkinRimOffScale, sdfMask.z) : _SkinRimOffScale);
    float NdotV_sat = saturate(dot(N, ruriData.V));
    float rimAmt = saturate((1.0 - (NdotV_sat * 0.85 + 0.15)) * rimModifier * rimOffScale);
    float3 rimAlbedo = albedo * (_SDFRimColor.rgb * rimAmt + (1.0 - rimAmt));
    float specScale = (_UseSDFLightmap ? sdfMask.y * _Specular : _Specular);
    float roughnessRaw = 1.0 - _Smoothness;
    float roughness = max(roughnessRaw * roughnessRaw, 0.0078125);
    float oneMinusRefl = (1.0 - _Metallic) * 0.96;
    float3 diffColor = oneMinusRefl * rimAlbedo;
    float3 specColor = _Metallic * (rimAlbedo - specScale * 0.04) + specScale * 0.04;
    float3 shadowLut = oneMinusRefl * ComputeShadowColor(albedo);
    Light mainLight = ruriData.mainLight;
    Endfield_ApplyScreenSpaceShadowBlur(mainLight, ruriData.shadowCoord, ruriData.normalizedScreenSpaceUV);
    float3 blendedLightCol;
    blendedLightCol.r = mainLight.color.r + _CharacterParams12.y * (_CharacterParams4.x - mainLight.color.r);
    blendedLightCol.g = mainLight.color.g + _CharacterParams12.y * (_CharacterParams4.y - mainLight.color.g);
    blendedLightCol.b = mainLight.color.b + _CharacterParams12.y * (_CharacterParams4.z - mainLight.color.b);
    float blendedLightInt = 1.0;
    float3 sdfBlendedN = N;
    float sdfValue = 0.0;
    float sdfNdotL = 0.0;
    if (_UseSDFLightmap)
    {
        float objLightX = dot(ruriData.adjustedLightDir, _FaceRight.xyz);
        float objLightZ = dot(ruriData.adjustedLightDir, _FaceForward.xyz);
        float objLight_invLen = rsqrt(objLightX * objLightX + HALF_MIN * HALF_MIN + objLightZ * objLightZ);
        float sdfLightZ = objLight_invLen * objLightZ;
        float lightSide = ((objLight_invLen * objLightX > 0.0) ? 1.0 : 0.0);
        float mirrorU = 1.0 - uv.x;
        float2 sdfUV = float2(mad(lightSide, uv.x - mirrorU, mirrorU), uv.y);
        float4 sdfSample = textureLod(_SDFLightmap, ruriUvClamp(_SDFLightmap, sdfUV), 0.0);
        sdfValue = sdfSample.x + sdfSample.y;
        float sdfNx_base = 1.0 - 2.0 * sdfSample.z;
        float sdfNx = mad(lightSide, (2.0 * sdfSample.z - 1.0) - sdfNx_base, sdfNx_base);
        float3 sdfFlatN = ruriNormalize(float3(sdfNx, HALF_MIN, 1.0 - abs(sdfNx)));
        float3 sdfNormalWS = ruriNormalize(sdfFlatN.x * _FaceRight.xyz + sdfFlatN.y * faceUp + sdfFlatN.z * _FaceForward.xyz);
        sdfBlendedN = ruriNormalize(lerp(sdfNormalWS, N, sdfMask.y));
        float backlitFactor = ruriData.camLightDot * saturate(-sdfLightZ) * (1.0 - _CharacterParams12.x);
        float sdfWrapNdotL = sdfLightZ + backlitFactor * (0.5 * (1.0 - sdfLightZ * sdfLightZ));
        float halfWrap = sdfWrapNdotL * 0.5;
        float sdfT = clamp(0.5 - halfWrap, 0.001, 0.999);
        float sdfS = saturate((sdfValue * 0.5 - max(2.0 * sdfT - 1.0, 0.0)) / (min(2.0 * sdfT, 1.0) - max(2.0 * sdfT - 1.0, 0.0)));
        sdfNdotL = abs(sdfS * sdfS * (3.0 - 2.0 * sdfS) + ceil(halfWrap) * halfWrap) * 2.0 - 1.0;
    }
    float geomNdotL = dot(N, ruriData.adjustedLightDir);
    float clampedNdotL = clamp(_CharacterParams11.w * _CharacterParams12.x + geomNdotL, -1.0, 1.0);
    float rampInput = (_UseSDFLightmap ? (lerp(sdfNdotL, clampedNdotL, sdfMask.y) * 0.5 + 0.5) : (clampedNdotL * 0.5 + 0.5));
    float3 rampCol;
    float rampA;
    float rampChroma;
    float rampChromaInv;
    if (_UseDiffRampMap)
    {
        float4 rampSmp = textureLod(_DiffRampMap, ruriUvClamp(_DiffRampMap, float2(rampInput, 0.5)), 0.0);
        rampCol = rampSmp.rgb;
        rampA = rampSmp.a;
        rampChroma = max(rampCol.r, max(rampCol.g, rampCol.b)) - min(rampCol.r, min(rampCol.g, rampCol.b));
        rampChromaInv = 1.0 - rampChroma;
    }
    else
    {
        rampCol = float3(1, 1, 1);
        rampA = 1.0;
        rampChroma = 0.0;
        rampChromaInv = 1.0;
    }
    float castShadow = (_UseSDFLightmap ? 1.0 : lerp(smoothstep(0.0, 1.0, mainLight.shadowAttenuation), 1.0, _CharacterParams1.z));
    float minShadow = min(rampA, baseAlpha) * castShadow;
    float combWeight = saturate(baseAlpha + rampA);
    float brightFull = clamp(ruriData.ambInt, 0.0, 1.5);
    float3 albScaled = shadowLut * _CharacterParams0.z;
    float3 fullDiff;
    float ambDiffInt;
    float3 nprDiff = ComputeNPRDiffuse(blendedDir, _CharacterParams3.xyz, brightFull, blendedLightCol, blendedLightInt, minShadow, combWeight, albScaled, diffColor, rampCol, rampChroma, rampChromaInv, fullDiff, ambDiffInt);
    float3 ambDiff = ambDiffInt * (minShadow * 0.5 + 0.5) * fullDiff;
    float ggxD_raw;
    float ggxNdotV;
    float3 ggxH;
    float ggxNdotH;
    float ggxTerm = BRDF_GGX_Stylized_Endfield(N, ruriData.V, ruriData.adjustedLightDir, ruriData.camFwd, roughness, ggxD_raw, ggxNdotV, ggxH, ggxNdotH);
    float3 hlSample = float3(0, 0, 0);
    if (_FaceHighlightMap)
    {
        float hlOffsetX = dot(ruriData.V, objectRight) * _HighlightMapVector.x;
        float hlOffsetY = dot(ruriData.V, objectUp) * _HighlightMapVector.y;
        hlSample = texture(_HighlightMap, float2(uv.x + hlOffsetX, uv.y + hlOffsetY)).rgb;
    }
    float3 mainLit = fullDiff * nprDiff + ambDiff * (specColor * ggxTerm * _CharacterParams13.w + hlSample);
    float mainLitLum = Luminance(mainLit);
    float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);
    float3 skinDir = ComputeSkinDir(ruriData.camFwd);
    float skinSmooth = ComputeSkinSmoothFalloff(dot(ruriData.V, sdfBlendedN));
    float skinAmt;
    if (_UseSDFLightmap)
    {
        float camAngleAbs = abs(camFwdObj.z * camFwdObj_xz_invLen);
        float camGateT = saturate((camAngleAbs - 0.9) * 10.0);
        float camGate = camGateT * camGateT * (3.0 - 2.0 * camGateT);
        float cp9wGate = saturate(_CharacterParams9.w * 10.0 - 3.0);
        float camFacingSkin = ((dot(ruriData.camFwd, skinDir) < -0.01) ? 1.0 : 0.0);
        skinAmt = lerp(camGate * skinSmooth, max(camGate, camFacingSkin) * sdfMask.w, cp9wGate);
    }
    else
    {
        skinAmt = skinSmooth;
    }
    float skinShadow = min(baseAlpha, saturate(dot(flatDir, skinDir) + 1.0));
    float3 skinTerm = ComputeSkinSpec(skinDir, sdfBlendedN, diffColor, skinShadow, skinAmt);
    float diffColorLum = Luminance(diffColor);
    float3 subsurfSpec = BRDF_SubsurfaceSpec_Endfield(N, ruriData.V, ruriData.adjXZ_x, ruriData.adjXZ_z, ruriData.adjXZLen, (1.0 - _CharacterParams12.x) * ruriData.camLightDot, baseAlpha, diffColorLum, diffColor, blendedLightCol * blendedLightInt);
    float3 cp14Term = float3(0, 0, 0);
    if (_UseSDFLightmap)
    {
        float halfCP15 = 0.5 * _CharacterParams15.z;
        float cp15T = clamp(0.5 - halfCP15, 0.001, 0.999);
        float cp15Lo = max(2.0 * cp15T - 1.0, 0.0);
        float cp15Hi = min(2.0 * cp15T, 1.0);
        float cp15S = saturate((sdfValue * 0.5 - cp15Lo) / (cp15Hi - cp15Lo));
        float cp15Raw = saturate(abs(cp15S * cp15S * (3.0 - 2.0 * cp15S) + ceil(halfCP15) * halfCP15) * 2.0 - 0.5);
        float cp14Spec = (1.0 - sdfMask.y) * (cp15Raw * cp15Raw * (3.0 - 2.0 * cp15Raw));
        cp14Term = diffColor * cp14Spec * _CharacterParams14.xyz * _CharacterParams14.w;
    }
    float3 litColor = DesaturateAroundLuma(mainLit, mainLitLum, desatAmt) + skinTerm + subsurfSpec + cp14Term;
    if (_EnableVFXColorAdjustment > 0.5)
        litColor = VFXColorAdjust(litColor, NdotV_sat, rimModifier);
    float3 finalColor = litColor / _ExposureParams.x;
    outputData.baseColor = albedo;
    outputData.normalWS = N;
    outputData.roughness = roughnessRaw;
    outputData.metallic = _Metallic;
    outputData.specular = specScale;
    outputData.globalIllumination = float4(finalColor, 1.0);
}

void Endfield_Eyes(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, float faceSign)
{
    float3 rawN = input.normalWS;
    float nInvLen = rsqrt(max(dot(rawN, rawN), 1.175494e-38));
    float3 N = faceSign * (nInvLen * rawN);
    float3 T = input.tangentWS.xyz;
    float tSign = input.tangentWS.w;
    float3 B = cross(rawN, T) * tSign;
    // 虹膜遮罩恒算:真源 b26(_EYE_HIGHLIGHT 无 _MATCAP_ON)照样算 step(0.25, dot(uv-0.5, uv-0.5)),
    // 它是 uv 的纯函数,跟 matcap 无关——曾经藏在 matcap 分支里,关掉 matcap 就恒 0,
    // 于是眼白也被当虹膜(下面的染色/高光全错位)。
    float2 fracUV = frac(input.uv);
    float2 uvFromCenter = fracUV - 0.5;
    float distSq = dot(uvFromCenter, uvFromCenter);
    float irisMask = ((distSq >= 0.25) ? 1.0 : 0.0);
    float scaledNx = 0.0;
    float scaledNy = 0.0;
    float matNz = 1.0;
    float2 sampleUV = input.uv;
    float3 lightN = N;
    float3 flatLightN = ruriNormalize(float3(N.x, HALF_MIN, N.z));
    if (_UseMatcap)
    {
        float Tv = dot(nInvLen * T, ruriData.V);
        float Bv = dot(nInvLen * (tSign * cross(rawN, T)), ruriData.V);
        float Nv = dot(nInvLen * rawN, ruriData.V);
        float tbvLen = rsqrt(max(Tv * Tv + Bv * Bv + Nv * Nv, 1.175494e-38));
        float parallaxRaw = saturate((distSq - 0.25) * (-5.0));
        float parallaxSmooth = parallaxRaw * parallaxRaw * (3.0 - 2.0 * parallaxRaw);
        sampleUV = float2(input.uv.x - (tbvLen * Tv * _ParallaxScale) * parallaxSmooth, input.uv.y - (tbvLen * Bv * _ParallaxScale * 0.25) * parallaxSmooth);
        float matNx = fracUV.x * 2.0 - 1.0;
        float matNy = fracUV.y * 2.0 - 1.0;
        matNz = max(sqrt(saturate(1.0 - dot(float2(matNx, matNy), float2(matNx, matNy)))), 1e-16);
        scaledNx = matNx * (-_MatcapNormalScale);
        scaledNy = matNy * (-_MatcapNormalScale);
        float maskFactor = 0.125 * (irisMask - 1.0);
        lightN = ruriNormalize(T * (scaledNx * maskFactor) + B * (scaledNy * maskFactor) + rawN * lerp(matNz, 1.0, irisMask));
        flatLightN = ruriNormalize(float3(lightN.x, HALF_MIN, lightN.z));
    }
    float4 eyeBaseSample = ruriRead_BaseMap(sampleUV);
    float3 eyeAlbedo = eyeBaseSample.rgb * _BaseColor.rgb;
    // _CUSTOMIZE_AVATAR:虹膜内(mask=0)整块乘 _EyeTintColor,眼白(mask=1)不染
    // (真源 Sub0_Pass0_Fragment_b30:413 逐字)。角色的眼色就住在这个 tint 里 ——
    // 底图本身是中性偏暖的,不染就是过曝的金色。
    if (_AvatarCustomizeEnable)
        eyeAlbedo *= lerp(_EyeTintColor.rgb, float3(1, 1, 1), irisMask);
    float eyeBaseAlpha = eyeBaseSample.a * _BaseColor.a;
    float3 ambCol = _CharacterParams2.xyz;
    float3 blendedLightCol = lerp(ruriData.mainLight.color, _CharacterParams5.xyz, _CharacterParams12.y);
    float blendedLightInt = 1.0;
    float oneMinusRefl = (1.0 - _Metallic) * 0.96;
    float3 diffColor = oneMinusRefl * eyeAlbedo;
    float3 shadowColor = oneMinusRefl * ComputeShadowColor(eyeAlbedo);
    float3 _otwC0 = float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[0].z);
    float3 _otwC1 = float3(UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[1].z);
    float3 _otwC2 = float3(UNITY_MATRIX_M[2].x, UNITY_MATRIX_M[2].y, UNITY_MATRIX_M[2].z);
    if (_FBXRotationFix > 0.5)
    {
        float3 tmp = _otwC0;
        _otwC0 = _otwC1;
        _otwC1 = -tmp;
    }
    float3x3 o2w3x3 = float3x3(_otwC0.x, _otwC1.x, _otwC2.x, _otwC0.y, _otwC1.y, _otwC2.y, _otwC0.z, _otwC1.z, _otwC2.z);
    float3 localLight = mul(ruriData.adjustedLightDir, o2w3x3);
    float3 normLocal = localLight * rsqrt(max(dot(localLight, localLight), 1.175494e-38));
    float3 projLight = mul(o2w3x3, float3(normLocal.x, 0, normLocal.z));
    projLight *= rsqrt(max(dot(projLight, projLight), 1.175494e-38));
    // 散射/高光混色的门是 **_EYE_HIGHLIGHT**,不是 _MATCAP_ON:真源变体矩阵实证 ——
    // b26(HIGHLIGHT 无 MATCAP)有 _EyeScatteringColor/_EyeHighLightColor,
    // b27(MATCAP 无 HIGHLIGHT)一处都没有。接错关键字 = 开了 matcap 就凭空多一层散射,
    // 关了 matcap 又把该有的高光整块吞掉。
    float3 eyeBlend = float3(1, 1, 1);
    if (_EyeHighLight)
    {
        float insideMask = 1.0 - irisMask;
        eyeBlend = (_EyeHighLightColor.rgb * irisMask + insideMask) * (_EyeScatteringColor.rgb * eyeBaseAlpha + (1.0 - eyeBaseAlpha));
    }
    float3 eyeRampCol = float3(1, 1, 1);
    float eyeRampAlpha = 1.0;
    float eyeRampChroma = 0.0;
    float eyeRampChromaInv = 1.0;
    float eyeRampViewAlpha = 0.0;
    if (_UseDiffRampMap)
    {
        float rampNdotL = dot(lightN, projLight);
        float rampInput = clamp(_CharacterParams11.w * _CharacterParams12.x + rampNdotL, -1.0, 1.0) * 0.5 + 0.5;
        float4 s = textureLod(_DiffRampMap, ruriUvClamp(_DiffRampMap, float2(rampInput, 0.5)), 0.0);
        eyeRampCol = s.rgb;
        eyeRampAlpha = s.a;
        float viewU = dot(lightN, ruriData.camFwd) * 0.5 + 0.5;
        eyeRampViewAlpha = textureLod(_DiffRampMap, ruriUvClamp(_DiffRampMap, float2(viewU, 0.5)), 0.0).a;
    }
    eyeRampChroma = max(eyeRampCol.r, max(eyeRampCol.g, eyeRampCol.b)) - min(eyeRampCol.r, min(eyeRampCol.g, eyeRampCol.b));
    eyeRampChromaInv = 1.0 - eyeRampChroma;
    // 眼睛的主光阴影不是乘进 minShadow(那是 Standard/Face/Fur 家族的结构)——真源 b26/b28
    // 是「暗支/亮支整式 lerp」:_1345/_1361 都以屏幕阴影 _1248 为 lerp 因子,
    // ramp alpha 不乘阴影(_1315 = min(1, ramp.a)),也没有 smoothstep。
    float eyeShadow = lerp(ruriData.mainLight.shadowAttenuation, 1.0, _CharacterParams1.z);
    float minRampA = min(eyeRampAlpha, 1.0);
    float combWeight = saturate(eyeRampViewAlpha + eyeRampAlpha);
    float3 albScaled = shadowColor * _CharacterParams0.z;
    float brightFull = clamp(ruriData.ambInt, 0.0, 1.5);
    float3 fullDiffLit;
    float ambDiffInt;
    float3 nprDiffLit = ComputeNPRDiffuse(flatLightN, ambCol, brightFull, blendedLightCol, blendedLightInt, minRampA, combWeight, albScaled, diffColor * eyeBlend, eyeRampCol, eyeRampChroma, eyeRampChromaInv, fullDiffLit, ambDiffInt);
    // 暗支(真源 b28 _1345 左端/_1361 左端):漫反射 = shadAmb × 暗支亮度(CP1.x 只在这里生效)× CP0.w,
    // 颜色 = lerp(albScaled, diffColor×eyeBlend, 视角 ramp alpha)。shadAmb 公式与 ComputeNPRDiffuse 内部一致。
    float nprNdotL = saturate(dot(flatLightN, _CharacterParams6.xyz) + _CharacterParams7.x) * _CharacterParams7.y + _CharacterParams7.z;
    float3 shadAmb = nprNdotL * (_CharacterParams1.y * minRampA * (1.0 - ambCol) + ambCol);
    float brightnessDark = lerp(min(lerp(0.65, 1.0, ruriData.ambInt), 1.5), clamp(ruriData.ambInt, 1.25, 1.75), _CharacterParams1.x);
    float3 fullDiffDark = shadAmb * brightnessDark * _CharacterParams0.w;
    float3 nprDiffDark = lerp(albScaled, diffColor * eyeBlend, eyeRampViewAlpha);
    float3 fullDiff = lerp(fullDiffDark, fullDiffLit, eyeShadow);
    float3 nprDiff = lerp(nprDiffDark, nprDiffLit, eyeShadow);
    float alphaPremult = lerp(1.0, eyeBaseAlpha, _AlphaPremultiply);
    float3 matcapContrib = float3(0, 0, 0);
    if (_UseMatcap)
    {
        // matcap 强度的 ramp 因子是 lerp(视角 alpha, minRampA, 屏幕阴影)(真源 _1367),不是裸 minRampA。
        float matcapMix = lerp(eyeRampViewAlpha, minRampA, eyeShadow);
        float matcapIntensity = (matcapMix * (1.0 - _CharacterParams0.z) + _CharacterParams0.z) * (matcapMix * 0.5 + 0.5);
        float3 matcapFullN = ruriNormalize(T * scaledNx + B * scaledNy + rawN * matNz);
        float3 viewN;
        viewN.x = dot(float3(UNITY_MATRIX_V[0].x, UNITY_MATRIX_V[1].x, UNITY_MATRIX_V[2].x), matcapFullN);
        viewN.y = dot(float3(UNITY_MATRIX_V[0].y, UNITY_MATRIX_V[1].y, UNITY_MATRIX_V[2].y), matcapFullN);
        viewN.z = dot(float3(UNITY_MATRIX_V[0].z, UNITY_MATRIX_V[1].z, UNITY_MATRIX_V[2].z), matcapFullN);
        float viewNLen = rsqrt(max(dot(viewN, viewN), 1.175494e-38));
        float2 matcapUV = float2(viewN.x * viewNLen * 0.5 + 0.5, viewN.y * viewNLen * 0.5 + 0.5);
        float4 matcapSmp = ruriSampleSrgb(_MatcapTex, ruriUvClamp(_MatcapTex, matcapUV));
        matcapContrib = (matcapSmp.rgb * _MatcapColor.a + matcapSmp.a * _MatcapColor.rgb) * (matcapIntensity * fullDiff);
    }
    float3 mainLit = nprDiff * fullDiff * alphaPremult + matcapContrib;
    float mainLitLum = Luminance(mainLit);
    float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);
    float3 term1 = DesaturateAroundLuma(mainLit, mainLitLum, desatAmt);
    float mainNdotL_xz = dot(float3(ruriData.adjXZ_x, ruriData.adjXZLen * HALF_MIN, ruriData.adjXZ_z), lightN);
    float wrapNdotL = saturate(0.5 + mainNdotL_xz - 0.5 * mainNdotL_xz * mainNdotL_xz);
    float cfXZLen = rsqrt(UNITY_MATRIX_I_V[2].x * UNITY_MATRIX_I_V[2].x + UNITY_MATRIX_I_V[2].z * UNITY_MATRIX_I_V[2].z);
    float camLightDotEye = -(ruriData.adjXZ_x * (cfXZLen * UNITY_MATRIX_I_V[2].x) + ruriData.adjXZ_z * (cfXZLen * UNITY_MATRIX_I_V[2].z));
    float camLightFacing = (1.0 - _CharacterParams12.x) * saturate(camLightDotEye);
    float NdotV = dot(ruriData.V, lightN);
    float edgeT = saturate((-abs(NdotV) + 0.4) * 5.0);
    float edgeFresnel = edgeT * edgeT * (3.0 - 2.0 * edgeT);
    float diffColorLum = Luminance(diffColor);
    float brightT = saturate((0.1 - diffColorLum) * 16.666);
    float brightnessGate = brightT * brightT * (3.0 - 2.0 * brightT);
    float3 subsurfSpec = brightnessGate * edgeFresnel * camLightFacing * wrapNdotL * (blendedLightCol * blendedLightInt) * max(diffColor, 0.15);
    // 同上:自发光组的门是 _EYE_HIGHLIGHT。_EMISSION 的项在**同一个括号内**、乘 alphaPremult 之前
    // (真源 b28→b29 净增量逐字:`(_EmissionMap.rgb * _EmissionColor.rgb) * _EmissionBrightness` 加在最前),
    // 采样 uv 与 _BaseMap 同一份视差修正后的 sampleUV。
    // 出货的变体里 _EMISSION 恒与 _EYE_HIGHLIGHT 同现(36 个变体逐条核对),故不另开门。
    float3 eyeDirect = float3(0, 0, 0);
    if (_EyeHighLight)
    {
        float3 emissionTerm = (_UseEmission ? ruriRead_EmissionMap(sampleUV).rgb * _EmissionColor.rgb * _EmissionBrightness : float3(0, 0, 0));
        eyeDirect = (emissionTerm + eyeAlbedo * _CharacterParams13.x + (irisMask * _EyeHighLightColor.rgb) * _CharacterParams13.y + (eyeBaseAlpha * _EyeScatteringColor.rgb) * _CharacterParams13.z) * alphaPremult;
    }
    float3 finalColor = (eyeDirect + subsurfSpec + term1) / _ExposureParams.x;
    outputData.baseColor = eyeAlbedo;
    outputData.normalWS = N;
    outputData.globalIllumination = float4(finalColor, 1.0);
}

float4 SampleDiffRamp(float modNdotL, float3 N, float3 camFwd, out float outChroma, out float outViewAlpha)
{
    if (!_UseDiffRampMap)
    {
        outChroma = 0.0;
        outViewAlpha = 0.0;
        return float4(1, 1, 1, saturate(modNdotL * 0.5 + 0.5));
    }
    float rampInput = clamp(_CharacterParams11.w * _CharacterParams12.x + modNdotL, -1.0, 1.0) * 0.5 + 0.5;
    float4 s = textureLod(_DiffRampMap, ruriUvClamp(_DiffRampMap, float2(rampInput, 0.5)), 0.0);
    outChroma = max(s.r, max(s.g, s.b)) - min(s.r, min(s.g, s.b));
    float viewU = dot(N, camFwd) * 0.5 + 0.5;
    outViewAlpha = textureLod(_DiffRampMap, ruriUvClamp(_DiffRampMap, float2(viewU, 0.5)), 0.0).a;
    return s;
}

float SampleSceneDepth(float2 uv) {
    return 0.0;
}

void Endfield_Hair(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, float faceSign)
{
    float2 uv = input.uv;
    float4 baseSample = ruriData.baseSample;
    float3 albedo = ruriData.albedo;
    float baseAlpha = baseSample.a * _BaseColor.a;
    if (_UseCutoff)
        clip(baseAlpha - _Cutoff);
    float metallic = ruriData.metallic;
    float specScale = ruriData.specScale;
    float shadowMask = ruriData.occlusion;
    float roughness = ruriData.roughness;
    float3 shadowColor = ComputeShadowColor(albedo);
    float3 nrmWS = ruriNormalize(input.normalWS);
    float3 tanWS = ruriNormalize(input.tangentWS.xyz);
    float3 bitWS = cross(nrmWS, tanWS) * input.tangentWS.w;
    float3 N;
    float3 specN;
    if (_UseSpecBumpMap && _UseBumpMap)
    {
        float4 nrmSmp = ruriRead_SplitNormalMap(uv);
        float dnX = (nrmSmp.x * 2.0 - 1.0) * _BumpScale;
        float dnY = (nrmSmp.y * 2.0 - 1.0) * _BumpScale;
        float dnZ = max(sqrt(1.0 - saturate(dnX * dnX + dnY * dnY)), 1e-16);
        N = faceSign * ruriNormalize(dnX * tanWS + dnY * bitWS + dnZ * nrmWS);
        float snX = (nrmSmp.z * 2.0 - 1.0) * _SpecBumpScale;
        float snY = (nrmSmp.w * 2.0 - 1.0) * _SpecBumpScale;
        float snZ = max(sqrt(1.0 - saturate(snX * snX + snY * snY)), 1e-16);
        specN = ruriNormalize(snX * tanWS + snY * bitWS + snZ * nrmWS);
    }
    else
        if (_UseBumpMap)
        {
            float4 nrmSmp = ruriRead_SplitNormalMap(uv);
            float dnX = (nrmSmp.x * 2.0 - 1.0) * _BumpScale;
            float dnY = (nrmSmp.y * 2.0 - 1.0) * _BumpScale;
            float dnZ = max(sqrt(1.0 - saturate(dnX * dnX + dnY * dnY)), 1e-16);
            N = faceSign * ruriNormalize(dnX * tanWS + dnY * bitWS + dnZ * nrmWS);
            specN = N;
        }
        else
        {
            N = faceSign * nrmWS;
            specN = N;
        }
    float3 flatDir = GetObjectFlatDir(input.positionWS);
    float3 otwCol0 = float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[0].z);
    float3 otwCol1 = float3(UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[1].z);
    float3 otwCol2 = float3(UNITY_MATRIX_M[2].x, UNITY_MATRIX_M[2].y, UNITY_MATRIX_M[2].z);
    if (_FBXRotationFix > 0.5)
    {
        float3 tmp = otwCol0;
        otwCol0 = otwCol1;
        otwCol1 = -tmp;
    }
    float3 anisoDir = ruriNormalize(otwCol0 * _AnisotropyDirX + otwCol1);
    float3 blendedBitan = lerp(cross(specN, anisoDir), input.tangentWS.xyz, metallic);
    float tanSignScale = lerp(1.0, input.tangentWS.w, metallic);
    float3 modBitan = tanSignScale * cross(specN, blendedBitan);
    float vDotC0 = dot(ruriData.V, otwCol0);
    float vDotC2 = dot(ruriData.V, otwCol2);
    float nDotC0 = dot(specN, otwCol0);
    float nDotC2 = dot(specN, otwCol2);
    float nXZLen = rsqrt(nDotC0 * nDotC0 + nDotC2 * nDotC2);
    float vXZLen = rsqrt(vDotC0 * vDotC0 + vDotC2 * vDotC2);
    float edgeDot = saturate(dot(float2(nXZLen * nDotC0, nXZLen * nDotC2), float2(vXZLen * vDotC0, vXZLen * vDotC2)));
    float edgeFade = exp2(log2(edgeDot) * _AnisotropyEdgeFade);
    float darkenOffsetX = lerp(_HairDarkenParams.x, _CharacterParams10.y, _CharacterParams10.x);
    float darkenOffsetZ = lerp(_HairDarkenParams.z, _CharacterParams10.w, _CharacterParams10.x);
    float darkenY = lerp(_HairDarkenParams.y, 0.0, _CharacterParams10.x);
    float heightT = saturate(((darkenOffsetZ - input.positionWS.y) + 0.2) * 2.857143);
    float heightSmooth = heightT * heightT * (3.0 - 2.0 * heightT);
    float darkenFactor = max(heightSmooth * darkenY, _HairDarkenParams.w);
    float darkenSum = darkenFactor + darkenOffsetX;
    float3 darkenedAlbedo = albedo;
    float3 darkenedShadowColor = shadowColor;
    float darkenedScale = 1.0;
    if (0.01 < darkenSum)
    {
        float dMax = max(darkenFactor, darkenOffsetX);
        float dInv = 1.0 - dMax;
        float dMul = dMax * 0.8 + dInv;
        darkenedAlbedo = albedo * dMul;
        darkenedShadowColor = shadowColor * dMul;
        darkenedScale = dMax * 2.0 + dInv;
    }
    float3 diffColor = darkenedAlbedo * 0.96;
    float dielSpec = specScale * 0.04;
    float3 shadowDiff = darkenedShadowColor * 0.96;
    float diffColorLum = Luminance(diffColor);
    Light mainLight = ruriData.mainLight;
    Endfield_ApplyScreenSpaceShadowBlur(mainLight, ruriData.shadowCoord, ruriData.normalizedScreenSpaceUV);
    float3 blendedLightCol = lerp(mainLight.color, _CharacterParams5.xyz, _CharacterParams12.y);
    float blendedLightInt = 1.0;
    float geomNdotL = dot(N, ruriData.adjustedLightDir);
    float wrapAdd = 0.5 - 0.5 * geomNdotL * geomNdotL;
    float camFadeFactor = (1.0 - _CharacterParams12.x) * (ruriData.camLightDot * ruriData.camYSmooth);
    float modNdotL = camFadeFactor * wrapAdd + geomNdotL;
    float rampChroma;
    float viewRampA;
    float4 ramp = SampleDiffRamp(modNdotL, N, ruriData.camFwd, rampChroma, viewRampA);
    float viewShadowProduct = viewRampA * shadowMask;
    float minShadow = min(ramp.a, shadowMask);
    float combWeight = saturate(viewShadowProduct + ramp.a);
    float brightFull = clamp(ruriData.ambInt, 0.0, 1.5);
    float3 albScaled = shadowDiff * _CharacterParams0.z;
    float3 fullDiff;
    float ambDiffInt;
    float3 nprDiff = ComputeNPRDiffuse(N, _CharacterParams2.xyz, brightFull, blendedLightCol, blendedLightInt, minShadow, combWeight, albScaled, diffColor, ramp.rgb, rampChroma, 1.0 - rampChroma, fullDiff, ambDiffInt);
    float specAmbInt = ambDiffInt * (minShadow * 0.5 + 0.5);
    float anisoShift1;
    float anisoShift2;
    if (_StrokeOn)
    {
        float2 strokeUV = uv * _StrokeMap_ST.xy + _StrokeMap_ST.zw;
        float strokeVal = texture(_StrokeMap, strokeUV).r * 2.0 - 1.0;
        anisoShift1 = strokeVal * _StrokeScale + _AnisotropyValue * 2.0 - 1.0;
        anisoShift2 = strokeVal * _StrokeScale + _AnisotropyValue2 * 2.0 - 1.0;
    }
    else
    {
        anisoShift1 = _AnisotropyValue * 2.0 - 1.0;
        anisoShift2 = _AnisotropyValue2 * 2.0 - 1.0;
    }
    float3 worldContrib = otwCol0 * vDotC0 + otwCol1 * ruriData.adjustedLightDir.y + otwCol2 * vDotC2;
    float3 H = ruriNormalize(ruriNormalize(ruriData.adjustedLightDir + worldContrib * 2.0) + ruriData.V);
    float3 shiftedT1 = ruriNormalize(specN * anisoShift1 + modBitan);
    float TdotH1 = dot(shiftedT1, H);
    float sinTH1 = max(sqrt(1.0 - TdotH1 * TdotH1), 0.0001);
    float strand1 = saturate(specScale * exp2(log2(sinTH1) * 200.0));
    float3 strand1Spec = (_UseSpecRampMap ? edgeFade * strand1 * textureLod(_SpecRampMap, ruriUvClamp(_SpecRampMap, float2(strand1, edgeFade * edgeFade * (((TdotH1 > 0.0) ? 1.0 : 0.0)))), 0.0).rgb : float3(edgeFade * strand1, edgeFade * strand1, edgeFade * strand1));
    float strand1Max = max(strand1Spec.r, max(strand1Spec.g, strand1Spec.b));
    float3 shiftedT2 = ruriNormalize(specN * anisoShift2 + modBitan);
    float TdotH2 = dot(shiftedT2, H);
    float sinTH2 = max(sqrt(1.0 - TdotH2 * TdotH2), 0.0001);
    float strand2Exp = trunc(max(1.0 - _AnisotropyRange2, 0.0) * 200.0);
    float3 strand2Spec = darkenedScale * (edgeFade * exp2(log2(sinTH2) * strand2Exp)) * ((1.0 - roughness) * _AnisotropyColor2.rgb);
    float lineMod = 1.0;
    if (_SpecularLine)
    {
        float2 lineUV = uv * _LineMap_ST.xy + _LineMap_ST.zw;
        float lineMapVal = texture(_LineMap, lineUV).x;
        float3 shiftedTL = ruriNormalize(specN * (_LineValue * 2.0 - 1.0) + modBitan);
        float TdotHL = dot(shiftedTL, H);
        float sinTHL = max(sqrt(1.0 - TdotHL * TdotHL), 0.0001);
        float procLine = ceil(max(frac(uv.x * _LineAmount) - 0.5, 0.0));
        float lineBlend = (_UseLineMap * (-procLine + (1.0 - lineMapVal)) + procLine) * _LineIntensity + (1.0 - _LineIntensity);
        float lineExp = trunc(max(1.0 - _LineRange, 0.0) * 200.0);
        lineMod = specScale * ((lineBlend + (1.0 - lineBlend) * strand1Max - 1.0) * exp2(log2(sinTHL) * lineExp)) + 1.0;
    }
    float alphaPremul = mad(baseAlpha, _AlphaPremultiply, 1.0 - _AlphaPremultiply);
    float3 mainLit = fullDiff * nprDiff * alphaPremul;
    float3 lineSatLit = lineMod * mainLit;
    float lineSatLitLum = Luminance(lineSatLit);
    float lineSatFactor = lineMod * (1.0 - _LineSaturation) + _LineSaturation;
    float3 diffContrib = lineSatFactor * (lineSatLit - lineSatLitLum) + lineSatLitLum;
    float3 anisoSpec = darkenedScale * dielSpec * strand1Spec * _AnisotropyIntensity * 5.0 + lerp(strand2Spec, float3(0, 0, 0), strand1Max);
    float3 specContrib = specAmbInt * fullDiff * anisoSpec * _CharacterParams13.w;
    float3 combined = diffContrib + specContrib;
    float combinedLum = Luminance(combined);
    float desatAmt = clamp(combinedLum - 0.5, 0.0, 0.5);
    float3 skinDir = ComputeSkinDir(ruriData.camFwd);
    float3 viewN = mul(((float3x3)UNITY_MATRIX_V), N);
    float viewNLen = rsqrt(viewN.x * viewN.x + viewN.y * viewN.y);
    float2 viewNDir = float2(viewN.x * viewNLen, viewN.y * viewNLen);
    float2 screenUV = input.positionNDC.xy / input.positionNDC.w;
    float aspect = _ScreenParams.y / _ScreenParams.x;
    float2 depthSampleUV = clamp(screenUV + viewNDir * float2(aspect, 1.0) * _CharacterParams9.w * 0.006, 1.0 / _ScreenParams.xy, 1.0 - 1.0 / _ScreenParams.xy);
    float sampledLinear = 1.0 / (_ZBufferParams.z * SampleSceneDepth(depthSampleUV) + _ZBufferParams.w);
    float depthT = saturate((sampledLinear - input.positionNDC.w - 0.1) * 10.0);
    float depthSmooth = depthT * depthT * (3.0 - 2.0 * depthT);
    float skinNdotL = min(shadowMask, min(shadowMask, saturate(dot(flatDir, skinDir) + 1.0)));
    float3 skinSpec = ComputeSkinSpec(skinDir, N, diffColor, skinNdotL, depthSmooth);
    float3 subsurfSpec = BRDF_SubsurfaceSpec_Endfield(N, ruriData.V, ruriData.adjXZ_x, ruriData.adjXZ_z, ruriData.adjXZLen, (1.0 - _CharacterParams12.x) * ruriData.camLightDot, shadowMask, diffColorLum, diffColor, blendedLightCol * blendedLightInt);
    float3 litColor = DesaturateAroundLuma(combined, combinedLum, desatAmt) + skinSpec + subsurfSpec;
    if (_EnableVFXColorAdjustment > 0.5)
        litColor = VFXColorAdjust(litColor, saturate(dot(N, ruriData.V)), 1.0);
    float3 finalColor = litColor / _ExposureParams.x;
    float outAlpha = ((_SurfaceType == 1) ? baseSample.a : 1.0);
    ruriData.alpha *= outAlpha;
    outputData.baseColor = albedo;
    outputData.normalWS = N;
    outputData.roughness = roughness;
    outputData.metallic = metallic;
    outputData.specular = specScale;
    outputData.globalIllumination = float4(finalColor, outAlpha);
}

float3 Shell_DyeBlend(float2 uv, float3 albedo)
{
    if (!_FurDyeEnable)
        return albedo;
    float2 dyeUV = float2(mad((uv.x - _BaseMap_ST.z) / max(0.001, abs(_BaseMap_ST.x)), _FurDyeMap_ST.x, _FurDyeMap_ST.z), mad((uv.y - _BaseMap_ST.w) / max(0.001, abs(_BaseMap_ST.y)), _FurDyeMap_ST.y, _FurDyeMap_ST.w));
    float3 dyeSmp = ruriSampleSrgb(_FurDyeMap, dyeUV).rgb;
    float3 screenBlend = 1.0 - (1.0 - albedo) * (1.0 - dyeSmp);
    return lerp(albedo, screenBlend, _FurDyeIntensity);
}

void Shell_SampleSurface(float2 uv, float shellIdx, float3 V, float3 normalWS_raw, out float furSample, out float shellAlpha)
{
    float4 furDirSmp = texture(_FurDirMap, uv);
    float furShellNoise = (frac(sin(dot(float2(shellIdx, shellIdx), float2(12.9898, 78.233))) * 43758.5469) * 2.0 - 1.0) * _FurNoise * 0.05;
    float2 furDirOffset = float2((furDirSmp.x * 2.0 - 1.0) * _FurDirMapEnable * 0.005 + furShellNoise, (furDirSmp.y * 2.0 - 1.0) * _FurDirMapEnable * 0.005 + furShellNoise);
    float2 furSampleUV = float2((uv.x - shellIdx * furDirOffset.x) * _FurMap_ST.x + _FurMap_ST.z, (uv.y - shellIdx * furDirOffset.y) * _FurMap_ST.x + _FurMap_ST.w);
    furSample = texture(_FurMap, furSampleUV).x;
    float cutoff = shellIdx * (_FurCutoffEnd - _FurCutoffStart) + _FurCutoffStart;
    float cutoffSharp = lerp(cutoff, sqrt(cutoff), _FurSharpen);
    float cutLo = max(cutoffSharp - 0.25, 0.0);
    float cutHi = min(cutoffSharp + 0.25, 1.0);
    float furRaw = saturate((furDirSmp.z * furSample - cutLo) / (cutHi - cutLo));
    float furSmooth = furRaw * furRaw * (3.0 - 2.0 * furRaw);
    float isBase = ((shellIdx <= 0.01) ? 1.0 : 0.0);
    float furAlphaRaw = isBase * (1.0 - furSmooth) + furSmooth;
    float3 geomN = ruriNormalize(normalWS_raw);
    float edgeFactor = (1.0 - shellIdx * shellIdx * shellIdx) + dot(geomN, V) - _FurEdgeFade;
    shellAlpha = ceil(shellIdx) * (saturate(furAlphaRaw * edgeFactor) - 1.0) + 1.0;
}

float Shell_AOFromNormalZ(float shellIdx, float nrmZ_raw)
{
    float nrmZ2 = min(nrmZ_raw * 2.0, 1.0);
    float nrmZ2sq = nrmZ2 * nrmZ2;
    return shellIdx * (1.0 - nrmZ2sq * _FurAO) + nrmZ2sq * _FurAO;
}

float Shell_TransmittedNdotL_Endfield(float furSample, float shellIdx, float geomNdotL, float camLightDot)
{
    float furInv = saturate((1.0 - furSample) * 1.4286);
    float furInvSmooth = furInv * furInv * (3.0 - 2.0 * furInv);
    float furTT = furInvSmooth * camLightDot * _FurNoise * (1.15 - _FurTTIntensity) + _FurTTIntensity;
    return clamp(furTT * shellIdx + geomNdotL, -1.0, 1.0);
}

void SpecularRamp_NPR_Endfield(float D_raw, float NdotV_spec, float roughSq4, float metallic, float roughness, float3 specColor, out float3 specRampColor, out float3 specRampEnv)
{
    specRampColor = specColor;
    specRampEnv = specColor;
    if (_UseSpecRampMap)
    {
        float specRampPartial = D_raw * (roughSq4 + 1e-4);
        float specRampU = lerp(specRampPartial, NdotV_spec * NdotV_spec, _SpecRampIridescentMode);
        float specRampV = (1.0 - metallic) * roughness;
        float3 s = textureLod(_SpecRampMap, ruriUvClamp(_SpecRampMap, float2(specRampU, specRampV)), 0).rgb;
        specRampColor = specColor * s;
        specRampEnv = lerp(specColor, specRampColor, _SpecRampIridescentMode);
    }
}

float3 DecodeHDREnvironment(float4 encodedIrradiance, float4 decodeInstructions)
{
    float alpha = max(decodeInstructions.w * (encodedIrradiance.w - 1.0) + 1.0, 0.0);
    return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * encodedIrradiance.xyz;
}

void EnvBRDF_Endfield(float NdotV, float roughSq, out float dfgX, out float dfgY)
{
    float NdotV2 = NdotV * NdotV;
    float NdotV3 = NdotV * NdotV2;
    float roughSq6 = roughSq * roughSq * roughSq;
    float2 numX = float2(dot(float2(3.32707, 1.0), float2(NdotV, 0.0365463)), dot(float2(-9.04756, 1.0), float2(NdotV, 9.0632)));
    float3 denX = float3(dot(float3(3.59685, -1.36772, 1.0), float3(NdotV2, NdotV3, 1.0)), dot(float3(-16.3174, 1.0, 9.22949), float3(NdotV2, 9.04401, NdotV3)), dot(float3(1.0, 19.7886, -20.2123), float3(5.56589, NdotV2, NdotV3)));
    dfgX = dot(numX, float2(1.0, roughSq)) / dot(denX, float3(1.0, roughSq, roughSq6));
    float2 numY = float2(dot(float2(-1.28514, 1.0), float2(NdotV, 0.99044)), dot(float2(1.0, -0.755907), float2(1.29678, NdotV)));
    float3 denY = float3(dot(float3(2.92338, 59.4188, 1.0), float3(NdotV, NdotV3, 1.0)), dot(float3(1.0, -27.0302, 222.592), float3(20.3225, NdotV, NdotV3)), dot(float3(626.13, 316.627, 1.0), float3(NdotV, NdotV3, 121.563)));
    dfgY = dot(numY, float2(1.0, roughSq)) / dot(denY, float3(1.0, roughSq, roughSq6));
}

float3 IBL_SplitSumCombine(half3 cubeSample, float NdotV_spec, float roughness, float3 specRampEnv, float ambIntensity, float3 ambCol)
{
    float dfgX;
    float dfgY;
    EnvBRDF_Endfield(NdotV_spec, roughness, dfgX, dfgY);
    float3 envBRDF = specRampEnv * dfgX + dfgY;
    float totalRefl = dfgX + dfgY;
    float reflBoost = (1.0 - totalRefl) / max(totalRefl, 1e-6);
    float3 cubeRefl = cubeSample * envBRDF * (1.0 + reflBoost * specRampEnv);
    return ambIntensity * cubeRefl * ambCol;
}

float3 IBL_SpecularSplitSum_Endfield_Probe(float3 V, float3 N, float NdotV_spec, float roughness, float roughnessRaw, float3 specRampEnv, float ambIntensity, float3 ambCol)
{
    float3 reflDir = reflect(-V, N);
    float cubeMip = log2(max(roughnessRaw, 0.001)) * 1.2 + 5.0;
    half4 cubeEnc = envSampleLOD(reflDir, cubeMip);
    half3 cubeSample = DecodeHDREnvironment(cubeEnc, unity_SpecCube0_HDR);
    return IBL_SplitSumCombine(cubeSample, NdotV_spec, roughness, specRampEnv, ambIntensity, ambCol);
}

void Endfield_Fur(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, float faceSign)
{
    float shellIdx = input.uv1.x;
    float3 furAlbedo = Shell_DyeBlend(input.uv, ruriData.albedo);
    float3 shadowColor = ComputeShadowColor(furAlbedo);
    float nrmZ_raw = 1.0;
    float3 N;
    if (_UseBumpMap)
    {
        float4 nrmSmp = ruriRead_BumpMap(input.uv);
        float nrmX_raw = nrmSmp.x * nrmSmp.w * 2.0 - 1.0;
        float nrmY_raw = nrmSmp.y * 2.0 - 1.0;
        nrmZ_raw = max(sqrt(1.0 - saturate(nrmX_raw * nrmX_raw + nrmY_raw * nrmY_raw)), 1e-16);
        float3 nrmWS = ruriNormalize(input.normalWS);
        float3 tanWS = ruriNormalize(input.tangentWS.xyz);
        float3 bitWS = cross(nrmWS, tanWS) * input.tangentWS.w;
        N = faceSign * ruriNormalize((nrmX_raw * _BumpScale) * tanWS + (nrmY_raw * _BumpScale) * bitWS + nrmZ_raw * nrmWS);
    }
    else
    {
        N = faceSign * ruriNormalize(input.normalWS);
    }
    float furSample;
    float shellAlpha;
    Shell_SampleSurface(input.uv, shellIdx, ruriData.V, input.normalWS, furSample, shellAlpha);
    clip(shellAlpha - 0.003);
    float furShadowMask = Shell_AOFromNormalZ(shellIdx, nrmZ_raw) * ruriData.occlusion;
    float4 vfxBlendSmp = float4(0, 0, 0, 0);
    float vfxTexAlpha = 0.0;
    float3 vfxMainRGB = float3(0, 0, 0);
    float vfxFresnelFlipped = 0.0;
    float vfxAlphaBase = 0.0;
    float vfxDissolveDelta = 0.0;
    float vfxDissolveEdge = 0.0;
    if (_EnableCharacterVFX)
    {
        float t = _Time.y;
        float2 vfxBlendUV = float2(mad(mad(_VFXSpecialParam.z, t, input.uv.x), _VFXSpecialBlendTex_ST.x, _VFXSpecialBlendTex_ST.z), mad(mad(_VFXSpecialParam.w, t, input.uv.y), _VFXSpecialBlendTex_ST.y, _VFXSpecialBlendTex_ST.w));
        vfxBlendSmp = ruriSampleSrgb(_VFXSpecialBlendTex, vfxBlendUV);
        float2 vfxDistortUV = input.uv + vfxBlendSmp.r * _VFXSpecialBlendTexRForDisturb;
        float2 vfxMainUV = float2(mad(mad(_VFXSpecialParam.x, t, vfxDistortUV.x), _VFXSpecialMainTex_ST.x, _VFXSpecialMainTex_ST.z), mad(mad(_VFXSpecialParam.y, t, vfxDistortUV.y), _VFXSpecialMainTex_ST.y, _VFXSpecialMainTex_ST.w));
        float4 vfxMainSmp = ruriSampleSrgb(_VFXSpecialMainTex, vfxMainUV);
        vfxTexAlpha = lerp(vfxMainSmp.a, vfxMainSmp.r, _UseVFXMainTexAsAlpha);
        vfxMainRGB = lerp(vfxMainSmp.rgb, float3(1, 1, 1), _UseVFXMainTexAsAlpha);
        float3 vfxGeomN = ruriNormalize(input.normalWS);
        float vfxFresnel = exp2(log2(saturate(dot(ruriData.V, vfxGeomN) + _VFXFresnelBias)) * _VFXFresnelPower);
        vfxFresnelFlipped = lerp(1.0 - vfxFresnel, vfxFresnel, _VFXFresnelFlip);
        vfxAlphaBase = _VFXColorAlpha * _VFXColor.a;
        vfxDissolveDelta = vfxBlendSmp.r - (_SpecialDissolveScheduleOffset * 2.02 - 1.01);
        vfxDissolveEdge = saturate(-vfxDissolveDelta);
    }
    float3 flatDir = GetObjectFlatDir(ruriData.positionWS);
    float3 ambCol = _CharacterParams2.xyz;
    float3 blendedLightCol = lerp(ruriData.mainLight.color, _CharacterParams5.xyz, _CharacterParams12.y);
    float blendedLightInt = 1.0;
    float roughnessF = float(ruriData.roughness);
    float metallicF = float(ruriData.metallic);
    float specScaleF = float(ruriData.specScale);
    float dielSpec = specScaleF * 0.04;
    float oneMinusRefl = (1.0 - metallicF) * 0.96;
    float3 diffColor = oneMinusRefl * furAlbedo;
    float3 specColor = metallicF * (furAlbedo - dielSpec) + dielSpec;
    float3 shadowDiff = oneMinusRefl * shadowColor;
    float alpha2 = max(roughnessF * roughnessF, 0.0078125);
    float roughSq4 = alpha2 * alpha2;
    float geomNdotL = dot(N, ruriData.adjustedLightDir);
    float furModNdotL = Shell_TransmittedNdotL_Endfield(furSample, shellIdx, geomNdotL, ruriData.camLightDot);
    float wrapAdd = 0.5 - 0.5 * furModNdotL * furModNdotL;
    float modNdotL = (1.0 - _CharacterParams12.x) * (ruriData.camLightDot * ruriData.camYSmooth) * wrapAdd + furModNdotL;
    float furChroma;
    float furViewAlpha;
    float4 furRamp = SampleDiffRamp(modNdotL, N, ruriData.camFwd, furChroma, furViewAlpha);
    float castShadow = lerp(smoothstep(0.0, 1.0, ruriData.mainLight.shadowAttenuation), 1.0, _CharacterParams1.z);
    float minShadow = min(furRamp.a, furShadowMask) * castShadow;
    float viewShadowProduct = furViewAlpha * furShadowMask;
    float combWeight = saturate(viewShadowProduct + furRamp.a);
    float3 albScaled = shadowDiff * _CharacterParams0.z;
    float diffColorLum = Luminance(diffColor);
    float brightFull = clamp(ruriData.ambInt, 0.0, 1.5);
    float3 fullDiff;
    float ambDiffInt;
    float3 nprDiff = ComputeNPRDiffuse(N, ambCol, brightFull, blendedLightCol, blendedLightInt, minShadow, combWeight, albScaled, diffColor, furRamp.rgb, furChroma, 1.0 - furChroma, fullDiff, ambDiffInt);
    float specAmbInt = ambDiffInt * (minShadow * 0.5 + 0.5);
    float ggxD_raw;
    float ggxNdotV;
    float3 ggxH;
    float ggxNdotH;
    float ggxTerm = BRDF_GGX_Stylized_Endfield(N, ruriData.V, ruriData.adjustedLightDir, ruriData.camFwd, alpha2, ggxD_raw, ggxNdotV, ggxH, ggxNdotH);
    float3 specRampColor;
    float3 specRampEnv;
    SpecularRamp_NPR_Endfield(ggxD_raw, ggxNdotV, roughSq4, metallicF, roughnessF, specColor, specRampColor, specRampEnv);
    float alphaPremul = shellAlpha * _AlphaPremultiply + (1.0 - _AlphaPremultiply);
    float3 mainLit = fullDiff * nprDiff * alphaPremul + (specAmbInt * fullDiff) * (ggxTerm * specRampColor) * _CharacterParams13.w;
    float mainLitLum = Luminance(mainLit);
    float3 skinDir = ComputeSkinDir(ruriData.camFwd);
    float skinShadow = min(furShadowMask, saturate(dot(flatDir, skinDir) + 1.0));
    float3 skinSpec = ComputeSkinSpec(skinDir, N, diffColor, skinShadow, ComputeSkinSmoothFalloff(dot(ruriData.V, N)));
    float camLightFacing = (1.0 - _CharacterParams12.x) * ruriData.camLightDot;
    float3 subsurfSpec = BRDF_SubsurfaceSpec_Endfield(N, ruriData.V, ruriData.adjXZ_x, ruriData.adjXZ_z, ruriData.adjXZLen, camLightFacing, furShadowMask, diffColorLum, diffColor, blendedLightCol * blendedLightInt);
    float cubeAmbInt = ambDiffInt * (clamp(ruriData.exposure, 0.5, 1.5) * _CharacterParams0.w);
    float3 cubemapContrib = IBL_SpecularSplitSum_Endfield_Probe(ruriData.V, N, ggxNdotV, alpha2, roughnessF, specRampEnv, cubeAmbInt, ambCol);
    float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);
    float3 desatMainLit = DesaturateAroundLuma(mainLit, mainLitLum, desatAmt);
    float3 finalColor = desatMainLit + skinSpec + subsurfSpec + cubemapContrib;
    if (_EnableCharacterVFX)
    {
        float vfxBlendFactor = saturate((vfxAlphaBase * vfxTexAlpha + vfxBlendSmp.a) * _VFXBlendTint.a);
        float3 vfxColorTerm = _VFXColorIntensity * _VFXColor.rgb * vfxMainRGB;
        float3 vfxMainColor = vfxBlendSmp.rgb * vfxBlendFactor * _VFXBlendTint.rgb + vfxColorTerm;
        float3 vfxDissolvedColor = lerp(vfxMainColor, vfxDissolveEdge * _VFXFresnelColor.rgb * _VFXColorIntensity, vfxDissolveEdge);
        float vfxFresnelAlpha = vfxFresnelFlipped * _VFXFresnelColor.a;
        float vfxDissolveVis = saturate(vfxDissolveDelta);
        float vfxOpacity = saturate(vfxDissolveVis * vfxAlphaBase * vfxTexAlpha) * lerp(1.0, vfxFresnelFlipped, _VFXFresnelAffectOpacity);
        float3 vfxContrib = vfxOpacity * lerp(vfxDissolvedColor, _VFXFresnelColor.rgb, vfxFresnelAlpha);
        finalColor += vfxContrib * alphaPremul;
    }
    finalColor /= _ExposureParams.x;
    ruriData.alpha = ((_SurfaceType == 1) ? shellAlpha : 1.0);
    outputData.baseColor = furAlbedo;
    outputData.normalWS = N;
    outputData.roughness = ruriData.roughness;
    outputData.metallic = ruriData.metallic;
    outputData.specular = ruriData.specScale;
    outputData.globalIllumination = float4(finalColor, shellAlpha);
}

float2 ComputeVFXUV_Endfield(float2 uv0, float2 uv1, float4 weights, float4 speed, float time, float customData, float4 rotateMat, float4 st, float2 disturb, float useDisturb)
{
    float2 uv = uv0 * weights.x + uv1 * weights.y;
    uv += speed.xy * time + speed.zw * customData;
    float2 c = uv - 0.5;
    uv.x = c.x * rotateMat.x + c.y * rotateMat.z + 0.5;
    uv.y = c.x * rotateMat.y + c.y * rotateMat.w + 0.5;
    uv = uv * st.xy + st.zw;
    uv += disturb * useDisturb;
    return uv;
}

void Endfield_VFX(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, half facing)
{
    float time = _Time.y;
    float custom1X = input.uv1.x * _InParticle;
    float custom1Y = input.uv1.y * _InParticle;
    float2 uv0 = input.uv;
    float2 uv1 = float2(mad(input.uv0zw.x, _InParticle, -custom1X) + input.uv1.x, mad(input.uv0zw.y, _InParticle, -custom1Y) + input.uv1.y);
    float2 disturb = float2(0, 0);
    if (_UseDisturb)
    {
        float2 disturbUV = ComputeVFXUV_Endfield(uv0, uv1, _DisturbUVWeights1, _DisturbUVSpeed1, time, custom1Y, _DisturbUVRotateMat1, _DisturbTex1_ST, float2(0, 0), 0);
        float4 disturbSample = texture(_DisturbTex1, disturbUV);
        float biDisturb = mad(disturbSample.x, 1.0 + _Bi_Disturb, -_Bi_Disturb);
        bool isNormalMode = (0.0 != _DisturbTex1Normal);
        disturb.x = (isNormalMode ? mad(biDisturb * disturbSample.w, 2.0, -1.0) * _DisturbUIntensity1 : biDisturb * _DisturbUIntensity1);
        disturb.y = (isNormalMode ? mad(disturbSample.y, 2.0, -1.0) * _DisturbUIntensity1 : biDisturb * _DisturbVIntensity1);
    }
    float2 mainUV = ComputeVFXUV_Endfield(uv0, uv1, _MainTexUVWeights, _MainTexUVSpeed, time, custom1X, _MainTexUVRotateMat, _MainTex_ST, disturb, _MainTexUseDisturb);
    float4 mainSample = ruriSampleSrgb(_MainTex, mainUV);
    float mainAlpha = lerp(mainSample.a, mainSample.r, _UseMainTexAsAlpha);
    float baseAlpha = lerp(input.color.a, 1.0, _DisableVertColor) * _TintColor.a * _TintColorAlpha * mainAlpha;
    float maskAlpha = 1.0;
    float3 maskColorFactor = float3(1, 1, 1);
    if (_UseMask)
    {
        float2 maskUV = ComputeVFXUV_Endfield(uv0, uv1, _MaskTexUVWeights, _MaskTexUVSpeed, time, custom1Y, _MaskTexUVRotateMat, _MaskTex_ST, disturb, _MaskTexUseDisturb);
        float4 maskSample = texture(_MaskTex, maskUV);
        maskAlpha = lerp(maskSample.a, maskSample.r, _UseMaskTexAsAlpha);
        maskColorFactor = lerp(maskSample.rgb, float3(1, 1, 1), _UseMaskTexAsAlpha);
    }
    float3 vcAdj = lerp(input.color.rgb, float3(1, 1, 1), _DisableVertColor);
    float3 mainColorFactor = lerp(mainSample.rgb, float3(1, 1, 1), _UseMainTexAsAlpha);
    float3 color = vcAdj * _TintColor.rgb * _TintColorIntensity * mainColorFactor * maskColorFactor;
    float combinedAlpha = baseAlpha * maskAlpha;
    if (_UseBlend)
    {
        float2 blendUV = ComputeVFXUV_Endfield(uv0, uv1, _BlendTexUVWeights, _BlendTexUVSpeed, time, custom1Y, _BlendTexUVRotateMat, _BlendTex_ST, disturb, _BlendTexUseDisturb);
        float4 blendSample = ruriSampleSrgb(_BlendTex, blendUV);
        float blendFactor = saturate((combinedAlpha + blendSample.a) * input.color.a * _BlendTint.a);
        color += blendFactor * blendSample.rgb * input.color.rgb * _BlendTint.rgb;
    }
    float3 faceNormal = ruriNormalize(input.normalWS);
    if (_EnableNormalMap != 0.0)
    {
        float2 normalUV = ComputeVFXUV_Endfield(uv0, uv1, _NormalMapUVWeights, _NormalMapUVSpeed, time, custom1Y, _NormalMapUVRotateMat, _NormalMap_ST, disturb, _NormalMapUseDisturb);
        float4 nSample = ruriSampleSrgb(_NormalMap, normalUV);
        float3 normalTS = float3(0, 0, 0);
        normalTS.x = nSample.r * nSample.a * 2.0 - 1.0;
        normalTS.y = nSample.g * 2.0 - 1.0;
        normalTS.z = max(sqrt(1.0 - min(dot(normalTS.xy, normalTS.xy), 1.0)), 1e-16);
        normalTS.xy *= _NormalScale;
        normalTS = ruriNormalize(normalTS);
        float3 T = ruriNormalize(input.tangentWS.xyz);
        float3 N = faceNormal;
        float bSign = ((input.tangentWS.w > 0.0) ? 1.0 : -1.0);
        float3 B = bSign * cross(N, T);
        faceNormal = ruriNormalize(normalTS.x * T + normalTS.y * B + normalTS.z * N);
    }
    faceNormal = ((facing >= 0) ? faceNormal : -faceNormal);
    float fresnelTerm = 1.0;
    if (_UseFresnel)
    {
        float3 viewDir = ruriNormalize(_WorldSpaceCameraPos - input.positionWS);
        float NdotV = dot(viewDir, faceNormal) + _FresnelBias;
        float fresnel = pow(saturate(NdotV), _FresnelPower);
        float invFresnel = 1.0 - fresnel;
        fresnelTerm = mad(_FresnelFlip, fresnel - invFresnel, invFresnel);
        float fresnelBlend = fresnelTerm * _FresnelColor.a;
        color = lerp(color, _FresnelColor.rgb, fresnelBlend);
    }
    float exposureScale = mad(_ExposureParams.x, _IgnorePostExposure, 1.0 - _IgnorePostExposure);
    color = clamp(color / exposureScale, 0.0, 1000.0);
    float nearFade = 1.0;
    if (_UseNearCameraFade != 0.0)
    {
        float dist = abs(dot(float3(UNITY_MATRIX_V[0].z, UNITY_MATRIX_V[1].z, UNITY_MATRIX_V[2].z), input.positionWS) + UNITY_MATRIX_V[3].z);
        nearFade = saturate((dist - _NearCameraFadeDistanceStart2) / (_NearCameraFadeDistanceEnd2 - _NearCameraFadeDistanceStart2)) * saturate((dist - _NearCameraFadeDistanceStart) / (_NearCameraFadeDistanceEnd - _NearCameraFadeDistanceStart));
    }
    float fresnelOpacity = lerp(1.0, fresnelTerm, _FresnelAffectOpacity);
    float finalAlpha = saturate(saturate(combinedAlpha) * fresnelOpacity * nearFade);
    float outAlpha = (1.0 - _BlendMode) * finalAlpha;
    ruriData.alpha = outAlpha;
    outputData.baseColor = finalAlpha * color;
    outputData.normalWS = faceNormal;
    outputData.globalIllumination = float4(finalAlpha * color, outAlpha);
}

void Endfield_OverlayShadow(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData)
{
    float4 tex = ruriData.baseSample;
    float3 rgb = lerp(tex.rgb, float3(1, 1, 1), _UseGrayAsAlpha);
    float alpha = lerp(tex.a, tex.r, _UseGrayAsAlpha);
    float shadowAlpha = alpha * _BaseColor.a;
    float finalIntensity = shadowAlpha * _BaseColor.a;
    float3 blended = rgb * _BaseColor.rgb;
    float3 finalColor = 1.0 + finalIntensity * (blended - 1.0);
    ruriData.alpha = shadowAlpha;
    outputData.baseColor = finalColor;
    outputData.normalWS = ruriNormalize(input.normalWS);
    outputData.globalIllumination = float4(finalColor, shadowAlpha);
}

void SilkStockingsSurface(float wetness, float baseAlpha, float3 N, float3 V, float perceptualRoughness, float2 uv, inout half3 albedo, inout float3 shadowColor, out float specularIntensity, out float anisoDirection, out float coverage, out float roughnessOverride)
{
    float wetSpecular = _SilkStockingsSpecularInt * lerp(_SilkStockingsSpecularMinAtMinWetness, 1.0, wetness);
    if (_SilkStockingsAdvance > 0.5)
    {
        float4 mask = texture(_SilkStockingsMask, uv);
        roughnessOverride = lerp(perceptualRoughness, 1.0 - mask.z, wetness);
        specularIntensity = wetSpecular * mask.x;
        anisoDirection = clamp(mad(mask.y, 2.0, -1.0), -0.949999988079071044921875, 0.949999988079071044921875);
        coverage = saturate((lerp(baseAlpha, mask.w, wetness) + 1.0) - _SilkStockingsColor.w);
    }
    else
    {
        roughnessOverride = perceptualRoughness;
        specularIntensity = wetSpecular;
        anisoDirection = -lerp(_SilkStockingsAnisoDirection, 0.5, saturate(baseAlpha * 0.5));
        coverage = saturate((baseAlpha + 1.0) - _SilkStockingsColor.w);
    }
    float3 wetTint = lerp(_SilkStockingsDryColor.rgb, _SilkStockingsWetColor.rgb, wetness);
    float rimAffect = lerp(_SilkStockingsMinAffect, _SilkStockingsMaxAffect, saturate(pow(1.0499999523162841796875 - saturate(dot(N, V)), coverage * 2.0)));
    albedo = lerp(albedo * wetTint, _SilkStockingsColor.rgb, rimAffect);
    shadowColor = lerp(shadowColor * wetTint, _SilkStockingsColor.rgb, rimAffect);
}

float EnvironmentWaterSubmersion(float3 positionWS)
{
    float waterHeight = lerp(_RuriCharacterEnvironmentWater.x, _CharacterParams10.w, _CharacterParams10.x);
    return smoothstep(-0.20000000298023223876953125, 0.1500000059604644775390625, waterHeight - positionWS.y) * _RuriCharacterEnvironmentEffect.y;
}

float EnvironmentWetness(float3 positionWS)
{
    return max(_RuriCharacterEnvironmentEffect.x, max(_RuriCharacterEnvironmentEffect.z, EnvironmentWaterSubmersion(positionWS)));
}

float POM_Tatarchuk(float2 uv, float3 V, float3 normalWS_raw, float3 tangentDir, float tangentSign)
{
    float3 pxNrm = ruriNormalize(normalWS_raw);
    float3 pxTan = ruriNormalize(tangentDir);
    float3 pxBit = cross(pxNrm, pxTan) * tangentSign;
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
    float2 pxPrevOff = float2(0, 0);
    float pxPrevH = 0.0;
    float pxLayerH = 1.0 - pxStepSz;
    float pxPrevLayerH = 1.0;
    float pxHitH = 0.0;
    bool pxHit = false;
    for (float pxi = 0; pxi < pxSteps + 1.0; pxi += 1.0)
    {
        float pxTexH = ruriRead_ParallaxTex(pxUV + pxAccum).r;
        if (pxLayerH < pxTexH)
        {
            pxHitH = pxTexH;
            pxHit = true;
            break;
        }
        pxPrevOff = pxAccum;
        pxAccum += pxUVDelta;
        pxPrevH = pxTexH;
        pxPrevLayerH = pxLayerH;
        pxLayerH -= pxStepSz;
    }
    if (!pxHit)
        pxHitH = pxPrevH;
    float pxT = (pxPrevH - pxPrevLayerH) / (-pxPrevLayerH + pxLayerH + pxPrevH - pxHitH);
    float2 pxFinalUV = pxUV + pxUVDelta * pxT + pxPrevOff;
    return ruriRead_ParallaxTex(pxFinalUV).r;
}

float BRDF_AnisotropicNDF_SilkStockings_Endfield(float3 N, float3 V, float3 H, float3 tangentDir, float tangentSign, float alpha2, float ph_aniso)
{
    float3 ph_T = ruriNormalize(tangentDir - N * dot(tangentDir, N));
    float3 ph_B = cross(N, ph_T) * tangentSign;
    float3 ph_H = ruriNormalize(H + V * _SilkStockingsSpecularValue);
    float ph_rT = alpha2 * (ph_aniso + 1.0);
    float ph_rB = (1.0 - ph_aniso) * alpha2;
    float ph_rTB = ph_rT * ph_rB;
    float ph_tH = ph_rB * dot(ph_T, ph_H);
    float ph_bH = dot(ph_B, ph_H) * ph_rT;
    float ph_nH = dot(N, ph_H) * ph_rTB;
    float ph_d = ph_tH * ph_tH + ph_bH * ph_bH + ph_nH * ph_nH;
    float ph_rTB3 = ph_rTB * ph_rTB * ph_rTB;
    float ph_d2 = ph_d * ph_d;
    return ((ph_d2 != ph_rTB3) ? (ph_rTB3 / ph_d2) : 1.0);
}

float SilkStockingsAnisoSplit(float anisoDirection, float coverage)
{
    return anisoDirection * (1.0 - saturate(coverage * _SilkStockingsSpecularFalloff));
}

float3 BRDF_ClearCoat_Direct_Burley(float ccMask, float ccPercRough, float ccAlpha, float3 ccF0, float ccNdotH, float ccNdotV, float VdotH, out float3 ccBaseScale, out float3 ccDiffScale)
{
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
    float ccD = ((ccDenomSq != ccAlphaSq) ? ccAlphaSq / ccDenomSq : 1.0);
    float ccV = 0.5 / (mad(ccNdotV, 2.0, ccAlpha) + 0.0001);
    return clamp(ccV * ccD * ccMaskedF, 0.0, 20.0);
}

float3 IBL_SpecularSplitSum_Endfield(float3 V, float3 N, float NdotV_spec, float roughness, float roughnessRaw, float3 specRampEnv, float ambIntensity, float3 ambCol)
{
    float3 reflDir = reflect(-V, N);
    float cubeMip = log2(max(roughnessRaw, 0.001)) * 1.2 + 5.0;
    half3 cubeSample = envSampleLOD(reflDir, cubeMip).rgb;
    return IBL_SplitSumCombine(cubeSample, NdotV_spec, roughness, specRampEnv, ambIntensity, ambCol);
}

float3 BRDF_ClearCoat_IBL_Burley(float3 V, float3 ccN, float ccPercRough, float ccAlpha, float3 ccF0)
{
    float3 ccReflDir = reflect(-V, ccN);
    float ccCubeMip = log2(max(ccPercRough, 0.001)) * 1.2 + 5.0;
    half3 ccCubeSmp = envSampleLOD(ccReflDir, ccCubeMip).rgb;
    float ccNdotV_ibl = saturate(dot(ccN, V));
    float ccDfgX;
    float ccDfgY;
    EnvBRDF_Endfield(ccNdotV_ibl, ccAlpha, ccDfgX, ccDfgY);
    float3 ccEnvBRDF = ccF0 * ccDfgX + ccDfgY;
    float ccTotalRefl = ccDfgX + ccDfgY;
    float ccReflBoost = (1.0 - ccTotalRefl) / max(ccTotalRefl, 1e-6);
    return ccCubeSmp * ccEnvBRDF * (1.0 + ccReflBoost * ccF0);
}

void Endfield_LiquidAg(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, float faceSign)
{
    float3 shadowColor = ComputeShadowColor(ruriData.albedo);
    float3 N = SampleNormalMap(input.uv, input.normalWS, input.tangentWS, faceSign);
    float ccMask = 0.0;
    float3 ccN = N;
    float ccPercRough = 1.0;
    float ccAlpha = 0.0078125;
    float3 ccF0 = float3(0, 0, 0);
    bool ccActive = false;
    if (_ClearCoat)
    {
        ccMask = ruriRead_ClearCoatMask(input.uv).r;
        ccN = lerp(faceSign * ruriNormalize(input.normalWS), N, _ClearCoatNormalMode);
        ccPercRough = 1.0 - _ClearCoatSmoothness;
        ccAlpha = max(ccPercRough * ccPercRough, 0.0078125);
        ccF0 = mad(_ClearCoatMetallic, 0.96, 0.04) * _ClearCoatColor.rgb;
        ccActive = ccMask > 0.001;
    }
    float silkSpecularIntensity = 0.0;
    float silkAnisoDirection = 0.0;
    float silkCoverage = 0.0;
    if (_SilkStockings)
    {
        float silkRoughness;
        SilkStockingsSurface(EnvironmentWetness(ruriData.positionWS), ruriData.baseAlpha * _BaseColor.a, N, ruriData.V, float(ruriData.roughness), input.uv, ruriData.albedo, shadowColor, silkSpecularIntensity, silkAnisoDirection, silkCoverage, silkRoughness);
        ruriData.roughness = silkRoughness;
    }
    float3 emissionTex = (_UseEmission ? ruriRead_EmissionMap(input.uv).rgb : float3(0, 0, 0));
    float parallaxSample = 0.0;
    if (_UseParallax)
    {
        parallaxSample = POM_Tatarchuk(input.uv, ruriData.V, input.normalWS, input.tangentWS.xyz, input.tangentWS.w);
    }
    float4 vfxBlendSmp = float4(0, 0, 0, 0);
    float vfxTexAlpha = 0.0;
    float3 vfxMainRGB = float3(0, 0, 0);
    float vfxFresnelFlipped = 0.0;
    float vfxAlphaBase = 0.0;
    float vfxDissolveDelta = 0.0;
    float vfxDissolveEdge = 0.0;
    if (_EnableCharacterVFX)
    {
        float t = _Time.y;
        float2 vfxBlendUV = float2(mad(mad(_VFXSpecialParam.z, t, input.uv.x), _VFXSpecialBlendTex_ST.x, _VFXSpecialBlendTex_ST.z), mad(mad(_VFXSpecialParam.w, t, input.uv.y), _VFXSpecialBlendTex_ST.y, _VFXSpecialBlendTex_ST.w));
        vfxBlendSmp = ruriSampleSrgb(_VFXSpecialBlendTex, vfxBlendUV);
        float2 vfxDistortUV = input.uv + vfxBlendSmp.r * _VFXSpecialBlendTexRForDisturb;
        float2 vfxMainUV = float2(mad(mad(_VFXSpecialParam.x, t, vfxDistortUV.x), _VFXSpecialMainTex_ST.x, _VFXSpecialMainTex_ST.z), mad(mad(_VFXSpecialParam.y, t, vfxDistortUV.y), _VFXSpecialMainTex_ST.y, _VFXSpecialMainTex_ST.w));
        float4 vfxMainSmp = ruriSampleSrgb(_VFXSpecialMainTex, vfxMainUV);
        vfxTexAlpha = lerp(vfxMainSmp.a, vfxMainSmp.r, _UseVFXMainTexAsAlpha);
        vfxMainRGB = lerp(vfxMainSmp.rgb, float3(1, 1, 1), _UseVFXMainTexAsAlpha);
        float3 vfxGeomN = ruriNormalize(input.normalWS);
        float vfxFresnel = exp2(log2(saturate(dot(ruriData.V, vfxGeomN) + _VFXFresnelBias)) * _VFXFresnelPower);
        vfxFresnelFlipped = lerp(1.0 - vfxFresnel, vfxFresnel, _VFXFresnelFlip);
        vfxAlphaBase = _VFXColorAlpha * _VFXColor.a;
        vfxDissolveDelta = vfxBlendSmp.r - (_SpecialDissolveScheduleOffset * 2.02 - 1.01);
        vfxDissolveEdge = saturate(-vfxDissolveDelta);
    }
    float3 flatDir = GetObjectFlatDir(ruriData.positionWS);
    float3 ambCol = _CharacterParams2.xyz;
    float roughnessF = float(ruriData.roughness);
    float metallicF = float(ruriData.metallic);
    float specScaleF = float(ruriData.specScale);
    float dielSpec = specScaleF * 0.04;
    float oneMinusRefl = (1.0 - metallicF) * 0.96;
    float3 diffColor = oneMinusRefl * ruriData.albedo;
    float3 specColor = metallicF * (ruriData.albedo - dielSpec) + dielSpec;
    float3 shadowDiff = oneMinusRefl * shadowColor;
    float alpha2 = max(roughnessF * roughnessF, 0.0078125);
    float3 blendedLightCol = lerp(ruriData.mainLight.color, _CharacterParams5.xyz, _CharacterParams12.y);
    float blendedLightInt = 1.0;
    float geomNdotL = dot(N, ruriData.adjustedLightDir);
    float wrapAdd = 0.5 - 0.5 * geomNdotL * geomNdotL;
    float modNdotL = (1.0 - _CharacterParams12.x) * (ruriData.camLightDot * ruriData.camYSmooth) * wrapAdd + geomNdotL;
    float stdChroma;
    float stdViewAlpha;
    float4 stdRamp = SampleDiffRamp(modNdotL, N, ruriData.camFwd, stdChroma, stdViewAlpha);
    float castShadow = lerp(smoothstep(0.0, 1.0, ruriData.mainLight.shadowAttenuation), 1.0, _CharacterParams1.z);
    float minShadow = min(stdRamp.a, ruriData.occlusion) * castShadow;
    float viewShadowProduct = stdViewAlpha * ruriData.occlusion;
    float combWeight = saturate(viewShadowProduct + stdRamp.a);
    float3 albScaled = shadowDiff * _CharacterParams0.z;
    float diffColorLum = Luminance(diffColor);
    float brightFull = clamp(ruriData.ambInt, 0.0, 1.5);
    float3 fullDiff;
    float ambDiffInt;
    float3 nprDiff = ComputeNPRDiffuse(N, ambCol, brightFull, blendedLightCol, blendedLightInt, minShadow, combWeight, albScaled, diffColor, stdRamp.rgb, stdChroma, 1.0 - stdChroma, fullDiff, ambDiffInt);
    float specAmbInt = ambDiffInt * (minShadow * 0.5 + 0.5);
    float alphaPremul = mad(ruriData.baseAlpha, _AlphaPremultiply, 1.0 - _AlphaPremultiply);
    float ggxD_raw;
    float ggxNdotV;
    float3 ggxH;
    float ggxNdotH;
    float ggxTermBase = BRDF_GGX_Stylized_Endfield(N, ruriData.V, ruriData.adjustedLightDir, ruriData.camFwd, alpha2, ggxD_raw, ggxNdotV, ggxH, ggxNdotH);
    float roughSq4 = alpha2 * alpha2;
    float ggxTerm = clamp(ggxD_raw * 0.5 / (ggxNdotV * 2.0 + alpha2 + 1e-4) - HALF_MIN, 0.0, 20.0);
    if (_SilkStockings)
    {
        float ph_ndf = BRDF_AnisotropicNDF_SilkStockings_Endfield(N, ruriData.V, ggxH, input.tangentWS.xyz, input.tangentWS.w, alpha2, -SilkStockingsAnisoSplit(silkAnisoDirection, silkCoverage));
        ggxTerm += silkSpecularIntensity * clamp(ph_ndf, 0.0, 20.0);
    }
    float3 specRampColor;
    float3 specRampEnv;
    SpecularRamp_NPR_Endfield(ggxD_raw, ggxNdotV, roughSq4, metallicF, roughnessF, specColor, specRampColor, specRampEnv);
    float3 ccSpecDir = float3(0, 0, 0);
    float3 ccBaseScale = float3(1, 1, 1);
    float3 ccDiffScale = float3(1, 1, 1);
    if (_ClearCoat && ccActive)
    {
        float ccNdotH = dot(ccN, ggxH);
        float ccNdotV = saturate(dot(ccN, ruriData.V));
        float VdotH = saturate(dot(ruriData.V, ggxH));
        ccSpecDir = BRDF_ClearCoat_Direct_Burley(ccMask, ccPercRough, ccAlpha, ccF0, ccNdotH, ccNdotV, VdotH, ccBaseScale, ccDiffScale);
    }
    float3 mainLit = ((_ClearCoat) ? (fullDiff * nprDiff * alphaPremul * ccDiffScale + (specAmbInt * fullDiff) * (ggxTerm * specRampColor * ccBaseScale * ccBaseScale + ccSpecDir) * _CharacterParams13.w) : (fullDiff * nprDiff * alphaPremul + (specAmbInt * fullDiff) * (ggxTerm * specRampColor) * _CharacterParams13.w));
    float mainLitLum = Luminance(mainLit);
    float3 skinDir = ComputeSkinDir(ruriData.camFwd);
    float skinShadow = min(ruriData.occlusion, saturate(dot(flatDir, skinDir) + 1.0));
    float3 skinSpec = ComputeSkinSpec(skinDir, N, diffColor, skinShadow, ComputeSkinSmoothFalloff(dot(ruriData.V, N)));
    float camLightFacing = (1.0 - _CharacterParams12.x) * ruriData.camLightDot;
    float3 subsurfSpec = BRDF_SubsurfaceSpec_Endfield(N, ruriData.V, ruriData.adjXZ_x, ruriData.adjXZ_z, ruriData.adjXZLen, camLightFacing, ruriData.occlusion, diffColorLum, diffColor, blendedLightCol * blendedLightInt);
    float cubeAmbInt = ambDiffInt * (clamp(ruriData.exposure, 0.5, 1.5) * _CharacterParams0.w);
    float3 envNormal = faceSign * ruriNormalize(input.normalWS);
    float envNdotV = saturate(dot(envNormal, ruriData.V));
    float envAlpha = roughnessF * roughnessF;
    float3 cubemapContrib = IBL_SpecularSplitSum_Endfield(ruriData.V, envNormal, envNdotV, envAlpha, roughnessF, specRampEnv, cubeAmbInt, ambCol) * _CubemapIntensity;
    if (_ClearCoat && ccActive)
    {
        cubemapContrib += ccMask * BRDF_ClearCoat_IBL_Burley(ruriData.V, ccN, ccPercRough, ccAlpha, ccF0) * _CubemapIntensity;
    }
    float3 emissionContrib = float3(0, 0, 0);
    if (_UseEmission)
        emissionContrib = emissionTex * _EmissionColor.rgb * _EmissionBrightness * alphaPremul;
    if (_UseParallax)
        emissionContrib += ruriData.baseAlpha * parallaxSample * _ParallaxColor.rgb * alphaPremul;
    float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);
    float3 desatMainLit = DesaturateAroundLuma(mainLit, mainLitLum, desatAmt);
    float3 litColor = desatMainLit + skinSpec + subsurfSpec + emissionContrib + cubemapContrib;
    if (_EnableCharacterVFX)
    {
        float vfxBlendFactor = saturate((vfxAlphaBase * vfxTexAlpha + vfxBlendSmp.a) * _VFXBlendTint.a);
        float3 vfxColorTerm = _VFXColorIntensity * _VFXColor.rgb * vfxMainRGB;
        float3 vfxMainColor = vfxBlendSmp.rgb * vfxBlendFactor * _VFXBlendTint.rgb + vfxColorTerm;
        float3 vfxDissolvedColor = lerp(vfxMainColor, vfxDissolveEdge * _VFXFresnelColor.rgb * _VFXColorIntensity, vfxDissolveEdge);
        float vfxFresnelAlpha = vfxFresnelFlipped * _VFXFresnelColor.a;
        float vfxDissolveVis = saturate(vfxDissolveDelta);
        float vfxOpacity = saturate(vfxDissolveVis * vfxAlphaBase * vfxTexAlpha) * lerp(1.0, vfxFresnelFlipped, _VFXFresnelAffectOpacity);
        float3 vfxContrib = vfxOpacity * lerp(vfxDissolvedColor, _VFXFresnelColor.rgb, vfxFresnelAlpha);
        litColor += vfxContrib * alphaPremul;
    }
    if (_EnableVFXColorAdjustment > 0.5)
        litColor = VFXColorAdjust(litColor, ggxNdotV, 1.0);
    float3 finalColor = litColor / _ExposureParams.x;
    ruriData.alpha *= ((_SurfaceType == 1) ? ruriData.baseAlpha : 1.0);
    outputData.baseColor = ruriData.albedo;
    outputData.normalWS = N;
    outputData.roughness = ruriData.roughness;
    outputData.metallic = ruriData.metallic;
    outputData.specular = ruriData.specScale;
    outputData.globalIllumination = float4(finalColor, ruriData.alpha);
}

void Endfield_Standard(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, float faceSign)
{
    float3 shadowColor = ComputeShadowColor(ruriData.albedo);
    float3 N = SampleNormalMap(input.uv, input.normalWS, input.tangentWS, faceSign);
    float ccMask = 0.0;
    float3 ccN = N;
    float ccPercRough = 1.0;
    float ccAlpha = 0.0078125;
    float3 ccF0 = float3(0, 0, 0);
    bool ccActive = false;
    if (_ClearCoat)
    {
        ccMask = ruriRead_ClearCoatMask(input.uv).r;
        ccN = lerp(faceSign * ruriNormalize(input.normalWS), N, _ClearCoatNormalMode);
        ccPercRough = 1.0 - _ClearCoatSmoothness;
        ccAlpha = max(ccPercRough * ccPercRough, 0.0078125);
        ccF0 = mad(_ClearCoatMetallic, 0.96, 0.04) * _ClearCoatColor.rgb;
        ccActive = ccMask > 0.001;
    }
    float silkSpecularIntensity = 0.0;
    float silkAnisoDirection = 0.0;
    float silkCoverage = 0.0;
    if (_SilkStockings)
    {
        float silkRoughness;
        SilkStockingsSurface(EnvironmentWetness(ruriData.positionWS), ruriData.baseAlpha * _BaseColor.a, N, ruriData.V, float(ruriData.roughness), input.uv, ruriData.albedo, shadowColor, silkSpecularIntensity, silkAnisoDirection, silkCoverage, silkRoughness);
        ruriData.roughness = silkRoughness;
    }
    float3 emissionTex = (_UseEmission ? ruriRead_EmissionMap(input.uv).rgb : float3(0, 0, 0));
    float parallaxSample = 0.0;
    if (_UseParallax)
    {
        parallaxSample = POM_Tatarchuk(input.uv, ruriData.V, input.normalWS, input.tangentWS.xyz, input.tangentWS.w);
    }
    float3 flatDir = GetObjectFlatDir(ruriData.positionWS);
    float3 ambCol = _CharacterParams2.xyz;
    float roughnessF = float(ruriData.roughness);
    float metallicF = float(ruriData.metallic);
    float specScaleF = float(ruriData.specScale);
    float dielSpec = specScaleF * 0.04;
    float oneMinusRefl = (1.0 - metallicF) * 0.96;
    float3 diffColor = oneMinusRefl * ruriData.albedo;
    float3 specColor = metallicF * (ruriData.albedo - dielSpec) + dielSpec;
    float3 shadowDiff = oneMinusRefl * shadowColor;
    float alpha2 = max(roughnessF * roughnessF, 0.0078125);
    float3 blendedLightCol = lerp(ruriData.mainLight.color, _CharacterParams5.xyz, _CharacterParams12.y);
    float blendedLightInt = 1.0;
    float geomNdotL = dot(N, ruriData.adjustedLightDir);
    float wrapAdd = 0.5 - 0.5 * geomNdotL * geomNdotL;
    float modNdotL = (1.0 - _CharacterParams12.x) * (ruriData.camLightDot * ruriData.camYSmooth) * wrapAdd + geomNdotL;
    float stdChroma;
    float stdViewAlpha;
    float4 stdRamp = SampleDiffRamp(modNdotL, N, ruriData.camFwd, stdChroma, stdViewAlpha);
    float castShadow = lerp(smoothstep(0.0, 1.0, ruriData.mainLight.shadowAttenuation), 1.0, _CharacterParams1.z);
    float minShadow = min(stdRamp.a, ruriData.occlusion) * castShadow;
    float viewShadowProduct = stdViewAlpha * ruriData.occlusion;
    float combWeight = saturate(viewShadowProduct + stdRamp.a);
    float3 albScaled = shadowDiff * _CharacterParams0.z;
    float diffColorLum = Luminance(diffColor);
    float brightFull = clamp(ruriData.ambInt, 0.0, 1.5);
    float3 fullDiff;
    float ambDiffInt;
    float3 nprDiff = ComputeNPRDiffuse(N, ambCol, brightFull, blendedLightCol, blendedLightInt, minShadow, combWeight, albScaled, diffColor, stdRamp.rgb, stdChroma, 1.0 - stdChroma, fullDiff, ambDiffInt);
    float specAmbInt = ambDiffInt * (minShadow * 0.5 + 0.5);
    float alphaPremul = mad(ruriData.baseAlpha, _AlphaPremultiply, 1.0 - _AlphaPremultiply);
    float ggxD_raw;
    float ggxNdotV;
    float3 ggxH;
    float ggxNdotH;
    float ggxTermBase = BRDF_GGX_Stylized_Endfield(N, ruriData.V, ruriData.adjustedLightDir, ruriData.camFwd, alpha2, ggxD_raw, ggxNdotV, ggxH, ggxNdotH);
    float roughSq4 = alpha2 * alpha2;
    float ggxTerm = clamp(ggxD_raw * 0.5 / (ggxNdotV * 2.0 + alpha2 + 1e-4) - HALF_MIN, 0.0, 20.0);
    if (_SilkStockings)
    {
        float ph_ndf = BRDF_AnisotropicNDF_SilkStockings_Endfield(N, ruriData.V, ggxH, input.tangentWS.xyz, input.tangentWS.w, alpha2, -SilkStockingsAnisoSplit(silkAnisoDirection, silkCoverage));
        ggxTerm += silkSpecularIntensity * clamp(ph_ndf, 0.0, 20.0);
    }
    float3 specRampColor;
    float3 specRampEnv;
    SpecularRamp_NPR_Endfield(ggxD_raw, ggxNdotV, roughSq4, metallicF, roughnessF, specColor, specRampColor, specRampEnv);
    float3 ccSpecDir = float3(0, 0, 0);
    float3 ccBaseScale = float3(1, 1, 1);
    float3 ccDiffScale = float3(1, 1, 1);
    if (_ClearCoat && ccActive)
    {
        float ccNdotH = dot(ccN, ggxH);
        float ccNdotV = saturate(dot(ccN, ruriData.V));
        float VdotH = saturate(dot(ruriData.V, ggxH));
        ccSpecDir = BRDF_ClearCoat_Direct_Burley(ccMask, ccPercRough, ccAlpha, ccF0, ccNdotH, ccNdotV, VdotH, ccBaseScale, ccDiffScale);
    }
    float3 mainLit = ((_ClearCoat) ? (fullDiff * nprDiff * alphaPremul * ccDiffScale + (specAmbInt * fullDiff) * (ggxTerm * specRampColor * ccBaseScale * ccBaseScale + ccSpecDir) * _CharacterParams13.w) : (fullDiff * nprDiff * alphaPremul + (specAmbInt * fullDiff) * (ggxTerm * specRampColor) * _CharacterParams13.w));
    float mainLitLum = Luminance(mainLit);
    float3 skinDir = ComputeSkinDir(ruriData.camFwd);
    float skinShadow = min(ruriData.occlusion, saturate(dot(flatDir, skinDir) + 1.0));
    float3 skinSpec = ComputeSkinSpec(skinDir, N, diffColor, skinShadow, ComputeSkinSmoothFalloff(dot(ruriData.V, N)));
    float camLightFacing = (1.0 - _CharacterParams12.x) * ruriData.camLightDot;
    float3 subsurfSpec = BRDF_SubsurfaceSpec_Endfield(N, ruriData.V, ruriData.adjXZ_x, ruriData.adjXZ_z, ruriData.adjXZLen, camLightFacing, ruriData.occlusion, diffColorLum, diffColor, blendedLightCol * blendedLightInt);
    float cubeAmbInt = ambDiffInt * (clamp(ruriData.exposure, 0.5, 1.5) * _CharacterParams0.w);
    float3 envNormal = faceSign * ruriNormalize(input.normalWS);
    float envNdotV = saturate(dot(envNormal, ruriData.V));
    float envAlpha = roughnessF * roughnessF;
    float3 cubemapContrib = IBL_SpecularSplitSum_Endfield(ruriData.V, envNormal, envNdotV, envAlpha, roughnessF, specRampEnv, cubeAmbInt, ambCol) * _CubemapIntensity;
    if (_ClearCoat && ccActive)
    {
        cubemapContrib += ccMask * BRDF_ClearCoat_IBL_Burley(ruriData.V, ccN, ccPercRough, ccAlpha, ccF0) * _CubemapIntensity;
    }
    float3 emissionContrib = float3(0, 0, 0);
    if (_UseEmission)
        emissionContrib = emissionTex * _EmissionColor.rgb * _EmissionBrightness * alphaPremul;
    if (_UseParallax)
        emissionContrib += ruriData.baseAlpha * parallaxSample * _ParallaxColor.rgb * alphaPremul;
    float desatAmt = clamp(mainLitLum - 0.5, 0.0, 0.5);
    float3 desatMainLit = DesaturateAroundLuma(mainLit, mainLitLum, desatAmt);
    float3 litColor = desatMainLit + skinSpec + subsurfSpec + emissionContrib + cubemapContrib;
    if (_EnableVFXColorAdjustment > 0.5)
        litColor = VFXColorAdjust(litColor, ggxNdotV, 1.0);
    float3 finalColor = litColor / _ExposureParams.x;
    ruriData.alpha *= ((_SurfaceType == 1) ? ruriData.baseAlpha : 1.0);
    outputData.baseColor = ruriData.albedo;
    outputData.normalWS = N;
    outputData.roughness = ruriData.roughness;
    outputData.metallic = ruriData.metallic;
    outputData.specular = ruriData.specScale;
    outputData.globalIllumination = float4(finalColor, ruriData.alpha);
}

void Fragment_Endfield(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, half facing)
{
    float faceSign = (facing >= 0 ? 1.0 : (_BackFaceNormalFlip * 2.0 - 1.0));
    Endfield_Setup(ruriData, input);
    if (_RuriOutlineShellGate)
        ApplyEndfieldOutlineAlbedo(ruriData.albedo);
    if (_CharaPartID == 1)
        Endfield_Face(ruriData, input, outputData, faceSign);
    else
        if (_CharaPartID == 2)
            Endfield_Eyes(ruriData, input, outputData, faceSign);
        else
            if (_CharaPartID == 3)
                Endfield_Hair(ruriData, input, outputData, faceSign);
            else
                if (_CharaPartID == 4)
                    Endfield_Fur(ruriData, input, outputData, faceSign);
                else
                    if (_CharaPartID == 5)
                        Endfield_Eyes(ruriData, input, outputData, faceSign);
                    else
                        if (_CharaPartID == 6)
                            Endfield_VFX(ruriData, input, outputData, facing);
                        else
                            if (_CharaPartID == 7)
                                Endfield_OverlayShadow(ruriData, input, outputData);
                            else
                                if (_CharaPartID == 8)
                                    Endfield_LiquidAg(ruriData, input, outputData, faceSign);
                                else
                                    Endfield_Standard(ruriData, input, outputData, faceSign);
}

void CalcRuriNPR(inout RuriData ruriData, CharaVaryings input, inout RuriGBufferData outputData, half facing)
{
    Fragment_Endfield(ruriData, input, outputData, facing);
}

float3 RuriCharaAdditionalLights(float3 positionWS, float3 N, float2 normalizedScreenSpaceUV, float3 albedo)
{
    float3 lightAccum = float3(0.0, 0.0, 0.0);
    return lightAccum;
}

float3 PackGBufferNormal(float3 normalWS)
{
    float l1 = abs(normalWS.x) + abs(normalWS.y) + abs(normalWS.z);
    float inv = 1.0 / ((l1 > 1e-6 ? l1 : 1e-6));
    float3 n = normalWS * inv;
    float t = saturate(-n.z);
    float2 oct = float2(n.x + ((n.x >= 0.0 ? t : -t)), n.y + ((n.y >= 0.0 ? t : -t)));
    float2 remapped = saturate(float2(oct.x * 0.5 + 0.5, oct.y * 0.5 + 0.5));
    uint2 i = uint2(uint((remapped.x * 4095.5)), uint((remapped.y * 4095.5)));
    uint2 hi = uint2(i.x >> 8, i.y >> 8);
    uint2 lo = uint2(i.x & 255, i.y & 255);
    return float3(lo.x / 255.0, lo.y / 255.0, (hi.x | (hi.y << 4)) / 255.0);
}

GBufferFragOutput RuriGBufferDataToCharaGbuffer(RuriData ruriData, RuriGBufferData outputData)
{
    float3 packedNormalWS = PackGBufferNormal(outputData.normalWS);
    GBufferFragOutput output = ruriZeroGBufferFragOutput();
    half unused = 0;
    output.gBuffer0 = float4(outputData.baseColor, outputData.alpha);
    output.gBuffer1 = float4(unused, outputData.metallic, outputData.specular, outputData.occlusion);
    output.gBuffer2 = float4(packedNormalWS, 1.0 - outputData.roughness);
    output.color = half4(outputData.globalIllumination);
    return output;
}

GBufferFragOutput CharaMixedPassFragment(CharaVaryings input, half facing)
{
    RuriData ruriData;
    InitializeCharaData(input, ruriData);
    GBufferData gBufferData = ruriSelfGBuffer(ruriData);
    if (_SurfaceType != 1)
    {
        ruriData.albedo = gBufferData.baseColor;
    }
    ruriData.albedo *= _BaseColor.rgb;
    ruriData.alpha *= _BaseColor.a;
    if (!_UseRMOSMap)
    {
        ruriData.roughness = _RoughnessIntensity;
        ruriData.metallic = _MetallicIntensity;
        ruriData.occlusion = _OcclusionIntensity;
        ruriData.specular = _SpecularIntensity;
    }
    RuriGBufferData outputData = ruriZeroRuriGBufferData();
    CalcRuriNPR(ruriData, input, outputData, facing);
    outputData.baseColor = outputData.globalIllumination.xyz;
    outputData.baseColor.rgb += RuriCharaAdditionalLights(ruriData.positionWS, ruriData.normalWS, ruriData.normalizedScreenSpaceUV, ruriData.albedo);
    outputData.alpha = ruriData.alpha;
    return RuriGBufferDataToCharaGbuffer(ruriData, outputData);
}

//----------------------------------------------------------------------region Shader 入口
void shade(V2F inputs) {
    ruriSparseCoord = inputs.sparse_coord;
    CharaVaryings ruriInput = ruriZeroCharaVaryings();
    ruriInput.uv = inputs.sparse_coord.tex_coord;
    ruriInput.positionWS = inputs.position;
    ruriInput.normalWS = normalize(inputs.normal);
    ruriInput.tangentWS = float4(normalize(inputs.tangent), (dot(cross(normalize(inputs.normal), normalize(inputs.tangent)), normalize(inputs.bitangent)) < 0.0) ? -1.0 : 1.0);
    ruriInput.uv1 = float4(0.0, 0.0, 0.0, 0.0);
    ruriInput.uv0zw = float2(0.0, 0.0);
    ruriInput.positionNDC = float4(0.0, 0.0, 1.0, 1.0);
    ruriInput.color = float4(1.0, 1.0, 1.0, 1.0);
    ruriInput.positionCS = gl_FragCoord;
    GBufferFragOutput ruriOut = CharaMixedPassFragment(ruriInput, ((uniform_facing >= 0) ? 1.0 : -1.0));
    alphaOutput(ruriOut.gBuffer0.a);
    diffuseShadingOutput(ruriOut.gBuffer0.rgb);
}
//----------------------------------------------------------------------endregion
