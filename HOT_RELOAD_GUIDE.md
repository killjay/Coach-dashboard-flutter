# Hot Reload & Live Development Guide

Flutter has excellent hot reload capabilities that allow you to see changes instantly without restarting the app.

## Hot Reload vs Hot Restart

### Hot Reload (Fast - Recommended)
- **What it does**: Injects updated code into the running app
- **Speed**: Very fast (usually < 1 second)
- **State**: Preserves app state
- **When to use**: For most code changes (UI, logic, etc.)

**How to use:**
- Press `r` in the terminal where Flutter is running
- Or click the hot reload button in your IDE (VS Code, Android Studio)
- Or save the file (if auto-save is enabled)

### Hot Restart (Slower)
- **What it does**: Restarts the app with new code
- **Speed**: Slower (5-10 seconds)
- **State**: Resets app state
- **When to use**: When hot reload doesn't work (e.g., after changing `main()`, adding dependencies, etc.)

**How to use:**
- Press `R` (capital R) in the terminal
- Or click the hot restart button in your IDE

## Running with Hot Reload

### For Web Development

```bash
# Start Flutter with hot reload for web
flutter run -d chrome --web-port=8080

# Or for a specific browser
flutter run -d edge
flutter run -d safari
```

### For Mobile Development

```bash
# For Android
flutter run -d android

# For iOS (Mac only)
flutter run -d ios

# List available devices
flutter devices
```

### For Desktop

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## IDE Integration

### VS Code
1. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
2. Type "Flutter: Run" or "Flutter: Hot Reload"
3. Or use the debug panel (F5 to start debugging)

**Keyboard Shortcuts:**
- `Cmd+S` / `Ctrl+S`: Save (triggers hot reload if enabled)
- `Cmd+Shift+P` → "Flutter: Hot Reload": Manual hot reload
- `Cmd+Shift+P` → "Flutter: Hot Restart": Hot restart

### Android Studio / IntelliJ
1. Click the green play button to run
2. Use the hot reload button (⚡) in the toolbar
3. Or press `Ctrl+\` (Windows/Linux) or `Cmd+\` (Mac)

## Auto Hot Reload

### VS Code Settings
Add to `.vscode/settings.json`:

```json
{
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "dart.flutterHotReloadOnSave": true
}
```

### Android Studio Settings
1. Go to Settings → Languages & Frameworks → Flutter
2. Enable "Hot reload on save"

## What Works with Hot Reload

✅ **Works with Hot Reload:**
- UI changes (colors, text, layouts)
- Logic changes (functions, calculations)
- State management updates
- Widget tree modifications
- Most code changes

❌ **Requires Hot Restart:**
- Changes to `main()` function
- Adding/removing dependencies in `pubspec.yaml`
- Changes to native code
- Changes to app initialization
- Changes to `MaterialApp` or `WidgetsApp` configuration
- Changes to route definitions (sometimes)

## Debugging Tips

### Check Hot Reload Status
Look for this message in the terminal:
```
Performing hot reload...
Reloaded 1 of 1234 libraries
```

### If Hot Reload Fails
1. Try hot restart (`R`)
2. Check for compilation errors
3. Look for runtime errors in the console
4. Sometimes a full restart is needed: Stop the app and run again

### Performance
- Hot reload is fastest for small changes
- Large changes might take a few seconds
- If it's slow, check your device/emulator performance

## Web-Specific Hot Reload

For web development, Flutter uses:
- **Dart Dev Compiler (DDC)**: For development (supports hot reload)
- **Dart2JS**: For production builds (no hot reload)

### Web Hot Reload Features
- ✅ Instant UI updates
- ✅ State preservation
- ✅ Fast iteration
- ⚠️ Some changes require refresh (e.g., route changes)

### Web Development Server
When you run `flutter run -d chrome`, Flutter:
1. Starts a development server
2. Compiles Dart to JavaScript
3. Serves the app on `http://localhost:8080` (or specified port)
4. Enables hot reload

## Best Practices

1. **Use Hot Reload Frequently**: Make small changes and reload often
2. **Save Files**: Enable auto-save for the best experience
3. **Watch the Console**: Check for errors after hot reload
4. **Hot Restart When Needed**: Don't hesitate to restart if hot reload doesn't work
5. **Keep Terminal Open**: The Flutter process needs to stay running

## Troubleshooting

### Hot Reload Not Working?
1. Check if Flutter is still running
2. Look for compilation errors
3. Try hot restart instead
4. Restart the Flutter process

### Changes Not Appearing?
1. Ensure the file is saved
2. Check if you're editing the right file
3. Verify the route/screen is active
4. Try hot restart

### Slow Hot Reload?
1. Close unused apps
2. Use a faster device/emulator
3. Reduce app complexity temporarily
4. Check for performance issues

## Example Workflow

```bash
# 1. Start the app
flutter run -d chrome

# 2. Make changes to your code
# (Edit files in your IDE)

# 3. Hot reload (press 'r' or save)
# Changes appear instantly!

# 4. If needed, hot restart (press 'R')
# App restarts with new code
```

## Additional Resources

- [Flutter Hot Reload Documentation](https://docs.flutter.dev/development/tools/hot-reload)
- [Flutter Performance Tips](https://docs.flutter.dev/perf/best-practices)

---

**Note**: Hot reload is one of Flutter's best features - use it liberally for fast development! 🚀

