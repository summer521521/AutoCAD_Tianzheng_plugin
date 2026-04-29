---
name: autocad-tianzheng-hvac
description: Use when controlling AutoCAD 2025 with Tianzheng HVAC T30 through the autocad_tianzheng MCP server, including connecting the THvac30V1 profile, reading or creating DWG engineering files, scanning layers/entities/blocks/text into SQLite/JSON/XLSX, running Tianzheng HVAC commands, loading Tianzheng ARX modules, or diagnosing Tangent path issues.
---

# AutoCAD + 天正暖通 HVAC

## 适用范围

用这个 skill 处理 AutoCAD 2025 + 天正暖通 T30V1 的连接、读图、建图、保存、导出和排障。默认 MCP server 是 `autocad_tianzheng`。机器相关路径从环境变量读取：

- AutoCAD: `AUTOCAD_EXE`
- 天正暖通根目录: `TIANZHENG_ROOT`
- 天正 profile: `THvac30V1`
- COM 自动化 profile: `CodexAutomation`
- MCP 工程: `AUTOCAD_TIANZHENG_MCP_ROOT`
- Python 解释器: `AUTOCAD_TIANZHENG_PYTHON`，未设置时默认使用 MCP 工程下的 `.venv\Scripts\python.exe`
- 默认输出: 优先放在 MCP 工程外的用户指定工作目录；不要写入插件仓库
- 注册表修复脚本: 从本机 AutoCAD/Tianzheng MCP 工程或独立运维脚本目录中选择，不随插件仓库发布

## 标准连接流程

1. 先连接指定 CAD 类型，不要依赖自动探测。当前稳定做法是 COM 通过 `CodexAutomation` 启动干净 AutoCAD；不要在连接阶段写入天正 `SupportPath/TRUSTEDPATHS`，也不要自动加载天正 ARX。

```json
[{"action":"connect","cad_type":"tianzheng_hvac"}]
```

把上面的 JSON 字符串传给 `manage_session`。

2. 连接后立刻探测天正状态：

```json
[{"action":"probe"}]
```

把上面的 JSON 字符串传给 `manage_tianzheng`。重点看 `current_profile`、`tangent_root_exists`、`missing_paths`、`support_path`、`trusted_paths` 和三个 ARX 文件是否存在。稳定连接时 `current_profile` 应是 `CodexAutomation`。

3. 做天正命令前再显式加载暖通 ARX：

```json
[{"action":"load_arx"}]
```

默认加载 `Tch_HvacCmd.arx`、`Tch_PipeBase.arx`、`tch_pipewire.arx`。如果加载后 AutoCAD 弹出错误中断或崩溃，优先回退到只读图、建基础实体、扫描索引的工作流；不要把 `auto_load_arx` 改成默认开启。

## 读图与索引

读取工程图时先用普通 CAD 工具查询图层、块、实体，再用天正索引补充可检索数据。扫描 ModelSpace 到 SQLite：

```json
[{
  "action":"scan_index",
  "db_path":"<output-root>\\index\\autocad_tianzheng_index.sqlite",
  "json_path":"<output-root>\\index\\autocad_tianzheng_index.json",
  "xlsx_path":"<output-root>\\index\\autocad_tianzheng_index.xlsx",
  "clear_drawing":true
}]
```

索引内容包括图纸路径、实体 handle、对象类型、图层、颜色、线型、文字、块名/名称、坐标 JSON 和 XData/扩展数据。需要追溯对象时优先用 handle。

## 建图与保存

新建图纸先调用 `manage_files` 的 `new`，再用 `draw_entities` 画基础实体和文字。保存用绝对路径：

```text
save|<output-root>\drawings\smoke_autocad_tianzheng.dwg
```

复杂工程文件优先分层创建：轴网/墙体/风管/水管/设备/标注/文字分别放到清晰图层；块名、图层名、文字标注要可检索。不要在没有用户确认的情况下覆盖已有 DWG。

## 执行天正命令

通过 `manage_tianzheng` 的 `run_command` 执行低风险命令：

```json
[{"action":"run_command","command":"_ABOUT","timeout_sec":10}]
```

如果返回 `Command is still active or waiting for user input`，说明命令大概率需要人工点选、输入或对话框确认。不要继续盲目发送回车或坐标，先报告需要人工交互。

## 排障顺序

1. `manage_session` 连接失败：确认 AutoCAD 和天正路径存在，再看 `AutoCAD.Application.25` COM ProgID；COM 的 `LocalServer32` 应包含 `/Automation /p CodexAutomation`。
2. `probe` 显示 `tangent_root_exists=false` 或 ARX 文件不存在：确认 `TIANZHENG_ROOT` 指向正确的天正安装根目录；如需注册表修复，使用本机维护脚本并重启 AutoCAD 和 Codex。
3. `TRUSTEDPATHS` 或 `SupportPath` 不含天正 `SYS`、`SYS25x64`：这是稳定自动化模式的预期状态；只有调试天正命令时才手动加载 ARX，不要把这些路径写进 `CodexAutomation` profile。
4. ARX 加载失败：确认文件在 `TIANZHENG_ROOT` 下的对应 `SYS25x64` 目录，再用 `load_arx` 单独加载具体路径。
5. Codex 看不到 MCP 或 skill：重启 Codex，新的 `config.toml` 和 skill 只会在重启后加载。
