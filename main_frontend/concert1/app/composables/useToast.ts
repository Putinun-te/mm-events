import { ref } from 'vue'

type Toast = { id: number; type: 'success' | 'error' | 'info'; message: string; timeout?: number }

const toasts = ref<Toast[]>([])
let idSeq = 1

export function useToast() {
  function push(message: string, type: Toast['type'] = 'info', timeout = 3000) {
    const id = idSeq++
    toasts.value.push({ id, type, message, timeout })
    if (timeout > 0) setTimeout(() => dismiss(id), timeout)
  }
  function dismiss(id: number) {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }
  return { toasts, push, dismiss }
}
