import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'

const apiFetch = vi.fn()
vi.mock('~/composables/useApi', () => ({ useApi: () => ({ apiFetch }) }))
vi.mock('~/composables/useAuth', () => ({ useAuth: () => ({ loadFromStorage: vi.fn() }) }))

import EventListPage from '~/pages/product-page.vue'

const rock = { id: 1, title: 'Rock Night', category: 'Rock', startDate: '2099-05-01T19:00:00' }
const jazz = { id: 2, title: 'Jazz Evening', category: 'Jazz', startDate: '2099-06-01T19:00:00' }
const pop = { id: 3, title: 'Pop Party', category: 'Pop', startDate: '2099-07-01T19:00:00' }

const page = (content: any[], last: boolean) => ({ content, last })

function mountPage() {
  return mount(EventListPage, {
    global: {
      stubs: {
        ProductCard: { props: ['event'], template: '<div class="card">{{ event.title }}</div>' },
        EventCardSkeleton: { template: '<div class="skeleton" />' },
        EmptyState: { props: ['title'], template: '<div class="empty">{{ title }}</div>' }
      }
    }
  })
}

const titles = (wrapper: any) => wrapper.findAll('.card').map((card: any) => card.text())
const loadMoreButton = (wrapper: any) => wrapper.findAll('button').find((b: any) => b.text().includes('Load more'))

describe('product-page.vue (event list)', () => {
  beforeEach(() => {
    apiFetch.mockReset()
  })

  it('loads the first page of upcoming events and shows one card each', async () => {
    apiFetch.mockResolvedValueOnce(page([rock, jazz], true))

    const wrapper = mountPage()
    await flushPromises()

    expect(apiFetch).toHaveBeenCalledWith('/api/events/json?page=0&size=12')
    expect(titles(wrapper)).toEqual(['Rock Night', 'Jazz Evening'])
    expect(wrapper.text()).toContain('2 events available')
    expect(loadMoreButton(wrapper)).toBeUndefined()
  })

  it('filters by name, ignoring case', async () => {
    apiFetch.mockResolvedValueOnce(page([rock, jazz], true))
    const wrapper = mountPage()
    await flushPromises()

    await wrapper.find('input[type="text"]').setValue('jAzZ')

    expect(titles(wrapper)).toEqual(['Jazz Evening'])
    expect(wrapper.text()).toContain('1 result found')
  })

  it('filters by category', async () => {
    apiFetch.mockResolvedValueOnce(page([rock, jazz, pop], true))
    const wrapper = mountPage()
    await flushPromises()

    const popButton = wrapper.findAll('button').find(b => b.text() === 'Pop')!
    await popButton.trigger('click')

    expect(titles(wrapper)).toEqual(['Pop Party'])
  })

  it('shows "No events found" when the filters match nothing', async () => {
    apiFetch.mockResolvedValueOnce(page([rock], true))
    const wrapper = mountPage()
    await flushPromises()

    await wrapper.find('input[type="text"]').setValue('opera')

    expect(titles(wrapper)).toEqual([])
    expect(wrapper.find('.empty').text()).toBe('No events found')
  })

  it('loads the next page on "Load more" until the last page', async () => {
    apiFetch
      .mockResolvedValueOnce(page([rock], false))
      .mockResolvedValueOnce(page([jazz], true))
    const wrapper = mountPage()
    await flushPromises()

    await loadMoreButton(wrapper)!.trigger('click')
    await flushPromises()

    expect(apiFetch).toHaveBeenLastCalledWith('/api/events/json?page=1&size=12')
    expect(titles(wrapper)).toEqual(['Rock Night', 'Jazz Evening'])
    expect(loadMoreButton(wrapper)).toBeUndefined()
  })

  it('treats a plain array as the complete list', async () => {
    apiFetch.mockResolvedValueOnce([rock, jazz, pop])
    const wrapper = mountPage()
    await flushPromises()

    expect(titles(wrapper)).toHaveLength(3)
    expect(loadMoreButton(wrapper)).toBeUndefined()
  })

  it('shows an error and the empty state when loading fails', async () => {
    apiFetch.mockRejectedValueOnce(new Error('network down'))
    vi.spyOn(console, 'error').mockImplementation(() => {})
    const wrapper = mountPage()
    await flushPromises()

    expect(wrapper.text()).toContain('Failed to load events.')
    expect(wrapper.find('.empty').text()).toBe('No events yet')
  })

  it('keeps the loaded events and shows an error when the next page fails', async () => {
    apiFetch
      .mockResolvedValueOnce(page([rock], false))
      .mockRejectedValueOnce(new Error('timeout'))
    const wrapper = mountPage()
    await flushPromises()

    await loadMoreButton(wrapper)!.trigger('click')
    await flushPromises()

    expect(titles(wrapper)).toEqual(['Rock Night'])
    expect(wrapper.text()).toContain('Failed to load more events.')
  })
})
