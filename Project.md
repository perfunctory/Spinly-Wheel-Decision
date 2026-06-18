给你一份可以直接交付开发（Flutter / RN 都适用）级别的完整产品设计文档，包含：

页面结构（每个页面做什么）
页面跳转逻辑
数据结构（本地 JSON）
核心转盘算法（可直接实现）
动画与交互逻辑
广告位设计（适配 App Store 变现）
完全离线实现方案

项目名按你之前定的：

🎡 Lucky Wheel - Decision Maker（完整PRD）
1. 产品定位
核心定义

一个离线随机决策工具类 App：

帮用户快速做选择
无服务器
无账号
无登录
完全本地运行
核心使用场景
今天吃什么 🍔
去哪里玩 📍
做什么决定 🤔
聚会小游戏 🎉
随机抽选 🎲
2. 页面结构（非常关键）

整个 App 只有 4 个核心页面：

Splash Page（启动页）
        ↓
Home Page（主页/转盘）
        ↓
Edit Wheel Page（编辑选项）
        ↓
Result Page（结果页）
3. 页面详细设计
3.1 Splash Page（启动页）
功能
Logo展示
简单动画
1.5~2秒后自动进入主页
UI
🎡 Lucky Wheel

Loading...
跳转逻辑
Timer(2s) → HomePage
3.2 Home Page（核心页面）
作用

👉 用户“主要操作页面”

UI结构
顶部
Lucky Wheel
[Settings ⚙️]
中间（核心）

👉 转盘组件

🎡 Wheel Canvas（自定义绘制）
底部输入区域
Pizza
Burger
Sushi
KFC

[+ Add Option]
按钮区
[SPIN NOW]
[EDIT WHEEL]
功能逻辑
1. SPIN NOW

触发转盘动画

2. EDIT WHEEL

跳转：

EditWheelPage
3. Settings

可选：

音效开关
震动开关
主题色
3.3 Edit Wheel Page（编辑页面）
作用

👉 用户自定义选项

UI
输入框
Add Option:
[__________] + Add
列表
Pizza   ❌
Burger  ❌
Sushi   ❌
KFC     ❌
功能
添加
点击 Add → push到 list
删除
点击 ❌ → remove
限制
最少 2 个
最多 20 个
保存
localStorage / SharedPreferences
返回
Back → HomePage (刷新 wheel)
3.4 Result Page（结果页）
作用

展示结果

UI
🎉 RESULT

🍔 Burger

[SPIN AGAIN]
[BACK HOME]
功能
Spin Again
HomePage → 自动触发 spin
Back Home
HomePage
4. 核心转盘实现（重点）
4.1 数据结构（本地 JSON）
[
  "Pizza",
  "Burger",
  "Sushi",
  "KFC"
]
4.2 转盘分段计算
final int count = options.length;
final double anglePerSlice = 360 / count;
4.3 绘制逻辑（Canvas）

每个扇形：

startAngle = index * anglePerSlice
sweepAngle = anglePerSlice
4.4 随机结果算法（核心）
int getRandomIndex(int length) {
  return Random().nextInt(length);
}
4.5 动画旋转逻辑（关键）
目标：让转盘“看起来很真实”
double baseRotations = 5 * 360; // 基础旋转5圈
double targetAngle = randomIndex * anglePerSlice;

double finalAngle = baseRotations + targetAngle;
动画控制
AnimationController(duration: 3s)
曲线（非常关键）
Curves.easeOutCubic
4.6 指针逻辑

固定顶部：

▲ pointer

计算落点：

final selectedIndex = (totalAngle % 360) / anglePerSlice;
5. 页面跳转逻辑
Splash
  ↓
HomePage
  ↓        ↘
EditPage   ResultPage
  ↓           ↑
HomePage ← Spin Again
6. 广告系统设计（适配变现）
Home Page
Banner（底部）
每次 Spin
Interstitial Ad

触发点：

点击 SPIN NOW 后 loading 0.5s
Result Page
Reward Video（可选）

例如：

Watch ad → Spin again bonus
7. 本地存储设计
class WheelData {
  List<String> options;
}

存储：

SharedPreferences
Hive（推荐）
8. 扩展玩法（提升留存）
8.1 模板系统（非常重要）

内置：

🍔 What to Eat
📍 Where to Go
🎉 Party Game
🤔 Yes / No
8.2 一键切换模板
Home → Template Drawer
8.3 多转盘模式（进阶）
单人模式
小组模式（Team Picker）
9. App Store安全设计（避免被判赌博）

必须保证：

❌ 不出现：

casino
jackpot
betting
coins
reward money

✔ 正确定位：

Decision Maker
Random Picker
Party Game Tool
10. MVP开发拆解（你可以直接照做）
Day 1
HomePage UI
Wheel Canvas
基础转盘旋转
Day 2
Edit Page
本地存储
Day 3
Result Page
动画优化
广告接入
Day 4（优化）
模板系统
UI美化
App Store提交
11. 最关键总结

这个 App 的本质不是“游戏”，而是：

🎯 一个高频决策工具 + 娱乐工具

成功关键在于：

转盘动画要“爽”
UI要“轻”
操作要“一键”
选项模板要“丰富”







版本3.0 PRD文档：

Lucky Wheel — v3.0 FINAL PRD
Random Experience Engine（状态驱动多玩法系统）
1. 产品最终定义
1.1 核心定位（最终形态）

一个完全离线运行的：

🎯 状态驱动的随机体验与决策系统（Random Experience Engine）

不是单一转盘工具，而是：

多种随机玩法系统（Wheel / Box / Duel / Chain）
统一状态驱动（Mood + Energy + Chaos）
可持续体验循环（Experience Loop）
1.2 产品本质

👉 用户不是“在用工具做选择”，而是在：

“与一个会变化的随机系统互动”

2. 系统整体架构（最终版）
2.1 三层架构
[ Interaction Layer ]
Wheel / Duel / Box / Chain

        ↓

[ Engine Layer ]
Random Engine + State Engine + Mode Engine

        ↓

[ Experience Layer ]
Mood / Narrative / Suggestion / Progression
2.2 核心设计原则（必须遵守）
所有玩法共享 State
所有结果影响 State
State 决定下一次体验
所有模式可串联
3. 全局状态系统（核心大脑）
3.1 Game State（统一状态模型）
{
  "mood": "neutral",
  "energy": 70,
  "luck": 50,
  "chaos": 20,
  "streak": 0,
  "history": [],
  "lastMode": "wheel"
}
3.2 状态作用机制（核心逻辑）
状态	影响
energy	决定“行动 vs 休息”概率
luck	高价值结果概率
chaos	随机程度
mood	行为风格
streak	连续体验强化
3.3 状态更新规则
Play → Result → State Mutation → Next Mode Bias
4. 玩法系统（统一整合版）
🎡 4.1 Wheel Engine 3.0（状态转盘）
4.1.1 核心升级

传统转盘 → 状态驱动转盘

4.1.2 机制
Base probability
+ mood bias
+ energy bias
+ chaos modifier
4.1.3 示例
energy low → rest类概率 ↑
luck high → premium选项 ↑
chaos high → 完全随机
4.1.4 视觉反馈
转盘颜色随 mood 变化
指针震动
结果带解释：

“Burger (You are low energy)”

🎭 4.2 Fate Chain 3.0（命运链系统）
4.2.1 核心定义

连续决策 + 状态演化 + 规则变化

4.2.2 流程
Spin → Result
     ↓
State Mutation
     ↓
Rule Evolution
     ↓
Next Spin Context Changes
4.2.3 示例

1️⃣ Pizza
→ energy +10

2️⃣ 系统变化
→ “high calorie bias active”

3️⃣ 下一次
→ Burger / Fast food概率↑

4.2.4 特点
每一步都“改变世界”
类似轻量 roguelike
📦 4.3 Mystery Box 3.0（动态盲盒系统）
4.3.1 核心升级

盲盒 = 状态生成内容

4.3.2 双层揭晓机制
Open Box
 ↓
Reveal Category
 ↓
Reveal Result
4.3.3 状态映射
{
  "lazy": ["Sleep", "Movie", "Rest"],
  "active": ["Workout", "Walk"],
  "chaos": ["Dare", "Random Call", "Delete App"]
}
4.3.4 特点
先惊喜类别
再惊喜结果
⚔️ 4.4 Duel Engine 3.0（对抗系统）
4.4.1 核心升级

不是 50/50，而是：

状态影响胜率 + 偏好系统

4.4.2 机制
A vs B
 ↓
State Bias
 ↓
Probability Shift
 ↓
Result
4.4.3 示例
tired → Sleep win ↑
energetic → Work win ↑
4.4.4 体验

👉 用户感觉“系统在理解我”

🧠 4.5 Mood Drift System（情绪漂移）
4.5.1 Mood 分类
["lazy", "focused", "chaotic", "lucky", "neutral"]
4.5.2 变化规则
Each action → mood shift
4.5.3 影响范围
Wheel bias
Box content
Duel probability
Chain evolution
🔁 5. Experience Loop（核心循环系统）
5.1 标准循环
Choose Mode
 ↓
Interact
 ↓
Result
 ↓
State Update
 ↓
Mood Change
 ↓
System Suggestion
 ↓
Next Action
5.2 自动续玩机制（关键）

系统自动引导：

吃太多 → Workout mode
太无聊 → Mystery Box
太随机 → Duel stabilize
🎯 6. Auto Suggest System（智能推荐）
6.1 机制
Result + State → Next Mode Suggestion
6.2 示例
当前状态	推荐
lazy	Workout Wheel
chaotic	Duel Mode
balanced	Chain Mode
🎮 7. Mode 统一入口（最终UI）
7.1 Home Dashboard
🎡 System Mood: Lazy

[Continue Experience]

[Select Mode]

[History]
7.2 Mode List
Wheel Engine
Fate Chain
Mystery Box
Duel Picker
🧱 8. 数据结构（最终版）
{
  "state": {
    "mood": "neutral",
    "energy": 70,
    "luck": 45,
    "chaos": 20
  },
  "history": [
    {
      "mode": "wheel",
      "result": "Pizza"
    },
    {
      "mode": "box",
      "result": "Movie"
    }
  ],
  "suggestion": "Workout Wheel"
}
🎨 9. UI体验原则（最终设计规则）
9.1 三大原则
状态可视化（Mood always visible）
结果必须“有解释”
每次操作都有下一步建议
9.2 结果页结构
RESULT

Burger 🍔

Why:
→ Low Energy State

Next Suggested:
→ Workout Mode
🚀 10. 产品最终形态总结

v1：

单转盘工具

v2：

多玩法随机系统

v3（最终）：

🎡 状态驱动的随机体验引擎（Experience Engine）

💡 最关键设计突破点（非常重要）

这个版本的核心不是玩法多，而是：

① State 统一一切行为
② Mood 让系统“像活的”
③ Suggestion 让用户“自动继续玩”
④ Chain 让体验“不断演化”