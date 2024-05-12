# スクリプトの引数定義
param (
    [string] $inputPath,
    [string] $outputExt=".png"
)

# 変数定義
$dateString = Get-Date -Format "yyyyMMddHHmmss"
$saveFolderRoot = [Environment]::GetFolderPath("MyPictures") + "\MyPDF2Image" 
$saveFolderPath = "${saveFolderRoot}\${dateString}"
Write-Host $saveFolderPath
return

# 対応する画像フォーマットの定義
# Note: png/jpg/gif形式に対応
$imageExtensions = @(".png", ".jpg", ".jpeg", ".gif")

# 出力対象の画像フォーマットの確認
if (-not ($outputExt.ToLower() -in $imageExtensions)) {
	Write-Error ".png/.jpg/.jpeg/.gif のいずれかの拡張子から選んでください"
    exit
}

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# PDFページの画像化処理
# Note: DPI(解像度設定)は"-density"オプションで変更可能
magick -density 300 "$inputPath" "${saveFolderPath}\%03d${outputExt}"

# 保存先フォルダの表示
Write-Host "保存先フォルダ: ${saveFolderPath}" -ForegroundColor Cyan