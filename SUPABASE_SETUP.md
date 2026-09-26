# Supabase Setup Guide for Shepherd's Watch

This guide will walk you through setting up Supabase as the backend database for the Shepherd's Watch application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Create a Supabase Project](#create-a-supabase-project)
3. [Configure Environment Variables](#configure-environment-variables)
4. [Run Database Migrations](#run-database-migrations)
5. [Verify Setup](#verify-setup)
6. [Next Steps](#next-steps)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

- A Supabase account (sign up at https://supabase.com)
- Node.js and npm installed
- This project cloned and dependencies installed

## Create a Supabase Project

1. **Go to Supabase Dashboard**
   - Visit https://app.supabase.com
   - Sign in or create a new account

2. **Create a New Project**
   - Click "New Project"
   - Choose your organization
   - Enter project details:
     - **Name**: `shepherd-s-watch` (or your preferred name)
     - **Database Password**: Choose a strong password (save this!)
     - **Region**: Select the region closest to you
   - Click "Create new project"
   - Wait 2-3 minutes for the project to initialize

3. **Get Your API Credentials**
   - Once the project is ready, go to **Project Settings** (gear icon in sidebar)
   - Navigate to **API** section
   - You'll need two values:
     - **Project URL** (looks like `https://xxxxxxxxxxxxx.supabase.co`)
     - **anon public** key (under "Project API keys")

## Configure Environment Variables

1. **Open the `.env.local` file** in the project root directory

2. **Add your Supabase credentials**:
   ```env
   VITE_SUPABASE_URL=https://your-project-id.supabase.co
   VITE_SUPABASE_ANON_KEY=your-anon-key-here
   ```

3. **Save the file**

> **⚠️ Important**: Never commit `.env.local` to version control. It should already be in `.gitignore`.

## Run Database Migrations

You have two options to run the database migrations:

### Option 1: Using the Supabase SQL Editor (Recommended)

1. **Go to the SQL Editor** in your Supabase dashboard
   - Click on the **SQL Editor** icon in the sidebar

2. **Run Migration 001 - Initial Schema**
   - Click "+ New query"
   - Copy the entire contents of `supabase/migrations/001_initial_schema.sql`
   - Paste into the SQL editor
   - Click "Run" or press `Ctrl+Enter`
   - You should see "Success. No rows returned"

3. **Run Migration 002 - RLS Policies**
   - Create another new query
   - Copy the entire contents of `supabase/migrations/002_rls_policies.sql`
   - Paste and run
   - Verify success

4. **Run Migration 003 - Functions and Views**
   - Create another new query
   - Copy the entire contents of `supabase/migrations/003_functions_views.sql`
   - Paste and run
   - Verify success

### Option 2: Using Supabase CLI (Advanced)

If you have the Supabase CLI installed:

```bash
# Link your project
supabase link --project-ref your-project-id

# Run all migrations
supabase db push
```

## Verify Setup

### 1. Check Tables Were Created

In the Supabase dashboard:
- Go to **Table Editor**
- You should see these tables:
  - `profiles`
  - `sheep`
  - `health_events`
  - `daily_tasks`

### 2. Verify Row Level Security

- Go to **Authentication** > **Policies**
- You should see RLS policies for all tables
- All tables should show "RLS enabled"

### 3. Test the Connection

1. **Install dependencies** (if not already done):
   ```bash
   npm install
   ```

2. **Start the development server**:
   ```bash
   npm run dev
   ```

3. **Check the browser console**:
   - Open DevTools (F12)
   - You should NOT see any Supabase credential warnings
   - If you see warnings, double-check your `.env.local` file

### 4. Test User Signup/Authentication

To test the database is working:

1. Set up authentication in your app (you'll need to implement auth UI)
2. Create a test user
3. Verify a profile is automatically created in the `profiles` table
4. Try creating a sheep record

## Next Steps

Now that Supabase is set up, you need to:

### 1. Implement Authentication

Create authentication pages for:
- User signup
- User login
- Password reset

Example using Supabase Auth:

```typescript
import { supabase } from '@/lib/supabase';

// Sign up
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password',
  options: {
    data: {
      full_name: 'John Doe',
    }
  }
});

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password',
});

// Sign out
const { error } = await supabase.auth.signOut();
```

### 2. Replace Mock Data with Real Database Queries

Update your components to fetch real data instead of using `mockData.ts`:

```typescript
import { supabase } from '@/lib/supabase';

// Fetch sheep
const { data: sheep, error } = await supabase
  .from('sheep')
  .select('*')
  .order('created_at', { ascending: false });

// Insert sheep
const { data, error } = await supabase
  .from('sheep')
  .insert({
    tag_id: 'SC-001',
    name: 'Bella',
    breed: 'Merino',
    date_of_birth: '2022-03-15',
    gender: 'female',
    weight_kg: 45,
    owner_id: user.id, // From auth session
  });

// Update sheep
const { data, error } = await supabase
  .from('sheep')
  .update({ health_score: 90 })
  .eq('id', sheepId);

// Delete sheep
const { data, error } = await supabase
  .from('sheep')
  .delete()
  .eq('id', sheepId);
```

### 3. Set Up Real-time Subscriptions (Optional)

Enable real-time updates for live data:

```typescript
const channel = supabase
  .channel('sheep-changes')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'sheep',
    },
    (payload) => {
      console.log('Change received!', payload);
      // Update your UI
    }
  )
  .subscribe();
```

### 4. Configure Email Templates (Optional)

- Go to **Authentication** > **Email Templates**
- Customize signup confirmation, password reset emails
- Add your branding

### 5. Set Up Storage for Sheep Images (Optional)

If you want to upload sheep images:

1. Go to **Storage** in Supabase dashboard
2. Create a new bucket called `sheep-images`
3. Set appropriate permissions
4. Update your code to upload images:

```typescript
const { data, error } = await supabase.storage
  .from('sheep-images')
  .upload(`${userId}/${sheepId}.jpg`, file);
```

## Troubleshooting

### "Invalid API key" Error

- Double-check your `.env.local` file
- Ensure you copied the **anon/public** key, not the service_role key
- Restart your dev server after changing `.env.local`

### RLS Policy Errors

If you get "Row Level Security" errors:
- Verify you're logged in (check `supabase.auth.getSession()`)
- Ensure RLS policies are enabled on all tables
- Check that the policies were created correctly in Migration 002

### Tables Not Found

- Verify all migrations ran successfully
- Check the **Table Editor** in Supabase dashboard
- Re-run the migrations if needed

### Connection Issues

- Check your internet connection
- Verify the VITE_SUPABASE_URL is correct
- Ensure your Supabase project is active (not paused)

### TypeScript Errors

If you get TypeScript errors related to database types:
- The types in `src/lib/database.types.ts` should match your schema
- You can regenerate types using Supabase CLI: `supabase gen types typescript --project-id your-project-id > src/lib/database.types.ts`

## Database Schema Overview

### Tables

| Table | Description |
|-------|-------------|
| `profiles` | User profiles linked to Supabase Auth |
| `sheep` | Individual sheep records with health tracking |
| `health_events` | Medical history and health events |
| `daily_tasks` | Task management and reminders |

### Views

| View | Description |
|------|-------------|
| `upcoming_tasks` | Tasks due in next 7 days |
| `high_risk_sheep` | Sheep with health score < 60 or high risk level |
| `pregnant_sheep_summary` | Summary of all pregnant sheep |
| `recent_health_events` | Health events from last 30 days |
| `vaccination_schedule` | Upcoming vaccinations in next 60 days |
| `flock_statistics` | Aggregate statistics per owner |

### Automatic Features

- **Auto-created profiles**: When a user signs up, a profile is automatically created
- **Auto-updated timestamps**: All tables have `updated_at` that updates automatically
- **Auto-calculated risk levels**: Risk level updates when health score changes
- **Auto-generated tasks**: Tasks are automatically created from health events:
  - Vaccination → Next vaccination in 6 months
  - Deworming → Next deworming in 3 months
  - Illness → Vet follow-up in 1 week
  - Pregnancy → Lambing watch in 145 days

## Security Notes

- All tables have Row Level Security (RLS) enabled
- Users can only access their own data
- The `anon` key is safe to use in client-side code
- Never expose the `service_role` key in client code
- Supabase handles authentication and authorization automatically

## Support

- **Supabase Docs**: https://supabase.com/docs
- **Supabase Discord**: https://discord.supabase.com
- **Project Issues**: Create an issue in your GitHub repository

---

**Happy farming! 🐑**
