# Frontend Artifact Download Fix

## Problem

```
Error: Unable to download artifact(s): Artifact not found for name: frontend-dist
Please ensure that your artifact is not expired and the artifact was uploaded using a compatible version of toolkit/upload-artifact.
```

## Root Cause

The `frontend-dist` artifact was not being created successfully because:
1. The `.output` directory might not exist after `npm run build`
2. No verification was in place to ensure the build actually produced the expected output
3. Silent failures in the upload step

## Solution Applied

### 1. Added Build Verification Step (Line 83-96)

```yaml
- name: 🔍 Verify build output
  working-directory: main_frontend/concert1
  run: |
    echo "Checking build output..."
    ls -la
    if [ -d ".output" ]; then
      echo "✅ .output directory exists"
      ls -la .output/
    else
      echo "❌ .output directory not found"
      echo "Available directories:"
      find . -maxdepth 2 -type d
      exit 1
    fi
```

**Purpose:** Fails the job immediately if `.output` doesn't exist after build

### 2. Enhanced Artifact Upload (Line 98-104)

```yaml
- name: 📤 Upload frontend dist
  uses: actions/upload-artifact@v4
  with:
    name: frontend-dist
    path: main_frontend/concert1/.output/
    retention-days: 1
    if-no-files-found: error  # Fail if no files found
```

**Purpose:** Explicitly fails if the upload finds no files

### 3. Added Download Verification (Line 159-163)

```yaml
- name: 🔍 Verify frontend artifact
  run: |
    echo "Checking downloaded frontend artifact..."
    ls -la main_frontend/concert1/.output/ || echo "❌ .output directory is empty or missing"
```

**Purpose:** Confirms the artifact was downloaded successfully before Docker build

## Testing

### Local Build Test

```bash
cd main_frontend/concert1
npm ci
npm run build
ls -la .output
```

**Expected output:**
```
.output/
├── nitro.json
├── public/
└── server/
```

### Workflow Test

The workflow will now:
1. ✅ Build the frontend
2. ✅ Verify `.output` exists (fail if missing)
3. ✅ Upload artifact with error on empty
4. ✅ Download artifact in build-images job
5. ✅ Verify download succeeded
6. ✅ Build Docker image

## Troubleshooting

### If `.output` Still Doesn't Exist

**Check Nuxt Configuration:**
```javascript
// nuxt.config.ts
export default defineNuxtConfig({
  // Ensure SSR is enabled for .output generation
  ssr: true,
  
  // Check build configuration
  nitro: {
    output: {
      dir: '.output'
    }
  }
})
```

### If Artifact Upload Fails

**Possible causes:**
1. Build step failed silently - check logs
2. Permission issues - ensure runner has write access
3. Path is incorrect - verify with `find . -name ".output" -type d`

### Alternative: Build in Docker

If artifacts continue to be problematic, we can build directly in Docker (Dockerfile.k8s already has build step):

```yaml
# Remove artifact dependency
- name: 🐳 Build and push frontend image
  uses: docker/build-push-action@v5
  with:
    context: main_frontend/concert1
    file: main_frontend/concert1/Dockerfile.k8s
    # Docker will run `npm run build` internally
```

## Next Steps

1. **Monitor the workflow** - Check if verification steps pass
2. **Check build logs** - Look for `.output` directory confirmation
3. **Verify artifact** - Ensure it appears in Actions artifacts tab

If issues persist, we can switch to Docker-based builds (no artifacts needed).

---

**Updated:** October 18, 2025  
**Status:** ✅ Verification steps added  
**Commit:** c1153c2
