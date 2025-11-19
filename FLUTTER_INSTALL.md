# Flutter Installation Guide

## Check if Flutter is Installed

First, let's check if Flutter is already installed somewhere:

```bash
# Reload your shell configuration
source ~/.zshrc

# Try to find Flutter
which flutter
flutter --version
```

## If Flutter is NOT Installed

### Option 1: Install via Homebrew (Recommended for macOS)

```bash
# Install Flutter via Homebrew
brew install --cask flutter

# Verify installation
flutter --version
```

### Option 2: Manual Installation

1. **Download Flutter SDK**
   ```bash
   cd ~
   git clone https://github.com/flutter/flutter.git -b stable
   ```

2. **Add to PATH** (already added to your .zshrc, but update the path if needed)
   ```bash
   # The path in .zshrc is set to ~/flutter/bin
   # If you installed to a different location, update ~/.zshrc
   ```

3. **Reload shell**
   ```bash
   source ~/.zshrc
   ```

4. **Verify installation**
   ```bash
   flutter --version
   flutter doctor
   ```

## Update PATH in .zshrc

If Flutter is installed in a different location, update your `~/.zshrc`:

```bash
# Open .zshrc in your editor
nano ~/.zshrc

# Find the Flutter PATH line and update it:
# export PATH="$PATH:$HOME/flutter/bin"
# Change to your actual Flutter installation path

# Save and reload
source ~/.zshrc
```

## Verify Flutter Setup

After installation, run:

```bash
flutter doctor
```

This will show you what's configured and what needs setup (Android Studio, Xcode, etc.).

## Common Flutter Installation Locations

- `~/flutter/bin` (default manual installation)
- `~/development/flutter/bin`
- `~/Documents/flutter/bin`
- `/usr/local/flutter/bin`
- `/opt/homebrew/Caskroom/flutter/` (Homebrew installation)

## Next Steps

Once Flutter is installed and in your PATH:

1. Run `flutter doctor` to check setup
2. Install any missing dependencies
3. Run `flutter pub get` in your project
4. Start developing!


