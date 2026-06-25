import { useEffect, useState } from 'react'
import { Plus, ListChecks, Trash2, GripVertical, X, Type, Hash, CheckSquare, Camera, Link2, Unlink } from 'lucide-react'
import api from '../api/client'

const ITEM_TYPES = [
  { value: 'checkbox', label: 'Checkbox', icon: CheckSquare },
  { value: 'text',     label: 'Text',     icon: Type },
  { value: 'number',   label: 'Number',   icon: Hash },
  { value: 'photo',    label: 'Photo',    icon: Camera },
]

function ItemTypeIcon({ type, size = 14 }) {
  const found = ITEM_TYPES.find(t => t.value === type)
  const Icon = found?.icon || CheckSquare
  return <Icon size={size} className="text-gray-400 flex-shrink-0" />
}

function TemplateEditor({ template, buildings, onSave, onCancel }) {
  const [name, setName] = useState(template?.name || '')
  const [buildingId, setBuildingId] = useState(template?.buildingId || '')
  const [items, setItems] = useState(() => {
    try { return template ? JSON.parse(template.itemsJson) : [] } catch { return [] }
  })
  const [saving, setSaving] = useState(false)

  function addItem() {
    setItems(prev => [...prev, { id: Date.now().toString(), text: '', type: 'checkbox' }])
  }

  function removeItem(id) {
    setItems(prev => prev.filter(it => it.id !== id))
  }

  function updateItem(id, field, value) {
    setItems(prev => prev.map(it => it.id === id ? { ...it, [field]: value } : it))
  }

  async function save() {
    if (!name.trim() || items.some(it => !it.text.trim())) return
    setSaving(true)
    try {
      const payload = { name, buildingId, itemsJson: JSON.stringify(items) }
      if (template?.id) {
        await api.put(`/Checklists/${template.id}`, payload)
      } else {
        await api.post('/Checklists', payload)
      }
      onSave()
    } catch (_) {}
    setSaving(false)
  }

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-5">
        <h2 className="text-base font-bold text-gray-800">{template?.id ? 'Edit' : 'New'} Checklist Template</h2>
        <button onClick={onCancel} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={16} /></button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-5">
        <div className="sm:col-span-2">
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Template Name *</label>
          <input className="input" placeholder="e.g. Washroom Hourly Check" value={name} onChange={e => setName(e.target.value)} />
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Building</label>
          <select className="input" value={buildingId} onChange={e => setBuildingId(e.target.value)}>
            <option value="">All buildings</option>
            {buildings.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>
      </div>

      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Checklist Items</label>
          <button onClick={addItem} className="text-xs text-brand-600 font-semibold flex items-center gap-1 hover:underline">
            <Plus size={12} /> Add Item
          </button>
        </div>

        {items.length === 0 ? (
          <div className="border-2 border-dashed border-gray-200 rounded-lg p-8 text-center">
            <p className="text-sm text-gray-400">No items yet. Add your first checklist item.</p>
          </div>
        ) : (
          <div className="space-y-2">
            {items.map((item, idx) => (
              <div key={item.id} className="flex items-center gap-3 bg-gray-50 rounded-lg p-3">
                <GripVertical size={14} className="text-gray-300 flex-shrink-0" />
                <span className="text-xs text-gray-400 w-5 flex-shrink-0">{idx + 1}.</span>
                <input
                  className="flex-1 bg-white border border-gray-200 rounded-lg px-3 py-1.5 text-sm outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent"
                  placeholder="Item description..."
                  value={item.text}
                  onChange={e => updateItem(item.id, 'text', e.target.value)}
                />
                <select
                  className="bg-white border border-gray-200 rounded-lg px-2 py-1.5 text-xs outline-none"
                  value={item.type}
                  onChange={e => updateItem(item.id, 'type', e.target.value)}
                >
                  {ITEM_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
                </select>
                <button onClick={() => removeItem(item.id)} className="p-1 hover:bg-red-50 rounded text-gray-400 hover:text-red-500">
                  <Trash2 size={13} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="flex gap-3 justify-end pt-2 border-t border-gray-100">
        <button onClick={onCancel} className="btn-secondary">Cancel</button>
        <button onClick={save} disabled={saving || !name.trim()} className="btn-primary">
          {saving ? 'Saving...' : 'Save Template'}
        </button>
      </div>
    </div>
  )
}

function AssignModal({ template, buildings, onClose, onAssigned }) {
  const [buildingId, setBuildingId] = useState('')
  const [entityType, setEntityType] = useState('Room')
  const [entities, setEntities] = useState([])
  const [loadingEntities, setLoadingEntities] = useState(false)
  const [selectedEntity, setSelectedEntity] = useState(null)
  const [saving, setSaving] = useState(false)

  async function loadEntities(bId, type) {
    if (!bId) { setEntities([]); setSelectedEntity(null); return }
    setLoadingEntities(true)
    setSelectedEntity(null)
    try {
      if (type === 'Room') {
        const res = await api.get(`/Hierarchy/building/${bId}`)
        const building = res.data
        const rooms = (building.floors || []).flatMap(f =>
          (f.rooms || []).map(r => ({ id: r.id, name: `${f.name} → ${r.name}`, type: 'Room' }))
        )
        setEntities(rooms)
      } else {
        const res = await api.get(`/Assets/building/${bId}`)
        setEntities((res.data || []).map(a => ({ id: a.id, name: a.name, type: 'Asset' })))
      }
    } catch (_) { setEntities([]) }
    setLoadingEntities(false)
  }

  function onBuildingChange(bId) {
    setBuildingId(bId)
    loadEntities(bId, entityType)
  }

  function onTypeChange(t) {
    setEntityType(t)
    loadEntities(buildingId, t)
  }

  async function assign() {
    if (!selectedEntity) return
    setSaving(true)
    try {
      await api.post(`/Checklists/${template.id}/assign`, {
        entityId: selectedEntity.id,
        entityType: selectedEntity.type,
        entityName: selectedEntity.name,
      })
      onAssigned()
    } catch (_) {}
    setSaving(false)
  }

  async function unassign(entityId) {
    try {
      await api.delete(`/Checklists/${template.id}/assign/${entityId}`)
      onAssigned()
    } catch (_) {}
  }

  const currentAssignments = template.assignments || []

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg">
        <div className="flex items-center justify-between p-5 border-b border-gray-100">
          <div>
            <h2 className="text-base font-bold text-gray-900">Assign Template</h2>
            <p className="text-xs text-gray-400 mt-0.5">{template.name}</p>
          </div>
          <button onClick={onClose} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={16} /></button>
        </div>

        <div className="p-5 space-y-4">
          {/* Current assignments */}
          {currentAssignments.length > 0 && (
            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Currently Assigned To</p>
              <div className="flex flex-wrap gap-2">
                {currentAssignments.map(a => (
                  <span key={a.id} className="inline-flex items-center gap-1.5 bg-brand-50 text-brand-700 text-xs font-medium px-3 py-1.5 rounded-full">
                    {a.entityName || a.entityId}
                    <button onClick={() => unassign(a.entityId)} className="hover:text-red-500 transition-colors">
                      <Unlink size={11} />
                    </button>
                  </span>
                ))}
              </div>
            </div>
          )}

          <div className="border-t border-gray-50 pt-4">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Add New Assignment</p>

            {/* Building selector */}
            <div className="mb-3">
              <label className="text-xs text-gray-500 block mb-1">Building</label>
              <select className="input" value={buildingId} onChange={e => onBuildingChange(e.target.value)}>
                <option value="">Select building...</option>
                {buildings.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            </div>

            {/* Entity type toggle */}
            <div className="flex gap-2 mb-3">
              {['Room', 'Asset'].map(t => (
                <button
                  key={t}
                  onClick={() => onTypeChange(t)}
                  className={`flex-1 py-2 rounded-lg text-sm font-semibold border transition-colors ${
                    entityType === t
                      ? 'bg-brand-600 text-white border-brand-600'
                      : 'bg-white text-gray-600 border-gray-200 hover:border-brand-300'
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>

            {/* Entity list */}
            {loadingEntities ? (
              <p className="text-xs text-gray-400 text-center py-4">Loading {entityType.toLowerCase()}s...</p>
            ) : entities.length === 0 && buildingId ? (
              <p className="text-xs text-gray-400 text-center py-4">No {entityType.toLowerCase()}s found in this building.</p>
            ) : (
              <div className="max-h-48 overflow-y-auto space-y-1.5">
                {entities.map(e => {
                  const alreadyAssigned = currentAssignments.some(a => a.entityId === e.id)
                  return (
                    <button
                      key={e.id}
                      disabled={alreadyAssigned}
                      onClick={() => setSelectedEntity(e)}
                      className={`w-full text-left px-3 py-2.5 rounded-lg text-sm border transition-colors ${
                        alreadyAssigned
                          ? 'bg-gray-50 text-gray-400 border-gray-100 cursor-not-allowed'
                          : selectedEntity?.id === e.id
                          ? 'bg-brand-50 text-brand-700 border-brand-300 font-medium'
                          : 'bg-white text-gray-700 border-gray-100 hover:border-brand-200 hover:bg-brand-50/40'
                      }`}
                    >
                      {e.name} {alreadyAssigned && <span className="text-xs text-gray-400">(already assigned)</span>}
                    </button>
                  )
                })}
              </div>
            )}
          </div>
        </div>

        <div className="flex gap-3 p-5 border-t border-gray-100">
          <button onClick={onClose} className="btn-secondary flex-1">Cancel</button>
          <button
            onClick={assign}
            disabled={!selectedEntity || saving}
            className="btn-primary flex-1 flex items-center justify-center gap-2"
          >
            <Link2 size={14} />
            {saving ? 'Assigning...' : 'Assign Template'}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function Checklists() {
  const [templates, setTemplates] = useState([])
  const [buildings, setBuildings] = useState([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(null) // null = hidden, {} = new, template obj = edit
  const [assigningId, setAssigningId] = useState(null) // id of template being assigned

  useEffect(() => { fetchAll() }, [])

  async function fetchAll() {
    try {
      const [tr, br] = await Promise.all([
        api.get('/Checklists'), api.get('/Hierarchy/all-buildings'),
      ])
      setTemplates(tr.data)
      setBuildings(br.data)
    } catch (_) {}
    setLoading(false)
  }

  async function remove(id) {
    if (!confirm('Delete this template?')) return
    try { await api.delete(`/Checklists/${id}`); fetchAll() } catch (_) {}
  }

  function parseItems(json) {
    try { return JSON.parse(json) } catch { return [] }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Checklist Templates</h1>
          <p className="text-sm text-gray-500 mt-1">{templates.length} templates</p>
        </div>
        <button onClick={() => setEditing({})} className="btn-primary">
          <Plus size={16} /> New Template
        </button>
      </div>

      {editing !== null && (
        <TemplateEditor
          template={editing.id ? editing : null}
          buildings={buildings}
          onSave={() => { setEditing(null); fetchAll() }}
          onCancel={() => setEditing(null)}
        />
      )}

      {assigningId && (() => {
        const assigningTemplate = templates.find(t => t.id === assigningId)
        return assigningTemplate ? (
          <AssignModal
            template={assigningTemplate}
            buildings={buildings}
            onClose={() => setAssigningId(null)}
            onAssigned={fetchAll}
          />
        ) : null
      })()}

      {loading ? (
        <div className="text-center text-gray-400 py-16 text-sm">Loading...</div>
      ) : templates.length === 0 && editing === null ? (
        <div className="card p-16 text-center">
          <ListChecks size={40} className="text-gray-300 mx-auto mb-3" />
          <p className="text-sm text-gray-500">No checklist templates yet</p>
          <p className="text-xs text-gray-400 mt-1">Create templates to assign to rooms and PM schedules</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {templates.map(t => {
            const items = parseItems(t.itemsJson)
            return (
              <div key={t.id} className="card p-5 hover:shadow-md transition-shadow">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 bg-brand-50 rounded-lg flex items-center justify-center flex-shrink-0">
                      <ListChecks size={17} className="text-brand-600" />
                    </div>
                    <div>
                      <p className="font-bold text-gray-900 text-sm">{t.name}</p>
                      <p className="text-xs text-gray-400">{items.length} items · {t.assignments?.length || 0} assigned</p>
                    </div>
                  </div>
                  <button onClick={() => remove(t.id)} className="p-1.5 hover:bg-red-50 rounded-lg text-gray-400 hover:text-red-500 transition-colors">
                    <Trash2 size={14} />
                  </button>
                </div>

                {items.length > 0 && (
                  <div className="space-y-1.5 mt-3 pt-3 border-t border-gray-50">
                    {items.slice(0, 4).map((item, i) => (
                      <div key={i} className="flex items-center gap-2 text-xs text-gray-500">
                        <ItemTypeIcon type={item.type} />
                        <span className="truncate">{item.text}</span>
                      </div>
                    ))}
                    {items.length > 4 && (
                      <p className="text-xs text-gray-400">+{items.length - 4} more items</p>
                    )}
                  </div>
                )}

                <div className="mt-3 pt-3 border-t border-gray-50 flex items-center justify-between gap-2">
                  <button
                    onClick={() => setAssigningId(t.id)}
                    className="flex items-center gap-1.5 text-xs text-gray-500 font-semibold hover:text-brand-600 transition-colors"
                  >
                    <Link2 size={12} /> Assign to Room/Asset
                  </button>
                  <button onClick={() => setEditing(t)} className="text-xs text-brand-600 font-semibold hover:underline">
                    Edit →
                  </button>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
