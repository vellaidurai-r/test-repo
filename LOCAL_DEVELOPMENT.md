# 🏃 Local Development & Testing Guide

## Quick Start - Run Locally in 3 Steps

### Step 1: Navigate to Project Directory
```bash
cd /Users/white/Tech/ci-cd/hello-world-node
```

### Step 2: Install Dependencies (First time only)
```bash
npm install
```

**Output should show:**
```
added 68 packages, and audited 69 packages in 1s
```

### Step 3: Start the Application
```bash
npm start
```

**Output should show:**
```
> hello-world-node@1.0.0 start
> node app.js

App listening at http://0.0.0.0:3000
```

---

## Test the Application

### Option 1: Using curl (in another terminal)
```bash
curl http://localhost:3000/
```

**Expected response:**
```
Hello World!
```

### Option 2: Open in Browser
```
http://localhost:3000/
```

You should see: **"Hello World!"** ✅

### Option 3: Using VS Code Terminal
1. Open VS Code
2. Open terminal (Ctrl+`)
3. Make sure you're in `/Users/white/Tech/ci-cd/hello-world-node`
4. Run: `npm start`
5. In another terminal tab (Ctrl+Shift+`), run: `curl http://localhost:3000/`

---

## Using the Run Script

Instead of typing commands each time, use the provided script:

```bash
chmod +x /Users/white/Tech/ci-cd/hello-world-node/run-local.sh
./run-local.sh
```

This script:
- ✅ Checks if dependencies are installed
- ✅ Validates app.js exists
- ✅ Starts the application
- ✅ Shows you where to access it

---

## Project Structure

```
hello-world-node/
├── app.js                 # Main application file
├── package.json          # Dependencies and scripts
├── package-lock.json     # Locked dependency versions
├── Dockerfile            # Docker container definition
├── .github/
│   └── workflows/
│       └── ci-cd.yml     # GitHub Actions CI/CD
├── ecs-task-def.json     # AWS ECS task definition
└── README.md             # Documentation
```

---

## Understanding the Code

### app.js
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`App listening at http://0.0.0.0:${port}`);
});
```

**Breakdown:**
- `express` - Web framework
- `app.get('/', ...)` - Handle GET requests to `/`
- `port` - Listen on port 3000 (or PORT env variable)
- `'0.0.0.0'` - Listen on all network interfaces
- `res.send('Hello World!')` - Send response

### package.json
```json
{
  "name": "hello-world-node",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

**Breakdown:**
- `"start": "node app.js"` - What `npm start` runs
- `dependencies` - Required packages (Express)

---

## Modifying the Application

### Add a New Route

Edit `app.js` and add:

```javascript
app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello World!', timestamp: new Date() });
});
```

Then test:
```bash
curl http://localhost:3000/api/hello
```

### Change the Response

Edit the response in `app.js`:

```javascript
app.get('/', (req, res) => {
  res.send('Hello from my local machine!');
});
```

### Change the Port

Option 1: Set environment variable
```bash
PORT=8080 npm start
```

Option 2: Edit the code
```javascript
const port = process.env.PORT || 8080;  // Changed from 3000
```

---

## Common Issues

### Issue: "npm: command not found"
**Solution:** Install Node.js from https://nodejs.org/

```bash
node --version
npm --version
```

Should show version numbers (e.g., v18.16.0, 9.5.0)

---

### Issue: "Error: listen EADDRINUSE :::3000"
**Cause:** Another app is using port 3000

**Solution 1:** Kill the process using port 3000
```bash
lsof -i :3000          # Find process ID
kill -9 <process-id>   # Kill it
npm start              # Start again
```

**Solution 2:** Use a different port
```bash
PORT=3001 npm start
```

---

### Issue: "Cannot find module 'express'"
**Cause:** Dependencies not installed

**Solution:** Run npm install
```bash
npm install
npm start
```

---

### Issue: "app.js not found"
**Cause:** You're in the wrong directory

**Solution:** Navigate to the correct directory
```bash
cd /Users/white/Tech/ci-cd/hello-world-node
npm start
```

---

## Testing Workflow

### Local Development Cycle

1. **Start the app**
   ```bash
   npm start
   ```

2. **Test in browser or curl**
   ```bash
   curl http://localhost:3000/
   ```

3. **Make changes to app.js** (stop server with Ctrl+C first if needed)

4. **Restart and test**
   ```bash
   npm start
   curl http://localhost:3000/
   ```

5. **Once happy with changes**
   ```bash
   git add app.js
   git commit -m "Update: Changed response message"
   git push
   ```
   → GitHub Actions automatically deploys to AWS!

---

## Environment Variables

### Set Custom Environment
```bash
PORT=3001 NODE_ENV=development npm start
```

### Use Environment Variables in Code
```javascript
const port = process.env.PORT || 3000;
const env = process.env.NODE_ENV || 'development';
console.log(`Running in ${env} mode on port ${port}`);
```

---

## Debugging

### Enable Verbose Logging
```javascript
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});
```

### Check Network Connections
```bash
netstat -an | grep 3000
# or
lsof -i :3000
```

### Check Node Version Issues
```bash
node --version
npm list express
```

---

## Next Steps

1. ✅ Run the app locally and verify it works
2. ✅ Test it in browser: `http://localhost:3000/`
3. ✅ Try making code changes
4. ✅ Push to GitHub to trigger CI/CD deployment
5. ✅ Watch GitHub Actions build and deploy
6. ✅ Access your deployed app on AWS!

---

## Useful Commands

```bash
# Install dependencies
npm install

# Start application
npm start

# Test with curl
curl http://localhost:3000/

# Check if port is in use
lsof -i :3000

# View logs in real-time
npm start  # Shows logs directly

# Stop the application
Ctrl + C

# Install a specific package
npm install <package-name>

# Update packages
npm update
```

---

## CI/CD Pipeline Reminder

Once you verify the app works locally:

1. Push to GitHub main branch
2. GitHub Actions automatically:
   - Builds Docker image
   - Pushes to ECR
   - Deploys to ECS
3. Your app is live on AWS!

**No manual deployment needed!** 🚀
