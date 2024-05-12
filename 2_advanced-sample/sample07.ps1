# スクリプトの引数定義
param (
    [string] $inputPath,      # 入力フォルダパス
    [string] $outExt=".mp3",  # 出力時拡張子
    [int] $interval=3         # 曲間の無音時間(秒数指定)
)

# 変数定義
$dateString = Get-Date -Format "yyyyMMddHHmmss"
$saveFolderPath = [Environment]::GetFolderPath("MyMusic") + "\MusicConcat"
$saveFilePath = "${saveFolderPath}\${dateString}${outExt}"
$silentFilePath = "${saveFolderPath}\silent.mp3"
$tempFilePath = ".\temp_list.txt"

# 対応する画像フォーマットの定義
# Note: mp3/wav/wma/aac形式に対応
$audioExtensions = @(".mp3", ".wav", ".wma", ".aac")

# 入力パスの存在確認
if (-not (Test-Path -Path $inputPath -PathType Container)) {
    Write-Error "入力フォルダがありません"
    exit
}

# 出力拡張子の確認
if (-not ($outExt.ToLower() -in $audioExtensions)) {
    Write-Error "指定された拡張子は利用できません: ${outExt}"
    exit
}

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# 無音ファイルの作成(楽曲間の無音時間用)
# Note: -tオプションで無音時間の秒数を指定 
ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t ${interval} `
     -aq 9 -c:a libmp3lame $silentFilePath 

# ファイルパスの取得
# Note: $outExtで指定された拡張子と同じファイルのみ対象
$filePathArray = Get-ChildItem -Recurse -Path $inputPath | 
    Where-Object { $_.Extension.ToLower() -eq $outExt } |
    ForEach-Object { $_.FullName } 

# ffmpeg読み込み用のファイルパスについてのテキストを作成
# Note: "file '[ファイルパスの文字列]'" の形式で入力を作成する
$fileString = ""
$filePathArray | ForEach-Object {
    $fileString += "file '$_'`n"
    $fileString += "file '${silentFilePath}'`n"
}
Write-Output $fileString | Out-File $tempFilePath -Encoding utf8

# ffmpegによる音声ファイルの結合処理
# Note: UTF-8のテキストファイルを入力として使用
ffmpeg -f concat -safe 0 -i $tempFilePath $saveFilePath

# 無音ファイルおよび一時ファイルの削除
Remove-Item $silentFilePath
Remove-Item $tempFilePath

# 完了メッセージ & 保存先パスの表示
Write-Host "ファイル結合処理が完了しました"
Write-Host "保存先パス: ${saveFilePath}" -ForegroundColor Cyan
