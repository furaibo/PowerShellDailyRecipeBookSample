
# 関数定義
function Get-Factorial ($n) {
    if ($n -eq 0) {
        return 1
    }
    $fact = 1
    1..$n | ForEach-Object { $fact *= $_ }
    return $fact
}

# 繰り返し計算
# Note: 計算値の精度を向上させるためdecimal型を使用
foreach ($iterCount in 1..5) {
    # 分母部分の計算
    [decimal]$sum = 0
    foreach ($n in 0..$iterCount) {
        $sum += `
            ((Get-Factorial (4*$n)) * (26390 * $n + 1103)) / `
            [math]::pow(([math]::pow(4, $n) * [math]::pow(99, $n) * (Get-Factorial $n)), 4)
    }
    [decimal]$denom = 2 * [math]::sqrt(2) * $sum / (99 * 99)

    # 円周率の概算値の表示(※有効桁数25桁まで)
    $pi_value = 1 / $denom
    $text = "Piの近似値: {0:N25} (n={1})" -f $pi_value, $iterCount
    Write-Host $text
}