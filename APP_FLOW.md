# Application Flow & User Journeys

## User Flow Diagram

```
                    ┌─────────────────┐
                    │   Splash Screen │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Authentication │
                    │  (Login/Register)│
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
        ┌──────────────┐         ┌──────────────┐
        │ Coach Role   │         │ Client Role  │
        └──────┬───────┘         └──────┬───────┘
               │                        │
               ▼                        ▼
    ┌──────────────────┐    ┌──────────────────┐
    │  Coach Dashboard │    │  Client Dashboard│
    └──────────────────┘    └──────────────────┘
```

## Coach User Journey

### 1. Onboarding
```
Splash → Login/Register → Role Selection (Coach) → Profile Setup → Coach Dashboard
```

### 2. Workout Management Flow
```
Dashboard → Workouts → Create Workout → Add Exercises → Save → Assign to Client(s)
```

### 3. Meal Plan Management Flow
```
Dashboard → Meal Plans → Create Meal Plan → Add Meals → Set Nutrition → Assign to Client(s)
```

### 4. Client Management Flow
```
Dashboard → Clients → Select Client → View Profile → View Progress → Assign Workout/Meal Plan
```

### 5. Analytics Flow
```
Dashboard → Analytics → Select Client/Date Range → View Charts → Export Report
```

## Client User Journey

### 1. Onboarding
```
Splash → Login/Register → Role Selection (Client) → Profile Setup → Client Dashboard
```

### 2. Workout Tracking Flow
```
Dashboard → My Workouts → Select Workout → View Exercises → Log Sets/Reps → Mark Complete
```

### 3. Water Tracking Flow
```
Dashboard → Water Tracker → Set Goal → Log Water → View Progress → View Statistics
```

### 4. Step Tracking Flow
```
Dashboard → Steps → Grant Permissions → View Steps → Set Goal → View History
```

### 5. Meal Plan Viewing Flow
```
Dashboard → Meal Plans → Select Plan → View Meals → View Recipes → Generate Shopping List
```

### 6. Progress Tracking Flow
```
Dashboard → Progress → Log Weight → Add Measurements → Upload Photo → View Charts
```

## Feature Interaction Flow

### Coach → Client Communication
```
Coach creates workout → Assigns to client → Client receives notification → 
Client views workout → Client completes workout → Coach sees completion status
```

### Data Synchronization
```
Client logs data (offline) → Sync when online → Coach sees updated data → 
Coach responds → Client receives update
```

## Screen Navigation Structure

### Coach App Navigation
```
Coach Dashboard (Bottom Nav)
├── Home
│   ├── Recent Activity
│   ├── Quick Stats
│   └── Client Overview
├── Workouts
│   ├── Workout List
│   ├── Create Workout
│   └── Workout Detail
├── Meal Plans
│   ├── Meal Plan List
│   ├── Create Meal Plan
│   └── Meal Plan Detail
├── Clients
│   ├── Client List
│   ├── Client Profile
│   └── Client Progress
└── Analytics
    ├── Overview
    ├── Client Analytics
    └── Reports
```

### Client App Navigation
```
Client Dashboard (Bottom Nav)
├── Home
│   ├── Today's Workout
│   ├── Water Progress
│   ├── Step Count
│   └── Quick Actions
├── Workouts
│   ├── Assigned Workouts
│   ├── Workout Detail
│   └── Workout History
├── Track
│   ├── Water Tracker
│   ├── Step Counter
│   └── Progress Log
├── Meal Plans
│   ├── Assigned Plans
│   ├── Meal Plan Detail
│   └── Recipes
└── Progress
    ├── Overview
    ├── Weight Chart
    ├── Measurements
    └── Photos
```

## Data Flow Architecture

### Read Flow (Client → Server)
```
UI Widget → Provider → Repository → API Service → Backend API → Database
                                                              ↓
UI Widget ← Provider ← Repository ← API Service ← Backend API ← Database
```

### Write Flow (Client → Server)
```
UI Widget → Provider → Repository → API Service → Backend API → Database
                                                              ↓
UI Widget ← Provider ← Repository ← API Service ← Backend API ← Database
                                                              ↓
                        Local Cache (Hive) ← Sync ← Database
```

## State Management Flow

### Using Riverpod
```
Widget → ref.watch(provider) → Provider → StateNotifier → Repository → API/Storage
                                                                      ↓
Widget ← rebuild ← Provider ← StateNotifier ← Repository ← API/Storage
```

## Authentication Flow

```
App Start → Check Auth Token → Valid? 
                                    ├─ Yes → Load User Data → Navigate to Dashboard
                                    └─ No → Show Login Screen
                                    
Login → Authenticate → Get Token → Store Token → Load User Data → Navigate to Dashboard
```

## Offline-First Flow

```
User Action → Save to Local DB (Hive) → Show in UI → 
Background Sync → Check Network → If Online: Sync to Server → 
If Offline: Queue for later → When Online: Sync queued items
```

## Real-time Updates Flow

```
Coach Action (e.g., assign workout) → Backend → WebSocket/Firebase → 
Client App → Update Provider → Refresh UI → Show Notification
```

## Health Data Integration Flow

### iOS (HealthKit)
```
App Request Permission → User Grants → 
Read Steps from HealthKit → Process Data → 
Store Locally → Sync to Server → Display in UI
```

### Android (Google Fit)
```
App Request Permission → User Grants → 
Read Steps from Google Fit → Process Data → 
Store Locally → Sync to Server → Display in UI
```

## Notification Flow

```
Event Occurs (e.g., workout assigned) → Backend → FCM → 
Device → Local Notification → User Taps → Navigate to Relevant Screen
```

## Error Handling Flow

```
API Call → Error Occurs → 
    ├─ Network Error → Show Offline Message → Queue for Retry
    ├─ Auth Error → Clear Token → Navigate to Login
    ├─ Validation Error → Show Error Message → Allow Retry
    └─ Server Error → Show Error Message → Log Error → Allow Retry
```

## Key User Interactions

### Coach Interactions
1. **Create & Assign Workout**
   - Create workout template
   - Add exercises with details
   - Assign to one or multiple clients
   - Set due date
   - Client receives notification

2. **Monitor Client Progress**
   - View client dashboard
   - Check workout completion
   - Review water/step logs
   - View progress photos
   - Send feedback/messages

3. **Create Meal Plans**
   - Design meal plan
   - Add recipes and nutrition info
   - Assign to clients
   - Track adherence

### Client Interactions
1. **Complete Workout**
   - View assigned workout
   - Follow exercise instructions
   - Log sets, reps, weights
   - Mark as complete
   - Coach sees completion

2. **Track Daily Metrics**
   - Log water intake throughout day
   - Monitor step count (automatic)
   - View daily progress
   - Achieve daily goals

3. **View Progress**
   - Log weight regularly
   - Add body measurements
   - Upload progress photos
   - View charts and trends
   - Share with coach

## Integration Points

### External Services
- **HealthKit/Google Fit**: Step count data
- **Firebase**: Authentication, database, storage, notifications
- **Payment Gateway**: (Future) Subscription management
- **Video Service**: (Future) Exercise videos, video calls

### Internal Services
- **API Service**: Backend communication
- **Auth Service**: Authentication management
- **Storage Service**: Local data persistence
- **Health Service**: Health data integration
- **Notification Service**: Push notifications

---

This flow diagram helps visualize how users interact with the application and how data flows through the system.


