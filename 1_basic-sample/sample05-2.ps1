# 変数の初期化
$a = 1
$b = 1 / [math]::sqrt(2)
$t = 1 / 4
$p = 1

# 繰り返し計算
# Note: 計算値の精度を向上させるためdecimal型を使用
foreach ($iterCount in 1..5) {
    # 次の数値の計算
    $a_next = [decimal](($a + $b) / 2)
    $b_next = [decimal]([math]::sqrt($a * $b))
    $t_next = [decimal]($t - $p * [math]::pow($a - $a_next, 2))
    $p_next = [decimal](2 * $p)

    # 数値の置き換え
    $a = $a_next
    $b = $b_next
    $t = $t_next
    $p = $p_next

    # 円周率の概算値の表示(※有効桁数25桁まで)
    $pi_value = [decimal]([math]::pow($a + $b, 2) / (4 * $t))
    $text = "Piの近似値: {0:N25} ({1}回目)" -f $pi_value, $iterCount
    Write-Host $text
}	