# 変数の初期化
$hitCount = 0
$tryLimit = 100000

# 繰り返し計算
foreach($_ in 1..$tryLimit) {
    # 乱数の生成
    $x = Get-Random -Minimum 0.0 -Maximum 1.0
    $y = Get-Random -Minimum 0.0 -Maximum 1.0
    $dist = [math]::sqrt($x*$x + $y*$y)

    # 半径1の円(単位円)内にある点の数え上げ
    if ($dist -le 1) {
        $hitCount++
    }
}

# 円周率の概算値の表示(※有効桁数10桁まで)
$pi_value = [decimal](4 * $hitCount / $tryLimit)
$text = "Piの近似値: {0:N10}" -f $pi_value
Write-Host $text