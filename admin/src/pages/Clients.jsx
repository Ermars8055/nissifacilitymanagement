import { useEffect, useState, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus, Building2, Mail, Phone, MoreVertical, Search, Pencil, Trash2, X } from 'lucide-react'
import api from '../api/client'

function ClientMenu({ client, onEdit, onDelete }) {
  const [open, setOpen] = useState(false)
  const ref = useRef(null)

  useEffect(() => {
    function handler(e) { if (ref.current && !ref.current.contains(e.target)) setOpen(false) }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  return (
    <div ref={ref} className="relative">
      <button onClick={e => { e.stopPropagation(); setOpen(v => !v) }} className="p-1.5 hover:bg-gray-100 rounded-lg">
        <MoreVertical size={15} className="text-gray-400" />
      </button>
      {open && (
        <div className="absolute right-0 top-8 bg-white border border-gray-200 rounded-xl shadow-lg z-20 w-36 py-1">
          <button onClick={() => { setOpen(false); onEdit() }} className="flex items-center gap-2 w-full px-3 py-2 text-sm text-gray-700 hover:bg-gray-50">
            <Pencil size={13} /> Edit
          </button>
          <button onClick={() => { setOpen(false); onDelete() }} className="flex items-center gap-2 w-full px-3 py-2 text-sm text-red-500 hover:bg-red-50">
            <Trash2 size={13} /> Delete
          </button>
        </div>
      )}
    </div>
  )
}

function EditModal({ client, onClose, onSaved }) {
  const [form, setForm] = useState({ name: client.name, contactEmail: client.contactEmail })
  const [saving, setSaving] = useState(false)

  async function save(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.put(`/Hierarchy/clients/${client.id}`, form)
      onSaved()
      onClose()
    } catch (_) {}
    setSaving(false)
  }

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl shadow-xl p-6 w-full max-w-md mx-4">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-bold text-gray-900">Edit Client</h2>
          <button onClick={onClose} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={16} /></button>
        </div>
        <form onSubmit={save} className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Company Name *</label>
            <input required className="input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Contact Email *</label>
            <input required type="email" className="input" value={form.contactEmail} onChange={e => setForm(f => ({ ...f, contactEmail: e.target.value }))} />
          </div>
          <div className="flex gap-3 justify-end pt-2">
            <button type="button" onClick={onClose} className="btn-secondary">Cancel</button>
            <button type="submit" disabled={saving} className="btn-primary">{saving ? 'Saving...' : 'Save Changes'}</button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default function Clients() {
  const navigate = useNavigate()
  const [clients, setClients] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: '', contactEmail: '', contactPhone: '', address: '' })
  const [saving, setSaving] = useState(false)
  const [editing, setEditing] = useState(null)

  useEffect(() => { fetchClients() }, [])

  async function fetchClients() {
    try {
      const r = await api.get('/Hierarchy/clients')
      setClients(r.data)
    } catch (_) {}
    setLoading(false)
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/Hierarchy/clients', form)
      setShowForm(false)
      setForm({ name: '', contactEmail: '', contactPhone: '', address: '' })
      fetchClients()
    } catch (_) {}
    setSaving(false)
  }

  async function deleteClient(client) {
    if (!window.confirm(`Delete "${client.name}"? This will also remove all their buildings, floors, and rooms.`)) return
    try {
      await api.delete(`/Hierarchy/clients/${client.id}`)
      setClients(cs => cs.filter(c => c.id !== client.id))
    } catch (_) {}
  }

  const filtered = clients.filter(c =>
    c.name?.toLowerCase().includes(search.toLowerCase()) ||
    c.contactEmail?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Clients</h1>
          <p className="text-sm text-gray-500 mt-1">{clients.length} corporate accounts</p>
        </div>
        <button onClick={() => setShowForm(true)} className="btn-primary">
          <Plus size={16} /> Add Client
        </button>
      </div>

      <div className="flex items-center gap-2 bg-white border border-gray-200 rounded-lg px-3 py-2 max-w-sm">
        <Search size={15} className="text-gray-400" />
        <input
          placeholder="Search clients..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="bg-transparent text-sm outline-none w-full placeholder-gray-400"
        />
      </div>

      {showForm && (
        <div className="card p-6">
          <h2 className="text-base font-bold text-gray-800 mb-4">New Client</h2>
          <form onSubmit={handleSubmit} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Company Name *</label>
              <input required className="input" placeholder="Apex Industries" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Contact Email *</label>
              <input required type="email" className="input" placeholder="contact@company.com" value={form.contactEmail} onChange={e => setForm(f => ({ ...f, contactEmail: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Phone</label>
              <input className="input" placeholder="+1 555 000 0000" value={form.contactPhone} onChange={e => setForm(f => ({ ...f, contactPhone: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Address</label>
              <input className="input" placeholder="123 Main St, New York" value={form.address} onChange={e => setForm(f => ({ ...f, address: e.target.value }))} />
            </div>
            <div className="sm:col-span-2 flex gap-3 justify-end pt-2">
              <button type="button" onClick={() => setShowForm(false)} className="btn-secondary">Cancel</button>
              <button type="submit" disabled={saving} className="btn-primary">{saving ? 'Saving...' : 'Create Client'}</button>
            </div>
          </form>
        </div>
      )}

      {loading ? (
        <div className="text-center text-gray-400 py-16 text-sm">Loading...</div>
      ) : filtered.length === 0 ? (
        <div className="card p-16 text-center">
          <Building2 size={40} className="text-gray-300 mx-auto mb-3" />
          <p className="font-semibold text-gray-600">No clients yet</p>
          <p className="text-sm text-gray-400 mt-1">Add your first client to get started</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.map(client => (
            <div key={client.id} className="card p-5 hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-brand-50 rounded-xl flex items-center justify-center">
                    <Building2 size={18} className="text-brand-600" />
                  </div>
                  <div>
                    <p className="font-bold text-gray-900 text-sm">{client.name}</p>
                    <p className="text-xs text-gray-400">ID: {client.id?.slice(0, 8)}</p>
                  </div>
                </div>
                <ClientMenu
                  client={client}
                  onEdit={() => setEditing(client)}
                  onDelete={() => deleteClient(client)}
                />
              </div>
              <div className="space-y-1.5 mt-3 pt-3 border-t border-gray-50">
                {client.contactEmail && (
                  <div className="flex items-center gap-2 text-xs text-gray-500">
                    <Mail size={13} className="text-gray-400" /> {client.contactEmail}
                  </div>
                )}
                {client.contactPhone && (
                  <div className="flex items-center gap-2 text-xs text-gray-500">
                    <Phone size={13} className="text-gray-400" /> {client.contactPhone}
                  </div>
                )}
              </div>
              <div className="mt-3 pt-3 border-t border-gray-50 flex items-center justify-between">
                <span className="badge bg-green-50 text-green-700">Active</span>
                <button
                  onClick={() => navigate(`/buildings?clientId=${client.id}`)}
                  className="text-xs text-brand-600 font-semibold hover:underline"
                >
                  View Buildings →
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {editing && (
        <EditModal
          client={editing}
          onClose={() => setEditing(null)}
          onSaved={fetchClients}
        />
      )}
    </div>
  )
}
