# スクリプトの引数定義
# Note: デフォルトのリサイズ後画像のサイズはXGA(1024x768)以下
param (
    [string] $inputPath,      # 入力フォルダパス
    [string] $outExt=".png",  # 出力時拡張子
    [int] $maxWidth=1024,     # リサイズ後画像の幅の最大値
    [int] $maxHeight=768      # リサイズ後画像の高さの最大値
)

# アセンブリの読み込み
Add-Type -AssemblyName System.Drawing

# 対応する画像フォーマットの定義
# Note: png/jpg/gif形式に対応
$imageExtensionFilters = @("*.png", "*.jpg", "*.jpeg", "*.gif")

# 変数定義
$dateString = Get-Date -Format "yyyyMMddHHmmss"
$saveFolderRoot = [Environment]::GetFolderPath("MyPictures") + "\Resized"
$saveFolderPath = "${saveFolderRoot}\${dateString}"

# 入力パスの存在確認
if (-not (Test-Path -Path $inputPath -PathType Container)) {
    Write-Error "入力フォルダが見つかりません"
    exit
}

# 入力パス以下にあるファイルパスの取得
$filePathArray = Get-ChildItem -Recurse -Path $inputPath `
    -Include $imageExtensionFilters

# 保存先フォルダの作成
# Note: このサンプルではマイピクチャ内に"Resized"フォルダを新規作成する
if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
    New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
}

# 画像のリサイズ処理実行
foreach($path in $filePathArray) {
    # 画像の読み出し
    $image = [System.Drawing.Image]::FromFile($path)

    # 画像の幅・高さおよび縮小比を取得
    $width = $image.Width
    $height = $image.Height
    $hRatio = $maxWidth / $image.Width
    $vRatio = $maxHeight / $image.Height

    # 縮小比に応じた縮小後の画像幅・高さの決定
    # Note: 指定した幅・高さに収まる範囲で最大のサイズになるように縦横比率を調整
    if (($hRatio -lt 1) -and ($vRatio -lt 1)) {
        if ($hRatio -lt $vRatio) {
            $width  = $maxWidth
            $height = [int]($height * $hratio)
        } else {
            $width  = [int]($width * $vRatio)
            $height = $maxHeight
        }
    } elseif ($hRatio -lt 1) {
        $width  = $maxWidth
        $height = [int]($height * $hratio)
    } elseif ($vRatio -lt 1) {
        $width  = [int]($width * $vRatio)
        $height = $maxHeight
    }

    # リサイズ後の画像の書き出し(ビットマップ形式)
    $canvas = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.DrawImage($image, 0, 0, $width, $height)

    # 出力時ファイル名の取得および出力パスの決定
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension("$path") + $outExt
    $outputPath = "${saveFolderPath}\${fileName}"

    # 画像ファイルの保存
    $canvas.Save($outputPath)

    # オブジェクトの破棄
    $graphics.Dispose()
    $canvas.Dispose()
    $image.Dispose()
}

# 保存先フォルダの表示
Write-Host "保存先フォルダ: ${saveFolderPath}" -ForegroundColor Cyan
