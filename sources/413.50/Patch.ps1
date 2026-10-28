#requires -Version 5.1
# PCL 2.99.0.0 exact-build local patcher. No modified launcher EXE is distributed.
# 在弹出的文件窗口中选择要处理的 Plain Craft Launcher 2.exe。
[CmdletBinding()]
param(
    [ValidateSet('Preview','Apply','Restore')]
    [string]$Mode = 'Preview',
    [string]$TargetPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SHA256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Get-HexBytes([string]$Hex) {
    if (($Hex.Length % 2) -ne 0) { throw 'Invalid manifest hex.' }
    $Result = New-Object byte[] ([int]($Hex.Length / 2))
    for ($i=0; $i -lt $Result.Length; $i++) {
        $Result[$i] = [Convert]::ToByte($Hex.Substring($i*2, 2), 16)
    }
    return ,$Result
}
function Select-PCLFile {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $Dialog = New-Object System.Windows.Forms.OpenFileDialog
        $Dialog.Title = '请选择需要处理的 Plain Craft Launcher 2.exe（建议选择测试副本）'
        $Dialog.Filter = 'Plain Craft Launcher 2.exe|Plain Craft Launcher 2.exe|EXE 文件 (*.exe)|*.exe'
        $Dialog.CheckFileExists = $true
        $Dialog.Multiselect = $false
        $Dialog.RestoreDirectory = $true
        try {
            if ($Dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                return $Dialog.FileName
            }
            throw '用户取消了文件选择；未修改任何文件。'
        }
        finally { $Dialog.Dispose() }
    }
    catch {
        if ($_.Exception.Message -like '*取消了文件选择*') { throw }
        Write-Warning '文件选择窗口不可用，请手动输入 EXE 的完整路径。'
        $PathText = Read-Host 'Plain Craft Launcher 2.exe 文件路径'
        if ([string]::IsNullOrWhiteSpace($PathText)) { throw '未选择文件；未作修改。' }
        return $PathText.Trim().Trim('"').Trim("'")
    }
}
function Check-Length([string]$Path, [long]$Length) {
    if ((Get-Item -LiteralPath $Path).Length -ne $Length) {
        throw 'EXE 大小不符合此补丁要求。'
    }
}

$ManifestFile = Join-Path $PSScriptRoot 'manifest.json'
$PayloadFile = Join-Path $PSScriptRoot 'payload.bin'
foreach ($File in @($ManifestFile, $PayloadFile)) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        throw ('补丁包不完整：' + $File)
    }
}
$Manifest = Get-Content -LiteralPath $ManifestFile -Encoding UTF8 -Raw | ConvertFrom-Json
$ExpectedOriginal = ([string]$Manifest.input_sha256).ToLowerInvariant()
$ExpectedPatched = ([string]$Manifest.output_sha256).ToLowerInvariant()
if ((Get-SHA256 $PayloadFile) -ne ([string]$Manifest.payload_sha256).ToLowerInvariant()) {
    throw '补丁数据的 SHA-256 校验失败；未修改任何文件。'
}
if ([string]::IsNullOrWhiteSpace($TargetPath)) { $TargetPath = Select-PCLFile }
$TargetPath = [IO.Path]::GetFullPath($TargetPath.Trim().Trim('"').Trim("'"))
if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
    throw '目标 EXE 文件不存在。'
}
$BackupFile = $TargetPath + '.pcl299-original.bak'
$Current = Get-SHA256 $TargetPath
Write-Host ('目标版本：' + [string]$Manifest.version_label)
Write-Host ('当前文件 SHA-256：' + $Current)

if ($Mode -eq 'Preview') {
    if ($Current -eq $ExpectedOriginal) {
        Check-Length $TargetPath ([long]$Manifest.input_length)
        Write-Host 'MATCH：文件完全匹配。可以使用 Apply。' -ForegroundColor Green
    }
    elseif ($Current -eq $ExpectedPatched) {
        Check-Length $TargetPath ([long]$Manifest.output_length)
        Write-Host 'ALREADY PATCHED：已经是最终修复版，无须重复打补丁。' -ForegroundColor Yellow
    }
    else {
        Write-Warning 'UNSUPPORTED：不是此补丁对应的原始 EXE；请核对版本和来源。'
    }
    return
}

if ($Mode -eq 'Restore') {
    if ($Current -eq $ExpectedOriginal) {
        Write-Host '当前已经是原始文件，无须恢复。'
        return
    }
    if ($Current -ne $ExpectedPatched) {
        throw '恢复已拒绝：目标不是本补丁的已知输出。'
    }
    if (-not (Test-Path -LiteralPath $BackupFile -PathType Leaf)) {
        throw '恢复已拒绝：没有找到此工具生成的原版备份文件。'
    }
    Check-Length $BackupFile ([long]$Manifest.input_length)
    if ((Get-SHA256 $BackupFile) -ne $ExpectedOriginal) {
        throw '恢复已拒绝：备份的 SHA-256 不符。'
    }
    $Temp = $TargetPath + '.restore-' + [Guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::Copy($BackupFile, $Temp, $false)
        [IO.File]::Replace($Temp, $TargetPath, $null, $true)
        if ((Get-SHA256 $TargetPath) -ne $ExpectedOriginal) {
            throw '恢复后 SHA-256 校验失败，请暂停使用并检查备份。'
        }
        Write-Host 'RESTORED：已恢复原始 EXE，原版备份仍保留。' -ForegroundColor Green
    }
    finally {
        if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Force }
    }
    return
}

if ($Current -eq $ExpectedPatched) {
    Write-Host 'ALREADY PATCHED：已经是最终修复版。' -ForegroundColor Yellow
    return
}
if ($Current -ne $ExpectedOriginal) {
    throw '应用已拒绝：EXE 的 SHA-256 与此精确版本不符。'
}
Check-Length $TargetPath ([long]$Manifest.input_length)
if (Test-Path -LiteralPath $BackupFile -PathType Leaf) {
    throw '应用已拒绝：原版备份已存在，为防止覆盖备份请先检查。'
}
$Original = [IO.File]::ReadAllBytes($TargetPath)
$Payload = [IO.File]::ReadAllBytes($PayloadFile)
$Output = New-Object byte[] ([int]$Manifest.output_length)
if ($Original.Length + $Payload.Length -ne $Output.Length) {
    throw '补丁载荷长度不符。'
}
[Array]::Copy($Original, 0, $Output, 0, $Original.Length)
[Array]::Copy($Payload, 0, $Output, $Original.Length, $Payload.Length)
foreach ($Op in $Manifest.operations) {
    $Position = [int]$Op.offset
    $Old = Get-HexBytes ([string]$Op.expected)
    $New = Get-HexBytes ([string]$Op.replacement)
    if ($Old.Length -ne $New.Length -or $Position -lt 0 -or
        $Position + $Old.Length -gt $Original.Length) {
        throw '补丁操作范围不合法。'
    }
    for ($i=0; $i -lt $Old.Length; $i++) {
        if ($Original[$Position+$i] -ne $Old[$i]) {
            throw ('IL 原始字节不一致：偏移 0x{0:X}' -f ($Position+$i))
        }
    }
    [Array]::Copy($New, 0, $Output, $Position, $New.Length)
}
$Temp = $TargetPath + '.patch-' + [Guid]::NewGuid().ToString('N') + '.tmp'
try {
    [IO.File]::WriteAllBytes($Temp, $Output)
    if ((Get-SHA256 $Temp) -ne $ExpectedPatched) {
        throw '修复文件的 SHA-256 校验失败；原始 EXE 未修改。'
    }
    # Windows 同卷原子替换，同时生成原版备份。
    [IO.File]::Replace($Temp, $TargetPath, $BackupFile, $true)
    if ((Get-SHA256 $TargetPath) -ne $ExpectedPatched -or
        (Get-SHA256 $BackupFile) -ne $ExpectedOriginal) {
        throw '替换后校验失败：请停止运行，并人工检查原版备份。'
    }
    Write-Host 'PATCH APPLIED：Minecraft 和整合包下载/安装补丁已写入 EXE。' -ForegroundColor Green
    Write-Host ('原版备份：' + $BackupFile)
    Write-Host '补丁永久生效，除非 EXE 被更新或覆盖。'
}
finally {
    if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Force }
}
