# 🐑 Shepherd's Watch

A comprehensive **digital flock management system** for farmers and shepherds to monitor, track, and manage their sheep with ease. Built with modern web technologies and real-time database integration.

## 📋 Table of Contents

- [About](#about)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Environment Setup](#environment-setup)
- [Database Setup](#database-setup)
- [First-Time Setup Guide](#first-time-setup-guide)
- [Running the Application](#running-the-application)
- [Project Structure](#project-structure)
- [Available Scripts](#available-scripts)
- [Usage Guide](#usage-guide)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Support](#support)

## 📖 About

**Shepherd's Watch** is a digital solution designed to help farmers manage their flocks efficiently. Whether you're tracking individual sheep health, managing breeding schedules, monitoring daily tasks, or keeping detailed health records, Shepherd's Watch provides an intuitive interface to manage all aspects of sheep farming.

### Key Goals

- 🎯 Simplify sheep flock management
- 📊 Provide real-time health monitoring and analytics
- 🐑 Track breeding, vaccination, and health schedules
- 📱 Enable farmers to access data anytime, anywhere
- 🔒 Secure data with authentication and row-level security

## ✨ Features

### Sheep Registry
- **Add & Track Sheep**: Register individual sheep with tag ID, name, breed, DOB, gender, and weight
- **Health Status**: Monitor current health status (healthy, sick, pregnant, lactating)
- **Image Support**: Upload and view sheep images for easy identification
- **Real-time Database**: All data synced with Supabase

### Health Monitoring
- **Health Score Tracking**: Numerical health scores (0-100) for each sheep
- **Health Events**: Log medical events, vaccinations, deworming, illnesses
- **Risk Assessment**: Automatic risk level calculation based on health metrics
- **Medical History**: Complete audit trail of all health interventions

### Task Management
- **Daily Tasks**: Create and track daily farming tasks
- **Smart Reminders**: Automated task generation for:
  - Vaccination schedules (every 6 months)
  - Deworming schedules (every 3 months)
  - Follow-up appointments
  - Lambing season alerts

### Breeding Intelligence
- **Breeding Records**: Track breeding history and genealogy
- **Pregnancy Tracking**: Monitor pregnant sheep with estimated lambing dates
- **Breeding Analytics**: View breeding statistics and patterns
- **Genetic Information**: Maintain records for selective breeding

### Dashboard & Analytics
- **Quick Overview**: See flock statistics at a glance
- **Health Insights**: Visual representation of flock health status
- **Task Status**: Prioritized view of upcoming tasks
- **Reports**: Generate detailed reports for farm management

### Security
- **User Authentication**: Secure login with email and password
- **Row Level Security (RLS)**: Users can only access their own data
- **Data Encryption**: All sensitive data encrypted in transit and at rest
- **Permission Control**: Fine-grained access control per resource

## 🛠️ Tech Stack

### Frontend
- **React 18**: Modern UI library with hooks
- **TypeScript**: Type-safe development
- **Vite**: Lightning-fast build tool
- **Tailwind CSS**: Utility-first CSS framework
- **shadcn/ui**: Beautiful, accessible component library
- **React Router**: Client-side navigation
- **React Hook Form**: Efficient form management
- **Zod**: TypeScript-first schema validation
- **Recharts**: Data visualization and charts
- **Framer Motion**: Smooth animations
- **Leaflet & React-Leaflet**: Maps for location tracking

### Backend & Database
- **Supabase**: PostgreSQL database with real-time features
- **Supabase Auth**: User authentication and session management
- **Row Level Security (RLS)**: Database-level access control
- **PostgreSQL Functions**: Custom database logic
- **Supabase Views**: Pre-computed data queries

### Development Tools
- **ESLint**: Code quality and linting
- **Vitest**: Unit testing framework
- **Tailwind CSS**: Styling
- **Vite PWA**: Progressive Web App support

## 📋 Prerequisites

Before you begin, ensure you have:

- **Node.js** (v16 or higher) - [Download](https://nodejs.org/)
- **npm** or **yarn** - Comes with Node.js
- **Git** - [Download](https://git-scm.com/)
- **Supabase Account** - [Sign up free](https://supabase.com)

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yuvarajbtalawar99-creator/shepherd-s-watch.git
cd shepherd-s-watch
```

### 2. Install Dependencies

```bash
npm install
```

This will install all required packages from `package.json`.

### 3. Verify Installation

```bash
npm --version
node --version
```

## ⚙️ Environment Setup

### 1. Create Environment File

Create a `.env.local` file in the project root:

```bash
touch .env.local
```

### 2. Add Supabase Credentials

Open `.env.local` and add your Supabase credentials:

```env
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Get Your Credentials

**How to find your Supabase credentials:**

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project (or create a new one)
3. Click **Settings** (gear icon) in the left sidebar
4. Navigate to **API** section
5. Copy:
   - **Project URL** → `VITE_SUPABASE_URL`
   - **anon/public key** → `VITE_SUPABASE_ANON_KEY`

> ⚠️ **Important**: 
> - Never commit `.env.local` to version control (it's in `.gitignore`)
> - Use the **anon/public** key, NOT the service_role key
> - Restart the dev server after updating `.env.local`

## 🗄️ Database Setup

### Step 1: Create Supabase Project

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Click **New Project**
3. Fill in project details:
   - **Name**: `shepherd-s-watch`
   - **Database Password**: Create a strong password
   - **Region**: Select closest to you
4. Click **Create new project**
5. Wait 2-3 minutes for initialization

### Step 2: Run Database Migrations

You have two options:

#### Option A: Using Supabase SQL Editor (Recommended)

1. In Supabase dashboard, click **SQL Editor**
2. Click **New Query**
3. Copy contents from `supabase/migrations/001_initial_schema.sql`
4. Paste into SQL editor and click **Run**
5. Repeat for:
   - `supabase/migrations/002_rls_policies.sql`
   - `supabase/migrations/003_functions_views.sql`

#### Option B: Using Supabase CLI (Advanced)

```bash
# Install Supabase CLI
npm install -g supabase

# Link your project
supabase link --project-ref your-project-id

# Run migrations
supabase db push
```

### Step 3: Verify Setup

Check in Supabase dashboard:

1. Go to **Table Editor**
2. Verify these tables exist:
   - ✅ `profiles`
   - ✅ `sheep`
   - ✅ `health_events`
   - ✅ `daily_tasks`

3. Go to **Authentication** → **Policies**
4. Verify RLS is enabled on all tables

## 🎯 First-Time Setup Guide

### Complete Setup Checklist

Follow these steps in order for a complete setup:

```
✅ Step 1: Clone Repository
   └─ git clone <repo>

✅ Step 2: Install Dependencies
   └─ npm install

✅ Step 3: Create Supabase Project
   └─ Go to supabase.com
   └─ Create new project

✅ Step 4: Create .env.local
   └─ Copy VITE_SUPABASE_URL
   └─ Copy VITE_SUPABASE_ANON_KEY

✅ Step 5: Run Database Migrations
   └─ Run all 3 SQL migration files

✅ Step 6: Start Development Server
   └─ npm run dev

✅ Step 7: Create Test User
   └─ Sign up in the application
   └─ Or create in Supabase dashboard

✅ Step 8: Add First Sheep
   └─ Navigate to Sheep Registry
   └─ Click "Add Sheep" button
   └─ Fill in the form
```

### Quick Start (5 minutes)

```bash
# 1. Clone and install
git clone <repo>
cd shepherd-s-watch
npm install

# 2. Set up environment (edit .env.local with your credentials)
# VITE_SUPABASE_URL=...
# VITE_SUPABASE_ANON_KEY=...

# 3. Start development server
npm run dev

# 4. Open http://localhost:5173 in your browser
```

## ▶️ Running the Application

### Development Mode

Start the development server with hot-reload:

```bash
npm run dev
```

The application will be available at `http://localhost:5173`

### Production Build

Create an optimized production build:

```bash
npm run build
```

Output files will be in the `dist/` directory.

### Preview Build

Preview the production build locally:

```bash
npm run build
npm run preview
```

### Linting

Check code quality:

```bash
npm run lint
```

### Testing

Run unit tests:

```bash
npm run test          # Run tests once
npm run test:watch   # Run tests in watch mode
```

## 📁 Project Structure

```
shepherd-s-watch/
├── src/
│   ├── components/           # Reusable React components
│   │   ├── sheep/            # Sheep-related components
│   │   ├── health/           # Health tracking components
│   │   ├── tasks/            # Task management components
│   │   └── ui/               # shadcn/ui components
│   ├── pages/                # Page components (routes)
│   │   ├── Dashboard.tsx
│   │   ├── SheepList.tsx
│   │   ├── SheepProfile.tsx
│   │   ├── BreedingIntelligence.tsx
│   │   └── DailyTasks.tsx
│   ├── lib/                  # Utility functions
│   │   ├── supabase.ts       # Supabase client
│   │   ├── auth.ts           # Authentication helpers
│   │   └── utils.ts          # Utility functions
│   ├── hooks/                # Custom React hooks
│   ├── types/                # TypeScript type definitions
│   ├── styles/               # Global styles
│   └── App.tsx               # Main app component
├── supabase/
│   └── migrations/           # Database migration files
│       ├── 001_initial_schema.sql
│       ├── 002_rls_policies.sql
│       └── 003_functions_views.sql
├── public/                   # Static assets
├── .env.local                # Environment variables (local)
├── vite.config.ts            # Vite configuration
├── tailwind.config.ts        # Tailwind CSS configuration
├── tsconfig.json             # TypeScript configuration
├── package.json              # Dependencies and scripts
└── README.md                 # This file
```

## 📜 Available Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with HMR |
| `npm run build` | Build production bundle |
| `npm run preview` | Preview production build locally |
| `npm run lint` | Run ESLint code linting |
| `npm run test` | Run unit tests once |
| `npm run test:watch` | Run tests in watch mode |

## 📖 Usage Guide

### Adding a Sheep

1. Navigate to **Sheep Registry** page
2. Click the **"Add Sheep"** button (top right)
3. Fill in the form:
   - **Tag ID**: Unique identifier (e.g., "SC-001")
   - **Name**: Sheep's name
   - **Breed**: Sheep breed (e.g., Merino, Romney, Jacob)
   - **Date of Birth**: Select from calendar
   - **Gender**: Male or Female
   - **Weight**: In kilograms
   - **Status**: Health status
   - **Image URL** (optional): Link to sheep image
4. Click **"Add Sheep"**
5. View in the sheep list

### Recording Health Events

1. Go to **Sheep Registry**
2. Click on a sheep to view its profile
3. In the **Health** tab, click **"Add Health Event"**
4. Select event type:
   - Vaccination
   - Deworming
   - Illness
   - Injury
   - Pregnancy
5. Fill in details and add notes
6. Click **"Save Event"**

### Creating Tasks

1. Navigate to **Daily Tasks**
2. Click **"New Task"**
3. Enter task details:
   - Title
   - Description
   - Due date
   - Priority level
   - Related sheep (optional)
4. Click **"Create Task"**
5. Mark as complete when finished

### Viewing Breeding Information

1. Go to **Breeding Intelligence**
2. View pregnant sheep and breeding history
3. Check estimated lambing dates
4. Review breeding records and genealogy

### Dashboard Overview

1. **Dashboard** shows:
   - Total flock count
   - Health statistics
   - Upcoming tasks
   - Recent health events
   - Risk assessments

## 🆘 Troubleshooting

### Issue: "Invalid API key" Error

**Solution:**
```bash
# 1. Check .env.local file
cat .env.local

# 2. Verify you're using anon key, not service_role key

# 3. Restart dev server
npm run dev
```

### Issue: Tables Not Found in Database

**Solution:**
1. Verify all 3 migrations ran successfully
2. Check Supabase dashboard → Table Editor
3. Re-run migrations if needed

### Issue: "Authentication required" Error

**Solution:**
```typescript
// Create a test user in Supabase dashboard
// Or implement the signup page:
1. Go to Supabase Dashboard
2. Go to Authentication
3. Click "Create user" button
4. Enter email and password
```

### Issue: Development Server Won't Start

**Solution:**
```bash
# Clear node_modules and reinstall
rm -rf node_modules
npm install

# Clear Vite cache
rm -rf .vite

# Start again
npm run dev
```

### Issue: TypeScript Errors

**Solution:**
```bash
# Regenerate types from Supabase schema
supabase gen types typescript --project-id your-project-id > src/lib/database.types.ts
```

### Issue: Data Not Refreshing

**Solution:**
- Check browser console (F12) for errors
- Verify RLS policies are enabled
- Ensure you're logged in
- Try a hard refresh (Ctrl+Shift+R)

## 🌐 Environment Variables Reference

```env
# Required - Your Supabase project credentials
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-public-key

# Optional - For additional features
# VITE_API_URL=http://localhost:3000
# VITE_ENABLE_ANALYTICS=true
```

## 📚 Additional Resources

### Documentation
- [React Documentation](https://react.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [shadcn/ui Components](https://ui.shadcn.com)

### Supabase Guides
- **Supabase Setup**: See `SUPABASE_SETUP.md`
- **Adding Sheep**: See `ADD_SHEEP_GUIDE.md`
- **Database Queries**: See `DATABASE_QUERIES.md`

### Getting Help
- Check the [Troubleshooting](#troubleshooting) section
- Review Supabase [documentation](https://supabase.com/docs)
- Join [Supabase Discord](https://discord.supabase.com)
- Check [GitHub Issues](https://github.com/yuvarajbtalawar99-creator/shepherd-s-watch/issues)

## 🔐 Security Best Practices

1. **Never commit `.env.local`** - It's in `.gitignore` for a reason
2. **Use anon key in frontend** - The service_role key stays on backend only
3. **Enable RLS on all tables** - Prevents unauthorized data access
4. **Validate input** - Use Zod schemas for all forms
5. **Use HTTPS** - Always use secure connections in production

## 📞 Support

### Getting Help

1. **Check Documentation**
   - Review SUPABASE_SETUP.md for database issues
   - Check ADD_SHEEP_GUIDE.md for feature help
   - See DATABASE_QUERIES.md for query examples

2. **Debug Steps**
   - Open browser console (F12)
   - Check for error messages
   - Verify environment variables
   - Test Supabase connection

3. **Create an Issue**
   - Go to [GitHub Issues](https://github.com/yuvarajbtalawar99-creator/shepherd-s-watch/issues)
   - Describe the problem clearly
   - Include error messages and steps to reproduce

## 👨‍💻 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Built with [React](https://react.dev)
- Database by [Supabase](https://supabase.com)
- UI Components from [shadcn/ui](https://ui.shadcn.com)
- Icons by [Lucide React](https://lucide.dev)
- Styling with [Tailwind CSS](https://tailwindcss.com)

---

**Happy farming! 🐑✨**

For the latest updates and news, follow this repository and check the [GitHub page](https://github.com/yuvarajbtalawar99-creator/shepherd-s-watch).
