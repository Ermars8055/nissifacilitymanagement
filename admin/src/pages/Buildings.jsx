import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Plus, Building2, MapPin, Layers, Search, Pencil, Trash2, X, ChevronLeft } from 'lucide-react'
import api from '../api/client'

const HEALTH_COLOR = v => {
  const n = parseFloat(v) || 0
  return n >= 90 ? 'text-green-600 bg-green-50' : n >= 70 ? 'text-amber-600 bg-amber-50' : 'text-red-600 bg-red-50'
}

function EditModal({ building, clients, onClose, onSaved }) {
  const [form, setForm] = useState({
    name: building.name,
    location: building.location,
    targetLat: building.targetLat ?? '',
    targetLng: building.targetLng ?? '',
    lobbyQrCode: building.lobbyQrCode ?? '',
  })
  const [saving, setSaving] = useState(false)
  const [geoStatus, setGeoStatus] = useState('')

  function captureGps() {
    setGeoStatus('Getting GPS...')
    navigator.geolocation.getCurrentPosition(
      pos => {
        setForm(f => ({ ...f, targetLat: pos.coords.latitude.toFixed(7), targetLng: pos.coords.longitude.toFixed(7) }))
        setGeoStatus(`Captured: ${pos.coords.accuracy.toFixed(0)}m accuracy`)
      },
      err => setGeoStatus('GPS failed: ' + err.message),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  async function save(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.put(`/Hierarchy/buildings/${building.id}`, {
        ...form,
        targetLat: form.targetLat !== '' ? parseFloat(form.targetLat) : null,
        targetLng: form.targetLng !== '' ? parseFloat(form.targetLng) : null,
      })
      onSaved()
      onClose()
    } catch (_) {}
    setSaving(false)
  }

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl shadow-xl p-6 w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-bold text-gray-900">Edit Building</h2>
          <button onClick={onClose} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={16} /></button>
        </div>
        <form onSubmit={save} className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Building Name *</label>
            <input required className="input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Location *</label>
            <input required className="input" value={form.location} onChange={e => setForm(f => ({ ...f, location: e.target.value }))} />
          </div>

          {/* Geofencing anchor */}
          <div className="border border-brand-100 rounded-xl p-4 bg-brand-50/40 space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-bold text-brand-900">GPS Geofence Anchor</p>
                <p className="text-xs text-gray-500 mt-0.5">Workers must be within 40m of these coordinates to check in</p>
              </div>
              <button type="button" onClick={captureGps} className="text-xs bg-brand-700 text-white px-3 py-1.5 rounded-lg font-semibold hover:bg-brand-800">
                📍 Use My GPS
              </button>
            </div>
            {geoStatus && <p className="text-xs text-brand-700 font-medium">{geoStatus}</p>}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-gray-500 block mb-1">Latitude</label>
                <input type="number" step="any" className="input text-sm" placeholder="e.g. 40.7128" value={form.targetLat} onChange={e => setForm(f => ({ ...f, targetLat: e.target.value }))} />
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-500 block mb-1">Longitude</label>
                <input type="number" step="any" className="input text-sm" placeholder="e.g. -74.0060" value={form.targetLng} onChange={e => setForm(f => ({ ...f, targetLng: e.target.value }))} />
              </div>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 block mb-1">Lobby QR Code</label>
              <input className="input text-sm font-mono" placeholder="e.g. QR-LOBBY-TOWER1" value={form.lobbyQrCode} onChange={e => setForm(f => ({ ...f, lobbyQrCode: e.target.value }))} />
              <p className="text-xs text-gray-400 mt-1">Workers scan this QR at the building entrance to start their shift</p>
            </div>
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

export default function Buildings() {
  const [searchParams] = useSearchParams()
  const clientIdFilter = searchParams.get('clientId') || ''
  const navigate = useNavigate()

  const [clients, setClients] = useState([])
  const [buildings, setBuildings] = useState([])
  const [healthMap, setHealthMap] = useState({}) // buildingId -> health string
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ clientId: clientIdFilter, name: '', location: '', totalFloors: '' })
  const [saving, setSaving] = useState(false)
  const [editing, setEditing] = useState(null)

  useEffect(() => { fetchAll() }, [clientIdFilter])

  async function fetchAll() {
    setLoading(true)
    try {
      const [cr, allB, healthR] = await Promise.all([
        api.get('/Hierarchy/clients'),
        api.get('/Hierarchy/all-buildings'),
        api.get('/Dashboard/buildings-health'),
      ])
      setClients(cr.data)
      setBuildings(allB.data)
      const map = {}
      healthR.data.forEach(h => { map[h.buildingId] = h.health })
      setHealthMap(map)
    } catch (_) {}
    setLoading(false)
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/Hierarchy/buildings', { ...form, totalFloors: parseInt(form.totalFloors) || 0 })
      setShowForm(false)
      setForm({ clientId: clientIdFilter, name: '', location: '', totalFloors: '' })
      fetchAll()
    } catch (_) {}
    setSaving(false)
  }

  async function deleteBuilding(b) {
    if (!window.confirm(`Delete "${b.name}"? This will remove all its floors, rooms, and assets.`)) return
    try {
      await api.delete(`/Hierarchy/buildings/${b.id}`)
      setBuildings(bs => bs.filter(x => x.id !== b.id))
    } catch (_) {}
  }

  const filterClient = clients.find(c => c.id === clientIdFilter)
  const filtered = buildings
    .filter(b => !clientIdFilter || b.clientId === clientIdFilter)
    .filter(b =>
      b.name?.toLowerCase().includes(search.toLowerCase()) ||
      b.location?.toLowerCase().includes(search.toLowerCase()) ||
      b.clientName?.toLowerCase().includes(search.toLowerCase())
    )

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          {filterClient && (
            <button onClick={() => navigate('/clients')} className="flex items-center gap-1 text-xs text-brand-600 font-semibold mb-1 hover:underline">
              <ChevronLeft size={13} /> Back to Clients
            </button>
          )}
          <h1 className="text-2xl font-bold text-gray-900">Buildings</h1>
          <p className="text-sm text-gray-500 mt-1">
            {filterClient ? `${filterClient.name} · ` : ''}{filtered.length} properties managed
          </p>
        </div>
        <button onClick={() => setShowForm(true)} className="btn-primary">
          <Plus size={16} /> Add Building
        </button>
      </div>

      <div className="flex items-center gap-2 bg-white border border-gray-200 rounded-lg px-3 py-2 max-w-sm">
        <Search size={15} className="text-gray-400" />
        <input
          placeholder="Search buildings..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="bg-transparent text-sm outline-none w-full placeholder-gray-400"
        />
      </div>

      {showForm && (
        <div className="card p-6">
          <h2 className="text-base font-bold text-gray-800 mb-4">New Building</h2>
          <form onSubmit={handleSubmit} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Client *</label>
              <select required className="input" value={form.clientId} onChange={e => setForm(f => ({ ...f, clientId: e.target.value }))}>
                <option value="">Select client</option>
                {clients.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Building Name *</label>
              <input required className="input" placeholder="Grand Tower" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Location *</label>
              <input required className="input" placeholder="New York, NY" value={form.location} onChange={e => setForm(f => ({ ...f, location: e.target.value }))} />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Total Floors</label>
              <input type="number" className="input" placeholder="10" value={form.totalFloors} onChange={e => setForm(f => ({ ...f, totalFloors: e.target.value }))} />
            </div>
            <div className="sm:col-span-2 flex gap-3 justify-end pt-2">
              <button type="button" onClick={() => setShowForm(false)} className="btn-secondary">Cancel</button>
              <button type="submit" disabled={saving} className="btn-primary">{saving ? 'Saving...' : 'Create Building'}</button>
            </div>
          </form>
        </div>
      )}

      {loading ? (
        <div className="text-center text-gray-400 py-16 text-sm">Loading...</div>
      ) : filtered.length === 0 ? (
        <div className="card p-16 text-center">
          <Building2 size={40} className="text-gray-300 mx-auto mb-3" />
          <p className="font-semibold text-gray-600">No buildings found</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.map(b => {
            const health = healthMap[b.id] || '...'
            const healthNum = parseFloat(health) || 0
            return (
              <div key={b.id} className="card overflow-hidden hover:shadow-md transition-shadow group">
                <div
                  onClick={() => navigate(`/buildings/${b.id}`)}
                  className="h-28 bg-gradient-to-br from-brand-900 to-brand-600 relative flex items-end p-4 cursor-pointer"
                >
                  <Building2 size={80} className="absolute right-3 top-3 text-white opacity-10" />
                  <span className={`badge ${HEALTH_COLOR(healthNum)}`}>{health} Health</span>
                </div>
                <div className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0 cursor-pointer" onClick={() => navigate(`/buildings/${b.id}`)}>
                      <p className="font-bold text-gray-900">{b.name}</p>
                      <p className="text-xs text-gray-400 mt-0.5">{b.clientName}</p>
                      <div className="flex items-center gap-1.5 mt-2 text-xs text-gray-500">
                        <MapPin size={12} /> {b.location || 'No location'}
                      </div>
                      <div className="flex items-center gap-1.5 mt-1 text-xs text-gray-500">
                        <Layers size={12} /> {b.floors || 0} floors
                      </div>
                    </div>
                    <div className="flex items-center gap-1 ml-2 flex-shrink-0">
                      <button onClick={() => setEditing(b)} className="p-1.5 hover:bg-gray-100 rounded-lg" title="Edit">
                        <Pencil size={13} className="text-gray-400" />
                      </button>
                      <button onClick={() => deleteBuilding(b)} className="p-1.5 hover:bg-red-50 rounded-lg" title="Delete">
                        <Trash2 size={13} className="text-red-400" />
                      </button>
                    </div>
                  </div>
                  <div className="mt-3 pt-3 border-t border-gray-50 flex justify-between items-center">
                    <div className="flex items-center gap-2">
                      <span className="badge bg-green-50 text-green-700">Active</span>
                      {b.targetLat ? (
                        <span className="badge bg-blue-50 text-blue-700 text-[10px]">📍 Geo-locked</span>
                      ) : (
                        <span className="badge bg-gray-50 text-gray-400 text-[10px]">No GPS anchor</span>
                      )}
                    </div>
                    <span
                      onClick={() => navigate(`/buildings/${b.id}`)}
                      className="text-xs text-brand-600 font-semibold group-hover:underline cursor-pointer"
                    >
                      Manage →
                    </span>
                  </div>

                </div>
              </div>
            )
          })}
        </div>
      )}

      {editing && (
        <EditModal
          building={editing}
          clients={clients}
          onClose={() => setEditing(null)}
          onSaved={fetchAll}
        />
      )}
    </div>
  )
}
