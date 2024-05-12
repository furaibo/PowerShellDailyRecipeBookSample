# URLの指定
$yahooTopUrl = "https://www.yahoo.co.jp/"

# リクエスト処理の実行
$req = Invoke-WebRequest -Uri $yahooTopUrl
if ($req.StatusCode -ne 200) {
	Write-Error "Yahoo!ページにアクセスできません"
    exit
}

# HTMLテキストの取得
$html = $req.Content

# 正規表現を使った文字列の抜き出し
# Note: PowerShell7以降ではParsedHtmlが利用できないため生のHTML文字列から直接文字列を取り出す 
# ヘッドライン部分のテキスト取得
$match1 = [regex]::Matches($html,
    '<section id="tabpanelTopics1".*?>(.+?)</section>')
$topicText = $match1.Groups[1].Value

# 更新日時の取得
$match2 = [regex]::Matches($topicText,
    '([0-9]{1,2}/[0-9]{1,2}.+?[0-9]{1,2}:[0-9]{2}更新)')
$updateTimeString = $match2.Groups[1].Value

# ulタグ内の文字列の取得
$match3 = [regex]::Matches($topicText, '<ul>(.+?)</ul>')
$ulInnerText = $match3.Groups[1].Value

# ulタグ内の文字列からさらにURL/タイトルの文字列を抜き出す
$outputLineArray = @()
$match4 = [regex]::Matches($ulInnerText,
    '<a class=.+? href="(.+?)".+?>.+?<h1 class.+?><span.+?>(.+?)</span></h1>')
$match4 | ForEach-Object {
    $url   = $_.Groups[1].Value
    $title = $_.Groups[2].Value
    $outputLineArray += "- ${title}`nURL: ${url}"
}

# 取得した文字列の出力
Write-Host "Yahoo!ヘッドライン ($updateTimeString)"
$outputLineArray | ForEach-Object { Write-Host $_ }
