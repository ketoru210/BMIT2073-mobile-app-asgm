# 模块归属

> 2026-08-28 定案。本文是**归属的唯一真相源**——谁负责哪些代码、哪些屏、哪条网络调用。
> 计划、契约、时间线见 [`plan_v2.md`](plan_v2.md)；本文只回答「谁做什么」。
> 归属变更直接改本文，并在群里通知；不要在别的文档里另记一份。

---

## 1. 分配原则

1. **每人手上都有一条真实的网络调用和一块真实的数据处理。** 导师明确要求。判据严格：读 asset、读 shared_preferences、调分享插件都**不算**网络调用，必须是真正发出 HTTP 请求。
2. **地基归一个人。** 会被别人依赖的东西（契约、数据层、状态层、共享组件、骨架）全归 A，也只有 A 能改。理由：合并冲突是多人 Flutter 的头号时间黑洞。
3. **弱成员拿独立、有模板、不阻塞他人的活。** 每一件都要有现成的东西可照抄，且不依赖别人的进度。
4. **按能讲懂的难度分页，不按行数配平。** 期末每人讲自己的模块 10 分钟，「原创性与理解」单项 35 分，考的是能不能答上追问。让弱成员讲最复杂的页，是拿最没把握的地方去顶最高分值的一项。
5. **一个文件只有一个作者。** 同一文件多人写，`git blame` 会糊掉，而 commit 归属是本作业的评分证据。资助模块因此按角色拆成两个仓库文件。

---

## 2. 逐人总表

| 成员 | 新写（主战场） | 接管已有 | 网络调用 | 数据处理 |
|---|---|---|---|---|
| **A**（组长） | `api_client.dart` + 四份接口契约 + 页内切换（已延后，见 §6） | 数据层 · `models/` · `AppState` · `widgets/` · `main.dart` · Filter · Diversity | data.gov.my 全量 GET + 回退缓存 | 两行 join · null 与 Supra 归属 · HHI · 全国汇总 |
| **B** | Supabase 项目（建表 · **RLS** · Auth · 回调配置）· `SupabaseUserRepository` · 登录/注册/档案 3 屏 · 资助管理端 2 屏 + `grant_admin_repository.dart` | `LocalUserRepository` · Home · State Comparison | Auth + `profiles` 读写 · `grants` insert · `applications` update | 本地与云端收藏合并 · 角色判定与 RLS 策略设计 |
| **C** | `grant_repository.dart` · 资助用户端 3 屏（浏览 / 申请 / 状态）· criteria 资格判定 · Breakdown 钻取里的「适用资助」卡片 | Sector Breakdown | `grants` select · `applications` insert / select | 分析上下文与资助条件的资格匹配、不符原因说明 |
| **D** | 政策目录远端化 · 导出 CSV/PDF · 从 `metrics.dart` 拆出 `policy_metrics.dart` | Policy Impact · Time Trend · About | 政策目录远端 GET + 版本比对回退 | 政策前后窗口年均增速（含非对称窗口）· 结果集重塑为扁平表 |

### 为什么这么分

- **A** 拿走所有会被别人依赖的东西，是唯一允许改共享文件的人。他的 10 分钟讲数据层与筛选闸门，不缺料。
- **B** 能力接近 A、少用 AI 但会查文档 → 拿最需要读官方文档和调配置的一块。管理端归他是因为它要的东西（角色、RLS、权限校验）全住在身份体系里，形成一条完整链路：Auth → profile → role → RLS → 管理能力。他屏数最多但每屏都轻（表单与列表）。
- **C** 能力较弱但可用 A 的资源 → 只拿资助用户端，不碰 Supabase 配置和权限；先用本地桩跑通，不等 B。**只留一条线**：分析出某州靠某部门 → 这里有哪些资助 → 怎么申请 → 状态怎么流转。一条连贯故事比四个碎片好讲。
- **D** 能力较弱且只有较弱的 AI → 拿完全独立、不卡任何人的活，每一件都有现成模板可照抄（网络照 A 的 client，导出照契约里的列定义）。政策目录远端化是**专为补齐他的网络调用而设的第四条通道**。

---

## 3. 屏归属（16 屏）

| 屏 | 行数 | 归属 | 状态 |
|---|---|---|---|
| Home | 521 | **B** | 已建成 |
| Filter | 355 | **A** | 已建成 |
| State Comparison | 413 | **B** | 已建成 |
| Sector Breakdown | 476 | **C** | 已建成 |
| Time Trend | 254 | **D** | 已建成 |
| Diversity Diagnosis | 252 | **A** | 已建成 |
| Policy Impact | 431 | **D** | 已建成 |
| About | 135 | **D** | 已建成 |
| 登录 / 注册 / 档案 | ×3 | **B** | 新写 |
| 资助浏览 / 详情申请 / 我的申请 | ×3 | **C** | 新写 |
| 资助发布 / 待审批 | ×2 | **B** | 新写 |

每人屏数：A 2 · B 7 · C 4 · D 3。

- **屏数不等于工作量。** A 只有 2 屏，但 Filter 是全项目交互最绕的页（模式适配 + 路由 + 校验闸门），且他还扛着全部地基。B 有 7 屏，但 auth 三屏是表单、管理端两屏是表单加列表，都不难。
- **Breakdown 的接点归属**：C 要在钻取详情里插一张「适用资助」卡片。整页也归 C，所以不存在跨人改文件的问题。如果哪天把 Breakdown 移走，这个接点要重新安排。

---

## 4. 文件归属

> **文件夹即归属边界**：只动自己 lane 里的文件；`models/` 的任何改动需全组同意；`widgets/` 的改动先在群里说。
> 好处是 commit 自然落在自己的文件里，这正是仓库被检查时要的逐人贡献证据。

```
lib/
├── main.dart                          入口 + provider + tab 壳            A
├── models/                            冻结契约（改动需全组同意）
│   ├── analysis_request.dart                                             A
│   ├── gdp_record.dart                                                   A
│   ├── sector.dart                                                       A
│   ├── policy_record.dart                                                A
│   ├── saved_analysis.dart                                               A
│   └── grant.dart                     Grant + GrantApplication      新   A
├── data/
│   ├── api_client.dart                data.gov.my GET + 解析        新   A
│   ├── gdp_repository.dart            仓库 + 缓存/回退                   A
│   ├── metrics.dart                   HHI · 全国汇总 · 占比               A
│   ├── sector_mapping.dart            原始代码 → Sector，唯一映射文件     A
│   ├── policy_metrics.dart            政策前后窗口   从 metrics 拆出      D
│   ├── policy_source.dart             政策目录远端 + 回退           新   D
│   ├── user_repository.dart           本地实现                           B
│   ├── supabase_user_repository.dart  云端实现 + 角色               新   B
│   ├── grant_repository.dart          资助读取与申请（接口）      新   C
│   ├── grant_admin_repository.dart    资助发布与审批（接口）      新   B
│   └── local_grant_repository.dart    离线桩 + 共享存储             A
├── state/
│   └── app_state.dart                 当前选择 + 数据集                  A
├── pages/
│   ├── filter_page.dart               共享筛选器                         A
│   ├── diversity_page.dart            Diversity Diagnosis                A
│   ├── home_page.dart                 问候 + 收藏列表                    B
│   ├── comparison_page.dart           State Comparison                   B
│   ├── breakdown_page.dart            Sector Breakdown + 下钻            C
│   ├── trend_page.dart                Time Trend                         D
│   ├── policy_page.dart               Policy Impact                      D
│   ├── about_page.dart                数据来源 + 免责声明                D
│   ├── auth/                          登录 / 注册 / 档案            新   B
│   ├── grants/                        浏览 / 申请 / 我的申请        新   C
│   └── grants_admin/                  发布 / 待审批                 新   B
├── export/                            CSV / PDF 生成 + 分享         新   D
├── ui/palette.dart                    设计令牌                           A
└── widgets/                           11 个共享组件                      A
assets/
├── gdp_snapshot.json                  打包基准数据                       A
├── policy_catalogue.json              政策目录本地回退                   D
└── grants_seed.json                   资助种子（离线桩用）               A
```

---

## 5. 交接顺序

谁必须先动，才不会有人空等。

| # | 谁 | 何时 | 做什么 |
|---|---|---|---|
| 1 | **A** | 即刻 | 出 `api_client.dart` 与四份契约。契约里必须含 `LocalGrantRepository` 桩**和假角色开关**。这两样不出，C 和 D 都动不了。 |
| 2 | **A** | 同期 | 拆出 `policy_metrics.dart` 交给 D。不拆的话 D 的数据处理证据在 `git blame` 里全是 A 的名字。 |
| 3 | **B** | 同期 | 先定 `grants` / `applications` 表结构交给 A 写进契约。C 的本地桩照此结构做，否则换实现要返工。Supabase 实例可以晚几天。 |
| 4 | **C** | 契约到手即开始 | 在本地桩上跑通三屏与资格判定，全程不碰 Supabase。 |
| 5 | **D** | 并行 | 政策目录远端化 → 导出 → About 免责声明。零依赖。 |
| 6 | **B** | **8/31 前（硬期限）** | 交出已初始化的 client、建好的表与 RLS 策略。 |
| 7 | **C** | B 交付后 | 本地桩换 Supabase 实现，接口不变。 |
| 8 | **B** | 排练前 | 准备两个演示账号（普通用户 + 管理员）。审批闭环要跨账号才演得出来。 |

**全项目唯一的跨人依赖**：C 的资助模块需要 B 的身份与角色。靠第 1 步的本地桩（含假角色开关）解除阻塞——C 不会空等。

---

## 6. 已延后 / 可砍

- **页内切换 year·sector**（原 TODO 2）：零网络、零数据处理，且要改 `AppState` 加三个结果页，与 B / C / D 正在接管的页面冲突。**延后到 9/5 之后；若时间紧，直接砍。** 归 A，不用于任何人的工作量证据。
- **资助管理端的压缩预案**：最坏情况砍成一屏（发布与审批合并成一个列表页）。这是 B 唯一可压缩的部分。

---

## 7. 导师要求的覆盖检查

| 成员 | 网络调用（真 HTTP） | 数据处理（真算法） | 被谁卡住 |
|---|---|---|---|
| **A** | data.gov.my 全量 GET<br>`api_client.dart` | 两行 join + HHI 集中度<br>`gdp_repository` · `metrics` | 无 |
| **B** | Auth + `profiles` 读写 + 资助发布与审批<br>`supabase_user_repository` · `grant_admin_repository` | 收藏合并 + 角色与 RLS 策略 | 无 |
| **C** | `grants` select + `applications` insert / select<br>`grant_repository.dart` | 资格匹配与不符原因说明 | B 的 Supabase 与角色（有本地桩兜底，不真卡） |
| **D** | 政策目录远端 GET + 版本回退<br>`policy_source.dart` | 政策前后窗口增速 + 导出重塑<br>`policy_metrics` · `export/` | A 的 client 模板（本周内给出） |

四人都落在**真正发出 HTTP 请求**的那一栏。

---

## 8. 期末演示（Week 13–14）

每人约 10 分钟，讲自己的模块。建议主线：

- **A** — 数据从哪来、怎么被清成能算的东西（两行 join、null、Supra），HHI 为什么是这么算的，筛选闸门如何保证页面永远收到合法请求。
- **B** — 身份怎么建立，权限怎么在服务端而不是 UI 上被挡住（RLS），一条资助从发布到批准的完整链路。
- **C** — 从一张饼图钻到一个部门，如何判断哪些资助适用、哪些不适用及原因，申请怎么提交、状态怎么流转。
- **D** — 一条政策生效前后发生了什么（并强调这是关联不是因果），窗口不足时如何诚实降级，分析结果如何导出。

Week 13 集体排练一次，含**双账号的资助审批演练**——这件事不要留到演示当天。
