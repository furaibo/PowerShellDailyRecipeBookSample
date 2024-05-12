# スクリプトの引数定義
Param(
    [string]$urlListPath = "",
    [string]$url = "",
    [int]$threads = 2
)

# yt-dlpのインストール状況の確認
try {
    (Get-Command yt-dlp).Definition
} catch {
    Write-Error "yt-dlpが見つかりません"
    exit
}

# 変数定義
$saveFolderPath = [Environment]::GetFolderPath("MyVideos") + "\DownloadFiles"
$fileNameFormat = "%(title)s.%(ext)s"
$fileSavePath = "${saveFolderPath}\${fileNameFormat}"

# URLリスト一覧のファイルがあるかどうか確認
# Note: urlListPathオプションの値がある場合はパスの存在をチェック
if ($urlListPath -ne "" -and
  (-not (Test-Path -Path $urlListPath -PathType Leaf))) {
    Write-Error "URL指定用のファイルが見つかりません"
    exit
}

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# ダウンロード処理の実行
# Note: -Nオプションでマルチスレッドでのダウンロード処理が可能
if ($urlListPath -ne "") {
    yt-dlp -a $urlListPath -o $fileSavePath `
        -N $threads --embed-thumbnail --windows-filenames --console-title 
} else {
    yt-dlp $url -o $fileSavePath `
        --embed-thumbnail --windows-filenames --console-title
}

# 保存先フォルダの表示
Write-Host "保存先フォルダ: ${saveFolderPath}" -ForegroundColor Cyan
