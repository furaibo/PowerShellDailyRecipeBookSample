# スクリプトの引数定義
Param([switch]$reuse)

# アセンブリの読み込み
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# キャプチャ関連設定のクラス(json形式用)
class CaptureConfig {
    [int] $rectX
    [int] $rectY
    [int] $rectWidth
    [int] $rectHeight
    [int] $waitSecond
    [string] $imageExt
    [string] $autoPressKey
}

# グローバル変数定義
$global:pageCountLimit = 500
$global:waitSecondDefault = 1
$global:waitSecondLimit = 20
$global:imageFormatDefault = [System.Drawing.Imaging.ImageFormat]::Jpeg
$global:imageExtDefault = ".jpg"
$global:autoPressKeyDefault = "{Right}"

# 関数の定義
# 拡張子文字列からの画像フォーマットの取得
function Get-ImageFormatFromExt($selectExt) {
    switch ($selectExt.ToLower()) {
        ".jpg" { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        ".png" { return [System.Drawing.Imaging.ImageFormat]::Png }
        ".bmp" { return [System.Drawing.Imaging.ImageFormat]::bmp }
        default { return $global:imageFormatDefault }
    }
}

# 画像形式の選択処理
function Get-ImageFormatAndExt() {
    $imageExt = $global:imageExtDefault
    $inputString = Read-Host -Prompt `
        "画像形式を選択してください ... 1: jpg, 2: png, 3: bmp (デフォルト: jpg)"
    $selectNumber = [int]$inputString

    switch ($selectNumber) {
        1 { $imageExt = ".jpg" }
        2 { $imageExt = ".png" }
        3 { $imageExt = ".bmp" }
        default { $imageExt = $global:imageExtDefault }
    }

    $imageFormat = Get-ImageFormatFromExt $imageExt
    return $imageFormat, $imageExt
}

# ページ数の入力処理
function Get-PageCount() {
    $pageCount = 0
    $inputString = Read-Host -Prompt "ページ数を入力してください"
    $pageCount = [int]$inputString

    if($pageCount -gt $global:pageCountLimit) {
        Write-Host "指定可能なページ数は上限${pageCountLimit}です"
        $pageCount = $global:pageCountLimit
    }

    return $pageCount
}

# マウスクリックによる矩形領域の取得
function Get-DragRectArea() {
    Write-Host "マウスをドラッグして矩形領域を選択してください(左クリックで開始)"
    while ([System.Windows.Forms.Control]::MouseButtons -ne 'Left') {
        Start-Sleep 0.5 }
    $p1 = [System.Windows.Forms.Control]::MousePosition
    Write-Host "Pressed"

    while ([System.Windows.Forms.Control]::MouseButtons -ne 'None') {
         Start-Sleep 0.5 }
    $p2 = [System.Windows.Forms.Control]::MousePosition
    Write-Host "Released"

    $rect = [System.Drawing.Rectangle]::FromLTRB(
        [Math]::Min($p1.X, $p2.X), [Math]::Min($p1.Y, $p2.Y),
        [Math]::Max($p1.X, $p2.X), [Math]::Max($p1.Y, $p2.Y))

    return $rect
}

# キャプチャ間隔秒数の取得
function Get-WaitSecond() {
    $inputString = Read-Host -Prompt `
        "キャプチャ間隔(秒数)を入力してください (デフォルト: 1秒)"
    if ($inputString -eq "") { return $global:waitSecondDefault }

    $waitSecond = [int]$inputString
    if($waitSecond -gt $waitSecondLimit) {
        Write-Host "指定可能なキャプチャ間隔は上限${waitSecondLimit}秒です"
        $waitSecond = $global:waitSecondLimit
    } elseif ($waitSecond -le 0) {
        $waitSecond = $global:waitSecondDefault
    }

    return $waitSecond
}

# 自動押下キーの取得
function Get-PressKey() {
    $pressKey = $global:autoPressKeyDefault
    $inputString = Read-Host -Prompt `
        "自動押下キーを選択してください ... 1: Right(→), 2: Left(←), 3: Enter (デフォルト: Right)"
    $selectNumber = [int]$inputString

    switch ($selectNumber) {
        1 { $pressKey = "{Right}" }
        2 { $pressKey = "{Left}" }
        3 { $pressKey = "{Enter}" }
    }

    return $pressKey
}

# スクリーンショットの取得・保存処理
function Get-Screenshot($rect, $saveFilePath, $imageFormat) {
    $bitmap = New-Object System.Drawing.Bitmap($rect.Width, $rect.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    $bitmap.Save($saveFilePath, $imageFormat)
    $graphics.Dispose()
    $bitmap.Dispose()
}

# 変数宣言
# ファイルパス関連の変数
$dateString = Get-Date -Format "yyyyMMddHHmmss"
$saveFolderRoot = [Environment]::GetFolderPath("MyPictures") + "\MyScreenshots"
$saveFolderPath = "${saveFolderRoot}\${dateString}"
$captureConfigFilePath = "${saveFolderRoot}\capture_config.json"

# キャプチャ設定関連の変数
$conf = New-Object CaptureConfig
$configExists = $reuse -and (Test-Path -Path $captureConfigFilePath)
$pageCount = 0
$imageFormat = $global:imageFormatDefault
$captureRect = [System.Drawing.Rectangle]::FromLTRB(0, 0, 0, 0)

# スクリーンショット取得設定が存在する場合は読み込む
if ($configExists) {
    # jsonの読み込み処理
    $json = Get-Content -Path $captureConfigFilePath | ConvertFrom-Json

    # jsonから読み込んだ情報によって設定情報を初期化
    $conf.rectX = $json.rectX
    $conf.rectY = $json.rectY
    $conf.rectWidth = $json.rectWidth
    $conf.rectHeight = $json.rectHeight
    $conf.waitSecond = $json.waitSecond
    $conf.imageExt = $json.imageExt
    $conf.autoPressKey = $json.autoPressKey
    $imageFormat = Get-ImageFormatFromExt $conf.imageExt
    $captureRect = [System.Drawing.Rectangle]::FromLTRB(
        $conf.rectX, $conf.rectY,
        $conf.rectX + $conf.rectWidth,
        $conf.rectY + $conf.rectHeight)

    Write-Host "`n前回のスクリーンショット取得設定を再利用します`n"

    # 取得ページ数の入力
    do {
        $pageCount = Get-PageCount
        $response = Read-Host -Prompt `
            "保存ページ数: ${pageCount} ... OK?(y/n)"
    } until ($response -eq 'y')

} else {
    # 画像フォーマットの取得
    $imageFormat, $conf.imageExt = Get-ImageFormatAndExt

    # 取得ページ数の入力
    do {
        $pageCount = Get-PageCount
        $response = Read-Host -Prompt `
            "保存ページ数: ${pageCount} ... OK?(y/n)"
    } until ($response -eq 'y')

    # スクリーンショット対象となる矩形領域の決定
    do {
        $captureRect = Get-DragRectArea
        $conf.rectX,  $conf.rectY = $captureRect.X, $captureRect.Y
        $conf.rectWidth,  $conf.rectHeight = `
            $captureRect.Width, $captureRect.Height
        $response = Read-Host -Prompt `
            "指定矩形領域: ${captureRect} ... OK?(y/n)"
    } until ($response -eq 'y')

    # スクリーンショット取得間隔の決定
    $conf.waitSecond = 1
    do {
        $conf.waitSecond = Get-WaitSecond
        $response = Read-Host -Prompt `
            "キャプチャ間隔: $($conf.waitSecond) sec ... OK?(y/n)"
    } until ($response -eq 'y')

    # スクリーンショット取得完了後の対象入力キーの決定
    $conf.autoPressKey = "{Right}"
    do {
        $conf.autoPressKey = Get-PressKey
        $response = Read-Host -Prompt `
            "自動押下キー: $($conf.autoPressKey) ... OK?(y/n)"
    } until ($response -eq 'y')
}

# キャプチャ開始前のメッセージ表示・スリープ時間
Write-Host "`n対象となるウィンドウをアクティブ状態にしてください。"
Write-Host "スクリーンショット開始後は画面操作を行わないでください。"
Write-Host "10秒後にスクリーンショット取得を開始します..."
Start-Sleep 10

# 保存先フォルダの作成
if (-not (Test-Path -Path $saveFolderPath)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# 設定情報の出力
Write-Host "`n[各種設定情報]"
Write-Host "- 保存先フォルダ: ${saveFolderPath}"
Write-Host "- 画像の保存形式: $($conf.imageExt)"
Write-Host "- 保存ページ数: ${pageCount} ページ"
Write-Host "- 指定矩形領域: ${captureRect}"
Write-Host "- キャプチャ間隔: $($conf.waitSecond) 秒"
Write-Host "- 自動押下キー: $($conf.autoPressKey)"

# スクリーンショットの取得処理実行
for ($i=1; $i -le $pageCount; $i++){
    # ファイル保存先パスの指定
    $saveFilePath = "{0}\{1:000}{2}" -f $saveFolderPath, $i, $conf.imageExt

    # スクリーンショット取得
    Get-Screenshot $captureRect $saveFilePath $imageFormat
    if ($i % 10 -eq 0) { Write-Host "${i}ページ取得完了..." }

    # キー押下処理の実行
    [System.Windows.Forms.SendKeys]::SendWait($conf.autoPressKey)

    # 指定秒数分のスリープ
    Start-Sleep $conf.waitSecond
}

# 現在のキャプチャ設定情報の書き出し(json形式)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($captureConfigFilePath, `
    (ConvertTo-Json $conf), $utf8NoBom)

# 完了メッセージの表示 & # 保存先フォルダの表示
Write-Host "スクリーンショット取得処理を完了しました"
Write-Host "保存先フォルダ: ${saveFolderPath}" -ForegroundColor Cyan
