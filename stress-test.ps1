function Start-StressMenu {
    Clear-Host
    Write-Host "--- Windows Hardware Stress Tool ---" -ForegroundColor Cyan
    Write-Host "1. Stress CPU (Multi-threaded)"
    Write-Host "2. Stress RAM (Memory Allocation)"
    Write-Host "3. Stress Hard Drive (I/O Write/Delete)"
    Write-Host "4. Stop All Tests & Cleanup"
    Write-Host "5. Exit"
    
    $choice = Read-Host "`nSelect an option (1-5)"

    switch ($choice) {
        1 { Start-CPUStress }
        2 { Start-RAMStress }
        3 { Start-DiskStress }
        4 { Stop-AllStress }
        5 { exit }
        Default { Start-StressMenu }
    }
}

function Start-CPUStress {
    $cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    Write-Host "Starting CPU stress on $cores threads..." -ForegroundColor Yellow
    for ($i = 0; $i -lt $cores; $i++) {
        Start-Job -ScriptBlock { while($true){ $result = 1.23 * 4.56 } } | Out-Null
    }
    Write-Host "CPU is now under load. Check Task Manager." -ForegroundColor Green
    Pause; Start-StressMenu
}

function Start-RAMStress {
    $amountGB = Read-Host "How many GB of RAM to consume?"
    Write-Host "Allocating $amountGB GB of RAM..." -ForegroundColor Yellow
    $script:ramBuffer = New-Object Byte[] ($amountGB * 1GB)
    for($i=0; $i -lt $script:ramBuffer.Length; $i++){ $script:ramBuffer[$i] = 1 }
    Write-Host "RAM allocated. Check Task Manager." -ForegroundColor Green
    Pause; Start-StressMenu
}

function Start-DiskStress {
    Write-Host "Starting Disk I/O stress (Writing/Deleting temp files)..." -ForegroundColor Yellow
    $testPath = "$env:TEMP\stress_test_file.tmp"
    $script:diskJob = Start-Job -ScriptBlock {
        param($path)
        $data = New-Object Byte[] 100MB
        while($true) {
            [System.IO.File]::WriteAllBytes($path, $data)
            Remove-Item $path -ErrorAction SilentlyContinue
        }
    } -ArgumentList $testPath
    Write-Host "Disk stress running in background." -ForegroundColor Green
    Pause; Start-StressMenu
}

function Stop-AllStress {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
    $script:ramBuffer = $null
    [System.GC]::Collect()
    Write-Host "All tests stopped and memory cleared." -ForegroundColor Cyan
    Pause; Start-StressMenu
}

Start-StressMenu
