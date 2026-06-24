import { useState } from 'react'
import { Building2, Shield, Users, BarChart2, AlertCircle } from 'lucide-react'
import { useAuth } from '../auth/AuthContext'

function GoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
      <path d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.258h2.908c1.702-1.567 2.684-3.874 2.684-6.615z" fill="#4285F4"/>
      <path d="M9 18c2.43 0 4.467-.806 5.956-2.184l-2.908-2.258c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z" fill="#34A853"/>
      <path d="M3.964 10.707A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.707V4.961H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.039l3.007-2.332z" fill="#FBBC05"/>
      <path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.96L3.964 7.293C4.672 5.163 6.656 3.58 9 3.58z" fill="#EA4335"/>
    </svg>
  )
}

const FEATURES = [
  { icon: Shield,   text: 'Role-based access control' },
  { icon: Users,    text: 'Team & building management' },
  { icon: BarChart2, text: 'Real-time facility analytics' },
]

export default function LoginPage() {
  const { login, authError } = useAuth()
  const [loading, setLoading] = useState(false)

  async function handleLogin() {
    setLoading(true)
    await login()
    setLoading(false)
  }

  return (
    <div className="min-h-screen bg-gray-50 flex">
      {/* Left panel */}
      <div className="hidden lg:flex lg:w-1/2 bg-brand-900 flex-col justify-between p-12">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-white/10 rounded-lg flex items-center justify-center">
            <Building2 size={18} className="text-white" />
          </div>
          <span className="text-white font-bold text-lg">FacilityPro</span>
        </div>

        <div>
          <h1 className="text-4xl font-bold text-white leading-tight mb-4">
            Manage your facilities<br />from one place.
          </h1>
          <p className="text-white/60 text-base mb-10">
            The admin console for your entire facility portfolio — buildings, assets, work orders, and teams.
          </p>
          <div className="space-y-4">
            {FEATURES.map(({ icon: Icon, text }) => (
              <div key={text} className="flex items-center gap-3">
                <div className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Icon size={15} className="text-white" />
                </div>
                <span className="text-white/80 text-sm">{text}</span>
              </div>
            ))}
          </div>
        </div>

        <p className="text-white/30 text-xs">© 2025 FacilityPro Inc.</p>
      </div>

      {/* Right panel */}
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="w-full max-w-sm">
          {/* Mobile logo */}
          <div className="flex items-center gap-2 mb-10 lg:hidden">
            <div className="w-8 h-8 bg-brand-600 rounded-lg flex items-center justify-center">
              <Building2 size={16} className="text-white" />
            </div>
            <span className="font-bold text-gray-900">FacilityPro</span>
          </div>

          <h2 className="text-2xl font-bold text-gray-900 mb-1">Admin sign in</h2>
          <p className="text-sm text-gray-500 mb-8">
            Use your organisation Google account to access the admin dashboard.
          </p>

          {/* Error */}
          {authError && (
            <div className="flex items-start gap-3 bg-red-50 border border-red-100 rounded-xl p-4 mb-6">
              <AlertCircle size={16} className="text-red-500 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-red-700">{authError}</p>
            </div>
          )}

          {/* Google button */}
          <button
            onClick={handleLogin}
            disabled={loading}
            className="w-full flex items-center justify-center gap-3 bg-white border border-gray-200 rounded-xl px-4 py-3.5 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-gray-300 border-t-brand-600 rounded-full animate-spin" />
            ) : (
              <GoogleIcon />
            )}
            {loading ? 'Signing in...' : 'Continue with Google'}
          </button>

          <div className="mt-8 p-4 bg-amber-50 border border-amber-100 rounded-xl">
            <p className="text-xs text-amber-700 font-semibold mb-1">Admin access only</p>
            <p className="text-xs text-amber-600">
              Only users with the Admin role can sign in here. Contact your system administrator if you need access.
            </p>
          </div>

          <p className="text-xs text-gray-400 text-center mt-8">
            Field workers should use the FacilityPro mobile app.
          </p>
        </div>
      </div>
    </div>
  )
}
