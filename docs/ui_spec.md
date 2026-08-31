# UI 还原规格 — 对照 gdp_app_merged_recolored.svg

> 2026-08-26，Pro 分析产出。Flash 实现时**逐屏对照本规格 + SVG 原图**，不自行发挥。
> 口径决定（用户已确认）：① 范围 = SVG 6 屏；② 流程完全按 SVG；③ Top industries 卡片去掉；④ 视觉一致 + 数字真实计算。
> 设计空间 390×844；页面水平边距 24，卡片圆角/阴影/颜色以本文为准。

## 0. 设计令牌（Design Tokens）

### 颜色
| 令牌 | 值 | 用途 |
|---|---|---|
| primary | `#9A9CEA` | 主色、激活态、图标 |
| primaryLight | `#A2B9EE` | gradHero 终点、bar 色 |
| accentLight | `#A2DCEE` | gradDetail 终点、青色系图标 |
| ink | `#1E2240` | 标题、正文、激活图标 |
| body | `#4A4F6E` | 正文（insight/表格文本） |
| muted | `#6B7194` | 次要文字 |
| faint | `#8A8FAD` | eyebrow、section 标签 |
| ghost | `#9AA0B5` | 未激活图标、轴标签、chevron |
| ground | `#F5F6FB` | 页面底色 |
| card | `#FFFFFF` | 卡片 |
| gridline | `#EEF0F8` | 图内网格线、表格分隔线、bar 轨道 |
| navLine | `#E7E9F4` | 底部导航顶部分隔线 |
| border | `#D9DCEC` | 输入框描边 |
| chipPeri | `#ECEDFB` | 紫系图标底 |
| chipGreenBg | `#E4F7F1` | 绿色 chip 底 |
| green | `#177E6C` | 绿色文字/图标（增长、INSIGHT 标题） |
| greenBar | `#ADEEE2` | INSIGHT 左竖条、低 HHI bar |
| chipCyanBg | `#E8F7FB` | 青色图标底 |
| cyan | `#48BEDC` | 第二州颜色（Johor 线/点） |
| cyanText | `#2E96B4` | 表格第二列标题 |
| periText | `#5A5DC4` | 表格第一列标题 |
| orange1 | `#E8804D` | HHI 第 1 名 bar |
| orange2 | `#F0A03C` | HHI 第 2 名 bar |
| riskBg | `#FDE7EC` | Risk 徽章底 |
| riskText | `#D14D6B` | Risk 徽章字 |

### 阴影
- **cardShadow**：`dy 5, blur 9, #9A9CEA @ 13%` → BoxShadow(color: primary@0.13, blurRadius: 9, offset: (0,5))
- **heroShadow**：`dy 9, blur 14, #9A9CEA @ 35%` → BoxShadow(color: primary@0.35, blurRadius: 14, offset: (0,9))

### 渐变
- **gradHero**：对角 `#9A9CEA → #A2B9EE`（LinearGradient begin: topLeft, end: bottomRight）
- **gradDetail**：对角 `#9A9CEA → #A2DCEE`
- **gradArea**：垂直 `#9A9CEA@0.28 → #9A9CEA@0.02`（趋势图面积填充）

### 字体/字号（默认 Roboto，勿引字体文件）
- eyebrow：9.5 w600 letterSpacing 1.4（结果页内），section 标签 letterSpacing 1.2
- 页面大标题：20–27 w700；卡标题 14 w700；正文 11.5–13；轴标签 8.5–9；导航标签 10

### 通用组件
1. **AppCard**：白底 rx18，cardShadow（复用为所有卡片的壳）
2. **HeroBand**（结果页头部）：gradHero 或 gradDetail 通栏，高 ~210（breakdown 版）/ ~168（comparison 版），内容含：返回箭头（白色，左上）、eyebrow（白 82%）、标题（白 20–27 w700）、副标题（白 90% 11.5）；SafeArea 内延伸，状态栏透明
3. **InsightStrip**（替代现在的 InsightCard）：白卡 rx18 cardShadow；左 4×40 rx2 绿竖条 greenBar；"INSIGHT" 9.5 w700 green letterSpacing 1.2；正文 11.5 body，最多两行
4. **SectionLabel**：9.5 w600 faint，letterSpacing 1.2，全大写
5. **BottomNav**：白底高 104，顶部 navLine 1px 分隔线；三目的地：Home（`Icons.home_outlined`）/ Analyze（`Icons.bar_chart_rounded`）/ About（`Icons.info_outline_rounded`）；激活色 primary w600，未激活 ghost w500；图标 24 + 文字（10pt）上下排
   > 图标改用 Material 内置图标（原规格为自绘线描）。SVG 里底部 132×5 的指示条是 iPhone home indicator，Android 由系统绘制，本项目不实现。
6. **DropdownCard**：白卡 rx16 高 48–54，左标签 14 w600 ink，右 chevron-down 图标 primary；点击弹底部面板（面板样式同 AppCard 白底 rx 顶部圆角）
7. **Pill**（州选择）：白卡 rx21 高 42，内容：5px 色点 + 州名 13 w600 + chevron-down（ghost）
8. **Toggle**：46×27 rx13.5，开 = primary 底 + 白圆点
9. **EyebrowChip / BadgeChip**：rx8 高 16 小徽章（Risk: riskBg/riskText；Balanced: chipGreenBg/green）
10. **IconChip**：22×22 rx7（或 40×40 rx13）彩色底 + Material 图标（stat 卡 12pt / 快捷卡 19pt）

## 1. 屏 01 — Home（tab 根）

顺序（ListView，padding 24）：
1. 问候：`Good morning,` 14 muted + `Ready to analyze?` 22 w700 ink；右侧 44px 圆形头像 chipPeri 底 + primary 线描头像
2. **Hero CTA**：gradHero rx24 heroShadow，高 116；内容：`Start Analysis` 19 w700 白 + `16 states · 11 years · 6 sectors` 11.5 白 85%；右侧白 22% 半透明圆 + 白色箭头
   > 三个数字**不得写死**：分别取自 `GdpRepository.canonicalStates.length`、`repository.years.length`、`Sector.values.length`。曾经写死成 `5 sectors`，与实际的六个行业分类（p1..p6）不符；`test/data_counts_test.dart` 钉住这三个计数。
3. **三张 stat 卡**（Row，各 1/3 宽，高 92 rx18 白 + cardShadow）：
   - States：`16` 20 w700 ink + `States` 10 muted；icon chipPeri 底 + primary `grid_view_rounded`
   - Years：`11` + `Years`；icon chipGreenBg 底 + green `schedule_rounded`
   - Sectors：`6` + `Sectors`；icon chipCyanBg 底 + accentLight `pie_chart_outline_rounded`
   > 同上：三张卡的数值均由数据推导，不写字面量。
4. `Quick analysis` 14 w700 ink
5. **三张快捷卡**（342×64 rx18 白 cardShadow，间距 10）：左 40×40 rx13 图标块 + 标题 14 w600 ink + 副标题 10 muted + 右 chevron ghost
   - Compare States — icon chipPeri + primary `bar_chart_rounded`；副标题 `Side-by-side metrics for any two states` → 进 Filter（预选 stateComparison）
   - Trend Analysis — icon chipGreenBg + green `trending_up_rounded`；副标题 `Industrial GDP growth over time` → Filter（预选 timeTrend）
   - Diversity Diagnosis — icon chipCyanBg + accentLight `speed_rounded`；副标题 `How balanced is a state's economy` → Filter（预选 diversityDiagnosis）
6. 底部 BottomNav，Home 激活

## 2. 屏 02 — Analysis Filter（Analyze tab 根 + push）

无 AppBar。ListView padding 24：
1. 返回箭头（ink，线描）常驻显示 → 被 push 时 pop；作为 Analyze tab 根页时回到 Home tab（不 pop，否则 tab 内 Navigator 会被清空成白屏）；`New analysis` 20 w700 ink；`Pick filters, then generate charts` 12 muted
2. SectionLabel `ANALYSIS MODE` → DropdownCard：4 个 SVG 模式 + Policy Impact（第 5 项，临时保留现有页面，扩展阶段再换肤）
3. **COMPARE STATES** 区（仅 stateComparison 模式显示）：白卡 rx16（高 ~212）内：
   - `State A` 标签 10.5 w600 muted → 输入框行（44 高 rx12 白底 border 描边）：primary 点 + 州名 13.5 w600 + chevron-down primary
   - `Compare with a second state` 11.5 w600 ink + `Off = view one state on its own` 9.5 muted + Toggle
   - Toggle 开时显示 State B 行（描边 primary；点为 cyan）
4. SectionLabel `ECONOMIC SECTOR` → DropdownCard（值如 `Manufacturing`）
5. SectionLabel `YEAR` → DropdownCard（选项 = `repository.years` 倒序；**默认值 = 快照最新的一年**，现为 `2025`）
   > `AppState.year` 在 `init()` 里取 `repository.years.last`，不写死年份；旧版写死 `2024`，快照加入 2025 后默认就停在了倒数第二年。
6. `Generate Analysis` 渐变按钮：gradHero rx25 高 50 heroShadow，白字 15.5 w700 居中 → push 对应结果页
   - 模式字段适配：breakdown/trend → 只显示单州行（无 toggle）；diversity → 州/sector 区全部隐藏，仅 year；sectorBreakdown 忽略 sector 选择
7. BottomNav，Analyze 激活

## 3. 屏 03 — Mode 1 · State Comparison

1. HeroBand(gradHero)：eyebrow `ANALYSIS RESULT · STATE COMPARISON` → 标题 `Selangor vs Johor`（真实州名）→ 副标题 `Manufacturing · 2024`
2. 两个 Pill（Row，各 166 宽，间隙 10）：州 A 点 primary、州 B 点 cyan；点击可换州（底部面板）
3. **对比表卡**（rx20 高 152）：
   - 表头：`METRIC` 11 w600 faint + 右两列州名 11 w700（periText / cyanText）
   - 分隔线 gridline；三行（12 body / 13 w700 ink 值）：
     - `GDP 2024 (RM B)`：`formatRmB(州 p0)` —— 大写 B，如 `RM 111.0B`
     - `Growth YoY`：州 p0 年增（green），W.P. 无 growth 行则用 abs 自算
     - `National share`：州 p0 ÷ 全国合计（allGeography 含 Supra）× 100，1 位小数
4. **趋势对比卡**（rx20 高 236）：标题 `Industrial GDP trend` 14 w700 + 副题 `RM billion · 2020 – 2025`（真实：最近 6 年）；fl_chart 双线（州 A primary、州 B cyan，宽 3，圆点白心描边 2.5）；y 轴 4 档 ghost 8.5 右对齐，横向 gridline；x 轴 6 年 ghost 9 居中；下方图例（色点 + 州名 10 body）
5. **InsightStrip**（真实计算，两行）：
   - 行1：`X's manufacturing output is A.B× Y's in 2024`
   - 行2：`though Y is closing the gap.`（仅当 Y 增速 > X 时）/ 否则 `and the gap is widening.`
6. BottomNav，Analyze 激活

## 4. 屏 04 — Mode 3 · Time Trend

**注意：此屏头部无渐变**（SVG 如此）：
1. 顶部：返回箭头（ink）+ eyebrow `ANALYSIS RESULT · TIME TREND` faint + 标题 `Johor manufacturing` 20 w700 + 副题 `2015 – 2025`（真实年份范围）12 muted
2. **趋势面积卡**（rx20 高 320）：标题 `Industrial GDP over time` 14 w700 + 副题 `RM billion · manufacturing` 10 faint；fl_chart 面积图：gradArea 填充 + primary 线宽 3 + 白心圆点（末点 r5 放大）；虚线网格（gridline, dashArray 3-4）横向 5 档 + 左侧数值 8.5 ghost；x 轴隔年标签 `'15 '17 '19 '21 '23 '25` 9 ghost
3. **InsightStrip**（真实计算）：
   - 行1：`X manufacturing has grown every year since YYYY`（连续正增长起始年；若无连涨则写 `…grew in N of the last 10 years`）
   - 行2：`up NN% over the decade`（2015→2025 累计涨幅取整）
4. BottomNav，Analyze 激活

## 5. 屏 05 — Mode 2 · Sector Breakdown

1. HeroBand(gradDetail)：返回箭头白 → eyebrow `ANALYSIS RESULT · SECTOR BREAKDOWN` → 大标题州名 27 w700 → `Sector composition` 白 22% chip rx12 → 右上 `2024 ⌄` 白 22% pill（点击弹年份面板）
2. **KPI 卡**（rx20 高 96）：eyebrow `INDUSTRIAL GDP · 2024` 9 faint；`RM 111.0B` 23 w700 ink（州 p0）；绿色 chip `▲ 5.8% vs 2023`（chipGreenBg/green 10 w600；负增长用 ▼）；右侧 sparkline（最近 6 年州 p0，primary 线宽 2，末点 primary 实心）+ `2020 – 2025` 8 ghost 居中
3. **环形图卡**（rx20 高 176）：标题 `Sector distribution` 14 w700；**环形图**（非整饼）：环宽 ~20，中心文字年份 10 w600 muted；右侧图例：色点 + 部门名 11.5 body + 右对齐百分比 11.5 w700（**6 个真实部门**：Agriculture/Mining/Manufacturing/Construction/Services/Import duties，用 sectorColors + greenBar 补色；不用 SVG 示例的 "Utilities" 假名）
4. **Top industries 卡：不做**（无子行业数据，已确认去掉）
5. **InsightStrip**（真实计算）：
   - 行1：`X drives NN.N% of State's output`
   - 行2：`with Y a distant second at NN.N%.`（第二大部门）
6. BottomNav，Analyze 激活

## 6. 屏 06 — Mode 4 · Diversity Diagnosis

1. HeroBand(gradHero)：eyebrow `ANALYSIS RESULT · DIVERSITY DIAGNOSIS` → `Economic concentration` 21 w700 → `All 16 states · 2025 · by HHI` 11.5 白 90%
   > 州数取自当年实际排名行数（`entries.length`），年份取自 `app.year`，两者都不写死。
2. **HHI 排名卡**（rx20，内含可滚动列表容纳 16 行；每行）：
   - 排名 `1` 12 w700 faint + 州名 12.5 w600 ink
   - 徽章：HHI > `HhiBands.risk` → Risk；< `HhiBands.balanced` → Balanced；中间不显示
     > **阈值按 HHI 的可达区间切分，不是 0–1。** 六个行业分类使下限锁定在 1/6，套用通用的 0.25 / 0.4 会导致 16 州里 12 个报 Risk、且 Balanced 永远无人达到（全马最分散的 Sarawak 也只有 0.27）。
     >
     > 切点取 1/6–1 这段区间的 1/4 与 1/2 处，**准确值为 3/8 = 0.375 与 7/12 = 0.5833…**。代码里由 `Sector.values.length` 推导（`metrics.dart` 的 `HhiBands`），不写舍入后的字面量——曾经写成 0.38 / 0.58，导致 Melaka 2018（0.3783）和 Johor 2020（0.3784）被误标为 Balanced。`test/hhi_bands_test.dart` 钉住这两个准确值。
     >
     > 实测 2015–2025 全部 11 年稳定落在 2–3 Risk / 8–10 中间 / 3–5 Balanced，Risk 组恒为三个联邦直辖区。
   - 右对齐 HHI 值 12 w700，宽 48，**3 位小数**
     > 2 位不够：11 年 × 16 州里有 **28 对相邻名次会显示成同一个数**（如 2015 年第 4 名 Perlis 0.46286 与第 5 名 Selangor 0.45596 都印 `0.46`），与旁边的名次自相矛盾。3 位只剩 1 对（2015 Melaka 0.38306 / N. Sembilan 0.38262，两者实差 0.0004，显示相同反而诚实）；4 位无重复但属于虚假精度。
   - 轨道 gridline 高 10 rx5 宽 302 + 填充条（宽 = HHI×302，色按名次：1→orange1、2→orange2、3→primaryLight、4+→greenBar）
3. 注脚：`HHI = Σ(sector share)² · 1/6 = 0.167 (even split) to 1.000 (one sector)` 9.5 ghost
   > 其中 `1/6` 与 `0.167` 由 `Sector.values.length` 和 `HhiBands.floor` 动态生成，不是写死的字符串——部门数若变更，注脚跟着变。
4. **InsightStrip**（真实计算）：
   - 行1：`Most concentrated: X (top two sectors).`
   - 行2：`Most balanced: Y, across five sectors.`
5. BottomNav，Analyze 激活

## 7. 架构改动

- **main.dart**：HomeShell 改用自绘 BottomNav；Analyze tab 内部嵌 Navigator（root = FilterPage，结果页 push 在其上）；Home 快捷卡/CTA → 切 tab 到 Analyze 并预选模式（AppState.mode）
- **删除**：analyze_tab.dart（分段切换）、insight_card.dart（被 InsightStrip 取代）；home 页收藏区块与书签按钮从 6 屏移除（UserRepository/SavedAnalysis 代码保留，扩展阶段再用）
- **AppState 扩展**：stateA/stateB/compareEnabled/sector/year；generate() 返回 AnalysisRequest
- **metrics.dart 新增**：
  - `nationalTotal(repo, year)`：allGeography p0 合计
  - `nationalShare(repo, state, year)`：州 p0 ÷ nationalTotal
  - `stateTotalYoY(repo, state, year)`：p0 growth 行优先，缺失则 abs 自算
  - `cumulativeGrowth(repo, state, sector, fromYear, toYear)`
  - `consecutiveGrowthSince(repo, state, sector)`：连续正增长起始年（或 null）
  - `hhiRanking(repo, year)`：16 州按 concentration 降序
- **palette.dart**：按 §0 令牌全量补齐；`formatRm` 改大写 B（`RM 111.0B`），保留小写 m 版
- **Policy Impact**：Filter 模式下拉第 5 项，跳转现有 PolicyPage（视觉暂不换肤，扩展阶段处理）
- **About tab**：视觉不动（扩展阶段换肤），但 **“What is HHI?” 一段已改为由 `HhiBands` 生成**（`about_page.dart` 的 `_hhiExplainer()`）。旧文案写的是“0–1，低于 0.25 均衡，高于 0.4 集中”，与排名页实际使用的徒章阀值直接矛盾；现文案为“0.167 – 1.000，低于 0.375 均衡，高于 0.583 集中”，与徒章同源。

## 8. 验收清单（Pro review 用）

- [ ] 6 屏与 SVG 逐屏对照：布局顺序、圆角、阴影、颜色、字号、间距
- [ ] BottomNav 三态正确（激活 primary w600 / 未激活 ghost w500）
- [ ] 渐变方向正确（hero 对角线、area 垂直）
- [ ] 真实数据渲染：Selangor/2025 等值可对照 data.gov.my 复核
- [ ] 界面上的计数与阀值均由数据推导（stat 卡 / Hero 副标题 / About 的 HHI 说明 / 排名页副标题与脚注），无写死字面量
- [ ] 16 州 HHI 排名完整、徽章按 `HhiBands`（>7/12 Risk / <3/8 Balanced）
- [ ] 空值安全：Putrajaya 2023 p3 null、W.P. 无 growth 行
- [ ] flutter analyze 0 issue；冒烟测试仍过
