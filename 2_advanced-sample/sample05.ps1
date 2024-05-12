# 変数の定義
# Note: 一時フォルダ・圧縮ファイル名として現在時刻の文字列を使用する
$sourceFolderPath = "${HOME}\Downloads"
$saveFolderPath = [Environment]::GetFolderPath("MyDocuments") + "\Archive"
$dateTimeString = Get-Date -Format "yyyyMMddHHmmss"
$tempFolderPath = "${saveFolderPath}\${dateTimeString}"
$saveZipFilePath = "${saveFolderPath}\${dateTimeString}_archive.zip"

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# 一時フォルダの作成(フォルダ名は時刻による)
New-Item -Path $tempFolderPath -ItemType Directory -Force > $null

# 1ヵ月以内に更新されたファイル名の取得・一時フォルダへのファイルコピー
# Note: フルパスを取得するには"FullName"プロパティを参照
Get-ChildItem -Path $sourceFolderPath |
  Where-Object { $_.LastWriteTime -gt (Get-Date).AddMonths(-1)} |
  Foreach-Object { Copy-Item $_.FullName -Destination "$tempFolderPath\$_" }

# 一時フォルダのzip化
# Note: zip形式ファイルをアーカイブ先(この場合はドキュメントフォルダ)に移す
Compress-Archive -Path $tempFolderPath -DestinationPath $saveZipFilePath

# 一時フォルダの削除処理
# Note: フォルダおよびその内部も含めて削除するには-Recurseオプションを追加
Remove-Item $tempFolderPath -Recurse

# 完了メッセージ & 保存先パスの表示
Write-Host "アーカイブ化処理が完了しました"
Write-Host "保存先パス: ${saveZipFilePath}" -ForegroundColor Cyan
