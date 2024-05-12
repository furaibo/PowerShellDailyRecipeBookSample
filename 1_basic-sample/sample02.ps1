# クイックソート処理を行う関数の定義
function Get-QuickSort($arr) {
    # 要素数が1以下ならばそのまま値を返す
    # Note: LengthもしくはCountで配列の長さを取得
    if ($arr.Length -eq 0) {
        return @()
    } elseif ($arr.Length -eq 1) {
        return $arr
    }

    # 変数の初期化
    # Note: 配列の先頭の値をピボットとして選択する
    $pivot = $arr[0]
    $arr1 = @()
    $arr2 = @()

    # ピボットに応じて各配列への分配を行う
    # Note: ピボット値よりも小さなものを$arr1, 大きなものを$arr2に格納する
    foreach ($item in ($arr | Select-Object -skip 1)) {
        if ($item -lt $pivot) {
            $arr1 += $item
        } else {
            $arr2 += $item
        }
    }

    # クイックソートの適用(再帰)
    # Note: 配列として関数からの返り値を受け取るには'@'を追加する
    $result = @(Get-QuickSort($arr1)) + @($pivot) + @(Get-QuickSort($arr2))
    return $result
}

# 乱数値の配列を取得(要素数20/値域:1～100)
$numArray = @()
0..20 | Foreach-Object { $numArray += (Get-Random -Minimum 1 -Maximum 100) }

# 配列へのクイックソート関数の適用
$sortedArray = @(Get-QuickSort($numArray))

# ソート前後の配列を表示する
Write-Host "Input: ${numArray}"
Write-Host "Output: ${sortedArray}"
