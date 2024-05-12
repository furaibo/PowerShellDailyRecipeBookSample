# スクリプトの引数定義
Param(
    [string]$inputPath,
    [switch]$random,
    [int]$width=20,
    [int]$height=20,
    [int]$limit=100
)

# ランダムな盤面データの作成
function Init-BoardRandom($wsize, $hsize) {
    $board = [int[][]]::New($hsize, $wsize)

    # Note: 3分の1程度が生きたセルとして生成されるようにする
    foreach ($i in 0..($hsize-1)) {
        foreach ($j in 0..($wsize-1)) {
            $value = (Get-Random -Minimum 1 -Maximum 100)
            if (($value % 3) -eq 0) {
                $board[$i][$j] = 1
            } else {
                $board[$i][$j] = 0
            }
        }
    }

    return $board
}

# 入力ファイルからの盤面データの作成
function Init-BoardFromInputFile($wsize, $hsize, $inputPath) {
    $board = [int[][]]::New($hsize, $wsize)
    $i, $j = 0, 0

    # Note: 生存しているセルは"o"として表記されているものとする
    foreach ($line in (Get-Content $inputPath)) {
        $charArray = $line.ToCharArray()
        $j = 0
        foreach ($c in $charArray) {
            if ($c -eq "o") {
                $board[$i][$j] = 1
            } else {
                $board[$i][$j] = 0
            }
            $j++
        }
        $i++
    }

    return $board
}

# 次の盤面データの取得
function Get-NextBoard($board, $wsize, $hsize) {
    $nextBoard = @()

    # 次のセル状態についての配列データを作成する
    foreach ($i in 0..($hsize-1)) {
        $row = @()

        foreach ($j in 0..($wsize-1)) {
            # セルの周囲マスのインデックス範囲を計算
            # Note: セルが盤面端にある場合に不正なインデックス指定を防ぐ
            $iStartIndex, $iEndIndex = `
                [math]::max(0, $i-1), [math]::min($hsize-1, $i+1)
            $jStartIndex, $jEndIndex = `
                [math]::max(0, $j-1), [math]::min($wsize-1, $j+1)

            # セルの周囲8マスの生存しているセルの数を計算する
            $aliveCellCount = 0
            foreach($x in $iStartIndex..$iEndIndex) {
                foreach($y in $jStartIndex..$jEndIndex) {
                    if (($x -ne $i) -or ($y -ne $j)) {
                        $aliveCellCount += $board[$x][$y]
                    }
                }
            }

            # 次の各セルの状態を決定
            $status = $board[$i][$j]
            if ($status -eq 0) {
                switch ($aliveCellCount) {
                    3 { $row += 1 }
                    default { $row += 0 }
                }
            } else {
                switch ($aliveCellCount) {
                    2 { $row += 1 }
                    3 { $row += 1 }
                    default { $row += 0 }
                }
            }
        }

        $nextBoard += ,$row
    }

    return $nextBoard
}

# 盤面の状態を出力する
# Note: 生存しているセルは"o"、そうでなければ"-"で表示する
function Show-BoardStatus($turn, $board) {
    # 画面上へカーソルを戻すANSIエスケープシーケンス追加
    # Note: Clear-Hostを使わずに画面描画するための処置
    $printStr = "$([char]0x1B)[0d"

    # 経過ターンの表示
    $printStr += "Turn: ${turn}`n"
    
    # 盤面状態の表示
    foreach ($row in $board) {
        foreach ($cell in $row) {
            if ($cell -eq 1) {
                $printStr += "o"
            } else {
                $printStr += "-"
            }
        }
        $printStr += "`n"
    }
    
    Write-Host $printStr
}

# 盤面のサイズの確認
# Note: ここでは盤面の幅は5以上100以下であるものとする
$isValidBoard = $true
if (($width -lt 5) -or ($width -gt 100)) {
    Write-Error "盤面の幅は5～100の範囲で入力してください"
    $isValidBoard = $false
}
if (($height -lt 5) -or ($height -gt 100)) {
    Write-Error "盤面の高さは5～100の範囲で入力してください"
    $isValidBoard = $false
}
if (-not $isValidBoard) { return }

# 盤面データの初期化
$board = @()
if ($random) {
    # ランダムに盤面データを初期化
    $board = Init-BoardRandom $width $height
} else {
    # 入力ファイルのパスの確認 
    if ($inputPath -eq "" -or (-not (Test-Path $inputPath))) {
        Write-Error "入力ファイルが見つかりません"
        exit
    }

    # 入力ファイルにもとづいて盤面データを初期化 
    $board = Init-BoardFromInputFile $width $height $inputPath
}

# ライフゲームの実行
Clear-Host
foreach($turn in 0..$limit) {
    Show-BoardStatus $turn $board
    Start-Sleep 1
    $board = Get-NextBoard $board $width $height
}
