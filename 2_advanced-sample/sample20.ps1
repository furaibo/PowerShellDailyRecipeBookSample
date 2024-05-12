# アセンブリの読み込み
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# テトリスブロック(テトリミノ)の情報を格納するクラス
class Block {
    [int] $IPos
    [int] $JPos
    [string] $Name
    [int[]] $RotateCenter
    [int[][]] $BlockPosArray
    
    Block($iPos, $jPos, $name, $rotateCenter, $blockPosArray) {
        $this.IPos = $ipos
        $this.JPos = $jpos
        $this.Name = $name
        $this.RotateCenter = $rotateCenter
        $this.BlockPosArray = $blockPosArray
    }
}

# テトリス盤面・操作に関するクラス
class Tetris {
    # 初期設定
    [int] $BoardWidth = 10              # 盤面の幅
    [int] $BoardHeight = 15             # 盤面の高さ
    [int] $InitBlockIPos = 0            # テトリミノの初期位置(縦方向)
    [int] $InitBlockJPos = 4            # テトリミノの初期位置(横方向)
    [int] $StayMilliSecondInit = 600    # テトリミノ固定化までの時間(ms)
    [int] $ShiftMillSecondSpan = 100    # 移動可能な最小間隔(ms)
    [int] $RotateMilliSecondSpan = 100  # 回転可能な最小間隔(ms)
    [int] $UnitMilliSecond = 50         # 処理受付の単位時間(ms)

    # 出現させるテトリミノの定義
    [PSCustomObject] $NewBlockPatternArray = @(
        @{ "pos" = @(@(-1,-1), @(0,-1), @(0,0), @(0,1));
            "center" = @(0,0); "name" = "L-Left"; },
        @{ "pos" = @(@(0,-1), @(0,0), @(0,1), @(-1,1));
            "center" = @(0,0); "name" = "L-Right"; },
        @{ "pos" = @(@(-1,-1), @(-1,0), @(0,0), @(0,1));
            "center" = @(0,0); "name" = "S-Left" },
        @{ "pos" = @(@(0,-1), @(0,0), @(-1,0), @(-1,1));
            "center" = @(0,0); "name" = "S-Right" },
        @{ "pos" = @(@(0,-1), @(-1,0), @(0,0), @(0,1));
            "center" = @(0,0); "name" = "T" },
        @{ "pos" = @(@(0,0), @(0,1), @(1,1), @(1,0));
            "center" = @(0.5,0.5); "name" = "O" },
        @{ "pos" = @(@(0,-1), @(0,0), @(0,1), @(0,2));
            "center" = @(0.5,0.5); "name" = "I" }
    )

    # フラグ管理用変数
    [bool] $GameOver = $false
    [bool] $BlockActive = $false

    # カウント用変数
    [int] $Level = 1
    [int] $Turn = 0
    [int] $Score = 0
    [int] $StayCount = 0
    [int] $StayMilliSecondLimit = 600
    [int] $LastShiftMilliSecond = 0
    [int] $LastRotateMilliSecond = 0

    # 盤面情報保存用
    [int[][]] $BoardArray
    [string] $BoardStatusString

    # テトリミノ情報保存用
    [Block] $CurrentBlock
    [Block] $NextBlock
    [Block[]] $ReservedBlocks

    # コンストラクタ
    Tetris() {
        # 盤面情報・テトリミノの初期化
        $this.BoardArray = [int[][]]::new($this.BoardHeight, $this.BoardWidth)
        $this.ReservedBlocks = @()
        $this.NextBlock = $this.GetNewBlock()
    }

    # 配列ディープコピー作成用メソッド
    [System.Collections.ArrayList] DeepCopyArray($array) {
        return [Management.Automation.PSSerializer]::DeSerialize(
            [Management.Automation.PSSerializer]::Serialize($array))
    }

    # 次の操作対象テトリミノをランダムで決定・取得
    [Block] GetNewBlock() {
        if ($this.ReservedBlocks.Length -le 1) {
            # テトリミノ7種が一巡するようにリザーブに追加
            foreach ($i in (0..6 | Get-Random -Count 7)) {
                $blockInfo = $this.NewBlockPatternArray[$i]
                $block = [Block]::new(
                    $this.InitBlockIPos, $this.InitBlockJPos,
                    $blockInfo["name"], $blockInfo["center"],
                    $blockInfo["pos"])
                $this.ReservedBlocks += $block
            }
        }
    
        # 次のテトリミノ情報を取得
        $newBlock = $this.ReservedBlocks[0]
        $this.ReservedBlocks = `
            $this.ReservedBlocks[1..($this.ReservedBlocks.Length-1)]
            
        return $newBlock
    }

    # 操作対象・ネクストとなるテトリミノの入れ替え処理
    [void] SwitchNextBlock() {
        # set next block
        $this.CurrentBlock = $this.NextBlock
        # get new block
        $this.NextBlock = $this.GetNewBlock()
    }

    # 盤面の描画
    [void] DrawTetrisBoard() {
        # 盤面およびスコアボードの描画
        Write-Host $this.GetCurrentBoardString()

        # デバッグ用表示(必要に応じてコメントアウト解除)
        #Write-Host $this.GetCurrentStatusString()
    }

    # 盤面情報の文字列データ化
    [string] GetCurrentStatusString() {
        $outputStr = ""
        $outputStr += "Turn:$($this.Turn)`n"
        $outputStr += "iPos:{0}, jPos:{1}`n" `
            -f $this.CurrentBlock.IPos, $this.CurrentBlock.JPos
        $outputStr += $this.BoardStatusString
        return $outputStr
    }

    # 現在の盤面情報の文字列データ取得
    [string] GetCurrentBoardString() {
        $boardLineArray = @()

        # 現在の盤面のディープコピーを作成する
        $tempBoardArray = $this.DeepCopyArray($this.BoardArray)

        # 現在操作中のテトリミノを盤面の配列情報に一旦反映する
        if ($this.BlockActive) {
            foreach($pos in $this.CurrentBlock.BlockPosArray) {
                $i = $this.CurrentBlock.IPos + $pos[0]
                $j = $this.CurrentBlock.JPos + $pos[1]
                if ($i -ge 0 -and $j -ge 0) { $tempBoardArray[$i][$j] = 1 }
            }
        }

        # 盤面情報の配列から文字列を作成
        foreach($row in $tempBoardArray) {
            $line = "|"

            foreach($cell in $row) {
                if ($cell -eq 0) {
                    $line += " "
                } else {
                    $line += "#"
                }
            }
            $line += "|"
            $boardLineArray += $line
        }
        $line = "=" * ($this.BoardWidth + 2)
        $boardLineArray += $line

        # ネクストのテトリミノを表示
        # Note: 1行だけANSIエスケープシーケンスで行削除処理
        $boardLineArray[1] += "   [Next]"
        $boardLineArray[2] += "   $([char]0x1B)[K{0}" -f $this.NextBlock.Name

        # 現在のスコアとレベルを表示
        $boardLineArray[4] += "   [Score]"
        $boardLineArray[5] += "   {0:0000}" -f $this.Score
        $boardLineArray[7] += "   [Level]"
        $boardLineArray[8] += "   {0}" -f $this.Level

        # 画面上へカーソルを戻すANSIエスケープシーケンス追加
        # Note: Clear-Hostを使わずに画面描画するための処置
        $boardStr = "$([char]0x1B)[0d"

        # 文字列の結合
        $boardStr += ($boardLineArray -join "`n")
        return $boardStr
    }

    # プレイヤー操作局面の進行
    [bool] GoPlayerActionPhase() {
        $stayMilliSecond = 0
        $prevIPos = $this.CurrentBlock.IPos

        # 操作用のキーコードの定義
        $keyLeft  = [System.Windows.Input.Key]::Left
        $keyRight = [System.Windows.Input.Key]::Right
        $keyDown  = [System.Windows.Input.Key]::Down
        $keySpace = [System.Windows.Input.Key]::Space
        $keyA = [System.Windows.Input.Key]::A
        $keyD = [System.Windows.Input.Key]::D
        $keyS = [System.Windows.Input.Key]::S

        # プレイヤー入力の受け付け
        while(($stayMilliSecond -lt $this.StayMilliSecondLimit)) {
            # キー入力に応じてテトリミノの移動処理
            if ([System.Windows.Input.Keyboard]::IsKeyDown($keyLeft) `
                -or [System.Windows.Input.Keyboard]::IsKeyDown($keyA)) {
                if ($this.LastShiftMilliSecond -ge $this.RotateMilliSecondSpan) {
                    $this.MoveBlockToLeft()
                    $this.LastShiftMilliSecond = 0
                }
            } elseif ([System.Windows.Input.Keyboard]::IsKeyDown($keyRight) `
                -or [System.Windows.Input.Keyboard]::IsKeyDown($keyD)) {
                if ($this.LastShiftMilliSecond -ge $this.RotateMilliSecondSpan) {
                    $this.MoveBlockToRight()
                    $this.LastShiftMilliSecond = 0
                }
            } elseif ([System.Windows.Input.Keyboard]::IsKeyDown($keyDown) `
                -or [System.Windows.Input.Keyboard]::IsKeyDown($keyS)) {
                if ($this.LastShiftMilliSecond -ge $this.RotateMilliSecondSpan) {
                    $this.MoveBlockToDown()
                    $this.LastShiftMilliSecond = 0
                }
            } elseif ([System.Windows.Input.Keyboard]::IsKeyDown($keySpace)) {
                if ($this.LastRotateMilliSecond -ge $this.RotateMilliSecondSpan) {
                    $this.RotateBlock($true)
                    $this.LastRotateMilliSecond = 0
                }
            }

            # 縦方向の座標の変化が起こったかどうかの判定
            if ($this.CurrentBlock.IPos -ne $prevIPos) {
                return $true
            }

            # テトリス盤面の描画
            $this.DrawTetrisBoard()

            # 経過秒数の追加
            $stayMilliSecond += $this.UnitMilliSecond
            $this.LastShiftMilliSecond += $this.UnitMilliSecond
            $this.LastRotateMilliSecond += $this.UnitMilliSecond
            Start-Sleep -m $this.UnitMilliSecond
        }

        return $false
    }

    # テトリス盤面を次の局面へと進める
    [void] GoNextPhase() {
        $this.BoardStatusString = ""

        # テトリミノが非アクティブ状態になっている場合の処理
        if (-not $this.BlockActive) {
            $nextBlockPosArray = $this.NextBlock.BlockPosArray

            # 次のテトリミノを出現させる空きスペースがあるかチェック
            if ($this.IsNewBlockAvailable($nextBlockPosArray)) {                
                # 次のテトリミノへの切り替え処理
                $this.SwitchNextBlock()
                $this.BlockActive = $true
                $this.BoardStatusString = "New Block!"
            } else {
                # ゲームオーバーのフラグを立てる
                $this.GameOver = $true
                $this.BoardStatusString = "Game Over!"
            }
            return
        }

        # 一定の時間経過でテトリミノの座標を下方向にシフトする
        if ($this.IsDownSpaceAvailable($this.CurrentBlock)) {
            $this.CurrentBlock.IPos++
        } else {
            # 現在操作中のテトリミノを非アクティブにし、固定化処理を行う
            $this.BlockActive = $false
            $this.RockDownCurrentBlock()
            $this.BoardStatusString = "Fixed!"

            # ライン消去処理とスコア加算を行う
            $eraseLineCount = $this.EraseLines()
            if ($eraseLineCount -gt 0) {
                $this.Score += $eraseLineCount

                # 一定スコアごとにレベルアップ
                $this.Level = [Math]::Floor($this.Score / 10) + 1
                $this.StayMilliSecondLimit = `
                    $this.StayMilliSecondInit - ($this.Level - 1) * 5

                # 盤面描画処理と一定時間スリープ
                $this.DrawTetrisBoard()
                Start-Sleep -m 50
            }
        }

        # 経過ターン数のカウントアップ
        $this.Turn++
    }

    # テトリミノ固定化(ロックダウン)処理
    [void] RockDownCurrentBlock() {
        foreach($pos in $this.CurrentBlock.BlockPosArray) {
            $i = $this.CurrentBlock.IPos + $pos[0]
            $j = $this.CurrentBlock.JPos + $pos[1]
            if ($i -lt 0) { continue }
            $this.BoardArray[$i][$j] = 1
        }
    }

    # ライン消去処理
    [int] EraseLines() {
        $eraseCount = 0
        $rowIndex = $this.BoardHeight - 1
        foreach ($_ in 1..($this.BoardHeight-1)) {
            # 対象となるラインがあるかをチェック
            if ($this.BoardArray[$rowIndex].Contains(0)) {
                $rowIndex--
            } else {
                # 各ライン消去
                $eraseCount++
                foreach ($i in $rowIndex..1) {
                    $this.BoardArray[$i] = $this.BoardArray[$i-1]
                }
                $this.BoardArray[0] = [int[]]::new($this.BoardWidth)
            } 
        }
        return $eraseCount
    }

    # 各種ステータスチェック用のメソッド群
    # ゲームオーバーかどうか
    [bool] IsGameOver() {
        return $this.GameOver
    }

    # 新しいテトリミノをいれるためのスペースが有るかどうか
    [bool] IsNewBlockAvailable($nextBlockPosArray) {
        foreach($pos in $nextBlockPosArray) {
            $i = $this.InitBlockIPos + $pos[0]
            $j = $this.InitBlockJPos + $pos[1]
            if ($i -lt 0) { continue }
            if ($this.BoardArray[$i][$j] -ne 0) { return $false }
        }
        return $true
    }

    # 現在捜査中のテトリミノから見て、指定した方向について空きスペースがあるか
    [bool] IsShiftSpaceAvailable([Block]$block, $iShift, $jShift) {
        foreach($pos in $block.BlockPosArray) {
            $i = $block.IPos + $pos[0] + $iShift
            $j = $block.JPos + $pos[1] + $jShift

            # 盤面や盤面端の境界情報に応じて、空きがない場合は$falseを返却する
            if ($i -gt ($this.BoardHeight - 1) -or
                $j -lt 0 -or $j -gt ($this.BoardWidth - 1)) {
                return $false
            } elseif ($this.BoardArray[$i][$j] -ne 0) {
                return $false
            }
        }       
        return $true
    }
    [bool] IsLeftSpaceAvailable([Block]$block) {
        return $this.IsShiftSpaceAvailable($block, 0, -1)
    }
    [bool] IsRightSpaceAvailable([Block]$block) {
        return $this.IsShiftSpaceAvailable($block, 0, 1)
    }
    [bool] IsDownSpaceAvailable([Block]$block) {
        return $this.IsShiftSpaceAvailable($block, 1, 0)
    }

    # プレイヤー入力によるテトリミノの移動処理
    [void] MoveBlockToLeft() {
        if ($this.IsLeftSpaceAvailable($this.CurrentBlock)) {
            $this.CurrentBlock.JPos--
        }
    }
    [void] MoveBlockToRight() {
        if ($this.IsRightSpaceAvailable($this.CurrentBlock)) {
            $this.CurrentBlock.JPos++
        }
    }
    [void] MoveBlockToDown() {
        if ($this.IsDownSpaceAvailable($this.CurrentBlock)) {
            $this.CurrentBlock.IPos++
        }
    }

    # プレイヤー入力によるテトリミノの回転処理
    [bool] RotateBlock($clockWise=$true) {
        $i = 0
        $j = 0
        $block = $this.CurrentBlock
        $rotateCenter = $block.RotateCenter
        $tempPosArray = @()

        foreach($pos in $block.BlockPosArray) {
            $iDiff = $pos[0] - $rotateCenter[0]
            $jDiff = $pos[1] - $rotateCenter[1]

            # 時計回りかどうかに応じて処理分岐
            if ($clockWise) {
                $i = $block.IPos + $jDiff + $rotateCenter[0]
                $j = $block.JPos - $iDiff + $rotateCenter[1]
                $tempPosArray += `
                    ,@((-$jDiff + $rotateCenter[0]),
                       ($iDiff + $rotateCenter[1]))
            } else {
                $i = $block.IPos - $jDiff + $rotateCenter[0]
                $j = $block.JPos + $iDiff + $rotateCenter[1]
                $tempPosArray += `
                    ,@(($jDiff + $rotateCenter[0]),
                       (-$iDiff + $rotateCenter[1]))
            }

            # 盤面や盤面端の境界情報に応じて、回転処理をせずに$falseを返却
            if ($i -lt 0 -or $i -gt ($this.BoardHeight - 1) -or
                $j -lt 0 -or $j -gt ($this.BoardWidth - 1)) {
                return $false
            } elseif ($this.BoardArray[$i][$j] -ne 0) {
                return $false
            }            
        }

        # 回転処理を行う
        $block.BlockPosArray = $tempPosArray

        return $true
    }
}

# テトリスの開始
$tetris = New-Object Tetris

# 画面のクリア
Clear-Host

# テトリスの処理: ゲームオーバー判定になるまで継続
while (-not $tetris.IsGameOver()) {
    # プレーヤーの操作受け付け処理
    # Note: このフェーズではプレーヤー操作可
    while ($tetris.GoPlayerActionPhase()) {}

    # テトリスの盤面進行処理(落下・ライン消去・テトリミノ結合処理)
    # Note: このフェーズではプレーヤー操作不可
    $tetris.GoNextPhase()

    # スリープ
    Start-Sleep -m 10
}
