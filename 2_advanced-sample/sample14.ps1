# スクリプトの引数定義 
Param(
    [string] $inputPath,
    [switch] $showSecret=$false
)

# 関数の定義 
function Convert-Base32ToByte($secret) {
    $base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    $bits = ""
    $output = @()

    # Base32のRFC定義にもとづくビット値の計算
    foreach ($char in $secret.ToUpper().ToCharArray()) {
        $bits += [Convert]::ToString(
            $base32Chars.IndexOf($char), 2).PadLeft(5, '0')
    }

    # 8ビットのチャンクをバイト値に変換、最後のビットは無視する
    for ($i = 0; $i -le ($bits.Length - 8); $i += 8) {
        $output += [Byte][Convert]::ToInt32(
            $bits.Substring($i, 8), 2)
    }
    return $output
}

function Get-OTPCodeInfo($secret) {
    # Unix時間の計算・ハッシュ関数へ渡す値の準備
    $now = Get-Date
    $numberOfSeconds = ([datetimeoffset]$now).ToUnixTimeSeconds()
    $numberOfIntervals = [Convert]::ToInt64([Math]::Floor($numberOfSeconds / 30))
    $remainingSec = 30 - ($numberOfSeconds % 30)
    $validDeadLine = $now.AddSeconds($remainingSec)

    # Unix時間由来のバイト列取得
    $intervalByteArray = [BitConverter]::GetBytes($numberOfIntervals)
    [Array]::Reverse($intervalByteArray)

    # HMAC-SHA1によるハッシュ処理
    $objHMACSHA1 = New-Object -TypeName System.Security.Cryptography.HMACSHA1
    $objHMACSHA1.key = Convert-Base32ToByte($secret)
    $hashByteArray = $objHMACSHA1.ComputeHash($intervalByteArray)

    # ハッシュ値周りの計算処理
    $offset = $hashByteArray[-1] -band 0xf
    $otpBits = (($hashByteArray[$offset]   -band 0x7f) -shl 24) -bor 
               (($hashByteArray[$offset+1] -band 0xff) -shl 16) -bor
               (($hashByteArray[$offset+2] -band 0xff) -shl  8) -bor
               (($hashByteArray[$offset+3] -band 0xff))

    # 下位6桁をコードとして取得
    $otpInt  = $otpBits % 1000000
    $otpCode = $otpInt.ToString().PadLeft(6, '0')

    # 返却値
    $info = @{
        RemainingSec = $remainingSec;
        ValidDeadline = $validDeadLine;
        OTPCode = $otpCode;
    }

    return $info
}

# 入力パスの存在確認
if (-not (Test-Path -Path $inputPath -PathType Leaf)) {
    Write-Error "入力ファイルが見つかりません"
    exit
}

# QRコードからの文字列読み込み
# Note: zbarimg内部でQRコードの読込処理を行ってくれる
$zbarResult = (zbarimg $inputPath --quiet)
if ("ERROR" -match $zbarResult) {
    Write-Error "読み込みに失敗しました。ファイル形式を確認してください"
    exit
}

# 秘密鍵の文字列データの取得
# Note: 取得した文字列中の "secret=" 以下に秘密鍵が格納されている
$match = [regex]::Matches($zbarResult, "QR-Code:.+secret\=(.+?)\&.+")
$secret = $match.Groups[1].Value

# ワンタイムパスワードの取得 
$info = Get-OTPCodeInfo $secret

# ワンタイムパスワードおよび有効期限情報の出力
Write-Host "[ワンタイムパスワード情報]"
if ($showSecret) { Write-Host "- 秘密鍵: ${secret}" }
Write-Host "- OTPCode: $($info["OTPCode"])"
Write-Host "- 有効期限: $($info["ValidDeadline"])"
Write-Host "- 残り時間: $($info["RemainingSec"]) sec"
