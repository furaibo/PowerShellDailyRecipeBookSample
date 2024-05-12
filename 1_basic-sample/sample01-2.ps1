1..100 | % {
    if ($_ % 3 -eq 0 -and $_ % 5 -eq 0) { Write-Host "FizzBuzz" }
    elseif ($_ % 3 -eq 0) { Write-Host "Fizz" }
    elseif ($_ % 5 -eq 0) { Write-Host "Buzz" }
    else { Write-Host $_ }
}