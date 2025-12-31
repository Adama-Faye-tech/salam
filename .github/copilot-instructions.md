# AI Coding Assistant Instructions for SALAM Project

## Project Overview
SALAM is a simplified Flutter app showing agricultural service providers. The app displays two static service providers with their contact information and photos, allowing farmers to easily contact them for agricultural services.

## Architecture
- **Frontend**: Flutter with minimal Provider state management
- **Database**: No backend required - static data only
- **Authentication**: None required
- **Storage**: Local asset images
- **Platform**: Multi-platform (iOS, Android, Web, Windows)

## Key Components
- `lib/providers/`: Minimal theme provider only
- `lib/screens/home/`: Simple home screen with provider cards
- Static provider data embedded in HomeScreen
- Contact functionality via phone calls and email

## Coding Patterns

### Simple Static Data
Provider information is stored as static constants in the HomeScreen:

```dart
static const List<Map<String, dynamic>> providers = [
  {
    'name': 'Service Agricole Dakar',
    'description': '...',
    'phone': '+221 77 123 45 67',
    'email': 'contact@serviceagricoledakar.sn',
    'address': 'Dakar, Sénégal',
    'services': ['Moisson', 'Labour', 'Semis'],
    'photos': ['assets/images/image1.png', ...],
  },
];
```

### Contact Integration
Use url_launcher for phone calls and emails:

```dart
Future<void> _launchPhone(String phone) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  }
}
```

### UI Patterns
- Clean card-based layout for providers
- Horizontal scrolling photo galleries
- Contact buttons for phone and email
- Agricultural green theme (AppColors.primary)

## Development Workflow

### Starting the App
Use the PowerShell script for consistent startup:
```powershell
.\start_flutter.ps1
```
Choose platform: Chrome (recommended for development), Windows, or Android.

### No Backend Required
The app uses only static data, so no backend server is needed.

## File Organization
- Keep minimal providers in `lib/providers/`
- Simple home screen in `lib/screens/home/`
- Static assets in `assets/images/`

## Testing
Run Flutter tests:
```bash
flutter test
```

## Key Files to Reference
- `lib/main.dart`: Simple app initialization
- `lib/screens/home/home_screen.dart`: Main screen with provider cards
- `lib/config/theme.dart`: App theming</content>
<parameter name="filePath">c:\Users\USER\adama\develop\baol\.github\copilot-instructions.md