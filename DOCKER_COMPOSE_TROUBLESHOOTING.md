# Troubleshooting: Cannot Access Web on Localhost

**Date:** October 15, 2025  
**Issue:** Frontend not accessible after `docker compose up`

## ✅ Current Status

### What's Working:
- ✅ **MySQL**: Running and healthy on port 3306
- ✅ **Backend**: Running and healthy on port 8080
  - Test: http://localhost:8080/actuator/health
- ⏳ **Frontend**: Container running but still installing dependencies

### What's the Issue:
The frontend takes **2-5 minutes** to start because it runs `npm install` every time the container starts.

---

## 🔍 Diagnosis

### Check Container Status:
```powershell
docker compose ps
```

Expected output:
```
concert-backend    Up (healthy)    0.0.0.0:8080->8080/tcp
concert-frontend   Up              0.0.0.0:3000->3000/tcp
concert-mysql      Up (healthy)    0.0.0.0:3306->3306/tcp
```

### Check Frontend Logs:
```powershell
docker logs concert-frontend --tail 50
```

**If you see:**
- `npm install` or `npm warn` → Still installing dependencies (wait)
- `Nuxt 4.x.x` or `Local: http://0.0.0.0:3000` → ✅ Ready!
- Errors → See troubleshooting below

---

## 🎯 Quick Fixes

### Solution 1: Wait for Frontend to Start
The frontend needs time to install dependencies.

**Check if it's ready:**
```powershell
# Follow logs in real-time
docker logs concert-frontend -f
```

**Look for these lines indicating it's ready:**
```
✔ Nuxt is ready!
  ▶ Local: http://0.0.0.0:3000
```

Then access: **http://localhost:3000/concert/**

---

### Solution 2: Pre-install Dependencies
Speed up future starts by pre-installing node_modules locally:

```powershell
cd main_frontend/concert1
npm install
```

Then restart:
```powershell
docker compose restart frontend
```

---

### Solution 3: Use the Fixed Dockerfile
Instead of using `node:20-alpine` with command, use the Dockerfile you created:

**Update `docker-compose.yml`:**
```yaml
  frontend:
    build:
      context: ./main_frontend/concert1
      dockerfile: Dockerfile
    container_name: concert-frontend
    restart: always
    environment:
      - NODE_ENV=production
      - NUXT_HOST=0.0.0.0
      - NUXT_PORT=3000
      - NUXT_PUBLIC_API_BASE=http://localhost:8080
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - concert-network
```

Then rebuild:
```powershell
docker compose down
docker compose build frontend
docker compose up -d
```

---

## 🧪 Test Access Points

### Backend API (Should work immediately):
```powershell
# Health check
curl http://localhost:8080/actuator/health

# API test
curl http://localhost:8080/api/auth/test
```

### Frontend (Needs 2-5 minutes):
```powershell
# Open in browser
start http://localhost:3000/concert/
```

**If you get "This site can't be reached":**
- Frontend is still starting
- Check logs: `docker logs concert-frontend -f`
- Wait for "Nuxt is ready!" message

---

## 🔍 Common Issues

### Issue 1: Port Already in Use

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:3000: bind: Only one usage of each socket address
```

**Solution:**
```powershell
# Find what's using port 3000
netstat -ano | findstr :3000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F

# Restart
docker compose up -d
```

---

### Issue 2: Frontend Keeps Restarting

**Check logs:**
```powershell
docker logs concert-frontend --tail 100
```

**Common causes:**
- Missing `package.json` → Check `main_frontend/concert1/package.json` exists
- Port conflict → Change port in docker-compose.yml
- Memory issues → Increase Docker Desktop memory

---

### Issue 3: Frontend Shows 404 or Blank Page

**Solution:**
Access the correct URL:
- ✅ **Correct**: http://localhost:3000/concert/
- ❌ **Wrong**: http://localhost:3000/

The app is served under `/concert/` path.

---

### Issue 4: "Cannot connect to backend"

**Check backend is running:**
```powershell
curl http://localhost:8080/actuator/health
```

**If backend is down:**
```powershell
# Check backend logs
docker logs concert-backend --tail 50

# Restart backend
docker compose restart backend
```

---

## ⚡ Quick Start Commands

### Start Everything:
```powershell
docker compose up -d
```

### Check Status:
```powershell
# See all containers
docker compose ps

# Check frontend is ready
docker logs concert-frontend --tail 20
```

### Access the Application:
```powershell
# Wait for frontend to show "Nuxt is ready!"
# Then open browser to:
start http://localhost:3000/concert/
```

### Stop Everything:
```powershell
docker compose down
```

### Restart Just Frontend:
```powershell
docker compose restart frontend
docker logs concert-frontend -f
```

---

## 📊 Expected Startup Timeline

```
Time    | Status
--------|-----------------------------------------------
0:00    | docker compose up
0:05    | MySQL starts
0:10    | Backend starts (waiting for MySQL)
0:15    | Backend healthy ✅
0:15    | Frontend starts npm install
1:00    | Frontend dependencies installing...
2:00    | Frontend still installing...
3:00    | Frontend build starts
4:00    | Nuxt dev server starting
4:30    | ✅ Frontend ready! http://localhost:3000/concert/
```

---

## 🚀 Faster Alternative: Use Dockerfile

The current `docker-compose.yml` runs `npm install` every time.

**Better approach** - Use the Dockerfile you created:

1. **Update docker-compose.yml** (see Solution 3 above)
2. **Build once:**
   ```powershell
   docker compose build
   ```
3. **Start:**
   ```powershell
   docker compose up -d
   ```
4. **Frontend starts in ~10 seconds** instead of 3-5 minutes!

---

## 📋 Checklist

- [ ] Run `docker compose up -d`
- [ ] Wait 1-2 minutes
- [ ] Check backend: http://localhost:8080/actuator/health
- [ ] Wait 3-5 minutes total
- [ ] Check frontend logs: `docker logs concert-frontend -f`
- [ ] Look for "Nuxt is ready!" message
- [ ] Access: http://localhost:3000/concert/
- [ ] Login with: john@example.com / password123

---

## 🎯 Current Recommendation

**Right now, you need to wait for frontend to finish installing dependencies.**

**Monitor it:**
```powershell
docker logs concert-frontend -f
```

**When you see:**
```
✔ Nuxt is ready!
  ▶ Local: http://0.0.0.0:3000
```

**Then access:**
http://localhost:3000/concert/

---

**Status:** ⏳ **Frontend is starting (installing dependencies)**  
**Action:** **Wait 2-5 minutes** or use the Dockerfile approach for faster starts
