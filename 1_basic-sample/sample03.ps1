# 開始時メッセージ
Write-Host "数当てゲーム: 1～100の間の数字を当ててください"

# 変数の初期化
$count = 0
$ans = (Get-Random -Minimum 1 -Maximum 100)

# 数当てゲームのループ処理 
while($true) {
    # ユーザ入力を受け付ける/入力値の型チェック(入力が不正ならやりなおし)
    $rawInput = Read-Host "1～100の間で数字を入力してください"
    if (-not ([int]::TryParse($rawInput, [ref]$null))) {
        continue
    }

    # 入力された数値が1～100の範囲内かチェック(入力が不正ならやりなおし)
    $inputNumber = [int]$rawInput
    if ($inputNumber -le 0 -or $inputNumber -gt 100) {
        continue
    }

    # 試行回数のカウント
    $count++

    # 数値および表示メッセージの判定
    if ($inputNumber -lt $ans) {
        Write-Host "もっと大きな数です"
    } elseif ($inputNumber -eq $ans) {
        Write-Host "正解です!"
        break
    } else {
        Write-Host "もっと小さな数です"
    }
}

# 試行回数の表示
Write-Host "試行回数: ${count}"
