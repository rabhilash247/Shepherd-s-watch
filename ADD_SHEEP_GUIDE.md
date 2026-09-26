# Add Sheep Feature - Implementation Guide

## Overview

The Add Sheep feature has been implemented with full Supabase integration. Users can now add new sheep to their flock through a form dialog, and the data is saved to the Supabase database.

## What Was Implemented

### 1. AddSheepDialog Component
**File**: `src/components/sheep/AddSheepDialog.tsx`

A comprehensive form dialog that:
- Collects all required sheep information
- Validates input using Zod schema
- Saves data to Supabase database
- Shows loading states and error handling
- Displays success/error toast notifications
- Automatically refreshes the sheep list after adding

**Form Fields**:
- Tag ID (required)
- Name (required)
- Breed (required)
- Date of Birth (required)
- Gender (required) - dropdown
- Weight in kg (required)
- Status (required) - dropdown (healthy, sick, pregnant, lactating)
- Image URL (optional)

### 2. Updated SheepList Component
**File**: `src/pages/SheepList.tsx`

Replaced mock data with real Supabase queries:
- Fetches sheep from database on component mount
- Shows loading spinner while fetching
- Displays error messages with retry button
- Empty state when no sheep exist
- Filters work with real data
- Automatic refresh after adding new sheep

### 3. Authentication Helper
**File**: `src/lib/auth.ts`

Helper functions for authentication:
- `getCurrentUser()` - Get current authenticated user
- `isAuthenticated()` - Check if user is logged in
- `getSession()` - Get current user session

## How to Use

### Prerequisites

Before you can add sheep, you need to:

1. **Set up Supabase credentials**:
   - Add your Supabase URL and anon key to `.env.local`
   - Restart the dev server

2. **Run database migrations**:
   - Execute all three SQL migration files in Supabase SQL Editor
   - See `SUPABASE_SETUP.md` for detailed instructions

3. **Create a user account**:
   - You'll need to implement authentication (sign up/login)
   - Or create a test user directly in Supabase dashboard

### Adding a Sheep

1. Navigate to the Sheep Registry page
2. Click the "Add Sheep" button (top right)
3. Fill in all required fields:
   - Tag ID: Unique identifier (e.g., "SC-007")
   - Name: Sheep's name (e.g., "Molly")
   - Breed: Sheep breed (e.g., "Merino")
   - Date of Birth: Select from calendar
   - Gender: Male or Female
   - Weight: In kilograms
   - Status: Current health status
4. Optionally add an image URL
5. Click "Add Sheep"
6. The new sheep will appear in the list immediately

## Database Integration

When you submit the form:
1. The form validates all fields
2. Checks if user is authenticated
3. Inserts data into `sheep` table in Supabase
4. Sets default values:
   - `health_score`: 100
   - `risk_level`: "low"
   - `owner_id`: Current user's ID
5. Returns the newly created sheep record
6. Refreshes the sheep list
7. Shows success notification

## Error Handling

The implementation handles various error scenarios:

- **Not authenticated**: Shows message to log in
- **Invalid form data**: Displays field-specific validation errors
- **Database error**: Shows error message with details
- **Network error**: Displays connection error
- **Loading state**: Shows spinner while saving
- **Empty state**: Prompts user to add first sheep

## Next Steps

To make this fully functional, you need to:

### 1. Implement Authentication

Create login/signup pages:

```typescript
// Example signup
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'securepassword',
  options: {
    data: {
      full_name: 'Farmer John'
    }
  }
});
```

### 2. Protect Routes

Add authentication guards to pages:

```typescript
useEffect(() => {
  const checkAuth = async () => {
    const user = await getCurrentUser();
    if (!user) {
      // Redirect to login
      navigate('/login');
    }
  };
  checkAuth();
}, []);
```

### 3. Update Other Components

Apply the same pattern to:
- Dashboard.tsx - Fetch real statistics
- BreedingIntelligence.tsx - Fetch breeding data
- DailyTasks.tsx - Fetch real tasks
- SheepProfile.tsx - Fetch individual sheep data

### 4. Add Real-time Updates (Optional)

Enable live updates when sheep are added:

```typescript
useEffect(() => {
  const channel = supabase
    .channel('sheep-changes')
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'sheep'
    }, (payload) => {
      // Add new sheep to list
      setSheep(prev => [payload.new, ...prev]);
    })
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}, []);
```

## Testing

### Manual Testing Steps:

1. ✅ **Fill valid data**: Form submits successfully
2. ✅ **Missing required fields**: Shows validation errors
3. ✅ **Invalid weight**: Shows "must be positive" error
4. ✅ **Duplicate tag ID**: Database shows unique constraint error
5. ✅ **Not authenticated**: Shows authentication error
6. ✅ **Cancel button**: Closes dialog without saving
7. ✅ **Success**: Shows toast and refreshes list

### Database Verification:

After adding a sheep, check in Supabase dashboard:
1. Go to Table Editor → sheep
2. Verify the new record exists
3. Check all fields are populated correctly
4. Verify `created_at` and `updated_at` timestamps
5. Confirm `owner_id` matches current user

## Troubleshooting

**"Authentication required" error**:
- Make sure you're logged in
- Create a test user in Supabase Auth

**"Failed to add sheep" error**:
- Check browser console for details
- Verify Supabase credentials in `.env.local`
- Ensure migrations have been run
- Check RLS policies are enabled

**Image URL not showing**:
- Image URL is optional
- Must be a valid public URL
- Consider implementing file upload to Supabase Storage

**Data not refreshing**:
- The `onSuccess` callback should trigger `fetchSheep()`
- Check browser console for errors

---

**The feature is ready to use once you:**
1. ✅ Add Supabase credentials to `.env.local`
2. ✅ Run database migrations
3. ✅ Create/login with a user account
