# Supabase Integration Setup Guide

This document outlines the steps needed to complete the Supabase integration for your Pull-Up Club app.

## ✅ Completed

1. **Supabase Service** - Created `lib/common/services/supabase_service.dart`
2. **Authentication Provider** - Created `lib/common/providers/auth_provider.dart`
3. **Authentication Screens** - Created login and signup screens
4. **Sync Service** - Created `lib/common/services/sync_service.dart` for offline-first sync
5. **Database Schema Updates** - Added sync fields (server_id, updated_at, deleted_at, sync_status)
6. **Repository Updates** - Integrated sync into workout repository
7. **Main App Updates** - Added auth state management and Supabase initialization

## 🔧 Required Steps

### 1. Regenerate Database Code

The database schema has been updated with sync fields. You need to regenerate the Drift database code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the updated database code with the new sync fields.

### 2. Configure Supabase Credentials

Update `lib/common/constants/app_constants.dart` with your Supabase project credentials:

```dart
static const String supabaseUrl = "YOUR_SUPABASE_URL";
static const String supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";
```

You can find these in your Supabase project:
- Go to Project Settings → API
- Copy the "Project URL" → `supabaseUrl`
- Copy the "anon public" key → `supabaseAnonKey`

### 3. Supabase Dashboard Configuration

#### Enable Email Authentication

1. Go to **Authentication** → **Providers** in your Supabase dashboard
2. Enable **Email** provider
3. Configure email settings (SMTP) if you want custom emails
4. Optionally disable email confirmation for development (Settings → Auth → Email Auth)

#### Verify RLS Policies

The schema includes Row Level Security (RLS) policies. Verify they're active:

1. Go to **Table Editor** → **workouts** → **Policies**
2. Ensure these policies exist:
   - "Users can view their own workouts"
   - "Users can insert their own workouts"
   - "Users can update their own workouts"
3. Repeat for **workout_sets** table

#### Verify Triggers

The schema includes triggers for:
- Auto-updating `updated_at` timestamps
- Auto-setting `user_id` on insert
- Updating parent workout timestamps when sets change

These should be automatically created when you run the schema. Verify in **Database** → **Functions** and **Database** → **Triggers**.

### 4. Run the Schema

Execute the SQL schema in your Supabase SQL Editor:

1. Go to **SQL Editor** in Supabase dashboard
2. Copy the contents of `supabase/schema.sql`
3. Paste and run it
4. Verify tables are created: `workouts` and `workout_sets`

### 5. Test the Integration

1. **Run the app**: `flutter run`
2. **Test Authentication**:
   - Sign up with a new account
   - Sign in with existing account
   - Test password reset
3. **Test Sync**:
   - Create a workout while offline
   - Go online and verify it syncs
   - Create a workout on another device
   - Verify it appears after sync

## 📋 Architecture Overview

### Offline-First Sync Strategy

1. **Local-First**: All operations (create, update, delete) happen in local SQLite database first
2. **Background Sync**: Changes are synced to Supabase in the background
3. **Bidirectional**:
   - **Push**: Local changes → Supabase
   - **Pull**: Supabase changes → Local
4. **Conflict Resolution**: Server timestamp wins (simplified - can be enhanced)

### Sync Fields

- `server_id`: Maps local ID to Supabase ID
- `updated_at`: Tracks when record was last modified
- `deleted_at`: Soft delete timestamp (NULL = active)
- `sync_status`: "pending", "synced", or "error"

### Authentication Flow

1. App starts → Check auth state
2. If not authenticated → Show login screen
3. If authenticated → Show main app
4. Auth state changes trigger automatic navigation

## 🐛 Troubleshooting

### Database Migration Errors

If you get errors about missing columns, the database migration might not have run. The app will automatically migrate from version 1 to 2 on first launch.

### Sync Not Working

1. Check Supabase credentials are correct
2. Verify user is authenticated
3. Check network connectivity
4. Review logs for sync errors
5. Verify RLS policies allow user access

### Authentication Errors

1. Verify email provider is enabled in Supabase
2. Check email confirmation settings
3. Verify RLS policies are active
4. Check Supabase logs for auth errors

## 📝 Next Steps (Optional Enhancements)

1. **Conflict Resolution**: Implement more sophisticated conflict resolution (e.g., last-write-wins with user confirmation)
2. **Sync Status UI**: Show sync status indicator in the app
3. **Manual Sync**: Add pull-to-refresh or manual sync button
4. **Offline Queue**: Show pending syncs in UI
5. **Error Handling**: Better error messages and retry logic
6. **Incremental Sync**: Only sync changed records since last sync timestamp

## 🔐 Security Notes

- The `anon` key is safe to use in client apps (it's public)
- RLS policies ensure users can only access their own data
- Never commit service role keys to the repository
- Consider adding rate limiting for auth endpoints in production
