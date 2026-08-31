# 项目计划 v2 — Malaysian State Industrial GDP Analyzer

> **本文是本项目唯一的计划文档。** 2026-08-28 合并自原 `plan.md` / `plan_CN.md`（v1，已删除）与 v2 增量，之后所有变更直接改本文，不再新开版本文件。
>
> BMIT2073 Mobile Application Development · 4 人小组 · Flutter/Dart · 占 coursework 总分 50%
> 主题：**SDG 9（产业、创新、基础设施）**，使用马来西亚政府开放数据。

---

## 1. 项目概述

- 一个用于**按州、按经济部门**探索与比较马来西亚 GDP 的手机应用。
- 用户选择一个**分析模式**，选州、选部门 → 应用给出**一张聚焦的图 + 一句大白话结论**。
- 由筛选器驱动，不是搜索框。
- 聚焦州 GDP 中的**工业 / 制造业**部分，这是与 SDG 9 的连接点。

### 1.1 问题陈述

- 官方数据是存在的（OpenDOSM 面板、DOSM 的 PDF 报告），但都是**桌面网页 + 密集报表**。
- 那些视图是固定的——用户无法自由组合 州 × 部门 × 年份。
- 目前没有任何手机应用让普通人做这种自主比较。
- 我们填的空白：**移动优先、用户驱动**的州工业数据分析。同样的官方数字，为手机重做一遍。

### 1.2 SDG 9 对齐

- SDG 9 = 产业、创新、基础设施。
- 我们刻意聚焦州 GDP 的**工业/制造部门**，而不只是 GDP 总量——总量告诉你谁富，部门级才告诉你谁**工业化**，后者才是 SDG 9 真正的问题。
- 应用呈现每个州的**产业结构**：哪些州由制造业驱动、哪些州过度依赖单一部门（脆弱）、哪些州在分散化。
- Diversity Diagnosis 模式是最强的 SDG 9 抓手：过度集中 = 工业基础脆弱，而这正好是一张图能讲完的一句话。

---

## 2. 数据源

- **data.gov.my** 官方 API，数据集 `gdp_state_real_supply`。政府开放数据，可引用、导师友好。
- **无需 API key**，普通 GET，返回 JSON。
- 形状：**州 × 经济部门 × 年份**，同时含**绝对值**（实际/不变价）与**增长率**。
- 数据为年度且静态，学期内不会变。所以策略是：**打包 JSON 快照进 assets 作为基准，运行时尝试拉取线上并回退**。理由：演示不能依赖校园 wifi。
- 字段真相以 **附录 B（spike 实测结果）** 为准，不以任何文档的假设为准。

### 2.1 政策目录（第二数据源）

- `policy_catalogue.json`：手工维护的马来西亚产业政策清单，见 **附录 A**。
- 从 asset **提升为远端源**：拉远端 → 失败回退 asset → 比对 `version` 字段决定用哪份。归属见 §8。

### 2.2 资助数据（第三数据源）

- Supabase 上的 `grants` 与 `applications` 两张表，由应用自身产生的业务数据。
- **不是政府开放数据，不得混淆**。约束见 §5.3。

---

## 3. 功能：五个分析模式

整个应用由**一个共享筛选器**驱动，而不是搜索框。

> 为什么是筛选而非搜索：数据集是一个小的固定网格（16 州 × 6 部门 × 11 年）。搜索意味着在手机上打字、以及出现空结果的可能；选择器则让每一次查询都合法，两次点击，零死路。在手机上，点 chip 胜过打字。

| # | 模式 | 回答什么问题 | 图表 | 结论示例 |
|---|------|------------|------|---------|
| 1 | **State Comparison** | 两三个州在某个部门上如何对比？ | 并排柱状 | "槟城的制造业产出是吉打的 3.5 倍。" |
| 2 | **Sector Breakdown** | 某个州的经济靠什么支撑？ | 饼图 / 构成 | "砂拉越：矿业 + 制造业 = GDP 的 47%。" |
| 3 | **Time Trend** | 某州某部门这些年怎么走的？ | 单线 | "柔佛制造业自 2021 年起年年增长。" |
| 4 | **Diversity Diagnosis** | 哪些州过度集中、哪些州均衡？ | 排名列表 | "最集中：布城（0.928）。最均衡：砂拉越（0.272）。" |

> 上表结论句均已用 `assets/gdp_snapshot.json` 2024 年数据复核。原先四句里有三句与真实数据不符（尤其模式 4 写反了——砂拉越是**最均衡**的州，不是最集中）。
| 5 | **Policy Impact** | 某条产业政策生效前后，目标部门的增速如何变化？ | 带竖线标注的折线 | "制造业在 NIMP 2030 前年均 +3.1%，之后 +5.2%。" |

- 每个模式输出同样的东西：**一张图 + 一句结论**。一致性 = 好建、好评分。
- Diversity Diagnosis 需要一个集中度计算（HHI，见 §6），这是"我们真的做了分析"的得分点，不是把 API 数字重新画一遍。
- **Policy Impact 的措辞纪律：只说"关联 / 前后对比"，绝不宣称因果。** 学术严谨，演示时是加分点。

### 3.1 移动优先设计（这是一门移动应用课，本节即卖点）

- **卡片流** — 一张卡一个结论。不做需要滚动的报告墙。
- **手势交互** — 点击图表分段下钻。
- **只用适合手机的图** — 单组柱、构成饼、单线。**禁止**密集多线图和宽表格：需要横屏才读得了的，一律不要。
- **限制每屏数据量** — 比较最多 2–3 个州。理由：手机宽度，且这会逼出一个聚焦的结论而不是数据堆砌。
- 对导师的说法：官方 OpenDOSM 面板是桌面 + 密集的；我们的是同一份官方数据**为手机重做**。

---

## 4. 架构分层

- **数据层** — 拉取、清洗成类型化记录、缓存、计算派生指标（工业占比、部门集中度）。**独占**所有原始 API 字符串处理。
- **筛选 / 状态层** — 一个共享选择器：选模式 → 只显示该模式下合法的选项 → 构造 `AnalysisRequest` 交给当前页面。
- **分析页面** — 一个模式一页。每页拿到 request，画自己的图，写自己的结论。**页面从不自己取数**。
- **UI / 共享组件** — 可复用的卡片、州选择、结论条。

> 为什么用一个共享筛选器而不是每页各做一个：4 个人各写一个选择器 = 4 套略有差异的 UX 和 4 套校验 bug。一个筛选器、一道校验闸门，页面只会收到合法的请求。

---

## 5. 新功能设计

> 本节说**为什么这么设计**；逐个功能的落地步骤、验收与已知坑见 [`feature_plans.md`](feature_plans.md)。

### 5.1 Policy Impact（模式 #5）

- 数据：`policy_catalogue.json`，字段 `policyId, name, abbreviation, effectiveYear, targetSectors[], summary, sourceUrl, version`。
- 交互：选一条政策 → 目标部门的逐年增长线图，`effectiveYear` 处画竖线标注 → 对比生效前 3 年 vs 后 3 年的年均增速（**跳过生效当年**，政策见效需要时间且当年噪声大）→ 一行结论。
- **数据窗口注意事项**：数据范围 2015–2025。Industry4WRD（2018）前后各 3 年充足；**LSS（2016）没有前置窗口**——2015 是首年、算不出增速，2016 自身的增速又因是生效年被跳过，所以 `beforeAvg` 为 null，UI 只能画标注线加说明（`test/policy_window_test.dart` 钉住这条）；NIMP / NETR / 稀土禁令（均 2023）后窗口仅 2 年，UI 上注明；NSS（2024）后窗口仅 1 年 → 降级为"画标注线 + 政策后数据尚不足，仅展示趋势"的诚实说明（walkthrough 严谨加分点）。
- 数据完全复用 `GdpRepository` 现有查询，零新查询接口。

### 5.2 User module（Supabase + 离线后门）

- 功能：本地/云端档案 + **收藏分析**（`SavedAnalysis` = `AnalysisRequest` 快照 + 时间戳 + 备注）+ **角色**（普通用户 / 管理员）。
- **后门设计——先本地、后云端，同一接口换实现**：v1 实现 `LocalUserRepository`（shared_preferences 存 JSON），不连 Supabase 也全功能运行；v2 实现 `SupabaseUserRepository`，同接口换实现。
- 收藏入口：结果卡上的收藏按钮 + Home tab 的收藏列表。

### 5.3 资助申请模块（Grants）

闭环：**管理员发布 grant → 用户浏览可申请的 grant → 用户提交申请 → 管理员批准或拒绝**。正好覆盖完整 CRUD，对应 brief 的「data management 15 分」。

**必须挂在分析上，不能是并列的第二个应用。** 接点：grant 的 criteria 用 `state + sector` 表达 → 用户在 Sector Breakdown 里钻取到「雪兰莪·制造业」→ 页面直接列出适用于此的资助 → 申请。资助是分析的**出口**（分析完能干什么），这个接点必须在 UI 上做出来。

四条硬约束：

1. **必须标注「演示用途，非官方申请渠道」。** 应用看起来在替政府收资助申请，有让人误以为申请已递交的风险。About 页与申请提交页各放一句明确说明。
2. **申请表单不设计任何敏感字段。** 不要身份证号、银行账号、联系电话。只收公司或项目名、州、部门、申请金额、简述。在字段设计阶段避开，比事后声明"我们不存"干净。
3. **种子资助用真实计划名，条件注明自定。** 用 MIDA Domestic Investment Strategic Fund、MITI Industry4WRD Intervention Fund、Cradle CIP 这类真实存在的名称并附 `sourceUrl`，但 criteria 注明「本应用自定的演示条件，非官方标准」。与政策目录同一套措辞纪律。
4. **状态机只有三态**：`pending / approved / rejected`。不加 draft、不加 under_review——每多一个状态就多一屏 UI 和一批边界情况。

**技术硬要求：管理端权限必须由 Supabase RLS 挡住，不能只在 UI 里隐藏入口。** 手机端「只藏按钮」等于没有权限控制。这条是 walkthrough 里最能讲的一段。

---

## 6. 冻结契约

> 这一节是让多人 Flutter 协作不散架的关键。任何变更需全组同意，且由 A 统一改。如果你的页面需要这里没有的东西，先提出来，不要自己加。

### AnalysisRequest — 一切依附的对象

```dart
enum AnalysisMode { stateComparison, sectorBreakdown, timeTrend, diversityDiagnosis, policyImpact }

class AnalysisRequest {
  final AnalysisMode mode;
  final List<String> states;   // 规范州名
  final Sector? sector;        // null = 全部部门（仅在模式允许时）
  final int yearStart;
  final int yearEnd;           // 单年时等于 yearStart
  final String? policyId;      // 仅 policyImpact 使用
}
```

各模式的合法性（由筛选 UI 保证，页面无需再校验）：

| 模式 | states | sector | years |
|------|--------|--------|-------|
| State Comparison | 1–2 | 必填 | 单年 |
| Sector Breakdown | 恰好 1 | 页面用全部部门 | 单年 |
| Time Trend | 恰好 1 | 必填 | 区间 |
| Diversity Diagnosis | 忽略（用全部州） | 忽略 | 单年 |
| Policy Impact | 忽略 | 由政策的 targetSectors 决定 | 由数据范围决定 |

### GdpRecord

- 字段：`state, sector, year, value?（RM 百万，不变价）, growthYoy?（%）`
- **两个值都可空**：原始数据 abs 与 growth 是两行，仓库层 join 成一条；且存在 null 值（见附录 B）。

### Sector — 冻结枚举

- `agriculture, mining, manufacturing, construction, services, importDuties`
- 原始代码 `p1`–`p6` 到枚举的映射只在 `sector_mapping.dart` 一个文件里。页面只见枚举。理由：DOSM 若改标签，只改一个文件。
- **`p0`（总量）不进枚举**，作为仓库内部的「总量」引用供占比 / HHI 计算。

### GdpRepository

```dart
class GdpRepository {
  Future<void> load();   // 线上拉取 → 失败回退打包快照
  List<GdpRecord> query({List<String>? states, Sector? sector, int? yearStart, int? yearEnd});
  double? totalValue({required String state, required int year});
  double? sectorValue({required String state, required Sector sector, required int year});
  double? growth({required String state, required Sector sector, required int year});
  double? industryShare({required String state, required int year});   // 制造业 ÷ 总量，%
  double? concentration({required String state, required int year});   // HHI，1/6 – 1
  List<String> get states;
  List<int> get years;
}
```

- **集中度 = HHI**（各部门占比的平方和）。标准经济学指标，一行代码，walkthrough 好讲。
- **阈值不能用通用的 `0.25 / 0.4`。** HHI 在 N 个部门下的下限是 `1/N`（各部门均分），不是 0；我们只有 6 个部门，下限锁死在 `1/6`。套用通用阈值的后果实测是：16 州里 12 个报「集中」，而「均衡」永远无人达标（全马最分散的砂拉越也只有 0.272）。
- 正确做法是在**可达区间 `1/6 – 1`** 上切分，取 1/4 与 1/2 处：**准确值 `3/8 = 0.375` 与 `7/12 = 0.5833…`**。代码里由 `Sector.values.length` 推导（`metrics.dart` 的 `HhiBands`），不写舍入字面量——曾写成 `0.38 / 0.58`，导致 Melaka 2018（0.3783）与 Johor 2020（0.3784）被误标为均衡。`test/hhi_bands_test.dart` 钉住准确值。
- 实测 2015–2025 全部 11 年稳定：2–3 个「集中」/ 8–10 个中等 / 3–5 个「均衡」，且「集中」组恒为三个联邦直辖区（布城行政、吉隆坡金融服务、纳闽离岸油气）。

#### 硬规定：界面上的计数与阀值一律从数据推导

不只是 HHI 阀值。凡是描述数据本身的数字，**一律不得写字面量**，否则快照一更新就会静默地说谎：

| 位置 | 旧写法 | 现在取自 |
|---|---|---|
| Home stat 卡 / Hero 副标题 | `16` / `11` / **`5`**（错，实际六个行业） | `canonicalStates.length` / `years.length` / `Sector.values.length` |
| About 页 “What is HHI?” | “0–1，< 0.25 均衡，> 0.4 集中”（与徒章矛盾） | `HhiBands` + `Sector.values.length` |
| 排名页副标题 | `All 16 states` | `entries.length` |
| 排名页 insight | “across all six sectors” | `Sector.values.length` |
| Trend insight | “over the decade” | `years.last - years.first` |
| 默认年份 | `AppState.year = 2024` | `init()` 里取 `repository.years.last`（2025）|
| `AnalysisRequest` 年份默认 | `= 2024` | 改为 `required`，由调用方传入 |

`test/data_counts_test.dart` 钉住三个计数（6 行业 / 16 州 / 11 年）与“默认年必须有数据”。

### UserRepository

```dart
abstract class UserRepository {
  Future<void> init({bool useRemote = false});
  String? get nickname;
  Future<void> setNickname(String name);
  String? get userId;          // 资助模块需要
  UserRole get role;           // user | admin，资助模块需要
  Future<List<SavedAnalysis>> favorites();
  Future<void> saveFavorite(SavedAnalysis a);
  Future<void> removeFavorite(String id);
}
```

### GrantRepository — 按角色拆成两个文件

```dart
// grant_repository.dart —— 用户端（C）
abstract class GrantRepository {
  Future<List<Grant>> available({String? state, Sector? sector});
  Future<void> apply(GrantApplication application);  // 用 GrantApplication.draft() 构造
  Future<List<GrantApplication>> myApplications();   // 只含本人，按提交时间倒序
}

// grant_admin_repository.dart —— 管理端（B）
abstract class GrantAdminRepository {
  Future<void> publish(Grant grant);
  Future<List<GrantApplication>> pending();
  Future<void> decide(String applicationId, ApplicationStatus status);
}
```

- **两个文件不合并。** 同一个文件两个人写，`git blame` 会糊掉，而 commit 归属是本作业的评分证据。
三条定案的行为规则（写在接口注释里，两端必须一致）：

1. **`available()` 只返回 `isOpen == true` 且未过 `deadline` 的资助。** 截止判定放在仓库层，不留给页面——否则管理端和用户端会各判各的。
2. **`myApplications()` 只返回本人的申请。** 本地桩虽然只有一个用户，也照样按 `userId` 过滤，这样换成 Supabase（由 RLS 做同样的事）时界面行为不变。
3. **申请 id 由仓库层生成，不由表单决定。** C 用 `GrantApplication.draft()` 构造（不传 id / status / submittedAt），`apply()` 落库时赋 id——对应 Supabase 里 `id` 列的服务端默认值。

- 桩已落地于 `local_grant_repository.dart`（`LocalGrantRepository` + `LocalGrantAdminRepository`，共享一个本地存储）。**假角色开关在 `LocalUserRepository.setFakeRole()`**——角色是用户属性，不在 grant 侧；C 用它在 B 的 Supabase 就绪前自测用户 / 管理员两种视角。

### Grant / GrantApplication — 冻结字段

```dart
enum UserRole { user, admin }
enum ApplicationStatus { pending, approved, rejected }

class Grant {
  final String id;
  final String name;
  final String agency;
  final String? state;      // null = 全国通用
  final Sector? sector;     // null = 不限部门
  final int? maxAmountRm;   // null = 无上限，单位实际令吉（不是 RM 百万）
  final DateTime deadline;
  final String sourceUrl;
  final String criteriaNote; // 真实计划名 + 一句「演示自定条件，非官方标准」
  final String description;
  final String publishedBy;
  final DateTime publishedAt;
  final bool isOpen;
}

class GrantApplication {
  final String id;
  final String grantId;
  final String userId;
  final String projectName;
  final String state;
  final Sector sector;
  final int requestedAmountRm;
  final String note;
  final ApplicationStatus status;
  final DateTime submittedAt;
  final DateTime? decidedAt;   // 待审批时为 null
}
```

- **criteria 结构化**：`state` / `sector` / `maxAmountRm` 三轴，`null` = 该轴不限。C 的资格判定据此逐条产出「符合 / 不符 + 原因」，这是它的数据处理证据。
- **`available()` 的 null 语义**：入参 `null` = 不按该轴过滤；grant 字段 `null` = 该轴不限，即 `grant.state == null || grant.state == 请求州`（sector 同理）。B 建表与 C 写查询必须用同一语义，否则是静默错。
- **金额单位陷阱**：`maxAmountRm` / `requestedAmountRm` 是**实际令吉**，而 GDP 原始值单位是 RM 百万。不得复用 `RM 98.4b` 那个按百万输入的格式化函数，否则差 6 个数量级。

### 政策目录远端格式（给 D 的 F8）

托管地址（GitHub raw 即可）返回：

```json
{ "version": 1, "policies": [ { ...PolicyRecord 字段... } ] }
```

- 比对远端 `version` 与本地 asset 里的 `version`；远端更新则用远端并缓存，否则用 asset；失败静默回退。
- 本地 asset `policy_catalogue.json` 也改成同构 `{version, policies[]}`——D 在 F8 改，A 不碰。

### 导出列定义（给 D 的 F9）

结果集重塑为扁平表，列序固定，四人一致：

```
year, state, sector, value_rm_mil, yoy_pct, share_pct
```

- `value_rm_mil` = RM 百万（与数据同单位）；`yoy_pct` / `share_pct` 为百分比数值（如 `44.3`，不带 `%` 符号）。
- CSV 带 UTF-8 BOM（Excel 中文不乱码）；PDF 页脚放数据来源与免责声明。

### 页面契约

- 每个页面从共享 provider 读当前 `AnalysisRequest`，渲染：**1 图 + 1 结论 + 可选下钻**。
- 页面**不**调 API、**不**自留数据集副本、**不**修改 request。
- 下钻只接收 `(state, sector, year)`，不多不少。
- 结论 = 一句带数字的大白话，由页面从仓库值算出。

### 格式约定

- 百分比：1 位小数 → `44.3%`
- 金额标签：缩写 → `RM 98.4b` / `RM 512m`（原始值单位是 RM 百万）
- 年份：纯数字 `2023`
- 州名：数据层一份规范列表；任何页面不得硬编码州名字符串。

---

## 7. 导航结构（按实际实现）

> 与 v1 的设想不同：筛选器**是一个独立页面**，结果页 push 在它之上。Analyze tab 是一个嵌套 Navigator，因此底部导航栏在每一屏都保持可见。

```
App · 底部 Tab
├── Home tab
│   └── Home（问候 + 收藏列表 + 开始分析）
├── Analyze tab  ← 嵌套 Navigator，根为 Filter
│   └── Filter（选模式 / 州 / 部门 / 年份）
│         └─[Generate]─▶ 结果页（5 选 1）
│               ├── State Comparison
│               ├── Sector Breakdown ──[点击分段]─▶ 下钻 + 适用资助
│               ├── Time Trend
│               ├── Diversity Diagnosis
│               └── Policy Impact
└── About tab
    └── About / 数据来源（署名、HHI 解释、免责声明、团队）

扩展（新增）
├── 登录 / 注册 / 档案
├── 资助浏览 → 详情与申请 → 我的申请状态       （用户端）
└── 资助发布 → 待审批列表                      （管理端，RLS 保护）
```

- 系统返回键：先回退 Analyze 的页面栈，再回 Home tab，最后才退出应用。根 Navigator 从不被 pop（曾导致白屏）。

---

## 8. 模块归属

> **归属的唯一真相源是 [`ownership.md`](ownership.md)。** 谁负责哪些代码、哪些屏、哪条网络调用，以及交接顺序与演示分工，全在那份文件里。归属变更只改那一份，不要在本文另记。

本文只保留三条与计划耦合的原则，其余不重复：

1. **每人手上都有一条真实的网络调用和一块真实的数据处理**（导师明确要求）。判据严格：读 asset、读 shared_preferences、调分享插件都不算，必须真正发出 HTTP 请求。
2. **地基归一个人**（契约、数据层、状态层、共享组件、骨架全归组长，也只有组长能改），因为合并冲突是多人 Flutter 的头号时间黑洞。
3. **弱成员拿独立、有模板、不阻塞他人的活**，且按能讲懂的难度分页而不是按行数配平——期末每人讲自己的模块，「原创性与理解」单项 35 分。

与时间线直接相关的两个硬节点（详见 `ownership.md` §5）：

- **A 即刻**交出 `api_client.dart` 与四份契约（含 `LocalGrantRepository` 桩和假角色开关），否则 C 和 D 都动不了。
- **B 在 8/31 前**交出已初始化的 Supabase client、建好的表与 RLS 策略。这是硬期限，不是建议——晚了 B 与 C 的网络调用证据会同时落空。

---

## 9. 文件结构

> 完整的目录树连同逐文件归属见 [`ownership.md`](ownership.md) §4。此处只说约束。

- **文件夹即归属边界**：只动自己 lane 里的文件；`models/` 的任何改动需全组同意；`widgets/` 的改动先在群里说。理由：合并冲突是多人 Flutter 的头号时间黑洞，而且 commit 自然落在自己的文件里，这正是仓库被检查时要的**逐人贡献证据**。
- **一个文件只有一个作者。** 同一文件多人写，`git blame` 会糊掉，而 commit 归属是本作业的评分证据。资助模块因此按角色拆成 `grant_repository.dart`（用户端）与 `grant_admin_repository.dart`（管理端）两个文件，不合并。
- 分层职责见 §4；新增文件必须落在既有的 `models/ data/ state/ pages/ widgets/` 分层里，不新开顶层目录（`export/` 除外，它是唯一的新增顶层）。

---

## 10. 技术栈

| 选择 | 理由 |
|---|---|
| **Flutter / Dart** | 作业强制要求 |
| **fl_chart** | 纯 Dart，无原生构建麻烦；柱/饼/线全覆盖，而我们本来也只允许自己用这三种；社区与示例最多 |
| **http** | 一个公开 GET 端点，无鉴权、无拦截器需求——`dio` 是杀鸡用牛刀 |
| **Provider** | 唯一的全局状态就是当前选择 + 已加载数据集，Provider 是最简单可行方案。页面只碰 request 与仓库，所以这个选择不会外溢到 B/C/D 的代码 |
| **Supabase** | 用户模块与资助模块的后端：Auth + Postgres + RLS，免费额度够用，Flutter 官方 SDK |
| **shared_preferences** | 本地实现的存储；也是「不连云端也能全功能运行」这条后门的基础 |
| **私有 GitHub 仓库** | 规格要求；逐人 commit 证据也存在这里 |

---

## 11. brief 核对清单

> 依据实际 brief（`BMIT2073 Assignment 202605.pdf`）。分数构成：**80/100 是个人分**（工作量 15、工作质量 15、**数据管理 15**、**原创性与理解 35**），20 分是小组/演示。原创性与理解单项就占 35 分——**必须能讲清自己模块的每一行**。而「数据管理 15」正是派生指标层与资助 CRUD 的价值所在。

**应用与仓库**

- [ ] 用 **Flutter/Dart** 构建
- [ ] 使用马来西亚政府开放数据服务 **SDG 9**（brief 允许「实时**或**静态」数据，所以快照 + 回退的做法明确合法）
- [ ] **私有 GitHub 仓库**且体现**全体成员的持续贡献**——各自推自己的模块，不许有人在最后一周批量上传（commit 历史会被检查）
- [ ] **提交前删除代码中的全部注释**——开发期保留，提交前一遍性剥离
- [ ] **已部署**——brief 说「design, develop, and deploy」：release APK + 真机现场演示
- [ ] 全部 5 个分析模式端到端跑在真实 data.gov.my 数据上

**提交包（Week 12 末，即 9 月 6 日）**

- [ ] 小组 ZIP（由组长提交），命名 `<ProgrammeCode+Group>_<TeamLeadName>`，内含：
  - [ ] 演示幻灯片，含**应用全部主屏**（PDF，`..._Presentation`）
  - [ ] **私有 GitHub 仓库链接**（确认导师能打开）
  - [ ] **Appendix A — 作业声明表**，含 **AI 披露声明**（PDF）
  - [ ] **Appendix B — 作业评估表**（**Excel**，不是 PDF）
- [ ] 每位成员各自的 ZIP，命名 `<ProgrammeCode+Group>_<TeamLead>_<YourName>`，内含：
  - [ ] **Appendix C — 同行评价表**（PDF）
  - [ ] **Appendix D — 任务描述**（PDF）
- [ ] AI 政策为 **Green（AI-Supported）**——鼓励用 AI，但 Appendix A 必须列出**使用的工具与 prompt，以及如何验证输出**。所以：`docs/ai_use_log.md` 每次会话后即时追加，**不要**在提交前夜回忆重构。

**演示**

- [x] ~~Week 6 原型演示~~（已完成）
- [ ] **Week 13–14 期末演示**：20–40 分钟（每人约 10 分钟），**必须出席**。须包含：介绍、**现场演示**、结构化代码走查——**每人讲自己的模块**

---

## 12. 时间线

> 固定日期：**Week 12 末（9 月 6 日）提交**，**Week 13–14 期末演示**。Week 11 = 8/24–8/30，Week 12 = 8/31–9/6。

| 日期 | 事项 |
|---|---|
| **8/28（今日）** | A 出 `api_client.dart` + 四份契约 + 拆 `policy_metrics.dart`；B 定表结构 |
| **8/29–8/31** | B：Supabase 实例 + Auth + 建表 + RLS（8/31 交付）· C：本地桩三屏 + 资格判定 · D：政策目录远端化 + 导出 |
| **9/1–9/2** | B：管理端两屏 · C：换 Supabase 实现 · 全员联调 |
| **9/3–9/4** | 真机全量测试 + 修；`flutter analyze` 归零 |
| **9/5** | 剥离全部注释；release APK 构建 |
| **9/6** | 提交包：slides（全部主屏）· Appendix A–D · 按命名规则打 ZIP |
| **Week 13** | 集体 walkthrough 排练，每人过自己模块；**含双账号的资助审批演练** |
| **Week 14** | 期末演示 |

---

## 13. 范围

- **在范围内**：州 × 部门 GDP 分析、5 个分析模式、派生指标（工业占比、HHI）、移动优先的卡片/手势 UI、离线回退数据、**用户账号与收藏**、**资助发布-申请-审批闭环**、结果导出。
- **不在范围内**：价格/通胀数据集、非 GDP 数据集、地图、单次比较超过 2 个州、资助的真实支付或对接任何官方系统。

> 注：v1 曾把「用户账号」列为范围外。导师反馈功能偏弱后，用户模块与资助模块成为核心新增，此条已推翻。

---

## 14. 风险清单

1. **时间线极紧。** 从今天到提交只有 9 天，其中 B 要新写约 750 行、C 约 550 行。缓解：C 与 D 的活都有本地桩或模板可先行，不等任何人；管理端两屏是 B 唯一可压缩的部分（最坏情况砍成一屏：发布与审批合并成一个列表页）。
2. **Supabase 若接不上。** 本地实现已全功能，演示无碍——但 B 与 C 的「网络调用」证据会同时落空。故 8/31 是硬期限，不是建议。
3. **资助功能的表述风险。** 见 §5.3 四条约束，尤其是免责标注与敏感字段。
4. **政策数据表述偏颇。** 措辞纪律（关联非因果）+ `sourceUrl` 注明出处。
5. **Release APK 构建环境（签名/工具链）未验证。** 9/5 之前先做一次 release build 排雷，不要留到当天。
6. **非代码交付物与开发抢时间。** slides 与 Appendix A–D 从本周起并行推进，不排在 9/5 之后。

---

## 附录 A — 政策目录

（2026-08-26 调研结果，生效年全部经官方来源验证）

| 政策 | 缩写 | 生效年 | 目标 sector | 来源 |
|---|---|---|---|---|
| New Industrial Master Plan 2030 | NIMP 2030 | 2023 | manufacturing | PMO 官方发布 |
| National Semiconductor Strategy | NSS | 2024 | manufacturing | MIDA 官方 |
| National Energy Transition Roadmap | NETR | 2023 | services（能源） | 经济部官方 PDF |
| Large Scale Solar programme | LSS | 2016 | services（发电） | 能源委员会官方 |
| 稀土出口禁令（12MP 中期检讨） | — | 2023 | mining | 政府公告 |
| National Agricommodity Policy 2021–2030 | DAKN 2030 | 2021 | agriculture | KPK 官方文件 |
| Industry4WRD: National Policy on Industry 4.0 | Industry4WRD | 2018 | manufacturing | MITI 官方 |
| Construction 4.0 Strategic Plan 2021–2025 | Construction 4.0 | 2021 | construction | CIDB 官方 |

- mining 条目用**稀土出口禁令（2023）**，替代尚未正式落地的 DMN3（备用方案：NMP2 2009）。
- 5 个部门全覆盖（manufacturing 3 条，符合马来西亚产业政策的实际分布）。

## 附录 B — 数据 spike 实测结果

（2026-08-26，全部经实测验证，CSV 与 JSON 逐行比对一致）

- **端点**：`https://api.data.gov.my/data-catalogue?id=gdp_state_real_supply`。**plan v1 里的 CKAN 旧端点已死**（404）。GET 无 key，返回**裸 JSON 数组**（无 CKAN wrapper），需跟随 301 重定向。
- **字段**（仅 5 个）：`series`（`abs` | `growth_yoy`）、`date`（`YYYY-01-01`，年度）、`state`、`sector`（代码）、`value`（float，可为 null）。
- **sector 代码**：`p0`=总量, `p1`=Agriculture, `p2`=Mining, `p3`=Manufacturing, `p4`=Construction, `p5`=Services, `p6`=Import duties（p0 ≈ p1..p6 之和，已验证）。
- **州**：17 个字符串 = 13 州 + `W.P. Kuala Lumpur` / `W.P. Labuan` / `W.P. Putrajaya` + **`Supra`**（跨国/不归属，离岸油气挂它名下，p2 有值其余为 0）。应用层：州选择器**排除 Supra**，但全国汇总**包含**它。
- **年份**：2015–2025（含完整 2025），单位 RM 百万，2015 年不变价。
- **陷阱**：
  1. `W.P. Putrajaya` 的 abs 行 2023 年才开始。
  2. `growth_yoy` 只有 13 个州、2016–2025（Supra / W.P. 无，2015 无）。
  3. 恰好 1 个 null 值（2023 Putrajaya p3 abs）→ `value` 必须可空。
  4. API **忽略** `series=` / `state=` 过滤参数 → 全量拉取、客户端过滤。
  5. 年份取 `date.substring(0,4)`，别把 `01-01` 当日数据解析。
- **原始数据大小**：212KB / 2163 行 → **整个数据集直接打包进 `assets/gdp_snapshot.json`**，不裁剪。
- **CSV 直链**（备份）：`https://storage.dosm.gov.my/gdp/gdp_state_real_supply.csv`（UTF-8 无 BOM）。
