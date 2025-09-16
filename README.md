# AgbCloud CLI

A command-line interface for AgbCloud services.

## Features

AgbCloud CLI provides comprehensive image management capabilities:

- **Authentication**: Secure OAuth-based login with Google account integration
- **Image Creation**: Build custom images from Dockerfiles with base image support
- **Image Management**: Activate, deactivate, and monitor image instances
- **Resource Control**: Configure CPU and memory resources (2c4g, 4c8g, 8c16g)
- **Image Listing**: Browse user and system images with pagination support

## Quick Start

```bash
# 1. Log in to AgbCloud
agbcloud login

# 2. List available system images (to find base image IDs)
agbcloud image list --type System

# 3. Create a custom image
agbcloud image create myapp --dockerfile ./Dockerfile --imageId agb-code-space-1

# 4. Activate the image with specific resources
agbcloud image activate img-7a8b9c1d0e --cpu 4 --memory 8

# 5. List your images
agbcloud image list

# 6. Deactivate when done
agbcloud image deactivate img-7a8b9c1d0e
```

## Installation

Download the latest release for your platform from the [releases page](https://github.com/agbcloud/agbcloud-cli/releases).

## Usage

```bash
# Show help
agbcloud --help

# Show version
agbcloud version

# Get detailed help for image commands
agbcloud image --help

# Use verbose mode for detailed output
agbcloud -v image create myapp -f ./Dockerfile -i agb-code-space-1
```

For detailed usage instructions and examples, see the [User Guide](docs/USER_GUIDE.md).

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details. 