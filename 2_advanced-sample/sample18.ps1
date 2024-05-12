# ビープ音の設定
# Note: ミリ秒表記
$beepUnitHeltz = 800
$beepUnitTime = 200

# モールス信号の変換用連想配列
$morseCodeDict = @{
    # アルファベット
    "A" = ".-"; "B" = "-..."; "C" = "-.-."; "D" = "-..";
    "E" = "."; "F" = "..-."; "G" = "--."; "H" = "....";
    "I" = ".."; "J" = ".---"; "K" = "-.-"; "L" = ".-..";
    "M" = "--"; "N" = "-."; "O" = "---"; "P" = ".--.";
    "Q" = "--.-"; "R" = ".-."; "S" = "..."; "T" = "-";
    "U" = "..-"; "V" = "...-"; "W" = ".--"; "X" = "-..-";
    "Y" = "-.--"; "Z" = "--..";
    # 数字
    "1" = ".----"; "2" = "..---"; "3" = "...--";
    "4" = "....-"; "5" = "....."; "6" = "-....";
    "7" = "--..."; "8" = "---.."; "9" = "----."; "0" = "-----"
    # 記号
    "." = ".-.-.-"; "," = "--..--"; ":" = "---..."; "?" = "..--..";
    "'" = ".----."; "-" = "-....-"; "(" = "-.--."; ")" = "-.--.-";
    "/" = "-..-."; "=" = "-...-"; "+" = ".-.-."; '"' = ".-..-.";
    '@' = ".--.-.";
    # スペース
    " " = "~"
}

# 変換対象の文字列の入力
$rawInputString = Read-Host "input string"
$inputString = $rawInputString.ToUpper()

# 入力文字列の正当性チェック
$exitFlag = $false
foreach ($char in $inputString.ToCharArray()) {
    if (-not $morseCodeDict.Contains([string]$char)) {
		Write-Error "不正な文字があります: '${char}'"
        $exitFlag = $true
    }
}
if ($exitFlag) { exit }

# 入力文字列のモールス信号への変換
$morseCodeArray = @()
$morseCodeString = ""
foreach ($word in $inputString.Split()) {
    $tmpCodeArray = $()
    foreach ($char in $word.ToCharArray()) {
        $code = $morseCodeDict[[string]$char]
        $tmpCodeArray += $code
        $tmpCodeArray += " "
    }
    $morseCodeArray += ,$tmpCodeArray
    $morseCodeString += $tmpCodeArray -join " "
}

# モールス信号文字列の出力
Write-Host $morseCodeString

# ビープ音でのモールス信号出力
foreach($tmpCodeArray in $morseCodeArray) {
    foreach($codeChunk in $tmpCodeArray) {
        foreach ($char in $codeChunk.ToCharArray()) {
            $code = [string]$char
            if ($code -eq ".") {
                # 短いビープ音を出力("トン"の音)
                [System.Console]::Beep(
                    $beepUnitHeltz, $beepUnitTime)
            } elseif ($code -eq "-") {
                # 長いビープ音を出力("ツー"の音)
                [System.Console]::Beep(
                    $beepUnitHeltz, $beepUnitTime * 3)
            }

            # 信号スペース間の無音時間
            Start-Sleep -M $beepUnitTime
        }
    }

    # 単語間スペースの無音時間
    Start-Sleep -M ($beepUnitTime * 6)
}
