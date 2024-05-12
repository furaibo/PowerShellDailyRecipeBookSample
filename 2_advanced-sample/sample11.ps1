# スクリプトの引数定義
Param(
    [string]$url = "",
    [string]$inputPath,
    [string]$urlListPath,
    [int]$minWidth=300,
    [int]$minHeight=300,
    [switch]$noDelete=$false
)

# アセンブリの読み込み
Add-Type -AssemblyName System.Drawing

# 対応画像フォーマット
$imageExtensions = @(".png", ".jpg", ".gif")

# 変数の初期化
$pageUrlArray = @()
$saveFolderRoot = [Environment]::GetFolderPath("MyPictures") + "\MyImages"
$failedUrlTextPath = "${saveFolderPath}\failed_url.txt"

# -urlオプションからのURL取得
if ($url -ne "") {
    $pageUrlArray += $url
}

# 入力ファイルからのURL取得
# Note: 1行あたり1つのURLが書かれているものとして読み込み処理
if ($urlListPath -ne "" -and `
    (Test-Path -Path $urlListPath -PathType Leaf)) {
    foreach ($line in (Get-Content $inputPath)) {
        $pageUrlArray += $line.Trim()
    }
}

# URL入力数のチェック
if ($pageUrlArray.Count -eq 0) {
    Write-Host "URLが入力されていません"
    exit
}

# ダウンロード処理の実行
foreach ($pageUrl in $pageUrlArray) {  
    # HTTPリクエスト処理の実行
    # Note: アクセス失敗したURLではメッセージの表示・ログ書き込み処理を実施
    $req = Invoke-WebRequest -Uri $pageUrl
    if ($req.StatusCode -ne 200) {
        Write-Host "指定されたページは利用できません"
        Write-Host "URL: ${pageUrl}"
        Write-Output $pageUrl | Out-File $failedUrlTextPath
        continue
    }

    # 保存先パスに関する変数
    $dateString = Get-Date -Format "yyyyMMddHHmmss"
    $saveFolderPath = "${saveFolderRoot}\${dateString}"
    $pageInfoFilePath = "${saveFolderRoot}\${dateString}\page_info.txt"

    # HTMLからURL文字列を取得
    $html = $req.Content
    $fetchUrls = @()

    # 正規表現を使ったURL情報の抜き出し(HTMLパーサなし)
    # Note: 現在はParsedHtmlが利用できないため生HTML文字列を使う
    # imgタグ内のsrcの取り出し 
    $match1 = [regex]::Matches($html, 'src="(http.+?)"')
    $match1 | ForEach-Object {
        $tempUrl = $_.Groups[1].Value
        $fetchUrls += $tempUrl.Split("?")[0]
    }

    # aタグ内のhrefの取り出し 
    $match2 = [regex]::Matches($html, 'href="(http.+?)"')
    $match2 | ForEach-Object {
        $tempUrl = $_.Groups[1].Value
        $fetchUrls += $tempUrl.Split("?")[0]
    }

    # URLのフィルタリング・重複の除去およびソート
    # Note: 配列$fetchUrlsの中で、指定の拡張子をもつ画像のみ取り出す
    $imageUrls = $fetchUrls |
        Where-Object {
            [System.IO.Path]::GetExtension($_) -in $imageExtensions } |
        Get-Unique | Sort-Object

    # ダウンロード可能な画像がない場合のメッセージ
    if ($imageUrls.Count -eq 0) {
        Write-Host "ダウンロード可能な画像がありません。"
        continue
    }

    # 保存先フォルダの作成
    if (-not (Test-Path -Path $saveFolderPath -PathType Container)) {
        New-Item -Path $saveFolderPath -ItemType Directory -Force > $null
    }

    # 画像ファイルのダウンロード処理
    # Note: ファイル名は番号として作成する
    $wc = New-Object System.Net.WebClient
    $count = 0
    foreach($link in $imageUrls) {
        $fileExt = ([uri]$link).Segments[-1]
        $fileName = "{0:03d}" -f ($count + 1)
        $filePath = "${saveFolderPath}\${fileName}${fileExt}"
        try {
            $wc.DownloadFile($link, $filePath)
        } catch {
            Write-Host "注意: ダウンロードに失敗しました(URL: ${link})"
        }
    }
}

# 指定サイズ以下の画像の削除
# Note: -noDeleteオプションが指定されている場合はファイル削除処理は実行されない
if (-not $noDelete) {
    $deleteFilePathArray = @()

    # 削除対象画像ファイルパスの取得
    Get-ChildItem "${saveFolderPath}\*" -Include $imageFormats | 
        ForEach-Object {
            $img = [System.Drawing.Image]::FromFile($_.FullName);
            if (($img.Width -lt $minWidth) -or ($img.Height -lt $minHeight)) {
                $deleteFilePathArray += $_.FullName
            }
            $img = $null
        }

    # 画像ファイルの削除処理
    foreach($path in $deleteFilePathArray) { 
        $errorCount = 0
        while($errorCount -lt 3) {
            try {
                # Note: ErrorAction指定によりエラー時の挙動を制御する
                Remove-Item $path -ErrorAction:Stop
                break
            } catch {
                Write-Host "注意: 削除に失敗しました(Path: ${path})"
                $errorCount++
                Start-Sleep 3
                continue
            }
        }
    }
}

# ダウンロード先ページ情報の出力
Write-Output "URL: ${inputUrl}" | Out-File $pageInfoFilePath

# 保存先フォルダの表示
Write-Host "保存先フォルダ: ${saveFolderPath}" -ForegroundColor Cyan
