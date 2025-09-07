<script setup lang="ts">

</script>
<template>
    <div class="max-w-6xl mx-auto px-4 mb-10">
    <!-- <div class="flex gap-8"> -->
    <div>
        <!-- Filter Section -->
        <div class="w-1/4 flex-shrink-0">
        <ProductFilterSeclection />
        </div>

        <!-- Product Cards Wrapper -->
        <div class="flex-1">
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-7 mt-10">
                <div v-for="i in 6" :key="i">
                    <ProductCard />
                </div>
            </div>
        </div>
    </div>
    </div>
</template>