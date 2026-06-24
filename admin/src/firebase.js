import { initializeApp } from 'firebase/app'
import { getAuth, GoogleAuthProvider, signInWithPopup, signOut } from 'firebase/auth'

const firebaseConfig = {
  apiKey: 'AIzaSyDivkXjJ-4Urn-2hephYWU_dWHOrK20Q78',
  authDomain: 'facilitypro-3f693.firebaseapp.com',
  projectId: 'facilitypro-3f693',
  storageBucket: 'facilitypro-3f693.firebasestorage.app',
  messagingSenderId: '1021610120973',
  appId: '1:1021610120973:web:2d3f388326fc60fbb90244',
}

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)

export async function signInWithGoogle() {
  const provider = new GoogleAuthProvider()
  provider.setCustomParameters({ prompt: 'select_account' })
  return signInWithPopup(auth, provider)
}

export async function signOutUser() {
  return signOut(auth)
}
