# スクリプトの引数定義
param (
    [string] $inputPath   # 入力ファイルパス
)

# ffmpeg/soxのインストール状況の確認
try {
    (Get-Command ffmpeg).Definition
    (Get-Command sox).Definition
} catch {
    Write-Error "ffmpeg もしくは sox が見つかりません"
    exit
}

# 変数定義
$dateString = Get-Date -Format "yyyyMMddHHmmss"
$saveRootPath = [Environment]::GetFolderPath("MyMusic") + "\MusicSeparated"
$saveFolderPath = "${saveRootPath}\${dateString}"

# 入力パスの存在確認
if (-not (Test-Path -Path $inputPath -PathType Leaf)) {
    Write-Error "入力ファイルが見つかりません"
    exit
}

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# 変数宣言
$fileName = [System.IO.Path]::GetFileName($inputPath)
$srcFilePath = "${saveFolderPath}\src.mp3"
$dstFilePath = "${saveFolderPath}\out.mp3"

# 保存先フォルダへのファイルコピー(&変換処理)
if ([IO.Path]::GetExtension($fileName) -ne ".mp3") {
    # ファイルコピー
    Copy-Item $inputPath -Destination $srcFilePath
} else {
    # ffmpegによるmp3形式への変換
    ffmpeg -i $inputPath -ab 256k $srcFilePath
}

# soxによるファイル分割処理
# Note: 音量0.1%以下を無音時間とみなし、無音時間3秒で分割する
sox -V3 $srcFilePath $dstFilePath `
    silence 0 3t 0.1% 0 3t 0.1% : newfile : restart

# 完了メッセージ & 保存先フォルダの表示
Write-Host "ファイル分割処理が完了しました"
Write-Host "保存先フォルダ: ${saveFolderPath}" -ForegroundColor Cyan