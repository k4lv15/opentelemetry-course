# Application Versions

This directory contains versioned releases of the Translation Queue application for OpenTelemetry instrumentation labs.

## Version Matrix

| Version    | Status     | Description                               | Docker Images                                                                                                                               | Labs |
| ---------- | ---------- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| **v1.1.0** | ✅ Current | Baseline application (no instrumentation) | [frontend](https://hub.docker.com/r/lmacademy/web-translator-frontend) • [worker](https://hub.docker.com/r/lmacademy/web-translator-worker) | -    |

## How to Use

### For Students

1. **Download the version** specified in your lab instructions
2. **Extract the ZIP** file to your working directory
3. **Navigate** into the extracted `code/` directory
4. **Check `VERSION`** to confirm you have the correct version
5. **Review changes**: Read `CHANGELOG.md` to understand what's new
6. **Follow lab instructions** to complete the implementation

### Version Contents

Each ZIP archive contains:

- Complete application source code (frontend + worker)
- Docker Compose configuration
- `VERSION` file - Current version number
- `CHANGELOG.md` - What's new and what's next
- `README.md` - Application documentation
- `.gitignore` - Git exclusion patterns

## Need Help?

- **Wrong version?** Check the lab instructions to confirm which version you need
- **Can't find a file?** Make sure you extracted the entire ZIP and are in the `code/` directory
- **Version issues?** Run `cat VERSION` and compare with lab requirements
- **Want to see changes?** Check `CHANGELOG.md` for detailed version history

## Docker Images

Pre-built Docker images are available for each version:

- **Frontend**: `lmacademy/web-translator-frontend:v1.x.0`
- **Worker**: `lmacademy/web-translator-worker:v1.x.0`

Images are built for both `linux/amd64` and `linux/arm64` platforms.
