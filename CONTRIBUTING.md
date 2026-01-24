# Contributing to ToEvent

Thank you for your interest in contributing to ToEvent.

## Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) to report issues.
Include your macOS version, ToEvent version, and steps to reproduce.

## Suggesting Features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).
Explain the problem you're solving and your proposed solution.

## Development Setup

### Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building

1. Clone the repository
2. Open `ToEvent/ToEvent.xcodeproj` in Xcode
3. Build and run (Cmd+R)

### OAuth Credentials

ToEvent supports Google Calendar and Outlook integration. For development:

1. Create your own OAuth app credentials:
   - Google: [Google Cloud Console](https://console.cloud.google.com/)
   - Microsoft: [Azure Portal](https://portal.azure.com/)
2. Update the client IDs in `AuthService.swift`

Production builds use separate credentials not included in the repository.

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Ensure the project builds without warnings
5. Submit a pull request using the [PR template](.github/PULL_REQUEST_TEMPLATE.md)

## Code Style

- Follow existing code conventions
- Use meaningful variable and function names
- Keep functions focused and small
- Add comments only where logic is not self-evident

## License

By contributing, you agree that your contributions will be licensed under the GPL-3.0 License.
