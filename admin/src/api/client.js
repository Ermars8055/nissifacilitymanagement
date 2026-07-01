import axios from 'axios'
import { auth } from '../firebase'

const api = axios.create({
  baseURL: 'http://localhost:5294/api',
  headers: { 'Content-Type': 'application/json' },
})

// Attach Firebase ID token to every request
api.interceptors.request.use(async config => {
  const user = auth.currentUser
  if (user) {
    try {
      const token = await user.getIdToken()
      config.headers.Authorization = `Bearer ${token}`
    } catch (_) {}
  }
  return config
})

export default api
