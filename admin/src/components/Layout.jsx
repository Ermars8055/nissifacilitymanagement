import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { useEffect, useRef, useState } from 'react'
import {
  LayoutDashboard, Users, Building2, Briefcase,
  ClipboardList, AlertCircle, Package, ChevronRight,
  Bell, Search, LogOut, CalendarClock, ListChecks, BarChart2,
  Settings, X, ClipboardCheck
} from 'lucide-react'
import { useAuth } from '../auth/AuthContext'
import api from '../api/client'

const nav = [
  { section: 'Overview' },
  { to: '/dashboard',    icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/reports',      icon: BarChart2,        label: 'Reports' },
  { section: 'Portfolio' },
  { to: '/clients',      icon: Briefcase,        label: 'Clients' },
  { to: '/buildings',    icon: Building2,        label: 'Buildings' },
  { to: '/assets',       icon: Package,          label: 'Assets' },
  { section: 'Operations' },
  { to: '/work-orders',  icon: ClipboardList,    label: 'Work Orders' },
  { to: '/complaints',   icon: AlertCircle,      label: 'Complaints' },
  { to: '/pm-scheduler', icon: CalendarClock,    label: 'PM Scheduler' },
  { to: '/checklists',   icon: ListChecks,       label: 'Checklists' },
  { section: 'Admin' },
  { to: '/users',        icon: Users,            label: 'Users' },
]

function initials(name = '') {
  const p = name.trim().split(' ')
  return p.length >= 2 ? `${p[0][0]}${p[1][0]}`.toUpperCase() : (name[0] || '?').toUpperCase()
}

// ── Global Search ──────────────────────────────────────────────
function GlobalSearch() {
  const navigate = useNavigate()
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [open, setOpen] = useState(false)
  const [allData, setAllData] = useState({ buildings: [], users: [], tasks: [], complaints: [] })
  const ref = useRef(null)

  // Load data once on mount
  useEffect(() => {
    async function load() {
      try {
        const [ur, br, tr, comr] = await Promise.all([
          api.get('/Users'), api.get('/Hierarchy/all-buildings'),
          api.get('/Tasks'), api.get('/Complaints'),
        ])
        setAllData({ buildings: br.data, users: ur.data, tasks: tr.data, complaints: comr.data })
      } catch (_) {}
    }
    load()
  }, [])

  useEffect(() => {
    const q = query.toLowerCase().trim()
    if (!q) { setResults([]); return }
    const hits = []

    allData.buildings.filter(b => b.name?.toLowerCase().includes(q) || b.location?.toLowerCase().includes(q))
      .slice(0, 3).forEach(b => hits.push({ type: 'Building', label: b.name, sub: b.location, to: `/buildings/${b.id}` }))

    allData.users.filter(u => u.name?.toLowerCase().includes(q) || u.email?.toLowerCase().includes(q))
      .slice(0, 3).forEach(u => hits.push({ type: 'User', label: u.name, sub: `${u.role} · ${u.email}`, to: '/users' }))

    allData.tasks.filter(t => t.title?.toLowerCase().includes(q) || t.assignedToName?.toLowerCase().includes(q))
      .slice(0, 3).forEach(t => hits.push({ type: 'Task', label: t.title, sub: t.assignedToName || 'Unassigned', to: '/work-orders' }))

    allData.complaints.filter(c => c.title?.toLowerCase().includes(q))
      .slice(0, 2).forEach(c => hits.push({ type: 'Complaint', label: c.title, sub: c.status, to: '/complaints' }))

    setResults(hits.slice(0, 8))
  }, [query, allData])

  useEffect(() => {
    function handler(e) { if (ref.current && !ref.current.contains(e.target)) setOpen(false) }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const TYPE_STYLE = { Building: 'bg-blue-50 text-blue-700', User: 'bg-purple-50 text-purple-700', Task: 'bg-amber-50 text-amber-700', Complaint: 'bg-red-50 text-red-700' }

  return (
    <div ref={ref} className="relative flex-1 max-w-sm">
      <div className="flex items-center gap-2 bg-gray-50 border border-gray-200 rounded-lg px-3 py-2">
        <Search size={15} className="text-gray-400 flex-shrink-0" />
        <input
          placeholder="Search buildings, users, tasks..."
          className="bg-transparent text-sm outline-none text-gray-700 w-full placeholder-gray-400"
          value={query}
          onChange={e => setQuery(e.target.value)}
          onFocus={() => setOpen(true)}
        />
        {query && (
          <button onClick={() => { setQuery(''); setResults([]) }} className="text-gray-400 hover:text-gray-600">
            <X size={13} />
          </button>
        )}
      </div>
      {open && results.length > 0 && (
        <div className="absolute top-full mt-1 left-0 right-0 bg-white border border-gray-200 rounded-xl shadow-xl z-50 overflow-hidden">
          {results.map((r, i) => (
            <button
              key={i}
              className="flex items-center gap-3 w-full px-4 py-2.5 hover:bg-gray-50 text-left"
              onClick={() => { navigate(r.to); setOpen(false); setQuery('') }}
            >
              <span className={`badge flex-shrink-0 ${TYPE_STYLE[r.type] || 'bg-gray-100 text-gray-600'}`}>{r.type}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-800 truncate">{r.label}</p>
                <p className="text-xs text-gray-400 truncate">{r.sub}</p>
              </div>
            </button>
          ))}
        </div>
      )}
      {open && query && results.length === 0 && (
        <div className="absolute top-full mt-1 left-0 right-0 bg-white border border-gray-200 rounded-xl shadow-xl z-50 px-4 py-3 text-sm text-gray-400">
          No results for "{query}"
        </div>
      )}
    </div>
  )
}

// ── Notifications Panel ────────────────────────────────────────
function NotificationsPanel({ onClose }) {
  const [activity, setActivity] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/Dashboard').then(r => {
      setActivity(r.data.recentActivity || [])
    }).catch(() => {}).finally(() => setLoading(false))
  }, [])

  return (
    <div className="absolute right-0 top-10 w-80 bg-white border border-gray-200 rounded-2xl shadow-2xl z-50 overflow-hidden">
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100">
        <p className="text-sm font-bold text-gray-800">Recent Activity</p>
        <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded-lg"><X size={14} /></button>
      </div>
      {loading ? (
        <div className="p-6 text-center text-xs text-gray-400">Loading...</div>
      ) : activity.length === 0 ? (
        <div className="p-6 text-center text-xs text-gray-400">No recent activity</div>
      ) : (
        <div className="divide-y divide-gray-50 max-h-80 overflow-y-auto">
          {activity.map((item, i) => {
            const isTask = item.type === 'task'
            return (
              <div key={i} className="flex items-start gap-3 px-4 py-3">
                <div className={`w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 ${isTask ? 'bg-blue-50' : 'bg-red-50'}`}>
                  {isTask
                    ? <ClipboardCheck size={13} className="text-blue-600" />
                    : <AlertCircle size={13} className="text-red-500" />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-semibold text-gray-800 truncate">{item.title}</p>
                  <p className="text-xs text-gray-400">{item.subtitle}</p>
                  <p className="text-xs text-gray-300 mt-0.5">{new Date(item.time).toLocaleDateString()}</p>
                </div>
                <span className={`badge text-xs flex-shrink-0 ${isTask ? 'bg-blue-50 text-blue-700' : 'bg-amber-50 text-amber-700'}`}>{item.status}</span>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

export default function Layout() {
  const { user, firebaseUser, logout } = useAuth()
  const navigate = useNavigate()
  const [showNotifs, setShowNotifs] = useState(false)
  const notifRef = useRef(null)

  useEffect(() => {
    function handler(e) { if (notifRef.current && !notifRef.current.contains(e.target)) setShowNotifs(false) }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  return (
    <div className="flex h-screen bg-gray-50 overflow-hidden">
      {/* Sidebar */}
      <aside className="w-60 bg-white border-r border-gray-100 flex flex-col flex-shrink-0">
        {/* Logo */}
        <div className="p-5 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-brand-600 rounded-lg flex items-center justify-center">
              <Building2 size={18} className="text-white" />
            </div>
            <div>
              <p className="font-bold text-gray-900 text-sm leading-tight">FacilityPro</p>
              <p className="text-xs text-gray-400">Admin Dashboard</p>
            </div>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 p-3 overflow-y-auto">
          {nav.map((item, i) =>
            item.section ? (
              <p key={i} className="text-[10px] font-bold text-gray-400 uppercase tracking-widest px-3 pt-4 pb-1 first:pt-2">
                {item.section}
              </p>
            ) : (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all mb-0.5 ${
                    isActive ? 'bg-brand-50 text-brand-600' : 'text-gray-500 hover:bg-gray-50 hover:text-gray-800'
                  }`
                }
              >
                {({ isActive }) => (
                  <>
                    <item.icon size={17} />
                    <span className="flex-1">{item.label}</span>
                    {isActive && <ChevronRight size={14} className="text-brand-400" />}
                  </>
                )}
              </NavLink>
            )
          )}
        </nav>

        {/* Bottom */}
        <div className="p-3 border-t border-gray-100 space-y-0.5">
          <button onClick={() => navigate('/settings')} className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-gray-500 hover:bg-gray-50 w-full">
            <Settings size={17} /> Settings
          </button>
          <button onClick={logout} className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-red-500 hover:bg-red-50 w-full">
            <LogOut size={17} /> Sign Out
          </button>
        </div>
      </aside>

      {/* Main */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Topbar */}
        <header className="h-14 bg-white border-b border-gray-100 flex items-center px-6 gap-4 flex-shrink-0">
          <GlobalSearch />
          <div className="flex items-center gap-3 ml-auto">
            {/* Notifications */}
            <div ref={notifRef} className="relative">
              <button onClick={() => setShowNotifs(v => !v)} className="relative p-2 hover:bg-gray-50 rounded-lg">
                <Bell size={18} className="text-gray-500" />
                <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full" />
              </button>
              {showNotifs && <NotificationsPanel onClose={() => setShowNotifs(false)} />}
            </div>
            <div className="flex items-center gap-2 pl-3 border-l border-gray-100 cursor-pointer" onClick={() => navigate('/settings')}>
              {firebaseUser?.photoURL ? (
                <img src={firebaseUser.photoURL} className="w-8 h-8 rounded-full object-cover" alt="" />
              ) : (
                <div className="w-8 h-8 bg-brand-600 rounded-full flex items-center justify-center">
                  <span className="text-white text-xs font-bold">{initials(user?.name || '')}</span>
                </div>
              )}
              <div className="hidden sm:block">
                <p className="text-sm font-semibold text-gray-800 leading-tight">{user?.name || 'Admin'}</p>
                <p className="text-xs text-gray-400">{user?.role || ''}</p>
              </div>
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
