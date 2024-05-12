# スクリプトの引数定義
Param(
    [string[]] $inputPath,  # 入力フォルダパス
    [string] $outputPath    # 出力ファイルパス
)

# 出力先パスの確認
if ($outputPath -eq "") {
    Write-Error "出力先パスを指定してください"
    return
} elseif (Test-Path $outputPath) {
    Write-Error "${outputPath} はすでに存在しています"
    return
}

# 入力ファイル数の確認
$inputPDFs = @($inputPath)
Write-Host $inputPDFs
if ($inputPDFs.Count -le 1) {
    Write-Error "2つ以上のファイルパスを入力してください"
    return
}

# PDFのマージ処理実行
pdftk $inputPath cat output $outputPath
Write-Host "ファイル出力先: ${outputPath}" -ForegroundColor Cyan
