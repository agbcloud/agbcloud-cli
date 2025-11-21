# AgbCloud CLI User Guide

This guide will walk you through how to use the AgbCloud CLI tool for image management operations.
## Table of Contents

- [Installation](#installation)
  - [Windows](#windows)
  - [macOS/Linux](#macoslinux)
  - [Uninstallation](#uninstallation)
- [Prerequisites](#prerequisites)
- [1. Login Authentication](#1-login-authentication)
- [2. Create Image](#2-create-image)
- [3. Activate Image](#3-activate-image)
- [4. Deactivate Image](#4-deactivate-image)
- [5. List Images](#5-list-images)
- [FAQ](#faq)

## Installation

### Windows

Install AgbCloud CLI using PowerShell:

```powershell
powershell -Command "irm https://agbcloud.github.io/agbcloud-cli/windows | iex"
```

### macOS/Linux

Install AgbCloud CLI using Homebrew:

```bash
# 1. Add Agb Cloud's Homebrew tap
brew tap agbcloud/agb

# 2. Install agb command-line tool
brew install agb

# 3. Verify installation
agb version
```


### Uninstallation

#### Windows
```powershell
# Remove installation directory
Remove-Item -Path "$env:LOCALAPPDATA\agbcloud" -Recurse -Force
```

#### macOS/Linux
```bash
# Uninstall agb
brew uninstall agb

# Remove tap (optional)
brew untap aliyun/agb
```



## Prerequisites

Before getting started, please ensure:
- AgbCloud CLI tool is installed
- You have a valid AgbCloud account
- Network connection is available

## 1. Login Authentication

Before using any image management features, you need to log in to AgbCloud.

### Command Syntax

```bash
agb login
```

### Usage Steps

1. **Execute login command**:
   ```bash
   agb login
   ```

2. **System response**:
   ```
   [SEC] Starting AgbCloud authentication...
   [SIGNAL] Using callback port: 8080
   [WEB] Requesting OAuth login URL...
   [OK] Successfully retrieved OAuth URL!
   [DOC] Request ID: req-xxxxx
   [SEARCH] Trace ID: trace-xxxxx
   
   [>>] Starting local callback server on port 8080...
   [LINK] OAuth URL:
     https://agb.cloud/oauth/authorize?...
   
   [WEB] Opening the browser for authentication...
   ```

3. **Browser authentication**:
   - CLI will automatically open the browser
   - If the browser doesn't open automatically, manually copy the URL to your browser
   - Complete Google account authentication in the browser

4. **Authentication successful**:
   ```
   [OK] Authentication successful!
   [KEY] Received authorization code: abcd1234...
   [REFRESH] Exchanging authorization code for access token...
   [OK] Login successful!
   ```

### Notes

- Login session has a certain validity period, re-login is required after expiration
- Login information is securely stored in local configuration files

## 2. Create Image

Creating custom images requires providing a Dockerfile and base image ID.

### Command Syntax

```bash
agb image create <image-name> --dockerfile <dockerfile-path> --imageId <base-image-id>
```

### Parameter Description

- `<image-name>`: Custom image name (required)
- `--dockerfile, -f`: Dockerfile file path (required)
- `--imageId, -i`: Base image ID (required)

### Usage Examples

```bash
# Full command
agb image create myCustomImage --dockerfile ./Dockerfile --imageId agb-code-space-1

# Using short parameters
agb image create myCustomImage -f ./Dockerfile -i agb-code-space-1
```

### Execution Flow

1. **Start creation**:
   ```
   [BUILD] Creating image 'myCustomImage'...
   [SIGNAL] Getting upload credentials...
   [OK] Upload credentials obtained (Task ID: task-xxxxx)
   ```

2. **Upload Dockerfile**:
   ```
   [UPLOAD] Uploading Dockerfile...
   [OK] Dockerfile uploaded successfully
   ```

3. **Create image**:
   ```
   [WORK] Creating image...
   [OK] Image creation initiated
   ```

4. **Monitor progress**:
   ```
   [MONITOR] Monitoring image creation progress...
   [DATA] Status: Creating
   [DATA] Status: Available
   [OK] Image creation completed successfully!
   ```

### Image Status Description

- **Creating**: Image is being created
- **Create Failed**: Image creation failed
- **Available**: Image creation completed and ready to use

## 3. Activate Image

Activating an image starts a running instance. You can specify CPU and memory resources.

### Command Syntax

```bash
agb image activate <image-id> [--cpu <cores>] [--memory <gb>]
```

### Parameter Description

- `<image-id>`: Image ID to activate (required)
- `--cpu, -c`: CPU cores (optional, must be used together with memory parameter)
- `--memory, -m`: Memory size in GB (optional, must be used together with CPU parameter)

**Supported CPU/Memory combinations:**
- `2c4g`: 2 CPU cores + 4 GB memory
- `4c8g`: 4 CPU cores + 8 GB memory  
- `8c16g`: 8 CPU cores + 16 GB memory

**Note:** If CPU and memory parameters are not specified, default resource configuration will be used. If specified, both CPU and memory must be provided and must be one of the supported combinations above.

### Usage Examples

```bash
# Basic activation (using default resources)
agb image activate img-7a8b9c1d0e

# Using 2c4g configuration
agb image activate img-7a8b9c1d0e --cpu 2 --memory 4

# Using 4c8g configuration
agb image activate img-7a8b9c1d0e --cpu 4 --memory 8

# Using 8c16g configuration  
agb image activate img-7a8b9c1d0e --cpu 8 --memory 16

# Using short parameters
agb image activate img-7a8b9c1d0e -c 4 -m 8
```

### Execution Flow

1. **Start activation**:
   ```
   [>>] Activating image 'img-7a8b9c1d0e'...
   [SAVE] CPU: 4 cores, Memory: 8 GB
   [SEARCH] Checking current image status...
   ```

2. **Status check**:
   ```
   [DATA] Current Status: Available
   [OK] Image is available, proceeding with activation...
   [REFRESH] Starting image activation...
   ```

3. **Activation successful**:
   ```
   [OK] Image activation initiated successfully!
   [DATA] Operation Status: true
   [SEARCH] Request ID: req-xxxxx
   ```

4. **Monitor activation status**:
   ```
   [MONITOR] Monitoring image activation status...
   [DATA] Status: Activating
   [DATA] Status: Activated
   [OK] Image activation completed successfully!
   ```

### Image Activation Status Description

- **Available**: Image is available but not activated
- **Activating**: Image is being activated
- **Activated**: Image is activated and running
- **Activate Failed**: Image activation failed
- **Ceased Billing**: Image has stopped billing

### Special Case Handling

- If the image is already activated, the system will display the current status
- If the image is being activated, it will automatically join the monitoring process
- If the image is in a failed state, it will attempt to reactivate
- **If an invalid CPU/memory combination is specified, the system will show an error and display supported combinations**

### Error Examples

```bash
# Invalid combination example
agb image activate img-7a8b9c1d0e --cpu 3 --memory 6

# Error output
[ERROR] Invalid CPU/Memory combination: 3c6g

[TOOL] Supported combinations:
  • 2c4g: --cpu 2 --memory 4
  • 4c8g: --cpu 4 --memory 8
  • 8c16g: --cpu 8 --memory 16
```

## 4. Deactivate Image

Deactivate (stop) a running image instance.

### Command Syntax

```bash
agb image deactivate <image-id>
```

### Parameter Description

- `<image-id>`: Image ID to deactivate (required)

### Usage Examples

```bash
agb image deactivate img-7a8b9c1d0e
```

### Execution Flow

1. **Start deactivation**:
   ```
   🛑 Deactivating image 'img-7a8b9c1d0e'...
   [REFRESH] Deactivating image instance...
   ```

2. **Deactivation successful**:
   ```
   [OK] Image deactivation initiated successfully!
   [DATA] Operation Status: true
   [SEARCH] Request ID: req-xxxxx
   ```

### Notes

- Deactivating an image will terminate the running instance
- The image status will change to "Available" after deactivation
- Deactivation operation usually takes effect immediately

## 5. List Images

View your image list with pagination and type filtering support.

### Command Syntax

```bash
agb image list [--type <type>] [--page <page-number>] [--size <page-size>]
```

### Parameter Description

- `--type, -t`: Image type, options:
  - `User`: User custom images (default)
  - `System`: System-provided base images
- `--page, -p`: Page number, default is 1
- `--size, -s`: Items per page, default is 10

### Usage Examples

```bash
# View user images (default)
agb image list

# View system images
agb image list --type System

# Paginated view
agb image list --page 2 --size 5

# Using short parameters
agb image list -t User -p 1 -s 20
```

### Output Example

```
[DOC] Listing User images (Page 1, Size 10)...
[SEARCH] Fetching image list...
[OK] Found 3 images (Total: 3)
[PAGE] Page 1 of 1 (Page Size: 10)

IMAGE ID                  IMAGE NAME               STATUS               TYPE            UPDATED AT          
--------                  ----------               ------               ----            ----------          
img-7a8b9c1d0e           myCustomImage            Available            User            2025-01-15 10:30    
img-2f3g4h5i6j           webAppImage              Activated            User            2025-01-15 09:15    
img-8k9l0m1n2o           dataProcessImage         Creating             User            2025-01-15 11:45    
```

### Status Description

Images can be in the following states:

**Creation-related statuses:**
- **Creating**: Image is being created
- **Create Failed**: Image creation failed
- **Available**: Image creation completed and ready to use

**Activation-related statuses:**
- **Activating**: Image is being activated
- **Activated**: Image is activated and running
- **Deactivating**: Image is being deactivated
- **Activate Failed**: Image activation failed
- **Ceased Billing**: Image has stopped billing

## FAQ

### Q: How to view command help?

A: Add `--help` or `-h` parameter after any command:

```bash
agb --help
agb image --help
agb image create --help
```

### Q: What to do if login fails?

A: Please check:
1. Network connection is normal
2. Browser can access agb.cloud normally
3. You have a valid Google account
4. Firewall is not blocking the callback port

### Q: What to do if image creation fails?

A: Please check:
1. Dockerfile syntax is correct
2. Base image ID is valid
3. Network connection is stable
4. Check the Request ID in error messages for technical support

### Q: How to view detailed execution information?

A: Use `--verbose` or `-v` parameter:

```bash
agb -v image create myImage -f ./Dockerfile -i agb-code-space-1
```

### Q: What to do if image activation is slow?

A: Image activation may take several minutes, especially when:
- First time activating a specific image
- Image is large
- System load is high

Please be patient, the system will automatically monitor activation status.

### Q: How to get base image IDs?

A: Use the image list command to view system images:

```bash
agb image list --type System
```

---

**Technical Support**: If you encounter issues, please contact the technical support team and provide relevant Request ID and Trace ID. 