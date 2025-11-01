# ☁️ Azure Blob Storage Integration Guide

## Overview
This guide shows how to integrate **Azure Blob Storage** for storing event images, user profile photos, and other media in your concert platform.

---

## 🎯 Why Azure Blob Storage?

| Feature | Benefit |
|---------|---------|
| **Scalability** | Store unlimited images/files |
| **CDN Integration** | Fast global content delivery via Azure CDN |
| **Security** | Private/public containers, SAS tokens, access policies |
| **Cost-Effective** | Pay only for what you use (~$0.018/GB/month) |
| **Reliability** | 99.9% SLA, automatic redundancy |
| **Integration** | Native support for Spring Boot and Node.js |

---

## 📋 Prerequisites

1. **Azure Account**: [Create free account](https://azure.microsoft.com/free/) (12 months free + $200 credit)
2. **Azure Storage Account**: Create via Azure Portal or CLI
3. **Container**: Blob container for storing files

---

## 🚀 Step-by-Step Setup

### 1. Create Azure Storage Account

#### Option A: Azure Portal
1. Go to [Azure Portal](https://portal.azure.com)
2. Create Resource → Storage Account
3. Configure:
   - **Name**: `concertstorage` (must be globally unique)
   - **Region**: Same as your backend (e.g., East US)
   - **Performance**: Standard
   - **Redundancy**: LRS (Locally Redundant Storage) for dev, GRS for production
4. Create

#### Option B: Azure CLI
```bash
# Login
az login

# Create resource group
az group create --name concert-rg --location eastus

# Create storage account
az storage account create \
  --name concertstorage \
  --resource-group concert-rg \
  --location eastus \
  --sku Standard_LRS

# Get connection string
az storage account show-connection-string \
  --name concertstorage \
  --resource-group concert-rg
```

### 2. Create Blob Containers

```bash
# Get connection string (save this!)
CONNECTION_STRING=$(az storage account show-connection-string \
  --name concertstorage \
  --resource-group concert-rg \
  --output tsv)

# Create containers
az storage container create \
  --name event-images \
  --connection-string "$CONNECTION_STRING" \
  --public-access blob  # Public read access

az storage container create \
  --name user-profiles \
  --connection-string "$CONNECTION_STRING" \
  --public-access blob

az storage container create \
  --name thumbnails \
  --connection-string "$CONNECTION_STRING" \
  --public-access blob
```

**Container Access Levels:**
- `blob` - Public read access to blobs (good for images)
- `container` - Public read access to container and blobs
- `off` - Private (requires authentication)

---

## 🔧 Backend Integration (Spring Boot)

### Step 1: Add Azure Dependency

Add to `main_backend/pom.xml`:

```xml
<dependencies>
    <!-- Existing dependencies... -->
    
    <!-- Azure Blob Storage -->
    <dependency>
        <groupId>com.azure</groupId>
        <artifactId>azure-storage-blob</artifactId>
        <version>12.25.0</version>
    </dependency>
</dependencies>
```

### Step 2: Configuration

Add to `main_backend/src/main/resources/application.properties`:

```properties
# Azure Blob Storage Configuration
azure.storage.connection-string=${AZURE_STORAGE_CONNECTION_STRING}
azure.storage.container.events=event-images
azure.storage.container.users=user-profiles
azure.storage.container.thumbnails=thumbnails

# Azure Blob Storage URL (after upload)
azure.storage.base-url=https://concertstorage.blob.core.windows.net
```

### Step 3: Add to docker-compose.yml

```yaml
services:
  backend:
    environment:
      - AZURE_STORAGE_CONNECTION_STRING=${AZURE_STORAGE_CONNECTION_STRING}
    # ... rest of config
```

Create `.env` file in project root:
```bash
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=concertstorage;AccountKey=YOUR_KEY;EndpointSuffix=core.windows.net
```

### Step 4: Create Azure Service

Create `main_backend/src/main/java/com/concert/service/AzureBlobService.java`:

```java
package com.concert.service;

import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobHttpHeaders;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Service
public class AzureBlobService {

    private final BlobServiceClient blobServiceClient;
    private final String baseUrl;
    
    @Value("${azure.storage.container.events}")
    private String eventsContainer;
    
    @Value("${azure.storage.container.users}")
    private String usersContainer;
    
    @Value("${azure.storage.container.thumbnails}")
    private String thumbnailsContainer;

    public AzureBlobService(
            @Value("${azure.storage.connection-string}") String connectionString,
            @Value("${azure.storage.base-url}") String baseUrl) {
        this.blobServiceClient = new BlobServiceClientBuilder()
                .connectionString(connectionString)
                .buildClient();
        this.baseUrl = baseUrl;
    }

    /**
     * Upload event image to Azure Blob Storage
     */
    public String uploadEventImage(MultipartFile file) throws IOException {
        return uploadFile(file, eventsContainer);
    }

    /**
     * Upload user profile photo to Azure Blob Storage
     */
    public String uploadUserProfile(MultipartFile file) throws IOException {
        return uploadFile(file, usersContainer);
    }

    /**
     * Upload thumbnail to Azure Blob Storage
     */
    public String uploadThumbnail(MultipartFile file) throws IOException {
        return uploadFile(file, thumbnailsContainer);
    }

    /**
     * Generic file upload
     */
    private String uploadFile(MultipartFile file, String containerName) throws IOException {
        // Generate unique filename
        String originalFilename = file.getOriginalFilename();
        String extension = originalFilename != null ? 
            originalFilename.substring(originalFilename.lastIndexOf(".")) : ".jpg";
        String blobName = UUID.randomUUID().toString() + extension;

        // Get container client
        BlobContainerClient containerClient = blobServiceClient
                .getBlobContainerClient(containerName);

        // Get blob client
        BlobClient blobClient = containerClient.getBlobClient(blobName);

        // Set content type
        BlobHttpHeaders headers = new BlobHttpHeaders()
                .setContentType(file.getContentType());

        // Upload
        blobClient.upload(file.getInputStream(), file.getSize(), true);
        blobClient.setHttpHeaders(headers);

        // Return public URL
        return String.format("%s/%s/%s", baseUrl, containerName, blobName);
    }

    /**
     * Delete blob from Azure
     */
    public void deleteBlob(String blobUrl) {
        try {
            // Extract container and blob name from URL
            String[] parts = blobUrl.replace(baseUrl + "/", "").split("/", 2);
            String containerName = parts[0];
            String blobName = parts[1];

            BlobContainerClient containerClient = blobServiceClient
                    .getBlobContainerClient(containerName);
            BlobClient blobClient = containerClient.getBlobClient(blobName);
            
            blobClient.delete();
        } catch (Exception e) {
            // Log error but don't fail if blob doesn't exist
            System.err.println("Error deleting blob: " + e.getMessage());
        }
    }

    /**
     * Check if blob exists
     */
    public boolean blobExists(String blobUrl) {
        try {
            String[] parts = blobUrl.replace(baseUrl + "/", "").split("/", 2);
            String containerName = parts[0];
            String blobName = parts[1];

            BlobContainerClient containerClient = blobServiceClient
                    .getBlobContainerClient(containerName);
            BlobClient blobClient = containerClient.getBlobClient(blobName);
            
            return blobClient.exists();
        } catch (Exception e) {
            return false;
        }
    }
}
```

### Step 5: Create Upload Controller

Create `main_backend/src/main/java/com/concert/controller/UploadController.java`:

```java
package com.concert.controller;

import com.concert.service.AzureBlobService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/upload")
@CrossOrigin(origins = "*")
public class UploadController {

    private final AzureBlobService azureBlobService;

    public UploadController(AzureBlobService azureBlobService) {
        this.azureBlobService = azureBlobService;
    }

    @PostMapping("/event-image")
    public ResponseEntity<?> uploadEventImage(
            @RequestParam("file") MultipartFile file,
            Authentication authentication) {
        try {
            // Validate file
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "File is empty"));
            }

            // Validate file type
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "File must be an image"));
            }

            // Validate file size (max 5MB)
            if (file.getSize() > 5 * 1024 * 1024) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "File size must be less than 5MB"));
            }

            // Upload to Azure
            String imageUrl = azureBlobService.uploadEventImage(file);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("imageUrl", imageUrl);
            response.put("message", "Image uploaded successfully");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to upload image: " + e.getMessage()));
        }
    }

    @PostMapping("/profile-photo")
    public ResponseEntity<?> uploadProfilePhoto(
            @RequestParam("file") MultipartFile file,
            Authentication authentication) {
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "File is empty"));
            }

            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "File must be an image"));
            }

            if (file.getSize() > 2 * 1024 * 1024) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "File size must be less than 2MB"));
            }

            String imageUrl = azureBlobService.uploadUserProfile(file);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("imageUrl", imageUrl);
            response.put("message", "Profile photo uploaded successfully");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to upload image: " + e.getMessage()));
        }
    }

    @DeleteMapping("/image")
    public ResponseEntity<?> deleteImage(
            @RequestParam("url") String imageUrl,
            Authentication authentication) {
        try {
            azureBlobService.deleteBlob(imageUrl);
            return ResponseEntity.ok(Map.of("success", true, "message", "Image deleted"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to delete image: " + e.getMessage()));
        }
    }
}
```

---

## 🎨 Frontend Integration (Nuxt 4)

### Step 1: Create Upload Composable

Create `main_frontend/concert1/composables/useImageUpload.ts`:

```typescript
export const useImageUpload = () => {
  const config = useRuntimeConfig()
  const backendUrl = config.public.backendBaseUrl || 'http://localhost:8080'

  const uploadEventImage = async (file: File): Promise<string> => {
    const formData = new FormData()
    formData.append('file', file)

    const token = localStorage.getItem('token')
    
    const response = await $fetch<{ imageUrl: string }>(`${backendUrl}/api/upload/event-image`, {
      method: 'POST',
      body: formData,
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    return response.imageUrl
  }

  const uploadProfilePhoto = async (file: File): Promise<string> => {
    const formData = new FormData()
    formData.append('file', file)

    const token = localStorage.getItem('token')
    
    const response = await $fetch<{ imageUrl: string }>(`${backendUrl}/api/upload/profile-photo`, {
      method: 'POST',
      body: formData,
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    return response.imageUrl
  }

  const deleteImage = async (imageUrl: string): Promise<void> => {
    const token = localStorage.getItem('token')
    
    await $fetch(`${backendUrl}/api/upload/image`, {
      method: 'DELETE',
      query: { url: imageUrl },
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
  }

  return {
    uploadEventImage,
    uploadProfilePhoto,
    deleteImage
  }
}
```

### Step 2: Create Image Upload Component

Create `main_frontend/concert1/app/components/ImageUpload.vue`:

```vue
<template>
  <div class="image-upload">
    <div v-if="!imageUrl" class="upload-area" @click="triggerFileInput">
      <input
        ref="fileInput"
        type="file"
        accept="image/*"
        @change="handleFileSelect"
        hidden
      />
      <div v-if="!uploading" class="upload-placeholder">
        <svg class="w-12 h-12 mx-auto mb-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        <p class="text-sm text-gray-600">Click to upload image</p>
        <p class="text-xs text-gray-400 mt-1">PNG, JPG up to {{ maxSizeMB }}MB</p>
      </div>
      <div v-else class="upload-loading">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
        <p class="text-sm text-gray-600 mt-2">Uploading...</p>
      </div>
    </div>

    <div v-else class="image-preview">
      <img :src="imageUrl" :alt="alt" class="uploaded-image" />
      <button @click="removeImage" class="remove-button">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <p v-if="error" class="error-message">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue?: string
  type?: 'event' | 'profile'
  maxSizeMB?: number
  alt?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'upload-complete': [url: string]
  'upload-error': [error: string]
}>()

const { uploadEventImage, uploadProfilePhoto, deleteImage } = useImageUpload()

const fileInput = ref<HTMLInputElement>()
const imageUrl = ref(props.modelValue || '')
const uploading = ref(false)
const error = ref('')

const maxSizeMB = props.maxSizeMB || 5

watch(() => props.modelValue, (newValue) => {
  imageUrl.value = newValue || ''
})

const triggerFileInput = () => {
  fileInput.value?.click()
}

const handleFileSelect = async (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  
  if (!file) return

  error.value = ''

  // Validate file type
  if (!file.type.startsWith('image/')) {
    error.value = 'Please select an image file'
    return
  }

  // Validate file size
  const sizeMB = file.size / (1024 * 1024)
  if (sizeMB > maxSizeMB) {
    error.value = `File size must be less than ${maxSizeMB}MB`
    return
  }

  try {
    uploading.value = true

    // Upload to Azure via backend
    const url = props.type === 'profile' 
      ? await uploadProfilePhoto(file)
      : await uploadEventImage(file)

    imageUrl.value = url
    emit('update:modelValue', url)
    emit('upload-complete', url)
  } catch (err: any) {
    error.value = err.message || 'Failed to upload image'
    emit('upload-error', error.value)
  } finally {
    uploading.value = false
  }
}

const removeImage = async () => {
  if (!imageUrl.value) return

  try {
    await deleteImage(imageUrl.value)
    imageUrl.value = ''
    emit('update:modelValue', '')
    error.value = ''
  } catch (err: any) {
    error.value = 'Failed to delete image'
  }
}
</script>

<style scoped>
.upload-area {
  border: 2px dashed #d1d5db;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
}

.upload-area:hover {
  border-color: #3b82f6;
  background-color: #f9fafb;
}

.image-preview {
  position: relative;
  display: inline-block;
}

.uploaded-image {
  max-width: 100%;
  max-height: 300px;
  border-radius: 8px;
  object-fit: cover;
}

.remove-button {
  position: absolute;
  top: 8px;
  right: 8px;
  background: rgba(239, 68, 68, 0.9);
  color: white;
  border: none;
  border-radius: 50%;
  padding: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.remove-button:hover {
  background: rgb(220, 38, 38);
}

.error-message {
  color: #ef4444;
  font-size: 0.875rem;
  margin-top: 0.5rem;
}
</style>
```

### Step 3: Use in Create Event Page

Update your event creation page:

```vue
<template>
  <div class="create-event-page">
    <h1>Create Event</h1>
    
    <form @submit.prevent="createEvent">
      <div class="form-group">
        <label>Event Image</label>
        <ImageUpload 
          v-model="eventData.imageUrl" 
          type="event"
          @upload-complete="handleImageUpload"
        />
      </div>

      <div class="form-group">
        <label>Title</label>
        <input v-model="eventData.title" required />
      </div>

      <div class="form-group">
        <label>Description</label>
        <textarea v-model="eventData.description" required></textarea>
      </div>

      <!-- Other fields... -->

      <button type="submit">Create Event</button>
    </form>
  </div>
</template>

<script setup lang="ts">
const eventData = reactive({
  title: '',
  description: '',
  imageUrl: '',  // This will be the Azure Blob URL
  location: '',
  startDate: '',
  endDate: '',
  ticketPrice: 0,
  personLimit: 0
})

const handleImageUpload = (url: string) => {
  console.log('Image uploaded to Azure:', url)
  // Image URL is automatically stored in eventData.imageUrl
}

const createEvent = async () => {
  // Save event with Azure image URL to events.json
  const response = await $fetch('/api/events/json', {
    method: 'POST',
    body: eventData  // imageUrl contains Azure Blob URL
  })
  
  // Navigate to event page
  navigateTo(`/concert/ProductPageDetail/${response.id}`)
}
</script>
```

---

## 📊 Updated Event JSON Structure

Your `events.json` will now store Azure URLs:

```json
[
  {
    "id": 1760350889162,
    "title": "Concert Night",
    "description": "Amazing concert",
    "imageUrl": "https://concertstorage.blob.core.windows.net/event-images/abc123.jpg",
    "thumbnailUrl": "https://concertstorage.blob.core.windows.net/thumbnails/abc123_thumb.jpg",
    "location": "Bangkok Arena",
    "startDate": "2025-10-13T19:00:00",
    "endDate": "2025-10-13T23:00:00",
    "ticketPrice": 500,
    "personLimit": 1000,
    "userId": 22,
    "userName": "Event Creator",
    "createdAt": "2025-10-13T10:21:29.162Z",
    "participants": []
  }
]
```

---

## 💰 Azure Pricing

### Free Tier (First 12 Months)
- 5 GB Blob Storage
- 20,000 read operations
- 2,000 write operations

### After Free Tier
- **Storage**: $0.018/GB/month (Hot tier)
- **Operations**: 
  - Write: $0.05 per 10,000
  - Read: $0.004 per 10,000
- **Data Transfer**: First 5 GB free, then ~$0.087/GB

**Example Cost:**
- 100 GB images = $1.80/month
- 100,000 views/month = $0.40
- **Total: ~$2.20/month**

---

## 🚀 Deployment Checklist

- [ ] Create Azure Storage Account
- [ ] Create blob containers (event-images, user-profiles, thumbnails)
- [ ] Get connection string
- [ ] Add Azure dependency to `pom.xml`
- [ ] Create `AzureBlobService.java`
- [ ] Create `UploadController.java`
- [ ] Add connection string to `.env`
- [ ] Update `docker-compose.yml` with environment variable
- [ ] Create frontend composable `useImageUpload.ts`
- [ ] Create `ImageUpload.vue` component
- [ ] Update event creation pages to use image upload
- [ ] Rebuild backend: `docker compose build backend`
- [ ] Test upload functionality

---

## 🔐 Security Best Practices

1. **Use SAS Tokens** for temporary access (advanced)
2. **Validate file types** on backend
3. **Limit file sizes** (5MB for events, 2MB for profiles)
4. **Store connection string** in environment variables (never commit!)
5. **Enable CORS** only for your domain in production
6. **Use private containers** for sensitive data
7. **Enable Azure CDN** for faster global delivery

---

## 📈 Optional: Add Azure CDN

For even faster image delivery worldwide:

```bash
# Create CDN profile
az cdn profile create \
  --name concert-cdn \
  --resource-group concert-rg \
  --sku Standard_Microsoft

# Create CDN endpoint
az cdn endpoint create \
  --name concert-images \
  --profile-name concert-cdn \
  --resource-group concert-rg \
  --origin concertstorage.blob.core.windows.net
```

Then use CDN URLs: `https://concert-images.azureedge.net/event-images/abc123.jpg`

---

## 🎉 Benefits of This Approach

✅ **Scalable**: Handle unlimited images  
✅ **Fast**: Azure's global CDN  
✅ **Reliable**: 99.9% uptime SLA  
✅ **Secure**: Private containers, SAS tokens  
✅ **Cost-effective**: Pay only for what you use  
✅ **Professional**: Industry-standard solution  
✅ **Hybrid**: Works perfectly with your JSON + MySQL architecture

---

Would you like me to implement this Azure Blob Storage integration for your platform?
