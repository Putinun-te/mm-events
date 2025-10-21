import { render, screen } from '@testing-library/vue'
import ProductCard from '@/app/components/ProductCard.vue'

it('renders product card content', async () => {
  render(ProductCard)
  // Headline
  expect(await screen.findByText('This is apple')).toBeInTheDocument()
  // Image
  const img = screen.getByRole('img')
  expect(img).toHaveAttribute('src', expect.stringContaining('apple.jpg'))
  // Buttons
  expect(screen.getByRole('button', { name: /more information/i })).toBeInTheDocument()
  expect(screen.getByRole('button', { name: /join now/i })).toBeInTheDocument()
})
