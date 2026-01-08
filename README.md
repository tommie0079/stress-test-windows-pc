
<img width="1258" height="338" alt="stress-test" src="https://github.com/user-attachments/assets/60895024-6d04-4be4-aa2b-4895318b5fef" />

```
function Start-StressMenu {
    # Set this window to High Priority so it can 'interrupt' the stress test
    (Get-Process -Id $PID).PriorityClass = 'High'
    
    Clear-Host
    Write-Host "--- Windows Hardware Stress Tool v2.8 ---" -ForegroundColor Cyan
    $active = Get-Job -State Running
    if ($active) { Write-Host "ACTIVE TEST: $($active[0].Name)" -ForegroundColor Yellow }
    else { Write-Host "ACTIVE TEST: NONE (IDLE)" -ForegroundColor Green }

    Write-Host "`n1. Stress CPU (All Cores)"
    Write-Host "2. Stress RAM (80% Auto-Detect)"
    Write-Host "3. Stress Hard Drive (Direct I/O)"
    Write-Host "4. Stress Network (WiFi/Ethernet)"
    Write-Host "5. STOP ALL TESTS" -ForegroundColor Red
    Write-Host "6. Exit"
    
    $choice = Read-Host "`nSelect Option"

    # Auto-stop before starting new test to prevent overlap
    if ($choice -match '^[1-4]$') { Stop-AllStress -Silent }

    switch ($choice) {
        1 { Start-CPUStress; Start-StressMenu }
        2 { Start-RAMStress; Start-StressMenu }
        3 { Start-DiskStress; Start-StressMenu }
        4 { Start-NetworkStress; Start-StressMenu }
        5 { Stop-AllStress; Start-StressMenu }
        6 { Stop-AllStress; exit }
        Default { Start-StressMenu }
    }
}

function Start-CPUStress {
    $cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    Write-Host "Launching $cores threads. Your PC may become sluggish." -ForegroundColor Yellow
    for ($i = 0; $i -lt $cores; $i++) {
        # Using a heavy math loop in the background
        Start-Job -Name "CPU_STRESS" -ScriptBlock { 
            while($true){ $result = [math]::Sqrt([math]::Pow(1.234, 5.678)) } 
        } | Out-Null
    }
}

function Start-RAMStress {
    $os = Get-CimInstance Win32_OperatingSystem
    $freeGB = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $targetGB = [Math]::Round($freeGB * 0.8, 2)

    Write-Host "Filling $targetGB GB of RAM..." -ForegroundColor Yellow
    Start-Job -Name "RAM_STRESS" -ScriptBlock {
        param($sizeGB)
        $storage = New-Object System.Collections.Generic.List[Byte[]]
        for ($i = 0; $i -lt ($sizeGB * 10); $i++) {
            $chunk = New-Object Byte[] 100MB
            for ($j = 0; $j -lt $chunk.Length; $j += 4KB) { $chunk[$j] = 1 }
            $storage.Add($chunk)
        }
        while($true) { Start-Sleep -Seconds 10 }
    } -ArgumentList $targetGB | Out-Null
}

function Start-DiskStress {
    Write-Host "Stressing Disk... (Using 4 parallel streams)" -ForegroundColor Yellow
    for ($i = 1; $i -le 4; $i++) {
        Start-Job -Name "DISK_STRESS" -ScriptBlock {
            param($id)
            $path = "$env:TEMP\extreme_disk_$id.tmp"
            $data = New-Object Byte[] 250MB
            while($true) {
                # WriteThrough forces the hardware to work and bypasses RAM cache
                $stream = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::WriteThrough)
                $stream.Write($data, 0, $data.Length)
                $stream.Close()
            }
        } -ArgumentList $i | Out-Null
    }
}

function Start-NetworkStress {
    Write-Host "Stressing Network... (High Volume Download)" -ForegroundColor Yellow
    $url = "https://speed.cloudflare.com/__down?bytes=1000000000"
    for ($i = 1; $i -le 4; $i++) {
        Start-Job -Name "NET_STRESS" -ScriptBlock {
            param($target)
            $wc = New-Object System.Net.WebClient
            while($true) {
                try { $wc.DownloadData($target) | Out-Null } catch { Start-Sleep -Seconds 1 }
            }
        } -ArgumentList $url | Out-Null
    }
}

function Stop-AllStress {
    param([switch]$Silent)
    if (-not $Silent) { Write-Host "TERMINATING ALL STRESS PROCESSES..." -ForegroundColor Red }
    
    # 1. Stop the PowerShell Jobs
    Get-Job | Stop-Job -ErrorAction SilentlyContinue
    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
    
    # 2. Force kill any lingering background PowerShell processes used for the jobs
    $currentPid = $PID
    Get-Process "powershell" | Where-Object { $_.Id -ne $currentPid } | Stop-Process -Force -ErrorAction SilentlyContinue

    # 3. Cleanup files and memory
    [System.GC]::Collect()
    Get-ChildItem "$env:TEMP\extreme_disk_*.tmp" -ErrorAction SilentlyContinue | Remove-Item -Force
    
    if (-not $Silent) { 
        Write-Host "System Stabilized." -ForegroundColor Green
        Start-Sleep -Seconds 1 
    }
}

Start-StressMenu
```
