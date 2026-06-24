import { useEffect, useState } from 'react'
import { Plus, ListChecks, Trash2, GripVertical, X, Type, Hash, CheckSquare, Camera } from 'lucide-react'
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

export default function Checklists() {
  const [templates, setTemplates] = useState([])
  const [buildings, setBuildings] = useState([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(null) // null = hidden, {} = new, template obj = edit

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

                <div className="mt-3 pt-3 border-t border-gray-50 flex justify-end">
                  <button onClick={() => setEditing(t)} className="text-xs text-brand-600 font-semibold hover:underline">
                    Edit Template →
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
