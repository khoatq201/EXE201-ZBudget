# ZBudget - Personal Finance Management App

## Project Structure

```
EXE201-ZBudget/
├── Backend/                 # Node.js Express API Server
│   ├── controllers/        # Route controllers
│   ├── models/             # Database models
│   ├── routes/             # API routes
│   ├── middleware/         # Custom middleware
│   ├── services/           # Business logic services
│   └── utils/              # Utility functions
├── zbudget/                # Flutter Mobile App
│   ├── lib/                # Dart source code
│   ├── android/            # Android platform files
│   ├── ios/                # iOS platform files
│   └── web/                # Web platform files
└── docs/                   # Documentation
```

## Setup Instructions

### Prerequisites
- Node.js (v14 or higher)
- Flutter SDK (latest stable)
- Android Studio / Xcode (for mobile development)
- Git

### Backend Setup
1. Navigate to Backend directory:
   ```bash
   cd Backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create environment file:
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` with your configuration.

4. Start the server:
   ```bash
   npm start
   ```

### Flutter App Setup
1. Navigate to zbudget directory:
   ```bash
   cd zbudget
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Setup Google Services:
   - Copy `android/app/google-services.json.template` to `android/app/google-services.json`
   - Update with your Firebase configuration

4. Run the app:
   ```bash
   flutter run
   ```

## Configuration Files

⚠️ **Important Security Notes:**

The following files contain sensitive information and should NOT be committed to version control:
- `Backend/.env` - Environment variables and secrets
- `zbudget/android/app/google-services.json` - Firebase configuration
- `zbudget/ios/Runner/GoogleService-Info.plist` - iOS Firebase configuration

Instead, use the provided template files and follow the setup instructions above.

## Git Workflow

1. Always check what files you're about to commit:
   ```bash
   git status
   git diff
   ```

2. Add files to staging:
   ```bash
   git add .
   ```

3. Commit your changes:
   ```bash
   git commit -m "Your commit message"
   ```

4. Push to remote repository:
   ```bash
   git push origin main
   ```

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Create a pull request

## License

This project is licensed under the MIT License.