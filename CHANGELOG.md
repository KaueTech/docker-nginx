# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Multi-architecture support (AMD64, ARM64, ARMv7)
- Security scanning with Trivy
- Performance testing
- Automatic dependency updates
- Issue and PR templates
- Contributing guidelines
- Code of conduct
- Security policy
- Funding configuration

### Changed
- Updated Dockerfile with English comments
- Improved documentation structure
- Enhanced Docker Compose examples
- Better error handling in entrypoint scripts

### Fixed
- Removed Portuguese comments from code
- Fixed SSL certificate generation issues
- Improved nginx configuration generation

## [1.0.0] - 2025-08-12

### Added
- Initial release
- HTTP, HTTPS with openssl certificates, and Cloudflare DNS variants
- Environment variable-based configuration
- Reverse proxy functionality
- SSL certificate management
- Basic Docker Compose setup

[Unreleased]: https://github.com/kauech/docker-nginx/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kauech/docker-nginx/releases/tag/v1.0.0
