<img width="306" height="109" alt="stress-test" src="https://github.com/user-attachments/assets/01216933-9ee3-4104-87d2-a3d03a3df04a" />

```
function Start-StressMenu {
    Clear-Host
    Write-Host "--- Windows Hardware Stress Tool v2 ---" -ForegroundColor Cyan
    Write-Host "Status: $( (Get-Job | Where-Object { $_.State -eq 'Running' }).Count ) Tests Running" -ForegroundColor Gray
    Write-Host "1. Start CPU Stress"
    Write-Host "2. Start RAM Stress (Allocates 2GB blocks)"
    Write-Host "3. Start Disk Stress"
    Write-Host "4. STOP ALL TESTS" -ForegroundColor Red
    Write-Host "5. Exit"
    
    $choice = Read-Host "`nChoice"

    switch ($choice) {
        1 { Start-CPUStress; Start-StressMenu }
        2 { Start-RAMStress; Start-StressMenu }
        3 { Start-DiskStress; Start-StressMenu }
        4 { Stop-AllStress; Start-StressMenu }
        5 { Stop-AllStress; exit }
        Default { Start-StressMenu }
    }
}

function Start-CPUStress {
    $cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    Write-Host "Launching $cores CPU stress threads..." -ForegroundColor Yellow
    for ($i = 0; $i -lt $cores; $i++) {
        Start-Job -Name "CPU_STRESS" -ScriptBlock { while($true){ $result = 1.23 * 4.56 } } | Out-Null
    }
}

function Start-RAMStress {
    $gb = Read-Host "How many GB to allocate? (Enter number only)"
    Write-Host "Allocating memory... this may take a moment." -ForegroundColor Yellow
    # We run this in a job so the menu stays responsive
    Start-Job -Name "RAM_STRESS" -ScriptBlock {
        param($size)
        $script:buffer = New-Object Byte[] ($size * 1GB)
        for($i=0; $i -lt $script:buffer.Length; $i++){ $script:buffer[$i] = 1 }
        while($true) { Start-Sleep -Seconds 10 } # Keep job alive
    } -ArgumentList $gb | Out-Null
}

function Start-DiskStress {
    Write-Host "Launching Disk I/O stress..." -ForegroundColor Yellow
    $testPath = "$env:TEMP\stress_test_file.tmp"
    Start-Job -Name "DISK_STRESS" -ScriptBlock {
        param($path)
        $data = New-Object Byte[] 100MB
        while($true) {
            [System.IO.File]::WriteAllBytes($path, $data)
            Remove-Item $path -ErrorAction SilentlyContinue
        }
    } -ArgumentList $testPath | Out-Null
}

function Stop-AllStress {
    Write-Host "Stopping all background tasks..." -ForegroundColor Red
    # 1. Stop the named jobs
    Get-Job -Name "CPU_STRESS", "RAM_STRESS", "DISK_STRESS" | Stop-Job -PassThru | Remove-Job
    
    # 2. Force cleanup of memory
    [System.GC]::Collect()
    
    # 3. Cleanup temp disk files
    $testPath = "$env:TEMP\stress_test_file.tmp"
    if (Test-Path $testPath) { Remove-Item $testPath -Force -ErrorAction SilentlyContinue }
    
    Write-Host "All tests cleared!" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

Start-StressMenu
```
