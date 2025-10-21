import dataProduct from '~~/data/dataProduct.json'

export default defineEventHandler(event => {
  return dataProduct
})