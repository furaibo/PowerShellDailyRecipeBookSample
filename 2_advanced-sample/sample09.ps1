# スクリプトの引数定義
Param(
    [string]$inputPath = "",     # 入力フォルダパス
    [string]$outExt = "",        # 出力ファイル拡張子
    [switch]$getaudio = $false   # 音声データ取得のみ
)

# ffmpegのインストール状況の確認
try {
    (Get-Command ffmpeg).Definition
} catch {
    Write-Error "ffmpegが見つかりません"
    exit
}

# 入力ファイルの存在チェック
# Note: inputPathオプションの値がある場合はパスの存在をチェック
if ($inputPath -ne "" -and `
    (-not (Test-Path -Path $inputPath -PathType Leaf))) {
    Write-Error "入力ファイルが見つかりません"
    exit
}

# 変数定義
$saveFolderPath = [Environment]::GetFolderPath("MyVideos") + "\ConvertedFiles"
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($inputPath)

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# ffmpegによるファイルの変換処理
try {
    if ($getaudio) {
        # 保存先パスの決定
        $saveFilePath = "${saveFolderPath}\${fileName}.mp3"

        # すでに同じパスにファイルが存在する場合は削除
        if (Test-Path -Path $saveFilePath) { Remove-Item $saveFilePath }
        
        # 動画からの音声データの抜き出し処理
        ffmpeg -i $src -q:a 0 -map a $saveFilePath

    } else {
        # 保存先パスの決定
        $saveFilePath = "${saveFolderPath}\${fileName}${outExt}"

        # すでに同じパスにファイルが存在する場合は削除
        if (Test-Path -Path $saveFilePath) { Remove-Item $saveFilePath }
        
        # 動画ファイル形式の変換
        ffmpeg -i $src $saveFilePath
    }
} catch {
    Write-Error "ffmpegによるファイル変換を完了できませんでした"
    exit
}

# 完了メッセージ & 保存先パスの表示
Write-Host "ファイル変換が完了しました"
Write-Host "保存先パス: ${saveFilePath}" -ForegroundColor Cyan
