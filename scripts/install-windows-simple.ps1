# PowerShell script to download and install AgbCloud CLI binary

# Determine architecture
$architecture = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { "amd64" } elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }

# Define version and download URL
$version = if ($env:AGBCLOUD_VERSION) { $env:AGBCLOUD_VERSION } else { "latest" }
$baseUrl = if ($env:AGBCLOUD_DOWNLOAD_URL) { $env:AGBCLOUD_DOWNLOAD_URL } else { "https://agbcloud-internal.oss-cn-hangzhou.aliyuncs.com" }
$destination = if ($env:AGBCLOUD_PATH) { $env:AGBCLOUD_PATH } else { "$env:APPDATA\bin\agbcloud" }

# Get latest version if needed
if ($version -eq "latest") {
    try {
        Write-Host "🔍 Checking for latest version..."
        $latestInfo = Invoke-RestMethod -Uri "$baseUrl/latest.json" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($latestInfo -and $latestInfo.version) {
            $version = $latestInfo.version
        } else {
            $version = "dev-$(Get-Date -Format 'yyyyMMdd-HHmm')"
        }
    } catch {
        Write-Host "⚠️  Could not fetch latest version, using fallback"
        $version = "dev-$(Get-Date -Format 'yyyyMMdd-HHmm')"
    }
}

$downloadUrl = "$baseUrl/agbcloud-$version-windows-$architecture.exe"

Write-Host "🚀 Installing AgbCloud CLI..."
Write-Host ""

# Display installation info
Write-Host "📋 Installation Details:"
Write-Host "   Version: $version"
Write-Host "   Architecture: $architecture"
if ($env:AGBCLOUD_PATH) {
    Write-Host "   Custom installation directory: $destination"
} else {
    Write-Host "   Default installation directory: $destination"
    Write-Host "   💡 You can override this by setting the AGBCLOUD_PATH environment variable."
}
Write-Host ""

# Create destination directory if it doesn't exist
try {
    if (!(Test-Path -Path $destination)) {
        Write-Host "📁 Creating installation directory at $destination"
        New-Item -ItemType Directory -Force -Path $destination -ErrorAction Stop | Out-Null
        Write-Host ""
    }
} catch {
    Write-Error "❌ Failed to create installation directory: $_"
    exit 1
}

# File to download
$outputFile = "$destination\agbcloud.exe"

# Check if already installed and get current version
$upgrading = $false
if (Test-Path $outputFile) {
    try {
        $currentVersion = & $outputFile version --short 2>$null
        if ($currentVersion -eq $version) {
            Write-Host "✅ AgbCloud CLI $version is already installed!"
            Write-Host "   Location: $outputFile"
            Write-Host ""
            Write-Host "🎉 You're all set! Use 'agbcloud --help' to get started."
            exit 0
        } else {
            Write-Host "📦 Upgrading from $currentVersion to $version"
            $upgrading = $true
        }
    } catch {
        Write-Host "📦 Existing installation found, upgrading..."
        $upgrading = $true
    }
    Write-Host ""
}

# Download the file with progress
try {
    if ($upgrading) {
        Write-Host "⬇️  Downloading AgbCloud CLI update from $downloadUrl"
    } else {
        Write-Host "⬇️  Downloading AgbCloud CLI from $downloadUrl"
    }

    # Use Invoke-WebRequest with progress
    $ProgressPreference = 'Continue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -UseBasicParsing -ErrorAction Stop

    Write-Host ""
    Write-Host "✅ Download complete!"
} catch {
    Write-Error "❌ Failed to download AgbCloud CLI: $_"
    Write-Host "   Please check your internet connection and try again."
    Write-Host "   If the problem persists, visit: https://github.com/your-org/agbcloud-cli/releases"
    exit 1
}

Write-Host ""

# Set executable permissions (Windows doesn't need this, but good practice)
try {
    Write-Host "🔧 Setting up binary permissions..."
    # Try to set attributes, but don't fail if it doesn't work (constrained language mode)
    try {
        Set-ItemProperty -Path $outputFile -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        [System.IO.File]::SetAttributes($outputFile, 'Normal')
    } catch {
        # In constrained language mode, this might fail, but it's not critical
        Write-Host "   ⚠️  Could not set file attributes (this is usually fine)"
    }
} catch {
    # This shouldn't happen now, but keep as fallback
    Write-Host "   ⚠️  Could not set binary permissions (this is usually fine on Windows)"
}

Write-Host ""

# Add to PATH if not already present
try {
    Write-Host "🔧 Updating PATH..."
    
    # Try to get current PATH, handle constrained language mode
    try {
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
        if (-not $currentPath) { $currentPath = "" }
        
        $pathEntries = $currentPath -split ';' | ForEach-Object { $_.TrimEnd('\') }
        
        if (-not ($pathEntries | Where-Object { $_ -eq $destination })) {
            Write-Host "   Adding $destination to user PATH..."
            $newPath = if ($currentPath.EndsWith(';')) { "$currentPath$destination" } else { "$currentPath;$destination" }
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)
            Write-Host "✅ PATH updated successfully!"
            Write-Host "   💡 Please restart your terminal or run a new PowerShell session"
        } else {
            Write-Host "✅ Already in PATH"
        }
    } catch {
        Write-Host "   ⚠️  Could not automatically update PATH (constrained language mode)"
        Write-Host "   📝 Please manually add the following to your PATH:"
        Write-Host "      $destination"
        Write-Host ""
        Write-Host "   🔧 To add manually:"
        Write-Host "      1. Press Win+R, type 'sysdm.cpl', press Enter"
        Write-Host "      2. Click 'Environment Variables'"
        Write-Host "      3. Under 'User variables', select 'Path' and click 'Edit'"
        Write-Host "      4. Click 'New' and add: $destination"
        Write-Host "      5. Click OK to save"
    }
} catch {
    Write-Host "   ⚠️  PATH update failed, but installation completed"
    Write-Host "   📝 Please manually add to PATH: $destination"
}

Write-Host ""

# Test installation
Write-Host "🧪 Testing installation..."
try {
    $installedVersion = & $outputFile version --short 2>$null
    Write-Host "✅ Installation test successful!"
    Write-Host ""
    
    if ($upgrading) {
        Write-Host "🎉 AgbCloud CLI successfully upgraded to $installedVersion!"
    } else {
        Write-Host "🎉 AgbCloud CLI $installedVersion installed successfully!"
    }
    
    Write-Host "   📍 Location: $outputFile"
    Write-Host ""
    Write-Host "📚 Quick Start:"
    Write-Host "   agbcloud --help          # Show help (note: 'agbcloud' not 'abgcloud')"
    Write-Host "   agbcloud version         # Show version"
    Write-Host "   agbcloud login           # Login to AgbCloud"
    Write-Host ""
    Write-Host "💡 Important Notes:"
    Write-Host "   • The command is 'agbcloud' (not 'abgcloud')"
    Write-Host "   • If 'agbcloud' command not found, restart your terminal"
    Write-Host "   • Or run directly: $outputFile"
    Write-Host ""
    Write-Host "🔗 Documentation: https://docs.agbcloud.com"
    
} catch {
    Write-Host "⚠️  Installation test failed, but binary was downloaded successfully"
    Write-Host "   📍 Binary location: $outputFile"
    Write-Host "   🔧 You can run it directly or add to PATH manually"
    Write-Host ""
    Write-Host "   💡 Try running directly:"
    Write-Host "      $outputFile version"
}

Write-Host "" 