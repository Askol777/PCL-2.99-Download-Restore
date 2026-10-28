# PCL 2.99 下载功能恢复补丁（非官方）

本项目整理了两个针对 **Plain Craft Launcher（PCL）2.99.0.0** 特定构建的本地补丁，用于尝试恢复 Minecraft 下载与整合包下载、安装功能。

**本项目是独立制作的第三方修改工具，与 PCL 官方无隶属或授权关系。** PCL 由龙腾猫跃开发，感谢原作者及其贡献者；[PCL 官方下载入口](https://meloong.com/pcl)、[官方源代码仓库](https://github.com/Meloong-Git/PCL)以及[作者的赞助入口](https://meloong.com/afd/a/LTCat)。

## 选择补丁

| 目标版本 | 补丁包 | 原始 EXE 的 SHA-256 |
| --- | --- | --- |
| 正式版 2.99.0.0（413.50） | [正式版补丁文件](patches/PCL_2.99.0.0_413.50.zip) | `6b6e1260cb5a1d6a303855f1c60cab3d0bc1aebba7e40a964180188b271e7386` |
| 快照版 2.99.0.0（414.0） | [快照版补丁文件](patches/PCL_2.99.0.0_414.0.zip) | `5b64d6d540c376390470cea3ab99d47661e8bca81be2ba647ea83e7d2e9428fa` |

**只支持哈希完全一致的原始 EXE。** 同名或同版本号的其他构建、更新后的文件，以及此前已修改过但输出哈希不同的文件，均不能保证适用。项目不包含 PCL 的原版或修改后的完整 EXE；请自行通过合法渠道取得相应文件。

打开对应的补丁文件页面后，点击右上角 **Download raw file** 下载 ZIP。各 ZIP 包含 PowerShell 脚本、补丁清单、数据和版本专用教程。补丁包校验值见 [SHA256SUMS](SHA256SUMS)。也可查看 [正式版详细教程](docs/413.50.md) 或 [快照版详细教程](docs/414.0.md)。

## 使用教程

适用于 Windows 和 Windows PowerShell 5.1。命令中的相对路径指向解压后的补丁文件夹，无需填写固定的盘符或用户名。

1. 退出 PCL。将 PCL 程序文件夹复制一份，使用复制出的测试副本；保留原文件和游戏数据的备份。
2. 选择对应版本的 ZIP 并完整解压，确保 `Patch.ps1`、`manifest.json`、`payload.bin` 位于同一文件夹。
3. 在该补丁文件夹中打开 PowerShell。先执行预览，然后在弹出的窗口中选择测试副本的 `Plain Craft Launcher 2.exe`：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\Patch.ps1" -Mode Preview
   ```

   显示 `MATCH` 才继续；`ALREADY PATCHED` 表示该文件已经是此包的已知输出，`UNSUPPORTED` 表示文件不匹配，不要继续应用。
4. 确认 PCL 已关闭，再执行应用命令，并选择刚刚通过预览的同一个 EXE：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\Patch.ps1" -Mode Apply
   ```

   显示 `PATCH APPLIED` 后，脚本会在 EXE 旁创建 `Plain Craft Launcher 2.exe.pcl299-original.bak`。请保留该备份。若已经存在同名备份，脚本会拒绝覆盖。
5. 运行修改后的 PCL，在独立测试游戏目录中测试 Minecraft 和需要的整合包安装、启动。补丁写入 EXE，无需每次启动都重新执行；更新或覆盖 EXE 后可能失效。

若需还原，先关闭 PCL，在补丁文件夹中执行下列命令并选择已修改的 EXE。脚本要求目标文件和自动备份的哈希均匹配，且会保留备份：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\Patch.ps1" -Mode Restore
```

预览中如果出现 `UNSUPPORTED`，请重新检查版本及文件来源，**不要通过强行修改校验信息来继续**。如果无法打开文件选择窗口，脚本会提示手动输入 EXE 的路径。

## 原文件来源与适用范围

本项目针对提交者此前提供的两个原始 EXE 制作：据提交者说明，正式版从 PCL 作者主页取得，快照版为其赞助使用的构建。上方链接是官方入口，但**未确认官方目前是否仍提供这两个历史构建**；文件是否适用以完整 SHA-256 为准。项目不代为提供快照版获取资格。

上述下载与赞助入口分别来自 [PCL 官方 README](https://github.com/Meloong-Git/PCL/blob/main/README.md) 和 [官方赞助配置](https://github.com/Meloong-Git/PCL/blob/main/.github/FUNDING.yml)。链接及其跳转可能随时间变化，请以官方仓库当前公布的地址为准。文件哈希用于确认补丁是否适配，不能单凭哈希认定文件没有恶意代码。

补丁通过修改用户选择的 EXE 及附加数据生效，可能使原有数字签名失效，也可能触发安全软件警告。不要为此盲目关闭安全防护。使用者应自行确认软件使用权限、适用条款和本地法律。

## 验证情况

此前提交者的 Windows 测试及对话中记录：正式版完成了 NeoForge、Modrinth 整合包安装与游戏启动；快照版完成了 Modrinth、CurseForge 整合包安装，以及 OptiFine 安装和游戏启动。正式版 CurseForge 与各类本地整合包格式未在这些记录中逐一验证。

项目整理时，已对两个 ZIP 做完整性检查，并使用提交者提供的对应原始 EXE 校验输入哈希、清单操作、载荷哈希和重建后文件哈希。**本次整理没有在 Windows 上重新执行最终打包脚本或做新的联网安装测试。** 其他系统、网络环境、镜像、版本与整合包的兼容性无法保证。

## 许可与免责声明

PCL 的版权、名称和相关内容属于各自权利人。项目中含有针对 PCL 的差分数据，不能仅因没有完整 EXE 就推定其获得再分发许可。PCL 项目许可和使用指南见 [官方 LICENCE](https://github.com/Meloong-Git/PCL/blob/main/LICENCE) 和本项目保存的 [上游文件](UPSTREAM-LICENCE)；本项目对这些补丁的公开分发授权尚未获得确认。项目自行制作的可许可部分与第三方材料范围见 [LICENSE](LICENSE) 和 [NOTICE.md](NOTICE.md)。

本工具按现状提供，不保证与所有构建兼容，也不保证数据安全或持续维护。使用前请备份，使用和分发的风险由使用者根据适用法律自行评估。反馈请在本项目提出，勿将本项目问题作为 PCL 官方问题报告。
