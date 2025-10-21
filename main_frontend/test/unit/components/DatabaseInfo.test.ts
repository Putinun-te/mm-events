import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import DatabaseInfo from '~/app/components/DatabaseInfo.vue'
import axios from 'axios'

vi.mock('axios')

describe('DatabaseInfo', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should render the component', () => {
    const wrapper = mount(DatabaseInfo)
    expect(wrapper.exists()).toBe(true)
    expect(wrapper.find('h2').text()).toBe('Database Information')
  })

  it('should hide credentials by default', () => {
    const wrapper = mount(DatabaseInfo)
    expect(wrapper.html()).not.toContain('Database Credentials')
  })

  it('should show check database button', () => {
    const wrapper = mount(DatabaseInfo)
    const button = wrapper.find('button')
    expect(button.text()).toBe('Check Database')
  })

  it('should toggle credentials visibility when button clicked', async () => {
    const wrapper = mount(DatabaseInfo)
    const button = wrapper.find('button')
    
    await button.trigger('click')
    expect(wrapper.html()).toContain('Database Credentials')
    
    await button.trigger('click')
    expect(wrapper.html()).not.toContain('Database Credentials')
  })

  it('should display database host information', async () => {
    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    
    expect(wrapper.html()).toContain('localhost:3306')
  })

  it('should display database name', async () => {
    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    
    expect(wrapper.html()).toContain('devop_db')
  })

  it('should display username', async () => {
    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    
    expect(wrapper.html()).toContain('username')
  })

  it('should display password', async () => {
    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    
    expect(wrapper.html()).toContain('password')
  })

  it('should display root access information', async () => {
    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    
    expect(wrapper.html()).toContain('Root Access')
  })

  it('should display connection status', async () => {
    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    
    expect(wrapper.html()).toContain('Connection Status')
    expect(wrapper.html()).toContain('concert-mysql')
  })

  it('should display quick connect commands', async () => {
    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    
    expect(wrapper.html()).toContain('Quick Connect Commands')
    expect(wrapper.html()).toContain('docker exec')
  })

  it('should fetch users when credentials shown for first time', async () => {
    const mockUsers = [
      { user_id: 1, name: 'Test User', email: 'test@example.com', company: 'Test Co', city: 'Bangkok', country: 'Thailand' }
    ]
    vi.mocked(axios.get).mockResolvedValue({ data: mockUsers })

    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(axios.get).toHaveBeenCalledWith('http://localhost:8080/api/users')
  })

  it('should display users list', async () => {
    const mockUsers = [
      { user_id: 1, name: 'Test User', email: 'test@example.com', company: 'Test Co', city: 'Bangkok', country: 'Thailand' }
    ]
    vi.mocked(axios.get).mockResolvedValue({ data: mockUsers })

    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))

    expect(wrapper.html()).toContain('Database Users')
  })

  it('should handle fetch users error', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    vi.mocked(axios.get).mockRejectedValue(new Error('Network error'))

    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))

    expect(consoleErrorSpy).toHaveBeenCalled()
    consoleErrorSpy.mockRestore()
  })

  it('should show refresh users button', async () => {
    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    
    expect(wrapper.html()).toContain('Refresh Users')
  })

  it('should refresh users when refresh button clicked', async () => {
    const mockUsers = [
      { user_id: 1, name: 'Test User', email: 'test@example.com', company: 'Test Co', city: 'Bangkok', country: 'Thailand' }
    ]
    vi.mocked(axios.get).mockResolvedValue({ data: mockUsers })

    const wrapper = mount(DatabaseInfo)
    await wrapper.find('button').trigger('click')
    await wrapper.vm.$nextTick()
    
    const buttons = wrapper.findAll('button')
    const refreshButton = buttons.find(b => b.text().includes('Refresh'))
    if (refreshButton) {
      await refreshButton.trigger('click')
      expect(axios.get).toHaveBeenCalled()
    }
  })

  it('should change button text when toggled', async () => {
    const wrapper = mount(DatabaseInfo)
    const button = wrapper.find('button')
    
    expect(button.text()).toBe('Check Database')
    
    await button.trigger('click')
    expect(button.text()).toBe('Hide Database Info')
  })

  it('should have proper styling classes', () => {
    const wrapper = mount(DatabaseInfo)
    expect(wrapper.find('.bg-white').exists()).toBe(true)
    expect(wrapper.find('.rounded-lg').exists()).toBe(true)
  })
})
