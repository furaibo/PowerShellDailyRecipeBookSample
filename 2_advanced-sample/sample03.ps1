# スクリプトの引数定義
param (
    [string] $inputPath
)

# 入力パスの存在確認
if (($inputPath -eq "") -or (-not (Test-Path -Path $inputPath))) {
    Write-Error "入力フォルダが見つかりません"
    exit
}

# 変数定義
$dateString = Get-Date -Format "yyyyMMddHHmmss"
$saveFolderPath = [Environment]::GetFolderPath("MyPictures") + "\MyImage2PDF"
$outputPDFPath = "${saveFolderPath}\${dateString}.pdf"

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# ImageMagickによる画像のPDF化処理
# Note: この例ではpng/jpeg/gif形式が対象 
magick "${inputPath}\*.{png,jpg,jpeg,gif}" -quality 100 $outputPDFPath

# 保存先フォルダの表示
Write-Host "保存先フォルダ: ${saveFolderPath}" -ForegroundColor Cyan