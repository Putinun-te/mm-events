<script setup lang="ts">
import { onMounted } from 'vue'

const route = useRoute()
const productId = route.params.id
const event = ref<any>(null)

console.log(productId)

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) {
      resolve()
      return
    }

    const script = document.createElement('script')
    script.src = src
    script.type = 'text/javascript'
    script.async = true
    script.onload = () => resolve()
    script.onerror = () => reject(new Error(`Failed to load script: ${src}`))
    document.head.appendChild(script)
  })
}

onMounted(() => {
  loadScript('https://api.longdo.com/map3/?key=REPLACE_WITH_MAP_API_KEY') // Replace with your key
    .then(() => {
      const map = new longdo.Map({
        placeholder: document.getElementById('map'),
        language: 'th'
      });


      var marker = new longdo.Marker({ 
        lon: 100.56, 
        lat: 13.74,
        title: 'Rotate Marker',
        rotate: 90
      });

      map.Overlays.add(marker);
      map.Layers.add(longdo.Layers.THAICHOTE);
    })
    .catch(error => {
      console.error("Failed to load Longdo Map script:", error);
    });

    event.value = window.history.state?.event ?? null
    if (!event.value) {
        console.log(event.value)
    }
});


</script>

<!-- <template>
  <div>
    <h1>This is for testing map</h1>
    <div id="map" style="width: 100%; height: 500px;"></div>
  </div>
</template> -->


<template>
    <div class="bg-gray-50 min-h-screen">
        <div class="container mx-auto px-4 py-8 max-w-7xl">
            <div class="bg-white rounded-3xl shadow-2xl overflow-hidden">
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 p-6 lg:p-12">
                    <div class="space-y-6">
                        <div class="main-image-container rounded-2xl overflow-hidden bg-gray-100 aspect-square">
                            <img src="~/assets/img/apple.jpg"/>
                            <div class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0"></div>
                        </div>
                        
                        <!--for more image below-->
                        <div class="grid">
                            <div>
                                <div id="map" style="width: 100%; height: 500px;"></div>
                            </div>
                        </div>
                    </div>

                    <div class="flex flex-col justify-between space-y-8">
                        <div class="space-y-4">
                            <div class="flex items-center gap-2">
                                <span class="px-3 py-1 bg-violet-100 text-violet-700 text-sm font-semibold rounded-full">Premium Quality</span>
                                <div class="flex items-center text-yellow-400">
                                    ⭐⭐⭐⭐⭐ <span class="text-gray-600 text-sm ml-2">(4.8/5)</span>
                                </div>
                            </div>
                            
                            <h1 class="text-4xl lg:text-5xl font-bold text-gray-900 leading-tight">
                                Premium Fresh Apples
                                <!-- {{ event.name }} -->
                            </h1>
                            
                            <p class="text-lg text-gray-600 leading-relaxed">
                                information
                                <!-- {{ event.description }} -->
                            </p>
                        </div>
                        <div class="space-y-6">
                            <div class="flex items-baseline gap-4">
                                <h2 class="text-4xl font-bold text-green-600">$20</h2>
                                <span class="text-xl text-gray-500 line-through">$25</span>
                                <span class="px-3 py-1 bg-red-100 text-red-600 text-sm font-semibold rounded-full">20% OFF</span>
                            </div>
                            
                            <div class="flex items-center gap-3">
                                <div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
                                <span class="text-green-600 font-semibold">Available Seat</span>
                            </div>
                        </div>
                        <div class="grid grid-cols-2 gap-4">
                            <div class="bg-gradient-to-br from-blue-50 to-indigo-50 p-4 rounded-xl">
                                <h3 class="font-semibold text-indigo-700 mb-2">🌱 Organic</h3>
                                <p class="text-sm text-gray-600">Naturally grown without pesticides</p>
                            </div>
                            <div class="bg-gradient-to-br from-green-50 to-emerald-50 p-4 rounded-xl">
                                <h3 class="font-semibold text-green-700 mb-2">🚚 Fresh Delivery</h3>
                                <p class="text-sm text-gray-600">Farm to table within 24 hours</p>
                            </div>
                            <div class="bg-gradient-to-br from-yellow-50 to-orange-50 p-4 rounded-xl">
                                <h3 class="font-semibold text-orange-700 mb-2">🍎 Hand-Picked</h3>
                                <p class="text-sm text-gray-600">Carefully selected for quality</p>
                            </div>
                            <div class="bg-gradient-to-br from-purple-50 to-pink-50 p-4 rounded-xl">
                                <h3 class="font-semibold text-purple-700 mb-2">💯 Quality Guarantee</h3>
                                <p class="text-sm text-gray-600">100% satisfaction or money back</p>
                            </div>
                        </div>
                        <div class="space-y-6">
                            <div class="flex items-center gap-4">
                                <label class="text-gray-700 font-semibold">Person:</label>
                                <div class="flex items-center border-2 border-gray-300 rounded-lg overflow-hidden">
                                    <button class="px-4 py-2 bg-gray-100 hover:bg-gray-200 transition-colors" onclick="changeQuantity(-1)">-</button>
                                    <span id="quantity" class="px-6 py-2 bg-white font-semibold">1</span>
                                    <button class="px-4 py-2 bg-gray-100 hover:bg-gray-200 transition-colors" onclick="changeQuantity(1)">+</button>
                                </div>
                                <!-- <span class="text-gray-500">kg</span> -->
                            </div>

                            <div class="flex flex-col sm:flex-row gap-4">
                                <button class="flex-1 bg-gradient-to-r from-violet-600 to-purple-600 text-white px-8 py-4 rounded-xl font-semibold text-lg hover:shadow-lg transform hover:scale-105 transition-all duration-200">
                                    🛒 Add to Cart
                                </button>
                                <!-- <button class="flex-1 border-2 border-violet-600 text-violet-600 px-8 py-4 rounded-xl font-semibold text-lg hover:bg-violet-50 transition-all duration-200">
                                    ❤️ Add to Wishlist
                                </button> -->
                            </div>
                        </div>
                        <!-- <div class="border-t pt-6">
                            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm text-gray-600">
                                <div class="flex items-center gap-2">
                                    <span class="text-green-500">✓</span>
                                    Free shipping over $50
                                </div>
                                <div class="flex items-center gap-2">
                                    <span class="text-green-500">✓</span>
                                    30-day return policy
                                </div>
                                <div class="flex items-center gap-2">
                                    <span class="text-green-500">✓</span>
                                    Secure payment
                                </div>
                            </div>
                        </div> -->
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>