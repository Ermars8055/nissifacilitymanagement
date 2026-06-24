import { useEffect, useState } from 'react'
import { Plus, Search, Building2, Mail, Trash2, Smartphone } from 'lucide-react'
import api from '../api/client'

const ROLE_STYLE = {
  Admin:      'bg-purple-50 text-purple-700',
  Manager:    'bg-blue-50 text-blue-700',
  Supervisor: 'bg-cyan-50 text-cyan-700',
  Technician: 'bg-amber-50 text-amber-700',
}

const ROLE_TABS = ['All', 'Admin', 'Manager', 'Supervisor', 'Technician']

// App users = field workers who use the Flutter mobile app
const APP_ROLES = new Set(['Technician', 'Supervisor'])

function initials(name = '') {
  const p = name.trim().split(' ')
  return p.length >= 2 ? `${p[0][0]}${p[1][0]}`.toUpperCase() : name[0]?.toUpperCase() || '?'
}

function avatarColor(role) {
  const map = { Admin: 'bg-purple-100 text-purple-700', Manager: 'bg-blue-100 text-blue-700', Supervisor: 'bg-cyan-100 text-cyan-700', Technician: 'bg-amber-100 text-amber-700' }
  return map[role] || 'bg-gray-100 text-gray-700'
}

export default function Users() {
  const [users, setUsers] = useState([])
  const [allBuildings, setAllBuildings] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [roleTab, setRoleTab] = useState('All')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: '', email: '', role: 'Technician' })
  const [saving, setSaving] = useState(false)
  const [assignUser, setAssignUser] = useState(null)
  const [selected, setSelected] = useState(new Set())

  useEffect(() => { fetchAll() }, [])

  async function fetchAll() {
    try {
      const [ur, br] = await Promise.all([api.get('/Users'), api.get('/Hierarchy/all-buildings')])
      setUsers(ur.data)
      setAllBuildings(br.data)
    } catch (_) {}
    setLoading(false)
  }

  async function createUser(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/Users', form)
      setShowForm(false)
      setForm({ name: '', email: '', role: 'Technician' })
      fetchAll()
    } catch (_) {}
    setSaving(false)
  }

  async function updateRole(userId, role) {
    try {
      await api.put(`/Users/${userId}/role`, { role })
      setUsers(us => us.map(u => u.id === userId ? { ...u, role } : u))
    } catch (_) {}
  }

  async function deleteUser(userId) {
    if (!window.confirm('Delete this user? This cannot be undone.')) return
    try {
      await api.delete(`/Users/${userId}`)
      setUsers(us => us.filter(u => u.id !== userId))
    } catch (_) {}
  }

  async function saveAssignments() {
    if (!assignUser) return
    setSaving(true)
    try {
      await api.post(`/Users/${assignUser.id}/buildings`, [...selected])
      setAssignUser(null)
      fetchAll()
    } catch (_) {}
    setSaving(false)
  }

  function openAssign(user) {
    setAssignUser(user)
    setSelected(new Set(user.buildingIds?.map(String) || []))
  }

  // Role counts
  const counts = ROLE_TABS.reduce((acc, r) => {
    acc[r] = r === 'All' ? users.length : users.filter(u => u.role === r).length
    return acc
  }, {})

  const filtered = users
    .filter(u => roleTab === 'All' || u.role === roleTab)
    .filter(u =>
      u.name?.toLowerCase().includes(search.toLowerCase()) ||
      u.email?.toLowerCase().includes(search.toLowerCase()) ||
      u.role?.toLowerCase().includes(search.toLowerCase())
    )

  const appUserCount = users.filter(u => APP_ROLES.has(u.role)).length

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <p className="text-sm text-gray-500 mt-1">
            {users.length} team members · <span className="text-brand-600 font-semibold">{appUserCount} mobile app users</span>
          </p>
        </div>
        <button onClick={() => setShowForm(true)} className="btn-primary">
          <Plus size={16} /> Add User
        </button>
      </div>

      {/* Role filter tabs */}
      <div className="flex items-center gap-1.5 flex-wrap">
        {ROLE_TABS.map(r => (
          <button
            key={r}
            onClick={() => setRoleTab(r)}
            className={`px-4 py-1.5 rounded-full text-sm font-semibold transition-colors flex items-center gap-1.5 ${roleTab === r ? 'bg-brand-600 text-white' : 'bg-white border border-gray-200 text-gray-500 hover:bg-gray-50'}`}
          >
            {r === 'Technician' && <Smartphone size={12} className={roleTab === r ? 'text-white' : 'text-amber-500'} />}
            {r === 'Supervisor' && <Smartphone size={12} className={roleTab === r ? 'text-white' : 'text-cyan-500'} />}
            {r}
            <span className={`text-xs px-1.5 py-0.5 rounded-full font-bold ${roleTab === r ? 'bg-white/20 text-white' : 'bg-gray-100 text-gray-500'}`}>
              {counts[r]}
            </span>
          </button>
        ))}
        <div className="ml-auto flex items-center gap-2 bg-white border border-gray-200 rounded-lg px-3 py-1.5">
          <Search size={14} className="text-gray-400" />
          <input placeholder="Search users..." value={search} onChange={e => setSearch(e.target.value)} className="bg-transparent text-sm outline-none placeholder-gray-400 w-40" />
        </div>
      </div>

      {/* Mobile app users banner */}
      {roleTab === 'All' && appUserCount > 0 && (
        <div className="flex items-center gap-3 bg-amber-50 border border-amber-100 rounded-xl px-4 py-3">
          <Smartphone size={18} className="text-amber-600 flex-shrink-0" />
          <p className="text-sm text-amber-800">
            <span className="font-bold">{appUserCount} users</span> (Technicians &amp; Supervisors) access the facility via the <span className="font-bold">mobile app</span>. They can scan QR codes, complete tasks, and report complaints.
          </p>
        </div>
      )}

      {/* Add User Form */}
      {showForm && (
        <div className="card p-6">
          <h2 className="text-base font-bold text-gray-800 mb-4">New Team Member</h2>
          <form onSubmit={createUser} className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Full Name *</label>
              <input required className="input" placeholder="John Smith" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Email *</label>
              <input required type="email" className="input" placeholder="name@company.com" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Role</label>
              <select className="input" value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value }))}>
                {['Admin', 'Manager', 'Supervisor', 'Technician'].map(r => <option key={r}>{r}</option>)}
              </select>
            </div>
            <div className="sm:col-span-3 flex gap-3 justify-end pt-2">
              <button type="button" onClick={() => setShowForm(false)} className="btn-secondary">Cancel</button>
              <button type="submit" disabled={saving} className="btn-primary">{saving ? 'Saving...' : 'Create Member'}</button>
            </div>
          </form>
        </div>
      )}

      {/* Assign Buildings Modal */}
      {assignUser && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl shadow-xl p-6 w-full max-w-md mx-4">
            <h2 className="text-base font-bold text-gray-900 mb-1">Assign Buildings</h2>
            <p className="text-sm text-gray-400 mb-4">{assignUser.name}</p>
            <div className="max-h-64 overflow-y-auto space-y-1 border border-gray-100 rounded-lg p-2">
              {allBuildings.map(b => (
                <label key={b.id} className="flex items-center gap-3 p-2 hover:bg-gray-50 rounded-lg cursor-pointer">
                  <input
                    type="checkbox"
                    className="accent-brand-600"
                    checked={selected.has(b.id.toString())}
                    onChange={ev => setSelected(s => { const n = new Set(s); ev.target.checked ? n.add(b.id.toString()) : n.delete(b.id.toString()); return n })}
                  />
                  <div>
                    <p className="text-sm font-semibold text-gray-800">{b.name}</p>
                    <p className="text-xs text-gray-400">{b.clientName} · {b.location}</p>
                  </div>
                </label>
              ))}
            </div>
            <div className="flex gap-3 mt-4">
              <button onClick={() => setAssignUser(null)} className="btn-secondary flex-1">Cancel</button>
              <button onClick={saveAssignments} disabled={saving} className="btn-primary flex-1">{saving ? 'Saving...' : 'Save'}</button>
            </div>
          </div>
        </div>
      )}

      {/* User Table */}
      {loading ? (
        <div className="text-center text-gray-400 py-16 text-sm">Loading...</div>
      ) : (
        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50">
                <th className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">User</th>
                <th className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">Role</th>
                <th className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">App Access</th>
                <th className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">Buildings</th>
                <th className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map(user => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-3">
                      <div className={`w-9 h-9 rounded-full flex items-center justify-center font-bold text-sm flex-shrink-0 ${avatarColor(user.role)}`}>
                        {initials(user.name)}
                      </div>
                      <div>
                        <p className="font-semibold text-gray-800">{user.name}</p>
                        <p className="text-xs text-gray-400 flex items-center gap-1"><Mail size={11} />{user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3.5">
                    <select
                      value={user.role}
                      onChange={e => updateRole(user.id, e.target.value)}
                      className={`text-xs font-semibold px-2.5 py-1 rounded-full border-0 ring-1 ring-inset cursor-pointer focus:outline-none ${ROLE_STYLE[user.role] || 'bg-gray-100 text-gray-600'} ring-current/20`}
                    >
                      {['Admin', 'Manager', 'Supervisor', 'Technician'].map(r => <option key={r}>{r}</option>)}
                    </select>
                  </td>
                  <td className="px-5 py-3.5">
                    {APP_ROLES.has(user.role)
                      ? <span className="flex items-center gap-1.5 text-xs font-semibold text-amber-600"><Smartphone size={13} /> Mobile App</span>
                      : <span className="text-xs text-gray-400">Admin Portal</span>}
                  </td>
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-1.5 text-xs text-gray-500">
                      <Building2 size={13} className="text-gray-400" />
                      {user.buildings?.filter(Boolean).join(', ') || <span className="text-gray-300 italic">None assigned</span>}
                    </div>
                  </td>
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-3">
                      <button onClick={() => openAssign(user)} className="text-xs text-brand-600 font-semibold hover:underline flex items-center gap-1">
                        <Building2 size={13} /> Assign Buildings
                      </button>
                      <button onClick={() => deleteUser(user.id)} className="text-xs text-red-400 hover:text-red-600 transition-colors">
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {filtered.length === 0 && (
            <div className="p-12 text-center text-gray-400 text-sm">No users found</div>
          )}
        </div>
      )}
    </div>
  )
}
