import { ref } from 'vue'

type Toast = {
  id: number
  type: 'success' | 'error' | 'info' | 'warning'
  message: string
  timeout?: number
  title?: string
}

const toasts = ref<Toast[]>([])
let idSeq = 1

export function useToast() {
  function push(
    message: string,
    type: Toast['type'] = 'info',
    timeout = 5000,
    title?: string
  ) {
    const id = idSeq++
    toasts.value.push({ id, type, message, timeout, title })
    if (timeout > 0) setTimeout(() => dismiss(id), timeout)
  }

  function success(message: string, title?: string, timeout = 5000) {
    push(message, 'success', timeout, title)
  }

  function error(message: string, title?: string, timeout = 7000) {
    push(message, 'error', timeout, title)
  }

  function info(message: string, title?: string, timeout = 5000) {
    push(message, 'info', timeout, title)
  }

  function warning(message: string, title?: string, timeout = 6000) {
    push(message, 'warning', timeout, title)
  }

  function dismiss(id: number) {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }

  function dismissAll() {
    toasts.value = []
  }

  return {
    toasts,
    push,
    success,
    error,
    info,
    warning,
    dismiss,
    dismissAll
  }
}
