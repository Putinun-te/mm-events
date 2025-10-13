<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

type LegacyEvent = {
  id: string | number
  name: string
  datestart: string // epoch seconds string
  dateend: string // epoch seconds string
  personlimit: number
  description: string
}

type ApiEvent = {
  id: string | number
  title: string
  description?: string
  startDate: string // ISO local date-time
  endDate: string // ISO local date-time
  personLimit?: number
}

const props = defineProps<{ event: LegacyEvent | ApiEvent }>()
const router = useRouter()

function toDate(val: any): Date {
  // supports epoch seconds string or ISO string
  if (typeof val === 'string' && /^\d+$/.test(val)) {
    return new Date(parseInt(val, 10) * 1000)
  }
  return new Date(val)
}

const displayName = computed(() => (props.event as any).name || (props.event as any).title || 'Untitled')
const displayDescription = computed(() => (props.event as any).description || '')
const startRaw = computed(() => (props.event as any).datestart || (props.event as any).startDate)
const endRaw = computed(() => (props.event as any).dateend || (props.event as any).endDate)
const capacity = computed(() => (props.event as any).personlimit ?? (props.event as any).personLimit ?? 0)

const formatEventDateMn = (raw: string) => {
  const date = toDate(raw)
  return date.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

const formatEventDateTime = (raw: string) => {
  const date = toDate(raw)
  return date.toLocaleString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  });
};

function more () {
  // router.push(`/ProductPageDetail/${props.event.id}`)
    router.push({
    path: `/ProductPageDetail/${props.event.id}`,
    state: { event: props.event }
  })
  // router.push({
  //   path: `/productdetail/${props.event.id}`,
  //   query: {
  //     name: props.event.name,
  //     description: props.event.description,
  //     personlimit: props.event.personlimit
  //   }
  // })
}
function join () {
  console.log('this is join')
  console.log(props.event.id)
}

// const imageUrl = computed(() => {
//   return `https://picsum.photos/seed/${props.event.id}/400/300`;
// });
</script>

<template>
  <div class="max-w-sm w-[90%] bg-white mx-auto my-12 p-6 rounded-2xl shadow-lg transition-all duration-300 ease-in-out hover:shadow-2xl hover:-translate-y-1.5">
    
    <div class="flex justify-center -mt-16 mb-4">
      <img 
        src="~/assets/img/apple.jpg" 
        class="w-32 h-32 object-cover rounded-2xl shadow-xl border-4 border-white" 
      />
    </div>  

    <div class="text-center">
      <h2 class="text-2xl font-bold text-slate-800 tracking-tight">{{ displayName }}</h2>
      <p class="mt-2 text-slate-600 text-sm leading-relaxed">
        {{ displayDescription }}
      </p>
    </div>

    <div class="mt-6 border-t border-slate-200 pt-4">
      <ul class="space-y-3 text-slate-600 text-sm">
        <li class="flex items-center gap-3">
            <path stroke-linecap="round" stroke-linejoin="round"/>
          <span class="font-semibold text-slate-700">Date:</span>{{ formatEventDateMn(startRaw as any) }}
        </li>        
        <li class="flex items-center gap-3">
            <path stroke-linecap="round" stroke-linejoin="round"/>
          <span class="font-semibold text-slate-700">Starts:</span>{{ formatEventDateTime(startRaw as any) }}
        </li>
        <li class="flex items-center gap-3">
            <path stroke-linecap="round" stroke-linejoin="round" />
          <span class="font-semibold text-slate-700">Ends:</span>{{ formatEventDateTime(endRaw as any) }}
        </li>
        <li class="flex items-center gap-3">
            <path stroke-linecap="round" stroke-linejoin="round" />
          <span class="font-semibold text-slate-700">Remain:</span>{{ capacity }} seat
        </li>
      </ul>
    </div>

    <div class="flex flex-col sm:flex-row gap-3 mt-6 justify-center">
      <button @click="more" class="px-5 py-2 text-sm font-semibold text-slate-700 bg-white border-2 border-slate-200 rounded-lg hover:bg-slate-100 transition-colors duration-300 cursor-pointer">
        More
      </button>
      <button @click="join" class="px-5 py-2 text-sm font-semibold text-white bg-slate-900 rounded-lg hover:bg-slate-800 transition-colors duration-300 cursor-pointer">
        Join
      </button>
    </div>
  </div>
</template>