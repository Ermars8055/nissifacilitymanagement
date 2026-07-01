import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Plus, Layers, DoorOpen, Trash2, Box } from 'lucide-react'
import api from '../api/client'

export default function BuildingDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [building, setBuilding] = useState(null)
  const [floors, setFloors] = useState([])
  const [health, setHealth] = useState('—')
  const [loading, setLoading] = useState(true)
  const [showFloorForm, setShowFloorForm] = useState(false)
  const [floorName, setFloorName] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => { fetchAll() }, [id])

  async function fetchAll() {
    try {
      const [br, fr, dr] = await Promise.all([
        api.get(`/Hierarchy/building/${id}`),
        api.get(`/Hierarchy/floors/${id}`),
        api.get(`/Dashboard?buildingId=${id}`),
      ])
      setBuilding(br.data)
      setFloors(fr.data)
      setHealth(dr.data.kpi?.buildingHealth || '—')
    } catch (_) {}
    setLoading(false)
  }

  async function addFloor(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/Hierarchy/floors', { buildingId: id, name: floorName })
      setFloorName('')
      setShowFloorForm(false)
      const fr = await api.get(`/Hierarchy/floors/${id}`)
      setFloors(fr.data)
    } catch (_) {}
    setSaving(false)
  }

  async function deleteFloor(floorId, floorName) {
    if (!window.confirm(`Delete floor "${floorName}"? All its rooms and assets will be removed.`)) return
    try {
      await api.delete(`/Hierarchy/floor/${floorId}`)
      setFloors(fs => fs.filter(f => f.id !== floorId))
    } catch (_) {}
  }

  if (loading) return <div className="text-center text-gray-400 py-16">Loading...</div>
  if (!building) return <div className="text-center text-gray-400 py-16">Building not found</div>

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/buildings')} className="p-2 hover:bg-gray-100 rounded-lg">
          <ArrowLeft size={18} className="text-gray-600" />
        </button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900">{building.name}</h1>
          <p className="text-sm text-gray-400">{building.location}</p>
        </div>
        <button onClick={() => navigate(`/buildings/${id}/3d`)} className="btn-primary flex items-center gap-2">
          <Box size={16} /> View 3D Building
        </button>
      </div>

      {/* Info cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {[
          { label: 'Location',     value: building.location || '—' },
          { label: 'Total Floors', value: floors.length },
          { label: 'Status',       value: building.status || 'Active' },
          { label: 'Health',       value: health },
        ].map(item => (
          <div key={item.label} className="card p-4">
            <p className="text-xs text-gray-400 font-semibold uppercase tracking-wide">{item.label}</p>
            <p className="text-lg font-bold text-gray-800 mt-1">{item.value}</p>
          </div>
        ))}
      </div>

      {/* Floors */}
      <div className="card">
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h2 className="text-sm font-bold text-gray-700 flex items-center gap-2">
            <Layers size={16} className="text-brand-600" /> Floors ({floors.length})
          </h2>
          <button onClick={() => setShowFloorForm(v => !v)} className="btn-primary text-xs py-1.5 px-3">
            <Plus size={14} /> Add Floor
          </button>
        </div>

        {showFloorForm && (
          <form onSubmit={addFloor} className="flex gap-3 p-4 border-b border-gray-100">
            <input
              required autoFocus
              className="input flex-1"
              placeholder="e.g. Ground Floor, Floor 1"
              value={floorName}
              onChange={e => setFloorName(e.target.value)}
            />
            <button type="submit" disabled={saving} className="btn-primary">{saving ? 'Saving...' : 'Add'}</button>
            <button type="button" onClick={() => setShowFloorForm(false)} className="btn-secondary">Cancel</button>
          </form>
        )}

        {floors.length === 0 ? (
          <div className="p-16 text-center">
            <Layers size={36} className="text-gray-300 mx-auto mb-3" />
            <p className="text-sm text-gray-500">No floors yet. Add the first floor.</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-50">
            {floors.map((floor, i) => (
              <FloorRow key={floor.id} floor={floor} index={i} buildingId={id} onDelete={deleteFloor} />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

function FloorRow({ floor, index, buildingId, onDelete }) {
  const navigate = useNavigate()
  const [rooms, setRooms] = useState([])
  const [open, setOpen] = useState(false)
  const [loadingRooms, setLoadingRooms] = useState(false)
  const [showRoomForm, setShowRoomForm] = useState(false)
  const [roomName, setRoomName] = useState('')
  const [saving, setSaving] = useState(false)

  async function fetchRooms() {
    if (rooms.length > 0 || loadingRooms) return
    setLoadingRooms(true)
    try {
      const r = await api.get(`/Hierarchy/rooms/${floor.id}`)
      setRooms(r.data)
    } catch (_) {}
    setLoadingRooms(false)
  }

  function toggle() {
    if (!open) fetchRooms()
    setOpen(v => !v)
  }

  async function addRoom(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/Hierarchy/rooms', { floorId: floor.id, name: roomName })
      setRoomName('')
      setShowRoomForm(false)
      const r = await api.get(`/Hierarchy/rooms/${floor.id}`)
      setRooms(r.data)
    } catch (_) {}
    setSaving(false)
  }

  async function deleteRoom(room) {
    if (!window.confirm(`Delete room "${room.name}"?`)) return
    try {
      await api.delete(`/Hierarchy/room/${room.id}`)
      setRooms(rs => rs.filter(r => r.id !== room.id))
    } catch (_) {}
  }

  return (
    <div>
      <div className="flex items-center gap-3 px-5 py-3.5 hover:bg-gray-50 cursor-pointer" onClick={toggle}>
        <div className="w-8 h-8 bg-brand-50 rounded-lg flex items-center justify-center flex-shrink-0">
          <span className="text-brand-600 font-bold text-sm">{index + 1}</span>
        </div>
        <div className="flex-1">
          <p className="text-sm font-semibold text-gray-800">{floor.name}</p>
          <p className="text-xs text-gray-400 font-mono">{floor.qrCode}</p>
        </div>
        <span className="text-xs text-gray-400">{rooms.length > 0 ? `${rooms.length} rooms` : ''}</span>
        <button
          onClick={e => { e.stopPropagation(); onDelete(floor.id, floor.name) }}
          className="p-1.5 hover:bg-red-50 rounded-lg text-gray-400 hover:text-red-500 transition-colors"
          title="Delete floor"
        >
          <Trash2 size={13} />
        </button>
        <span className="text-xs text-gray-400">{open ? '▲' : '▼'}</span>
      </div>

      {open && (
        <div className="bg-gray-50 border-t border-gray-100 px-5 pb-3">
          <div className="flex items-center justify-between py-2">
            <p className="text-xs font-semibold text-gray-400 flex items-center gap-1.5">
              <DoorOpen size={13} /> Rooms
            </p>
            <button onClick={() => setShowRoomForm(v => !v)} className="text-xs text-brand-600 font-semibold hover:underline flex items-center gap-1">
              <Plus size={12} /> Add Room
            </button>
          </div>
          {showRoomForm && (
            <form onSubmit={addRoom} className="flex gap-2 mb-3">
              <input required autoFocus className="input flex-1 text-xs py-1.5" placeholder="Room name" value={roomName} onChange={e => setRoomName(e.target.value)} />
              <button type="submit" disabled={saving} className="btn-primary text-xs py-1.5 px-3">{saving ? '...' : 'Add'}</button>
              <button type="button" onClick={() => setShowRoomForm(false)} className="btn-secondary text-xs py-1.5 px-3">Cancel</button>
            </form>
          )}
          {loadingRooms ? (
            <p className="text-xs text-gray-400 py-2">Loading rooms...</p>
          ) : rooms.length === 0 ? (
            <p className="text-xs text-gray-400 py-2">No rooms yet</p>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
              {rooms.map(room => (
                <div key={room.id} className="bg-white border border-gray-200 rounded-lg p-3 relative group flex flex-col justify-between">
                  <div>
                    <div className="flex justify-between items-start">
                      <p className="text-sm font-semibold text-gray-800 truncate pr-5">{room.name}</p>
                      <button
                        onClick={() => deleteRoom(room)}
                        className="p-1 opacity-0 group-hover:opacity-100 hover:bg-red-50 rounded text-gray-400 hover:text-red-500 transition-all absolute top-2 right-2"
                        title="Delete room"
                      >
                        <Trash2 size={11} />
                      </button>
                    </div>
                    <p className="text-xs text-gray-400 font-mono mt-0.5">{room.qrCode}</p>
                  </div>
                  <div className="flex items-center justify-between mt-3">
                    <p className="text-xs text-gray-400">{room.assets?.length || 0} assets</p>
                    <button onClick={() => navigate(`/rooms/${room.id}/3d`)} className="text-xs font-semibold text-brand-600 hover:text-brand-700 bg-brand-50 hover:bg-brand-100 px-2 py-1 rounded transition-colors flex items-center gap-1">
                      <Box size={10} /> 3D Editor
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
