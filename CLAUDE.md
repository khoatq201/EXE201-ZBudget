# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## IMPORTANT: Context Loading Instructions

**ALWAYS start your session by loading project context from MCP Serena memories:**

When you start a new Claude Code session, you MUST:

1. **Activate Serena MCP** (if not already active):
   ```
   Use the mcp__serena__activate_project tool with the project path
   ```

2. **Check and perform onboarding** (first time only):
   ```
   Use mcp__serena__check_onboarding_performed
   If not performed, use mcp__serena__onboarding
   ```

3. **Read project memories** to gain full context:
   ```
   Use mcp__serena__list_memories to see available memories
   Then read relevant memories using mcp__serena__read_memory
   ```

**Available Memory Files** (read these for context):
- `project_overview.md` - Project purpose, architecture, features, structure
- `tech_stack.md` - Complete technology stack (Frontend & Backend)
- `code_style_conventions.md` - Naming conventions, patterns, best practices
- `suggested_commands.md` - All essential development commands
- `task_completion_checklist.md` - Step-by-step checklist for completing tasks

**Why This Matters:**
- Memories contain critical project context that is NOT in this CLAUDE.md file
- They include detailed conventions, patterns, and gotchas specific to this codebase
- Reading memories ensures you don't miss important information about how to work with this project
- Memories are maintained and updated as the project evolves

**Example Session Start:**
```
1. Activate Serena for this project
2. List available memories
3. Read project_overview, tech_stack, and code_style_conventions memories
4. Now you're ready to work on the task!
```

## Project Overview

ZBudget is a personal finance management application consisting of:
- **Frontend**: Flutter mobile app (in `zbudget/` directory)
- **Backend**: Node.js Express API with MongoDB (in `Backend/` directory)

## Common Development Commands

### Backend (Node.js + Express + MongoDB)

**Working Directory**: Navigate to `Backend/` for all backend commands

```bash
cd Backend
```

**Start Development Server**:
```bash
npm run dev              # Start with nodemon (auto-reload)
npm start                # Start production server
```

**Database Setup**:
```bash
npm run setup            # Initialize database and create indexes
npm run setup:seed       # Initialize database with seed data
npm run setup:clean      # Clean up database
npm run models:validate  # Validate model schemas
```

**Database Health & Stats**:
```bash
npm run db:stats         # Get database statistics
npm run db:health        # Check database connection health
```

**Testing & Code Quality**:
```bash
npm test                 # Run Jest tests
npm run test:watch       # Run tests in watch mode
npm run lint             # Run ESLint
npm run lint:fix         # Fix ESLint errors
npm run format           # Format code with Prettier
```

### Frontend (Flutter)

**Working Directory**: Navigate to `zbudget/` for all Flutter commands

```bash
cd zbudget
```

**Install Dependencies**:
```bash
flutter pub get          # Install Flutter dependencies
```

**Run Application**:
```bash
flutter run              # Run on connected device/emulator
flutter run -d chrome    # Run on Chrome (web)
flutter run -d android   # Run on Android
flutter run -d ios       # Run on iOS
```

**Build Application**:
```bash
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
flutter build web        # Build web app
```

**Testing**:
```bash
flutter test             # Run all tests
flutter test test/path/to/test_file.dart  # Run specific test
```

**Code Analysis**:
```bash
flutter analyze          # Run Dart analyzer
```

**Clean Build**:
```bash
flutter clean            # Clean build artifacts
flutter pub get          # Then reinstall dependencies
```

## Architecture Overview

### Backend Architecture

**Technology Stack**:
- Express.js server with ES modules (`"type": "module"` in package.json)
- MongoDB with Mongoose ODM
- JWT authentication
- Google OAuth integration

**Directory Structure**:
```
Backend/
├── server.js           # Main Express server entry point
├── controllers/        # Route controllers (business logic)
│   ├── authController.js      # Authentication logic
│   └── expenseController.js   # Expense management
├── models/             # Mongoose models
│   ├── index.js       # Model exports and utilities
│   ├── User.js
│   ├── Expense.js
│   ├── Budget.js
│   ├── Challenge.js
│   ├── UserChallenge.js
│   ├── Group.js
│   └── Notification.js
├── routes/             # Express routes
│   ├── authRoutes.js
│   └── expenseRoutes.js
├── middleware/         # Custom middleware
│   ├── auth.js        # JWT authentication
│   ├── errorHandler.js
│   ├── logger.js
│   └── responseLogger.js
└── services/           # Business logic services
```

**Key Backend Features**:
1. **Transaction Support**: Use `transactions.withTransaction()` for multi-document operations
2. **Decimal128 for Money**: All financial amounts use Mongoose Decimal128 for precision
3. **Compound Indexes**: Optimized queries with strategic indexing
4. **Gamification System**: Points, levels, challenges, and achievements
5. **Group Expense Sharing**: Multi-user expense tracking

**Database Connection**:
- Connection utility: `connectDB()` from `models/index.js`
- Auto-reconnection handling
- Graceful shutdown on SIGINT/SIGTERM

**API Endpoints**:
```
/api/health             # Health check
/api/auth               # Authentication (login, signup, Google OAuth)
/api/expenses           # Expense management
```

**Environment Variables** (`.env` file required):
- `MONGODB_URI`: MongoDB connection string
- `JWT_SECRET`: JWT signing secret
- `PORT`: Server port (default: 3000)
- `GOOGLE_CLIENT_ID`: Google OAuth client ID
- Rate limiting and CORS configurations

### Frontend Architecture

**Technology Stack**:
- Flutter 3.9+ with Dart SDK ^3.9.0
- Provider for state management
- go_router for navigation
- Material Design UI

**Directory Structure**:
```
zbudget/lib/
├── main.dart               # App entry point
├── config/
│   └── app_router.dart    # GoRouter configuration (all routes)
├── constants/             # App constants
│   ├── colors.dart
│   └── typography.dart
├── models/                # Data models (8 files)
├── providers/             # State management providers
│   └── app_provider.dart
├── screens/               # UI screens organized by feature
│   ├── auth/             # Login, signup, OTP verification
│   ├── home/             # Dashboard, add expense/income
│   ├── budget/           # Budget list, create budget
│   ├── group/            # Group management
│   ├── settings/         # Profile, security, theme, language
│   ├── challenge_screen.dart
│   ├── reports_screen.dart
│   └── main_navigator.dart  # Bottom navigation shell
├── services/              # Business logic services
│   ├── auth_service.dart
│   ├── expense_service.dart
│   ├── savings_service.dart
│   ├── group_service.dart
│   ├── challenge_service.dart
│   ├── profile_service.dart
│   ├── currency_service.dart
│   ├── notification_service.dart
│   ├── language_service.dart
│   ├── theme_service.dart
│   └── security_service.dart
├── utils/                 # Utility functions
│   └── auth_guard.dart   # Route protection
└── widgets/               # Reusable UI components
```

**Navigation Architecture**:
- Uses `go_router` with ShellRoute for bottom navigation
- Route protection via `AuthGuard.checkAuthentication` redirect
- Main routes: `/home`, `/budget`, `/groups`, `/challenges`, `/reports`, `/settings`
- Authentication flows: `/login`, `/signup`, `/verify-otp`, `/forgot-password`

**State Management**:
- Provider pattern with ChangeNotifier
- Services registered in main.dart via MultiProvider
- 8 main services: Auth, Expense, Savings, Group, Challenge, Profile, Currency, App

**Key Features**:
1. **Multi-language Support**: Vietnamese/English localization
2. **Dark Mode**: Theme switching capability
3. **Multi-currency**: Currency conversion service
4. **OCR Receipt Scanning**: Google ML Kit text recognition
5. **Image Handling**: Camera and file picker integration
6. **Charts & Visualizations**: fl_chart for expense reports

## Important Development Notes

### Backend

1. **ES Modules**: Backend uses ES modules - use `import/export` syntax, not `require()`
2. **Decimal Handling**: When working with money, convert Decimal128 to float: `parseFloat(amount.toString())`
3. **Transactions**: For operations affecting multiple collections, use `transactions.withTransaction()` or specific helpers like `addExpenseWithBudgetUpdate()`
4. **Authentication**: Protected routes use `authenticate` middleware
5. **Error Handling**: Global error handler in `errorHandler.js`

### Frontend

1. **Route Navigation**: Use `context.go('/route')` or `context.push('/route')` from go_router
2. **State Access**: Access services via `Provider.of<ServiceName>(context)` or `context.read<ServiceName>()`
3. **Authentication Flow**:
   - Login/Signup → OTP Verification → Complete Profile → Home
   - All main screens are protected by AuthGuard
4. **Asset Configuration**: Assets must be declared in `pubspec.yaml` before use
5. **Google Services**: Requires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) - these are gitignored

### Security Considerations

**Never commit these files**:
- `Backend/.env` - Contains database credentials, JWT secrets, API keys
- `zbudget/android/app/google-services.json` - Firebase configuration
- `zbudget/ios/Runner/GoogleService-Info.plist` - iOS Firebase configuration

Use template files instead:
- Copy `.env.example` to `.env` and fill in values
- Copy `google-services.json.template` to `google-services.json` and configure

## Testing Strategy

**Backend**:
- Unit tests with Jest
- Test database utilities available in `models/index.js`
- Use `dbUtils.dropAllCollections()` for test cleanup (development only)

**Frontend**:
- Widget tests in Flutter
- Test file: `lib/main_test.dart`
- Run specific tests: `flutter test test/path/to/file.dart`

## Database Schema

**Key Models**:
1. **User**: Authentication, profile, gamification stats (points, level, streaks)
2. **Expense**: Transactions with category, location, receipt, budget linking
3. **Budget**: Period-based budgets with category allocations and alerts
4. **Challenge**: Gamification challenges with milestones and rewards
5. **UserChallenge**: User progress tracking for challenges
6. **Group**: Expense sharing groups with members and permissions
7. **Notification**: Multi-type notification system

**Relationships**:
- User → Expenses (one-to-many)
- User → Budgets (one-to-many)
- User → UserChallenges (one-to-many)
- Budget → Expenses (one-to-many via budgetId)
- Group → Users (many-to-many via members array)
- Challenge → UserChallenges (one-to-many)

## Git Workflow

This repository has both frontend and backend code. When making changes:

1. **Backend changes**: Work in `Backend/` directory
2. **Frontend changes**: Work in `zbudget/` directory
3. **Shared configs**: Root level contains some Flutter configs due to project structure

**Main branch**: `main`

**Current status**: Repository has some uncommitted changes in `.dart_tool/` which are development artifacts (safe to ignore or add to .gitignore).
