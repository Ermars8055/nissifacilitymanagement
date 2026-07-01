import { createContext, useContext, useEffect, useState } from 'react'
import { onAuthStateChanged } from 'firebase/auth'
import { auth, signInWithGoogle, signOutUser } from '../firebase'
import api from '../api/client'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)       // backend user object
  const [firebaseUser, setFirebaseUser] = useState(null)
  const [loading, setLoading] = useState(true)  // checking persisted session
  const [authError, setAuthError] = useState(null)

  // Restore session from Firebase persisted auth
  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (fbUser) => {
      if (fbUser) {
        try {
          const token = await fbUser.getIdToken()
          const r = await api.get(`/Users/by-email?email=${encodeURIComponent(fbUser.email)}`, {
            headers: { Authorization: `Bearer ${token}` }
          })
          const backendUser = r.data
          if (backendUser.role !== 'Admin' && backendUser.role !== 'Super Admin') {
            await signOutUser()
            setUser(null)
            setFirebaseUser(null)
            setAuthError('Access denied. Admin role required.')
          } else {
            setFirebaseUser(fbUser)
            setUser(backendUser)
            setAuthError(null)
          }
        } catch {
          await signOutUser()
          setUser(null)
          setFirebaseUser(null)
        }
      } else {
        setUser(null)
        setFirebaseUser(null)
      }
      setLoading(false)
    })
    return unsub
  }, [])

  async function login() {
    setAuthError(null)
    try {
      const result = await signInWithGoogle()
      const email = result.user.email

      let backendUser
      try {
        const r = await api.get(`/Users/by-email?email=${encodeURIComponent(email)}`)
        backendUser = r.data
      } catch {
        await signOutUser()
        setAuthError('Your account has not been set up. Contact your administrator.')
        return
      }

      if (backendUser.role !== 'Admin' && backendUser.role !== 'Super Admin') {
        await signOutUser()
        setAuthError('Access denied. Only Admin users can access this dashboard.')
        return
      }

      setFirebaseUser(result.user)
      setUser(backendUser)
    } catch (e) {
      if (e.code !== 'auth/popup-closed-by-user') {
        setAuthError(e.message || 'Sign-in failed. Please try again.')
      }
    }
  }

  async function logout() {
    await signOutUser()
    setUser(null)
    setFirebaseUser(null)
  }

  return (
    <AuthContext.Provider value={{ user, firebaseUser, loading, authError, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
