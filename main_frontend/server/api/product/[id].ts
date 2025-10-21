import product from "~~/data/dataProduct.json"

export default defineEventHandler((event) => {
  const id = getRouterParam(event, 'id')
  const item = product.find((p: any) => String(p.id) === String(id))
  if (!item) {
    setResponseStatus(event, 404)
    return { message: 'Not Found' }
  }
  return item
})
