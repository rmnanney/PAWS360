# PAWS360 - Testing Checklist

Use this checklist to verify all features are working correctly.

## 🔐 Initial Setup

- [ ] Extracted zip file successfully
- [ ] Ran `./scripts/setup/setup-from-scratch.sh` without errors
- [ ] PostgreSQL container started (`docker ps | grep paws360-postgres`)
- [ ] Backend started successfully (check for "Started Paws360Application" message)
- [ ] Frontend started successfully (check for "ready started server" message)
- [ ] Can access http://localhost:3000

## 🔑 Authentication

- [ ] Login page loads correctly
- [ ] Can login with test@uwm.edu / password
- [ ] Redirects to homepage after successful login
- [ ] Can see user name in header ("Test Student")
- [ ] Logout button works and returns to login page

## 🏠 Homepage

- [ ] Homepage loads with UWM background image
- [ ] All cards are visible:
  - [ ] Academic Records
  - [ ] Class Search
  - [ ] Enrollment Date
  - [ ] Finances
  - [ ] Personal Information
  - [ ] Quick Links
  - [ ] Holds & Tasks
- [ ] Clicking each card navigates to the correct page

## 🎓 Academic Records Page

- [ ] Page loads without errors
- [ ] Overview cards show:
  - [ ] Cumulative GPA
  - [ ] Academic Standing
  - [ ] Graduation Progress
  - [ ] Current Semester
- [ ] Tabs are present (Current Grades, Transcript, GPA History)
- [ ] Each tab displays appropriate content or "no data" message
- [ ] "Download Transcript" button is visible

## 📚 Courses

### Course Search
- [ ] Course search page loads
- [ ] Can see "Course catalog unavailable" message (expected - database schema mismatch)

### My Courses
- [ ] "My Courses" page loads
- [ ] Shows enrolled courses or appropriate message

## 📅 Enrollment Dates

- [ ] Page loads successfully
- [ ] Shows enrollment windows:
  - [ ] Spring 2026 (Dec 6, 2025)
  - [ ] Winter 2026 (Oct 18, 2025)
  - [ ] Fall 2025 (May 3, 2025)
- [ ] Spring 2026 shows as "Open now" or "Upcoming"
- [ ] Past terms show as "Closed"
- [ ] Tabs work (Dates & eligibility, Plan & search, My schedule)

## ✅ Holds & Tasks

- [ ] Page loads successfully
- [ ] Shows "0" for all metrics (Academic Holds, Financial Holds, Pending Tasks, To Do Items)
- [ ] All metrics show green (no holds/tasks)
- [ ] Tabs work (Holds, Tasks, Completed)
- [ ] Each tab shows appropriate "no items" message with checkmark icon

## 🎨 UI/UX

### Theme
- [ ] Dark mode toggle is visible in header
- [ ] Clicking toggle switches between light and dark mode
- [ ] Dark mode applies consistently across all pages
- [ ] Login page stays in light mode regardless of toggle

### Responsive Design
- [ ] Sidebar collapses on mobile/small screens
- [ ] All pages are readable on different screen sizes
- [ ] Cards resize appropriately

### Navigation
- [ ] Sidebar navigation works for all items
- [ ] Header search/navigation works
- [ ] Back button works correctly
- [ ] Navigation is smooth without page flickers

## 🔧 Technical Checks

### Backend
- [ ] Backend health check works: `curl http://localhost:8086/actuator/health`
- [ ] Returns `{"status":"UP"}`
- [ ] No errors in backend logs

### Frontend
- [ ] Frontend responds: `curl http://localhost:3000`
- [ ] Returns HTML content
- [ ] No console errors in browser (F12 > Console)
- [ ] No network errors in browser (F12 > Network)

### Database
- [ ] Database is accessible: `docker exec paws360-postgres pg_isready -U paws360`
- [ ] Returns "accepting connections"
- [ ] Test user exists in database

## 🐛 Known Issues (Not Bugs)

These are expected based on current implementation:

- **Course Search**: Shows "unavailable" because imported database schema doesn't match entity model
- **Academic Data**: May show placeholder data or empty states for test user
- **Some Features**: May have limited functionality due to missing backend endpoints

## ✨ Extra Credit

- [ ] Run health check script: `./scripts/setup/health-check.sh`
- [ ] Stop and restart services successfully
- [ ] Check logs in `/tmp/paws360-logs/`
- [ ] Database persists after restart

## 📝 Notes

Space for tester notes, observations, or issues found:

```
[Add notes here]
```

---

## ✅ Sign-off

- **Tester Name**: ___________________
- **Date**: ___________________
- **Overall Status**: Pass / Fail / Partial
- **Ready for Production**: Yes / No / With Fixes

---

**If any items fail**, please note:
1. Which item(s) failed
2. Error messages (if any)
3. Steps to reproduce
4. Screenshots (if applicable)
