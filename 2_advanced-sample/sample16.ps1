# スクリプトの引数定義
Param(
    [string]$from,
    [string]$to,
    [string]$date,
    [string]$time,
    [int]$h=-1,
    [int]$m=-1
)

# 入力パラメータのチェック 
if ($from -eq "") {
    Write-Error "'from'パラメータを入力してください"
    exit
} elseif ($to -eq "") {
    Write-Error "'to'パラメータを入力してください"
    exit=0
}

# URLの指定
$url = "https://transit.yahoo.co.jp/search/print?"

# 出発・到着先のパラメータ付加
$url += "from=${from}&to=${to}"

# 日時のパラメータ付加 
$dt = Get-Date
if ($date -ne "") {
    try {
        $dt = [DateTime]$date
    } catch {
        Write-Error "日付の入力フォーマットに誤りがあります"
        exit
    }
}
$url += "&y=$($dt.Year)"
$url += "&m=$($dt.Month.ToString('00'))"
$url += "&d=$($dt.Day.ToString('00'))"

# 時刻のパラメータ付加(時間)
if ($time -ne "") {
    $timeArr = $time.Split(":")
    $h = [int]$timeArr[0]
    $m = [int]$timeArr[1]

    if (($h -ge 0) -and ($h -lt 24)) {
        $url += "&hh=${h}"
    } else {
        Write-Error "時刻のフォーマットに誤りがあります"
        exit
    }

    # 時刻のパラメータ付加(分)
    if (($m -ge 0) -and ($m -lt 60)) {
        $m1 = $m / 10
        $m2 = $m % 10
        $url += "&m1=${m1}&m2=${m2}"
    } else {
        Write-Error "時刻のフォーマットに誤りがあります"
    }
}

# リクエスト処理の実行
$req = Invoke-WebRequest -Uri $url
if ($req.StatusCode -ne 200) {
    Write-Error "Yahoo!ページにアクセスできません"
    exit
}

# HTMLテキストの取得
$html = $req.Content

# 経路検索エラー判定
if ($html -match "経路検索ができませんでした") {
    Write-Howt "経路検索エラーが発生しています。"
    Write-Host "条件を変更して再度検索してください"
    exit
}

# 正規表現を使った文字列の抜き出し
# Note: PowerShell7以降ではParsedHtmlが利用できないため生のHTML文字列から直接文字列を取り出す 
# 経路の概要部分のテキスト取得
$match1 = [regex]::Matches($html,
    '<div class="routeSummary"><ul class="summary">(.+?)</ul>')
$routeSummaryText = $match1.Groups[1].Value

# 時刻情報
$match1_1 = [regex]::Matches($routeSummaryText,
    '<li class="time">(.+?)</li>')
$timeString = ($match1_1.Groups[1].Value -replace '<.+?>', '')

# 運賃情報の取得
$match1_2 = [regex]::Matches($routeSummaryText,
    '<li class="fare">(.+?)</li>')
$fareString = ($match1_2.Groups[1].Value -replace '<.+?>', '')

# 経路の詳細部分のテキスト取得
$match2 = [regex]::Matches($html,
    '<div class="routeDetail">(.+)</div>')
$routeDetailText = $match2.Groups[1].Value

# 駅情報の取得
$stationInfoArray = @()
$match2_1 = [regex]::Matches($routeDetailText,
    '<div class="station">.+?<dl><dt>(.+?)</dt></dl>.+?</div>')
$match2_1 | ForEach-Object {
    $stationInfoArray += $_.Groups[1].Value }

# 経路情報の取得
$fareInfoArray = @()
$match2_2 = [regex]::Matches($routeDetailText,
    '<div class="access"><ul class="info">(.+?)</ul></div>')
$match2_2 | ForEach-Object {
    $tempString = $_.Groups[1].Value.Trim()
    $tempString = ($tempString -replace '\[line\]', '')
    $tempString = ($tempString -replace '<.+?>', '')
    $fareInfoArray += $tempString
}

# 路線検索結果の出力 
Write-Host $timeString
Write-Host $FareString
foreach($i in 0..($stationInfoArray.Length-2)) {
    Write-Host "[ $($stationInfoArray[$i]) ]"
    Write-Host " ↓ $($fareInfoArray[$i])"
}
Write-Host "[ $($stationInfoArray[-1]) ]"
