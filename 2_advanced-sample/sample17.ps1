# スクリプトの引数定義
Param(
    [string]$word = ""
)

# 関数定義
# SELECT文用
function Get-SQLCommand($conn, $sql) {
    $sqlcmd = $conn.CreateCommand()
    $sqlcmd.CommandText = $sql
    return $sqlcmd
}

# INSERT/DELETE/UPDATE文用
# Note: ExecuteNonQuery実行時の変更行数表示をOut-Nullで捨てる
function Get-SQLExecuteNonQuery($conn, $sql, $returnCount=$false) {
    $sqlcmd = $conn.CreateCommand()
    $sqlcmd.CommandText = $sql
    if ($returnCount) {
        return $sqlcmd.ExecuteNonQuery()
    } else {
        $sqlcmd.ExecuteNonQuery() | Out-Null
    }
}

# 単語の意味の取得
function Get-NewWordMeaning($word) {
    # 英辞郎からのスクレイピング処理
    $url = "https://eow.alc.co.jp/search?q=${word}"

    # リクエスト処理の実行
    $req = Invoke-WebRequest -Uri $url
    if ($req.StatusCode -ne 200) {
		Write-Error "指定のWebページにアクセスできません"
        exit
    }

    # HTML取得
    $html = $req.Content

    # 意味情報の抜き出し
    $meaningText = ""
    $match1 = [regex]::Matches($html,
        '<span class="wordclass">(.+?)</span><ol>(.+?)</ol>')
    foreach($m1 in $match1) {
        $wordClass = $m1.Groups[1].Value
        $meaningSection = $m1.Groups[2].Value

        # liタグ以下から情報の取得
        $meaningText += "${wordClass}`n"
        $match2 = [regex]::Matches(
            $meaningSection, '<li>(.+?)</li>')

        # liタグが存在するかどうかで分岐
        if ($match2) {
            $count = 1
            foreach($m2 in $match2) {
                $tempStr = $m2.Groups[1].Value
                $tempStr = $tempStr -replace '<span.+?>.+?</span>', ''
                $tempStr = $tempStr -replace '<br />.+$', ''
                $meaningText += "${count}. ${tempStr}`n" 
                $count++
            }
        } else {
            $tempStr = $meaningSection
            $tempStr = $tempStr -replace '<span.+?>.+?</span>', ''
            $tempStr = $tempStr -replace '<br />.+$', ''
            $meaningText += "${tempStr}`n" 
        }
    }
    return $meaningText
}

# 変数宣言
$isNewDatabase = $false
$isUpdateHistoryRequired = $false
$saveFolderPath = [Environment]::GetFolderPath("MyDocuments")
$sqliteFilePath = "${saveFolderPath}\wordbook.sqlite"

# 入力パラメータのチェック
if ($word -eq "") {
	Write-Host "-wordオプションで検索したい英単語を指定してください" 
    exit
}

# 入力パスの存在確認
if (-not (Test-Path -Path $sqliteFilePath -PathType Leaf)) {
    $isNewDatabase = $true
}

# SQLiteの接続処理
$conn = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$conn.ConnectionString = "Data Source = ${sqliteFilePath}"
try {
    $conn.Open()
} catch {
	Write-Error "SQLiteファイルのオープンに失敗しました"
    exit
}

# 新規テーブル作成時の処理
if ($isNewDatabase) {
    # 単語登録用テーブルのSQL
    $sqlCreateTable1 = "CREATE TABLE words (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT,
        meaning TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );"

    # 単語検索履歴登録用テーブルのSQL
    $sqlCreateTable2 = "CREATE TABLE word_search_histories (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );"

    # テーブル作成用SQLクエリの実行
    Get-SQLExecuteNonQuery $conn $sqlCreateTable1
    Get-SQLExecuteNonQuery $conn $sqlCreateTable2
}

# 完全一致検索の準備
$searchExactResult = @()
$sqlSearchExactWord = "SELECT * FROM words WHERE word='${word}';"
$sqlcmd1 = Get-SQLCommand $conn $sqlSearchExactWord
$reader1 = $sqlcmd1.ExecuteReader()

# 完全一致検索の実行
while ($reader1.HasRows) {
    if ($reader1.Read()) {
        $tempStr = "[$($reader1["word"])]`n$($reader1["meaning"])"
        $searchExactResult += $tempStr
    }
}

# 完全一致検索の結果に応じて次の処理を決定
if ($searchExactResult.Length -eq 0) {
    # 部分一致検索の準備
    $searchLikeResult = @()
    $sqlSearchLikeWord = "
        SELECT * FROM words WHERE word LIKE '${word}%';"
    $sqlcmd2 = Get-SQLCommand $conn $sqlSearchLikeWord
    $reader2 = $sqlcmd2.ExecuteReader()

    # 部分一致検索の実行
    while ($reader2.HasRows) {
        if ($reader2.Read()) {
            $tempStr = "$($reader2["word"]) - $($reader2["meaning"])"
            $searchLikeResult += $tempStr
        }
    }

    # 部分一致検索結果がなかった場合の処理
    if ($searchLikeResult.Length -eq 0) {
        # 新出単語のスクレイピング処理
        $meaning = Get-NewWordMeaning $word

        # 単語の登録処理
        $sqlInsertNewWord = "
            INSERT INTO words(word, meaning)
            VALUES ('${word}', '${meaning}');"
        Get-SQLExecuteNonQuery $conn $sqlInsertNewWord

        # 単語検索履歴登録フラグの設定
        $isUpdateHistoryRequired = $true
    }
} elseif ($searchExactResult.Length -ge 1) {
    # 完全一致検索結果の表示
    foreach ($tempStr in $searchExactResult) {
        Write-Host $tempStr
    }
    # 単語検索履歴登録フラグの設定
    $isUpdateHistoryRequired = $true
}

# 単語検索履歴の登録処理
if ($isUpdateHistoryRequired) {
    $sqlInsertNewHistory = "
        INSERT INTO word_search_histories (word)
        VALUES ('${word}');"
    Get-SQLExecuteNonQuery $conn $sqlInsertNewHistory
}
