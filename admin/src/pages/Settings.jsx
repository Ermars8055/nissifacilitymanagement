import { useAuth } from '../auth/AuthContext'
import { LogOut, User, Mail, Shield, Building2 } from 'lucide-react'

const ROLE_STYLE = {
  Admin:      'bg-purple-50 text-purple-700',
  Manager:    'bg-blue-50 text-blue-700',
  Supervisor: 'bg-cyan-50 text-cyan-700',
  Technician: 'bg-amber-50 text-amber-700',
}

function initials(name = '') {
  const p = name.trim().split(' ')
  return p.length >= 2 ? `${p[0][0]}${p[1][0]}`.toUpperCase() : (name[0] || '?').toUpperCase()
}

export default function Settings() {
  const { user, firebaseUser, logout } = useAuth()

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
        <p className="text-sm text-gray-500 mt-1">Manage your account and preferences</p>
      </div>

      {/* Profile Card */}
      <div className="card p-6">
        <h2 className="text-sm font-bold text-gray-700 mb-5">Your Profile</h2>
        <div className="flex items-center gap-5">
          {firebaseUser?.photoURL ? (
            <img src={firebaseUser.photoURL} className="w-16 h-16 rounded-full object-cover flex-shrink-0" alt="" />
          ) : (
            <div className="w-16 h-16 bg-brand-600 rounded-full flex items-center justify-center flex-shrink-0">
              <span className="text-white text-xl font-bold">{initials(user?.name || '')}</span>
            </div>
          )}
          <div>
            <p className="text-xl font-bold text-gray-900">{user?.name || 'Unknown'}</p>
            <p className="text-sm text-gray-500 mt-0.5">{user?.email || firebaseUser?.email}</p>
            <span className={`badge mt-2 ${ROLE_STYLE[user?.role] || 'bg-gray-100 text-gray-600'}`}>{user?.role || 'Admin'}</span>
          </div>
        </div>

        <div className="mt-6 space-y-3">
          <div className="flex items-center gap-3 py-3 border-t border-gray-50">
            <User size={16} className="text-gray-400 flex-shrink-0" />
            <div>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Full Name</p>
              <p className="text-sm text-gray-800 font-medium mt-0.5">{user?.name || '—'}</p>
            </div>
          </div>
          <div className="flex items-center gap-3 py-3 border-t border-gray-50">
            <Mail size={16} className="text-gray-400 flex-shrink-0" />
            <div>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Email</p>
              <p className="text-sm text-gray-800 font-medium mt-0.5">{user?.email || firebaseUser?.email || '—'}</p>
            </div>
          </div>
          <div className="flex items-center gap-3 py-3 border-t border-gray-50">
            <Shield size={16} className="text-gray-400 flex-shrink-0" />
            <div>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Role</p>
              <p className="text-sm text-gray-800 font-medium mt-0.5">{user?.role || '—'}</p>
            </div>
          </div>
          {user?.buildings?.length > 0 && (
            <div className="flex items-center gap-3 py-3 border-t border-gray-50">
              <Building2 size={16} className="text-gray-400 flex-shrink-0" />
              <div>
                <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Assigned Buildings</p>
                <p className="text-sm text-gray-800 font-medium mt-0.5">{user.buildings.filter(Boolean).join(', ')}</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Auth Info */}
      {firebaseUser && (
        <div className="card p-6">
          <h2 className="text-sm font-bold text-gray-700 mb-4">Authentication</h2>
          <div className="flex items-center gap-3">
            {firebaseUser.photoURL && (
              <img src={firebaseUser.photoURL} className="w-8 h-8 rounded-full" alt="" />
            )}
            <div>
              <p className="text-sm font-semibold text-gray-800">{firebaseUser.displayName}</p>
              <p className="text-xs text-gray-400">Signed in via Google</p>
            </div>
            <span className="ml-auto badge bg-green-50 text-green-700">Active</span>
          </div>
        </div>
      )}

      {/* Danger Zone */}
      <div className="card p-6 border border-red-100">
        <h2 className="text-sm font-bold text-gray-700 mb-4">Session</h2>
        <p className="text-sm text-gray-500 mb-4">Sign out from this admin session. You will be redirected to the login page.</p>
        <button onClick={logout} className="flex items-center gap-2 px-4 py-2 bg-red-50 hover:bg-red-100 text-red-600 text-sm font-semibold rounded-lg transition-colors">
          <LogOut size={16} /> Sign Out
        </button>
      </div>
    </div>
  )
}
