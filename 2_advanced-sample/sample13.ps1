# スクリプトの引数定義
Param(
    [string]$url = "",
    [int]$width = 15
)

# QRコード画像保存先フォルダ・ファイルパスの初期化
$dateString = Get-Date -Format "yyyyMMddHHmmss"
$fileName = "\${dateString}.png"
$saveFolderPath = `
    [Environment]::GetFolderPath("MyPictures") + "\MyQRcodes"
$saveFilePath = "${saveFolderPath}\${fileName}"

# URLアクセスのチェック
$req = Invoke-WebRequest -Uri $url 
if ($req.StatusCode -ne 200) {
    Write-Error "アクセスできません`nステータスコード: $($req.StatusCode)"
    exit
}

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# QRcode画像の生成・保存
try {
    New-PSOneQRCodeURI -URI $url -Width $width -OutPath $saveFilePath
    Write-Host "QRコード画像の生成が完了しました"
    Write-Host "QRコード画像パス: ${saveFilePath}"
} catch {
    Write-Error "新しいQRコード生成に失敗しました"
}
