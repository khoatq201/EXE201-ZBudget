# Google Sign-In Implementation for ZBudget

## Overview

Google Sign-In has been successfully implemented in the ZBudget Flutter application with backend authentication support.

## Features Implemented

### Frontend (Flutter)

- ✅ Google Sign-In button on login screen
- ✅ Google authentication flow
- ✅ Error handling and user feedback
- ✅ Integration with existing AuthService
- ✅ Auto-navigation to home after successful sign-in

### Backend (Node.js/Express)

- ✅ Google ID token verification
- ✅ User creation/update with Google profile data
- ✅ JWT token generation for authenticated users
- ✅ Database integration with Google user fields
- ✅ Audit logging for Google sign-in attempts

## Files Modified

### Flutter Files

1. `pubspec.yaml` - Added `google_sign_in: ^6.2.1` dependency
2. `lib/services/auth_service.dart` - Added Google Sign-In methods
3. `lib/screens/auth/login_screen.dart` - Added Google Sign-In UI button
4. `lib/config/app_router.dart` - Cleaned up router configuration

### Backend Files

1. `package.json` - Added `google-auth-library` dependency
2. `routes/authRoutes.js` - Added `/google-signin` endpoint
3. `models/User.js` - Added Google OAuth fields (`googleId`, `authProvider`)
4. `.env` - Added Google OAuth credentials

## Configuration

### Google OAuth Credentials

```env
GOOGLE_CLIENT_ID=996746380802-c7hh05j9jqtr2jpbidajq4g8hel30p0f.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
```

### Database Schema Updates

New fields added to User model:

- `googleId`: String (sparse index for Google user ID)
- `authProvider`: Enum ['local', 'google'] (default: 'local')
- `passwordHash`: Made conditional (required only for local auth)

## API Endpoints

### POST `/api/auth/google-signin`

Authenticates users via Google ID token.

**Request Body:**

```json
{
  "idToken": "string",
  "email": "string",
  "displayName": "string",
  "photoUrl": "string"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Đăng nhập Google thành công",
  "accessToken": "jwt_token",
  "refreshToken": "refresh_token",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "fullName": "User Name",
    "avatar": "profile_picture_url",
    "isVerified": true
  }
}
```

## How It Works

1. **User clicks "Đăng nhập với Google"** on login screen
2. **Google Sign-In popup** appears for authentication
3. **Google returns ID token** after successful authentication
4. **Flutter sends ID token** to backend `/api/auth/google-signin` endpoint
5. **Backend verifies token** with Google's OAuth2 service
6. **User is created/updated** in database with Google profile data
7. **JWT tokens generated** and returned to Flutter
8. **User is authenticated** and redirected to home screen

## Usage Instructions

### For Users

1. Open the ZBudget app
2. Navigate to the login screen
3. Click "Đăng nhập với Google" button
4. Complete Google authentication in popup
5. You'll be automatically signed in and redirected to the home screen

### For Developers

1. Ensure backend server is running on `http://localhost:3000`
2. Ensure Flutter app is running on `http://localhost:8080`
3. Google credentials are configured in backend `.env` file
4. MongoDB is running and connected

## Error Handling

- **Cancelled sign-in**: Shows "Đăng nhập đã bị hủy" message
- **Invalid token**: Shows "Token Google không hợp lệ" message
- **Network errors**: Shows "Không thể đăng nhập với Google" message
- **Backend errors**: Proper error messages displayed to user

## Security Features

- ✅ Google ID token verification on backend
- ✅ JWT token generation for session management
- ✅ Audit logging for security monitoring
- ✅ Rate limiting on authentication endpoints
- ✅ Secure token storage in SharedPreferences

## Testing

To test Google Sign-In:

1. Start backend: `cd Backend && node server.js`
2. Start Flutter: `cd zbudget && flutter run -d chrome --web-port=8080`
3. Navigate to login screen
4. Click Google Sign-In button
5. Complete authentication flow

## Future Enhancements

- [ ] Add Google Sign-In for mobile platforms (Android/iOS)
- [ ] Implement Google account linking for existing users
- [ ] Add Google profile sync functionality
- [ ] Implement Google logout on all devices

## Troubleshooting

### Common Issues

1. **CORS errors**: Ensure backend CORS is configured for `http://localhost:8080`
2. **Token verification fails**: Check Google Client ID in environment variables
3. **Database connection**: Ensure MongoDB is running and accessible
4. **Port conflicts**: Make sure ports 3000 (backend) and 8080 (frontend) are available

### Debug Commands

```bash
# Check backend logs
tail -f Backend/logs/combined-*.log

# Check Flutter debug output
flutter logs

# Test backend endpoint manually
curl -X POST http://localhost:3000/api/auth/google-signin \
  -H "Content-Type: application/json" \
  -d '{"idToken":"test","email":"test@gmail.com"}'
```

## Support

For issues related to Google Sign-In implementation, check:

1. Backend server logs in `Backend/logs/`
2. Flutter debug console output
3. Browser developer tools for network requests
4. Database connection and user records
