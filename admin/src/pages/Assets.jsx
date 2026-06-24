import { useEffect, useState } from 'react'
import { Package, Search, QrCode, Plus, X, Trash2 } from 'lucide-react'
import api from '../api/client'

function RegisterForm({ onClose, onSaved }) {
  const [buildings, setBuildings] = useState([])
  const [categories, setCategories] = useState([])
  const [floors, setFloors] = useState([])
  const [rooms, setRooms] = useState([])
  const [form, setForm] = useState({
    buildingId: '', clientId: '', floorId: '', roomId: '',
    categoryId: '', name: '', serialNumber: '', status: 'Active'
  })
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    async function loadBuildings() {
      try {
        const cr = await api.get('/Hierarchy/clients')
        const bAll = []
        for (const c of cr.data) {
          const br = await api.get(`/Hierarchy/buildings/${c.id}`)
          br.data.forEach(b => bAll.push({ ...b, clientId: c.id }))
        }
        setBuildings(bAll)
      } catch (_) {}
    }
    loadBuildings()
  }, [])

  async function onBuildingChange(buildingId) {
    const b = buildings.find(x => x.id === buildingId)
    setForm(f => ({ ...f, buildingId, clientId: b?.clientId || '', floorId: '', roomId: '', categoryId: '' }))
    setFloors([])
    setRooms([])
    setCategories([])
    if (!buildingId) return
    try {
      const [fr, cr] = await Promise.all([
        api.get(`/Hierarchy/floors/${buildingId}`),
        b ? api.get(`/Assets/categories/${b.clientId}`) : Promise.resolve({ data: [] })
      ])
      setFloors(fr.data)
      setCategories(cr.data.filter(c => c.parentCategoryId)) // only sub-categories
    } catch (_) {}
  }

  async function onFloorChange(floorId) {
    setForm(f => ({ ...f, floorId, roomId: '' }))
    setRooms([])
    if (!floorId) return
    try {
      const r = await api.get(`/Hierarchy/rooms/${floorId}`)
      setRooms(r.data)
    } catch (_) {}
  }

  async function submit(e) {
    e.preventDefault()
    setSaving(true)
    try {
      const payload = {
        categoryId: form.categoryId,
        buildingId: form.buildingId,
        floorId: form.floorId || null,
        roomId: form.roomId || null,
        name: form.name,
        serialNumber: form.serialNumber,
        status: form.status,
      }
      await api.post('/Assets', payload)
      onSaved()
      onClose()
    } catch (_) {}
    setSaving(false)
  }

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-5">
        <h2 className="text-base font-bold text-gray-800">Register New Asset</h2>
        <button onClick={onClose} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={16} /></button>
      </div>
      <form onSubmit={submit} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Building *</label>
          <select required className="input" value={form.buildingId} onChange={e => onBuildingChange(e.target.value)}>
            <option value="">Select building</option>
            {buildings.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Category *</label>
          <select required className="input" value={form.categoryId} onChange={e => setForm(f => ({ ...f, categoryId: e.target.value }))} disabled={!form.buildingId}>
            <option value="">Select category</option>
            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Floor (optional)</label>
          <select className="input" value={form.floorId} onChange={e => onFloorChange(e.target.value)} disabled={!form.buildingId}>
            <option value="">Building level</option>
            {floors.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Room (optional)</label>
          <select className="input" value={form.roomId} onChange={e => setForm(f => ({ ...f, roomId: e.target.value }))} disabled={!form.floorId}>
            <option value="">No specific room</option>
            {rooms.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Asset Name *</label>
          <input required className="input" placeholder="e.g. Rooftop HVAC Unit 1" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Serial Number</label>
          <input className="input" placeholder="SN-XXXX-0001" value={form.serialNumber} onChange={e => setForm(f => ({ ...f, serialNumber: e.target.value }))} />
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Status</label>
          <select className="input" value={form.status} onChange={e => setForm(f => ({ ...f, status: e.target.value }))}>
            <option>Active</option>
            <option>Under Maintenance</option>
            <option>Decommissioned</option>
          </select>
        </div>
        <div className="sm:col-span-2 flex gap-3 justify-end pt-2">
          <button type="button" onClick={onClose} className="btn-secondary">Cancel</button>
          <button type="submit" disabled={saving || !form.buildingId || !form.categoryId || !form.name} className="btn-primary">
            {saving ? 'Registering...' : 'Register Asset'}
          </button>
        </div>
      </form>
    </div>
  )
}

export default function Assets() {
  const [assets, setAssets] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [showForm, setShowForm] = useState(false)

  useEffect(() => { fetchAll() }, [])

  async function fetchAll() {
    setLoading(true)
    try {
      const r = await api.get('/Assets/all')
      setAssets(r.data)
    } catch (_) {}
    setLoading(false)
  }

  async function deleteAsset(asset) {
    if (!window.confirm(`Delete asset "${asset.name}"?`)) return
    try {
      await api.delete(`/Assets/${asset.id}`)
      setAssets(as => as.filter(a => a.id !== asset.id))
    } catch (_) {}
  }

  const filtered = assets.filter(a =>
    a.name?.toLowerCase().includes(search.toLowerCase()) ||
    a.category?.name?.toLowerCase().includes(search.toLowerCase()) ||
    a.buildingName?.toLowerCase().includes(search.toLowerCase()) ||
    a.room?.name?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Assets</h1>
          <p className="text-sm text-gray-500 mt-1">{assets.length} assets registered</p>
        </div>
        <button onClick={() => setShowForm(true)} className="btn-primary">
          <Plus size={16} /> Register Asset
        </button>
      </div>

      <div className="flex items-center gap-2 bg-white border border-gray-200 rounded-lg px-3 py-2 max-w-sm">
        <Search size={15} className="text-gray-400" />
        <input placeholder="Search by name, category, building..." value={search} onChange={e => setSearch(e.target.value)} className="bg-transparent text-sm outline-none w-full placeholder-gray-400" />
      </div>

      {showForm && (
        <RegisterForm onClose={() => setShowForm(false)} onSaved={fetchAll} />
      )}

      {loading ? (
        <div className="text-center text-gray-400 py-16 text-sm">Loading assets...</div>
      ) : filtered.length === 0 ? (
        <div className="card p-16 text-center">
          <Package size={40} className="text-gray-300 mx-auto mb-3" />
          <p className="text-sm text-gray-500">No assets found</p>
          <p className="text-xs text-gray-400 mt-1">Register assets using the button above or via building → floor → room</p>
        </div>
      ) : (
        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50">
                {['Asset', 'Category', 'Location', 'QR Code', 'Status', ''].map(h => (
                  <th key={h} className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map(asset => (
                <tr key={asset.id} className="hover:bg-gray-50">
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 bg-brand-50 rounded-lg flex items-center justify-center flex-shrink-0">
                        <Package size={15} className="text-brand-600" />
                      </div>
                      <div>
                        <p className="font-semibold text-gray-800">{asset.name}</p>
                        <p className="text-xs text-gray-400">{asset.serialNumber || '—'}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3.5">
                    <span className="badge bg-gray-100 text-gray-600">{asset.category?.name || '—'}</span>
                  </td>
                  <td className="px-5 py-3.5">
                    <p className="text-sm text-gray-700">{asset.buildingName}</p>
                    <p className="text-xs text-gray-400">{asset.room?.name || 'Building level'}</p>
                  </td>
                  <td className="px-5 py-3.5">
                    <span className="flex items-center gap-1.5 text-xs font-mono text-gray-500">
                      <QrCode size={13} className="text-gray-400" /> {asset.qrCode}
                    </span>
                  </td>
                  <td className="px-5 py-3.5">
                    <span className={`badge ${asset.status === 'Active' || !asset.status ? 'bg-green-50 text-green-700' : asset.status === 'Under Maintenance' ? 'bg-amber-50 text-amber-700' : 'bg-gray-100 text-gray-600'}`}>
                      {asset.status || 'Active'}
                    </span>
                  </td>
                  <td className="px-5 py-3.5">
                    <button onClick={() => deleteAsset(asset)} className="p-1.5 hover:bg-red-50 rounded-lg text-gray-400 hover:text-red-500 transition-colors">
                      <Trash2 size={14} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
