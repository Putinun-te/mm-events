# Git Remote Configuration

## Current Remotes

This repository has **two** remotes configured:

```bash
origin  → https://github.com/MorningMores/Test.git
devops  → https://github.com/MorningMores/develop.git  ✅ PRIMARY
```

## ⚠️ IMPORTANT: Always Push to `devops`

The **primary repository** is `MorningMores/develop`, accessible via the `devops` remote.

### Correct Push Commands

```bash
# For k8s-development branch
git push devops k8s-development

# For main branch  
git push devops main

# Set upstream to devops (one-time setup)
git branch --set-upstream-to=devops/k8s-development k8s-development
```

### After Setting Upstream

Once you set the upstream, you can simply use:
```bash
git push
```

## Quick Reference

| Action | Command |
|--------|---------|
| Push current branch | `git push devops HEAD` |
| Push with upstream | `git push -u devops k8s-development` |
| Force push (careful!) | `git push devops k8s-development --force-with-lease` |
| Check remotes | `git remote -v` |
| Fetch from devops | `git fetch devops` |

## Set Default Remote for Current Branch

To avoid typing `devops` every time:

```bash
# Set devops as upstream for k8s-development
git branch --set-upstream-to=devops/k8s-development k8s-development

# Now you can just use:
git push
git pull
```

## GitHub URLs

- **Primary Repository:** https://github.com/MorningMores/develop
- **Test Repository:** https://github.com/MorningMores/Test

---

**Last Updated:** October 18, 2025  
**Current Branch:** k8s-development → devops/k8s-development
