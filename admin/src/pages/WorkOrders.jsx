import { useEffect, useState } from 'react'
import { Plus, Search, ClipboardList, Clock, User, MapPin, X, CheckCircle2, Play, AlertTriangle, Trash2 } from 'lucide-react'
import api from '../api/client'

const STATUS_STYLE = {
  Pending:       'bg-amber-50 text-amber-700',
  'In Progress': 'bg-blue-50 text-blue-700',
  Completed:     'bg-green-50 text-green-700',
  Missed:        'bg-red-50 text-red-700',
}
const FILTERS = ['All', 'Pending', 'In Progress', 'Completed', 'Missed']

function DetailDrawer({ task, onClose, onUpdate }) {
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState(false)

  async function setStatus(status) {
    setSaving(true)
    try {
      await api.put(`/Tasks/${task.id}/status`, { status })
      onUpdate()
      onClose()
    } catch (_) {}
    setSaving(false)
  }

  return (
    <div className="fixed inset-0 bg-black/40 flex justify-end z-50" onClick={onClose}>
      <div className="bg-white w-full max-w-md h-full shadow-2xl flex flex-col" onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h2 className="font-bold text-gray-900">Work Order</h2>
          <button onClick={onClose} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={16} /></button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-5">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className={`badge ${STATUS_STYLE[task.status] || 'bg-gray-100 text-gray-600'}`}>{task.status}</span>
              {task.isVerified && <span className="badge bg-green-50 text-green-700">QR Verified</span>}
            </div>
            <h3 className="font-bold text-gray-900 text-lg">{task.title}</h3>
            {task.description && <p className="text-sm text-gray-500 mt-1">{task.description}</p>}
          </div>

          <div className="space-y-2.5">
            <div className="flex items-center gap-2 text-sm text-gray-500">
              <MapPin size={14} className="text-gray-400 flex-shrink-0" />
              <span>{task.entityName} ({task.entityType})</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-500">
              <User size={14} className="text-gray-400 flex-shrink-0" />
              <span>{task.assignedToName || 'Unassigned'}</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-500">
              <Clock size={14} className="text-gray-400 flex-shrink-0" />
              <span>Scheduled: {new Date(task.scheduledTime).toLocaleString()}</span>
            </div>
            {task.completedTime && (
              <div className="flex items-center gap-2 text-sm text-gray-500">
                <CheckCircle2 size={14} className="text-green-500 flex-shrink-0" />
                <span>Completed: {new Date(task.completedTime).toLocaleString()}</span>
              </div>
            )}
            {task.notes && (
              <div className="bg-gray-50 rounded-lg p-3 text-sm text-gray-600 mt-2">{task.notes}</div>
            )}
          </div>

          <hr className="border-gray-100" />

          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Update Status</p>
            <div className="grid grid-cols-2 gap-2">
              {['Pending', 'In Progress', 'Completed', 'Missed'].map(s => (
                <button
                  key={s}
                  disabled={saving || task.status === s}
                  onClick={() => setStatus(s)}
                  className={`px-3 py-2 rounded-lg text-sm font-semibold border transition-all disabled:opacity-50 ${
                    task.status === s
                      ? `${STATUS_STYLE[s]} border-current`
                      : 'border-gray-200 text-gray-500 hover:bg-gray-50'
                  }`}
                >
                  {s === 'In Progress' && <Play size={12} className="inline mr-1" />}
                  {s === 'Completed' && <CheckCircle2 size={12} className="inline mr-1" />}
                  {s === 'Missed' && <AlertTriangle size={12} className="inline mr-1" />}
                  {s}
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className="p-6 border-t border-gray-100">
          <button onClick={onClose} className="btn-secondary w-full">Close</button>
        </div>
      </div>
    </div>
  )
}

export default function WorkOrders() {
  const [tasks, setTasks] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState('All')
  const [showForm, setShowForm] = useState(false)
  const [selected, setSelected] = useState(null)
  const [users, setUsers] = useState([])
  const [buildings, setBuildings] = useState([])
  const [form, setForm] = useState({ title: '', description: '', assignedToId: '', assignedToName: '', entityName: '', entityType: 'Room', buildingId: '', scheduledTime: '' })
  const [saving, setSaving] = useState(false)

  useEffect(() => { fetchAll() }, [])

  async function fetchAll() {
    try {
      const [tr, ur, br] = await Promise.all([
        api.get('/Tasks'), api.get('/Users'), api.get('/Hierarchy/all-buildings'),
      ])
      setTasks(tr.data)
      setUsers(ur.data)
      setBuildings(br.data)
    } catch (_) {}
    setLoading(false)
  }

  async function createTask(e) {
    e.preventDefault()
    setSaving(true)
    try {
      const payload = {
        title: form.title,
        description: form.description,
        assignedToId: form.assignedToId,
        assignedToName: form.assignedToName,
        entityId: form.buildingId,
        entityName: form.entityName,
        entityType: form.entityType,
        buildingId: form.buildingId,
        scheduledTime: form.scheduledTime,
        status: 'Pending',
      }
      await api.post('/Tasks', payload)
      setShowForm(false)
      setForm({ title: '', description: '', assignedToId: '', assignedToName: '', entityName: '', entityType: 'Room', buildingId: '', scheduledTime: '' })
      fetchAll()
    } catch (_) {}
    setSaving(false)
  }

  const filtered = tasks
    .filter(t => filter === 'All' || t.status === filter)
    .filter(t => t.title?.toLowerCase().includes(search.toLowerCase()) || t.assignedToName?.toLowerCase().includes(search.toLowerCase()))

  const counts = FILTERS.slice(1).reduce((acc, s) => ({ ...acc, [s]: tasks.filter(t => t.status === s).length }), {})

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Work Orders</h1>
          <p className="text-sm text-gray-500 mt-1">{tasks.length} total tasks</p>
        </div>
        <button onClick={() => setShowForm(true)} className="btn-primary">
          <Plus size={16} /> New Work Order
        </button>
      </div>

      {/* Filter chips */}
      <div className="flex items-center gap-2 flex-wrap">
        {FILTERS.map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-1.5 rounded-full text-sm font-semibold transition-colors ${filter === f ? 'bg-brand-600 text-white' : 'bg-white border border-gray-200 text-gray-500 hover:bg-gray-50'}`}>
            {f} {f !== 'All' && counts[f] ? <span className="ml-1 opacity-70">({counts[f]})</span> : null}
          </button>
        ))}
        <div className="ml-auto flex items-center gap-2 bg-white border border-gray-200 rounded-lg px-3 py-1.5">
          <Search size={14} className="text-gray-400" />
          <input placeholder="Search..." value={search} onChange={e => setSearch(e.target.value)} className="bg-transparent text-sm outline-none placeholder-gray-400 w-40" />
        </div>
      </div>

      {/* Create Form */}
      {showForm && (
        <div className="card p-6">
          <h2 className="text-base font-bold text-gray-800 mb-4">New Work Order</h2>
          <form onSubmit={createTask} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="sm:col-span-2">
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Title *</label>
              <input required className="input" placeholder="e.g. HVAC Filter Replacement" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
            </div>
            <div className="sm:col-span-2">
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Description</label>
              <textarea rows={2} className="input resize-none" placeholder="Task details..." value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Assign To *</label>
              <select required className="input" value={form.assignedToId} onChange={e => {
                const u = users.find(u => u.id === e.target.value)
                setForm(f => ({ ...f, assignedToId: e.target.value, assignedToName: u?.name || '' }))
              }}>
                <option value="">Select technician</option>
                {users.filter(u => u.role === 'Technician' || u.role === 'Supervisor').map(u => <option key={u.id} value={u.id}>{u.name} ({u.role})</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Building *</label>
              <select required className="input" value={form.buildingId} onChange={e => setForm(f => ({ ...f, buildingId: e.target.value }))}>
                <option value="">Select building</option>
                {buildings.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Location Name *</label>
              <input required className="input" placeholder="e.g. Washroom A, HVAC Unit 1" value={form.entityName} onChange={e => setForm(f => ({ ...f, entityName: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Scheduled Time *</label>
              <input required type="datetime-local" className="input" value={form.scheduledTime} onChange={e => setForm(f => ({ ...f, scheduledTime: e.target.value }))} />
            </div>
            <div className="sm:col-span-2 flex gap-3 justify-end pt-2">
              <button type="button" onClick={() => setShowForm(false)} className="btn-secondary">Cancel</button>
              <button type="submit" disabled={saving} className="btn-primary">{saving ? 'Saving...' : 'Create Work Order'}</button>
            </div>
          </form>
        </div>
      )}

      {/* Task List */}
      {loading ? (
        <div className="text-center text-gray-400 py-16 text-sm">Loading...</div>
      ) : filtered.length === 0 ? (
        <div className="card p-16 text-center">
          <ClipboardList size={40} className="text-gray-300 mx-auto mb-3" />
          <p className="text-sm text-gray-500">No work orders found</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map(task => (
            <div key={task.id} onClick={() => setSelected(task)} className="card p-5 hover:shadow-sm transition-shadow cursor-pointer">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 bg-brand-50 rounded-xl flex items-center justify-center flex-shrink-0">
                  <ClipboardList size={18} className="text-brand-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="font-bold text-gray-900">{task.title}</p>
                    <span className={`badge ${STATUS_STYLE[task.status] || 'bg-gray-100 text-gray-600'}`}>{task.status}</span>
                    {task.isVerified && <span className="badge bg-green-50 text-green-700">QR Verified</span>}
                  </div>
                  <div className="flex items-center gap-4 mt-2 flex-wrap">
                    <span className="flex items-center gap-1.5 text-xs text-gray-500"><MapPin size={12} /> {task.entityName} ({task.entityType})</span>
                    <span className="flex items-center gap-1.5 text-xs text-gray-500"><User size={12} /> {task.assignedToName}</span>
                    <span className="flex items-center gap-1.5 text-xs text-gray-500"><Clock size={12} /> {new Date(task.scheduledTime).toLocaleString()}</span>
                  </div>
                  {task.description && <p className="text-xs text-gray-400 mt-1.5 truncate">{task.description}</p>}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {selected && (
        <DetailDrawer task={selected} onClose={() => setSelected(null)} onUpdate={fetchAll} />
      )}
    </div>
  )
}
