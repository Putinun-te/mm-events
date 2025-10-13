<script setup lang="ts">
import { ref } from 'vue';

interface user {
  fullName: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phone: string;
  address: string;
  city: string;
  country: string;
  pincode: number;
}

const userData = reactive<user>({
  fullName: "",
  email: "",
  password: "",
  firstName: "",
  lastName: "",
  phone: "",
  address: "",
  city: "",
  country: "",
  pincode: 0
})

// let fullName = ref('')
// let email = ref('')
// let password = ref('')
// let firstName = ref('')
// let lastName = ref('')
// let phone = ref()
// let address = ref('')
// let city = ref('')
// let country = ref('')
// let pincode = ref()


function handlesubmit () {
  console.log('1')
  console.log(userData)

  // if (!userData.firstName.trim() || !userData.lastName.trim() || !userData.email.trim() || !userData.password.trim() || !userData.phone.trim()){
  if(!userData.firstName.trim()){ 
    alert('please insert information')
    return
  }
}



</script>
<template>
  <div class="bg-white rounded shadow-sm py-12 sm:py-16">
    <div class="flex items-center justify-center">
      <form @submit.prevent="handlesubmit" class="w-full max-w-2xl">
        <div class="p-6 md:p-8">
          <h1 class="text-3xl font-bold text-gray-900">Account Information</h1>

          <div class="mt-10">
            <h2 class="text-lg font-semibold leading-7 text-gray-800">Profile Photo</h2>
            <div class="mt-4 flex items-center justify-center mb-4">
              <div class="relative w-32 h-32 bg-gray-200 rounded-full flex items-center justify-center text-gray-400">
                <!-- <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg> -->
              </div>
            </div>
          </div>

          <div class="mt-8">
            <h2 class="text-xl font-semibold leading-7 text-gray-800">Profile Information</h2>
            <div class="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-5">
              <div>
                <label for="first-name" class="block text-sm font-medium text-gray-700">First Name</label>
                <input
                v-model="userData.firstName"
                type="text" 
                placeholder="Enter first name" 
                class="mt-1 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div>
                <label for="last-name" class="block text-sm font-medium text-gray-700">Last Name</label>
                <input v-model="userData.lastName" type="text" placeholder="Enter last name" class="mt-1 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
            </div>
          </div>

          <div class="mt-10">
            <h2 class="text-xl font-semibold leading-7 text-gray-800">Contact Details</h2>
            <p class="mt-1 text-sm text-gray-500">These details are private and only used to contact you for ticketing or prizes.</p>
            <div class="mt-6 space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="email" class="text-sm font-medium text-gray-700">Email</label>
                <input v-model="userData.email" type="email" placeholder="Enter Email" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="password" class="text-sm font-medium text-gray-700">Password</label>
                <input v-model="userData.password" type="text" placeholder="Enter password" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>                            
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="phone" class="text-sm font-medium text-gray-700">Phone Number: 000-000-0000</label>
                <input v-model="userData.phone" type="tel"  pattern="[0-9]{3}-[0-9]{2}-[0-9]{3}" placeholder="Enter phone number" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="address" class="text-sm font-medium text-gray-700">Address</label>
                <input v-model="userData.address" type="text" placeholder="Enter address" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="city" class="text-sm font-medium text-gray-700">City/Town</label>
                <input v-model = "userData.city" type="text" placeholder="Enter city" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="country" class="text-sm font-medium text-gray-700">Country</label>
                <input v-model = "userData.country"  type="text" placeholder="Enter country" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="pincode" class="text-sm font-medium text-gray-700">Pincode</label>
                <input v-model = "userData.pincode" type="number"  placeholder="Enter pincode" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
            </div>
          </div>
          
          <div class="mt-10">
            <button type="submit" class="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white transition-colors" style="background-color: #362e54;" onmouseover="this.style.backgroundColor='#4a3f70'" onmouseout="this.style.backgroundColor='#362e54'">Save My Profile</button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>