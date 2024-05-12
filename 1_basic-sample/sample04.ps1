# 積分の近似値を求める関数の定義
function Get-Calculus {
    # 引数の定義
    # Note: 関数を渡すため、Param句を使った引数指定としている
    # - $func: 積分を実行する関数
    # - $lower: 積分区間の下端
    # - $upper: 積分区間の上端
    Param($func, $lower, $upper)

    # 変数の初期化
    # Note: 積分区間の分割数は変数$divLimitで定義する
    $divLimit = 100000
    [double]$width = ([math]::abs($upper - $lower) / $divLimit)
    [double]$sum = 0

    # 積分の実行
    # Note: 関数実行時の戻り値型のトラブルを避けるにはInvoke-Commandの利用を推奨
    foreach ($i in 0..$divLimit) {
        $x = $lower + $width * $i
        $y = Invoke-Command $func -ArgumentList $x
        $diff = $y * $width
        $sum += $diff
    }

    return $sum
}

# 値を計算する関数の定義
function Func1($x) { return [math]::sin($x) }
function Func2($x) { return [math]::pow($x,3) + [math]::pow($x,2) + $x + 1 }

# 積分区間の定義
$lower = 0
$upper = 3

# 積分の計算を実行
# Note: 関数を変数として渡す時は "$function:(関数名)" とする。
$result1 = Get-Calculus -func $function:Func1 -lower $lower -upper $upper
$result2 = Get-Calculus -func $function:Func2 -lower $lower -upper $upper

# 結果の表示
Write-Host "Result 1: $result1"
Write-Host "Result 2: $result2"