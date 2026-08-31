# 新功能实施小计划

> 每个新功能一张卡：目标 / 落哪些文件 / 步骤 / 验收 / 已知坑。
> 归属见 [`ownership.md`](ownership.md)，契约与设计理由见 [`plan_v2.md`](plan_v2.md) §5–§6。
> 本文只回答「这件事具体怎么落地」，不重复归属和契约原文。

---

## F1 · 实时 API 通道 `api_client.dart` ｜ A

**目标**：把 `assets/gdp_snapshot.json` 从唯一数据源降级为回退缓存，实时数据走 data.gov.my。

**文件**：新增 `lib/data/api_client.dart`；改 `lib/data/gdp_repository.dart`（加载路径分支）。

**步骤**
1. `GET https://api.data.gov.my/data-catalogue?id=gdp_state_real_supply`，解析成现有 `GdpRecord` 列表，字段映射复用 `sector_mapping.dart`。
2. `GdpRepository.load()` 加 `{bool useRemote = true}`：远端成功 → 用远端并写入本地缓存；超时/失败/解析异常 → 退回 asset，置一个 `isStale` 标志。
3. About 页显示数据来源与获取时间（远端 / 本地基准）。
4. 超时设 8 秒，失败不抛给 UI。

**验收**：飞行模式下应用照常全功能运行，About 页显示「本地基准数据」。

**坑**：远端行数与 asset 不一致会让现有测试（`data_counts_test`）失败——测试固定走 `useRemote: false`。

---

## F2 · 四份契约 + 本地桩 ｜ A（阻塞 C 和 D，最先做）

**目标**：C 和 D 不等任何人就能开工。

**文件**：`lib/models/grant.dart`（`Grant` / `GrantApplication` / `ApplicationStatus` / `UserRole`）、`lib/data/grant_repository.dart`（抽象 + `LocalGrantRepository` 桩）、`lib/data/grant_admin_repository.dart`（抽象）。

**步骤**
1. 按 plan_v2 §6 落三个抽象接口 + 模型类，字段与 B 定的 `grants` / `applications` 表结构一一对应。
2. `LocalGrantRepository`：内存 + shared_preferences，附 6~8 条种子资助（真实计划名 + `sourceUrl`，criteria 注明自定）。
3. 桩里加**假角色开关** `setFakeRole(UserRole)`，C 无需登录即可切换用户/管理员视角。
4. 另出一页 `docs/` 备注：政策目录远端 JSON 格式 + 导出列定义（给 D）。

**验收**：C 拉下代码即可跑通「浏览 → 申请 → 看状态」，全程不连网。

**坑**：表结构必须先跟 B 对齐再冻结，否则换 Supabase 实现时 C 要返工。

---

## F3 · Supabase 基建（表 · RLS · Auth）｜ B ｜ 硬期限 8/31

**目标**：一个可用的云端后端，权限在服务端挡住。

**产出**：Supabase 项目 + 4 张表 + RLS 策略 + 初始化好的 client（`main.dart` 由 A 接线）。

**步骤**
1. 建表：`profiles(id, nickname, role)` · `favorites(id, user_id, payload jsonb, created_at)` · `grants(...)` · `applications(id, grant_id, user_id, status, ...)`。
2. 开 Auth（email + password 即可，不做第三方登录）；注册触发器自动建 `profiles` 行，`role` 默认 `user`。
3. RLS：
   - `favorites` / `applications`：`user_id = auth.uid()` 才可读写。
   - `grants`：所有登录用户可 select；insert/update 仅 `role = 'admin'`。
   - `applications` 的 status 更新：仅 admin。
4. 管理员账号手动在表里把 `role` 改成 `admin`（不做「注册成管理员」入口）。
5. 用 Supabase 控制台的 SQL 编辑器直接跑，把建表与策略 SQL 存进 `docs/supabase_schema.sql` 当交付证据。

**验收**：用普通账号的 token 直接调 `grants` insert 必须被拒——这一条要在演示里当场演。

**坑**：RLS 忘开就等于全公开；每张表建完立刻 `enable row level security`。

---

## F4 · 云端档案与收藏 + 认证三屏 ｜ B

**文件**：新增 `lib/data/supabase_user_repository.dart`、`lib/pages/auth/{login,register,profile}_page.dart`。

**步骤**
1. 实现 `UserRepository` 全部方法（含新增的 `userId` / `role`），接口一字不改。
2. 三屏：登录（邮箱密码 + 错误提示）、注册、档案（昵称、角色标签、登出、收藏数）。
3. **收藏合并**：登录时把本地 shared_preferences 里的收藏推上云端，按 `SavedAnalysis.id` 去重，冲突取时间戳新的。
4. 未登录仍可用整个分析功能（走 `LocalUserRepository`），登录只是升级。

**验收**：离线用了几次、收藏了 3 条，登录后云端能看到这 3 条且不重复。

**坑**：合并只做一次，做完打个 `merged` 标记，否则每次登录重复推。

---

## F5 · 资助管理端两屏 ｜ B

**文件**：`lib/data/grant_admin_repository.dart` 实现 + `lib/pages/grants_admin/{publish,pending}_page.dart`。

**步骤**
1. 发布页：表单（名称、机构、州、部门、金额上限、截止日、`sourceUrl`、criteria）→ `publish()`。
2. 待审批页：`pending()` 列表 → 点开看申请详情 → 通过 / 拒绝 → `decide()`。
3. 入口只在 `role == admin` 时出现在档案页；但**权限由 RLS 保证**，藏按钮只是体验。

**压缩预案**：时间紧则合并成一屏（上方发布表单折叠、下方待审列表）。这是 B 唯一可砍的部分。

**验收**：双账号演练——管理员发布 → 用户看到并申请 → 管理员批准 → 用户端状态变 approved。

---

## F6 · 资助用户端 ｜ C

**文件**：`lib/pages/grants/{browse,detail,my_applications}_page.dart` + `grant_repository.dart` 的 Supabase 实现。

**步骤**
1. 浏览页：`available(state:, sector:)` 列表，顶部显示当前分析上下文（州 · 部门），可清除筛选看全部。
2. 详情页：资助信息 + **资格判定结果**——逐条 criteria 打勾或打叉，不符的写明原因（如「本资助限雪兰莪，当前分析为槟城」）。不符不禁用申请按钮，只提示。
3. 申请表单：只收项目名、州、部门、申请金额、简述。页面顶部固定一句「演示用途，非官方申请渠道」。
4. 我的申请页：`myApplications()`，三态 chip（pending / approved / rejected）。
5. **接点**：Sector Breakdown 钻取详情里加一张「适用资助 N 条」卡片 → 带 `(state, sector)` 跳浏览页。
6. 全程先在 `LocalGrantRepository` 桩上跑通；B 交付后只换实现类。

**验收**：从饼图钻到「雪兰莪·制造业」→ 卡片 → 浏览页已自动带上筛选。

**坑**：资格判定是本模块的「数据处理」证据，逻辑要写在仓库/服务层而不是 widget 里，否则不好讲。

---

## F7 · 拆出 `policy_metrics.dart` ｜ A 拆 → D 拥有

**目标**：让 D 的数据处理在 `git blame` 里是 D 的名字。

**步骤**：把 `metrics.dart` 里的 `growthAroundPolicy` / `PolicyGrowth` 移到新文件 `lib/data/policy_metrics.dart`，改 `policy_page.dart` 的 import。A 只做搬运，之后所有改动归 D。

**验收**：`flutter analyze` 0 issue，Policy Impact 页表现不变。

---

## F8 · 政策目录远端化 ｜ D

**目标**：给 D 一条真实 HTTP 调用。

**文件**：新增 `lib/data/policy_source.dart`；`assets/policy_catalogue.json` 保留为回退。

**步骤**
1. 把政策目录 JSON 托管到一个可公开 GET 的地址（GitHub raw 即可），带 `version` 字段。
2. `PolicySource.load()`：GET 远端 → 比对 `version` 与本地 asset → 远端更新则用远端并缓存，否则用 asset；失败静默回退。
3. Policy Impact 页顶部标一行「政策目录 v3 · 远端 / 本地」。
4. 非对称窗口逻辑（LSS 前 1 后 3、NSS 后窗口不足降级为只画标注线）落在 `policy_metrics.dart`。

**验收**：改远端 JSON 的 version 并加一条政策，重启应用能看到新政策；断网则回到本地目录。

**坑**：GitHub raw 有缓存延迟，演示前先刷新确认。

---

## F9 · 导出 CSV / PDF ｜ D

**文件**：新增 `lib/export/`（`csv_exporter.dart` · `pdf_exporter.dart` · `share.dart`）。

**步骤**
1. 把当前分析结果集重塑成扁平表：`year, state, sector, value_rm_mil, yoy_pct, share_pct`（列定义由 A 的契约文档给定，四人一致）。
2. CSV：手写拼接即可，注意逗号与引号转义、UTF-8 BOM（Excel 中文不乱码）。
3. PDF：`pdf` + `printing` 包，一页 = 标题 + 参数摘要 + 表格 + 数据来源与免责声明。
4. 用 `share_plus` 唤起系统分享；文件写到临时目录。
5. 入口：各结果页右上角导出按钮（图标与位置照 `ui_spec.md`）。

**验收**：真机导出 CSV 用 WPS 打开中文正常；PDF 页脚有数据来源。

**坑**：分享插件不算网络调用，D 的网络证据只在 F8——F8 不能砍。

---

## 依赖与顺序一眼图

```
F2 契约桩（A）──┬──> F6 资助用户端（C）──> 换实现依赖 F3
                └──> （给 D 网络模板）
F1 实时 API（A） 独立
F3 Supabase（B）──┬──> F4 认证三屏（B）
                  └──> F5 管理端（B）──> 双账号演练依赖 F6
F7 拆分（A→D）──> F8 政策远端（D）──> F9 导出（D）   三件均不卡他人
```

唯一的真跨人依赖是 F6 → F3，已被 F2 的本地桩解除阻塞。
