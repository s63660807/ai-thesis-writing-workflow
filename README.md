# 论文写作流程分享包

这个文件夹用于把一套已经验证过的 AI 辅助论文写作流程分享给其他人。别人下载整个文件夹后，可以把 `目标文件-论文写作前期准备.md` 直接作为第一次指令交给 Codex、Workbuddy 或其他支持本地文件读取的智能体，让智能体完成前期准备工作。

## 文件说明

- `论文写作流程.md`：论文写作主流程规范。
- `论文信息采集表.md`：用户填写的论文基础信息表。
- `目标文件-论文写作前期准备.md`：直接交给智能体执行的通用目标指令。
- `install-skills.ps1`：Codex 用户可选使用的安装脚本，用于把本文件夹内的 skills 安装到本机 Codex skills 目录。
- `环境准备说明.md`：说明需要哪些外部软件，以及为什么不把安装包本体放进分享包。
- `check-environment.ps1`：只检查 Python、Node.js、Git、Pandoc、浏览器和 bundled skills，不安装软件。
- `install-dependencies-winget.ps1`：Windows 用户可选使用的 winget 自动安装脚本。
- `skills/`：已导入的本地 skill 文件，包含研究写作、PDF、CNKI、Google Scholar 等能力。

## 通用使用方式

1. 下载或复制整个文件夹。
2. 打开 Codex、Workbuddy 或其他支持本地文件操作的智能体。
3. 让智能体以本文件夹为当前工作目录。
4. 把 `目标文件-论文写作前期准备.md` 的全文作为指令发给智能体。
5. 按智能体提示完成环境检查、skill 加载或安装、信息采集表补充和论文前期准备。

可以先运行环境检查：

```powershell
powershell -ExecutionPolicy Bypass -File .\check-environment.ps1
```

## 不同智能体的处理方式

- Codex：可以直接运行 `install-skills.ps1`，把 `skills/` 同步到本机 Codex skills 目录。
- Workbuddy 或其他智能体：优先使用软件自带的“导入知识库”“导入技能”“项目资料”“本地文件夹读取”等能力，让智能体读取本文件夹和 `skills/` 下的 `SKILL.md` 文件。
- 如果当前软件没有独立的 skill 安装机制，就把 `skills/` 当作本地指令库使用：需要写作、检索、PDF 等能力时，让智能体先读取对应 skill 的 `SKILL.md`，再执行任务。

Codex 用户可选手动安装 skills：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-skills.ps1
```

Windows 用户如果确认要自动安装基础依赖，可以使用：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-dependencies-winget.ps1
```

## 已打包的 skills

- `research-writing-skill`
- `pdf`
- `cnki-advanced-search`
- `cnki-download`
- `cnki-export`
- `cnki-journal-index`
- `cnki-journal-search`
- `cnki-journal-toc`
- `cnki-navigate-pages`
- `cnki-paper-detail`
- `cnki-parse-results`
- `cnki-search`
- `gs-advanced-search`
- `gs-cited-by`
- `gs-export`
- `gs-fulltext`
- `gs-navigate-pages`
- `gs-search`

## 注意事项

- Skill 安装完成不等于外部数据库一定可用。CNKI、Google Scholar、Zotero、学校图书馆和付费数据库可能需要登录、权限、验证码或用户手动下载。
- 英文文献可补充使用学术搜索网站 [https://xs.xasa.top/](https://xs.xasa.top/)。如果当前智能体支持脚本、MCP 或浏览器自动化，可以用它辅助查找英文文献，但文献信息和全文仍需进入校验流程。
- 中文文献优先走 CNKI MCP/浏览器自动化批量检索、排序、下载和读取；筛选时优先高被引、高下载和权威来源论文，如 SCI、SSCI、CSCD、CSSCI、北大核心、EI、中科院分区表、JCR分区表等，不能核验的来源级别保持待核验。
- 中文 Markdown、CSV、PDF 抽取内容建议统一按 UTF-8 处理。
- 论文写作中不要编造文献、数据、访谈、政策文件和页码；无法确认的信息应保留为待核验。
- `skills/` 中的技能文件来自本机已安装的技能包；公开分享或二次分发时，请保留各技能目录自带的许可证和来源说明。
