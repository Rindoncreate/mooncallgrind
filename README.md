# MoonCallgrind

MoonBit 的 Callgrind 文本格式库。把压缩文件解析为类型化记录，保留调用点、
目标位置、直接递归、分段边界和 UInt64 计数，由使用者决定怎样聚合。

`Rindoncreate/mooncallgrind@0.1.0` 已发布到 [Mooncakes](https://mooncakes.io/docs/Rindoncreate/mooncallgrind@0.1.0)，
并通过独立项目的 JS/native 注册表安装验证。尚未正式申报，没有获得赛事初审认可。
AI 辅助了实现、测试和文档；参赛者需理解并对代码负责，正式人工申报另行完成。

## 用途

同一个 `main -> work` 可以来自第 10、20 行，目标位置也可能不同。先合并函数边
会失去这些差异。本库保留成本行与对应 `calls=` 记录，供 MoonBit 程序直接处理：

- 在性能检查中区分同一 caller/callee 的不同调用点。
- 在 Wasm 或 JS 工具中导入现有 Callgrind 文件，读取完整调用记录。
- 依据不同分段的事件表做自定义汇总，或先规范化再交给其他工具。

不包含采样器、GUI、符号解析或 pprof 转换。`totals`、`diff` 是消费示例；
本库不将指令计数解释为耗时，不推导递归 inclusive 总成本。

## 运行

需要官方 MoonBit 工具链；CLI 另外需要 Node.js 22+。

```sh
git clone https://github.com/Rindoncreate/mooncallgrind.git
cd mooncallgrind
moon check --target js --deny-warn
moon build --target js --deny-warn
moon test --target js --deny-warn
moon run examples/sites --target js
node bin/mooncallgrind.mjs inspect examples/two-sites.callgrind
node bin/mooncallgrind.mjs totals examples/two-sites.callgrind Ir
node bin/mooncallgrind.mjs normalize examples/two-sites.callgrind normalized.callgrind
node bin/mooncallgrind.mjs diff examples/two-sites.callgrind normalized.callgrind Ir
```

规范化输出文件必须不存在，避免覆盖。CLI 严格解码 UTF-8；JSON 中的计数、位置和
调用次数全部是十进制字符串，避免 JavaScript Number 截断。

## 从 Mooncakes 安装

在使用者的 `moon.mod` 添加固定版本依赖：

```moonbit
import {
  "Rindoncreate/mooncallgrind@0.1.0",
}
```

在使用者的 `moon.pkg` 添加包导入：

```moonbit
import { "Rindoncreate/mooncallgrind" @cg }
```

运行 `moon update`、`moon check --target js --deny-warn`。完整独立验证可运行
`python3 tools/check_registry.py`；该脚本从注册表获取固定版本，无源码 workspace 回退。
发布来源、原始 ZIP 校验和及验证记录见 [0.1.0 发布记录](docs/releases/0.1.0.md)。

## MoonBit API

在包的 `moon.pkg` 中导入 `"Rindoncreate/mooncallgrind" @cg`：

```moonbit
let p = @cg.parse("events: Ir\nfn=main\ncfn=work\ncalls=2 70\n10 30\n")
for record in p.records {
  match record.kind {
    SelfCost => ()
    Call(count, target, positions) =>
      println("\{record.positions[0]} -> \{target.function_name}:\{positions[0]}, calls=\{count}")
  }
}
```

片段应位于能处理 `@cg.ParseError` 的函数中。完整示例见
[examples/sites](examples/sites/main.mbt)，公共签名见 [pkg.generated.mbti](pkg.generated.mbti)。

| 接口 | 行为 |
| --- | --- |
| `parse(text)` | 返回 `Profile`；失败时抛出带行号的 `Syntax`、`Unsupported` 或 `Resource` |
| `normalize(text)` | 规范化为绝对位置和显式名称 ID，保留支持的记录与头字段 |
| `profile.self_totals(event)` | 按每段事件名定位列，合并函数自身成本，排除调用边成本 |
| `diff(before, after, event)` | 返回精确 before/after 值，不推断回归原因 |

格式解释、数值检查、规范化和分析均为 MoonBit；Node 仅处理文件和输出。
库不需要 Python、Rust 或 Valgrind 进程；Valgrind 仅用于独立兼容性测试。

## 验证、范围与来源

- [格式与错误契约](docs/format-profile.md)
- [API 数据语义](docs/api.md)
- [测试和复现](docs/verification.md)
- [生态差异和来源](docs/ecosystem.md)
- [赛事交付状态](docs/competition.md)
- [源码发布包与发布后验证](docs/release.md)

源码 MIT；真实样本 Apache-2.0，归属和原始许可证见 [fixtures/NOTICE.md](fixtures/NOTICE.md)。
AI 辅助开发。通用 CI 导出和源码包消费者脚手架改编自作者此前的 moondhcp4，
没有复用 DHCP 协议实现。
