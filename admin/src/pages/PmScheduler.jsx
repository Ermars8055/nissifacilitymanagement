import { useEffect, useState } from 'react'
import { Plus, CalendarClock, Trash2, ToggleLeft, ToggleRight, Play, X } from 'lucide-react'
import api from '../api/client'

const FREQ_STYLE = {
  Daily:   'bg-blue-50 text-blue-700',
  Weekly:  'bg-purple-50 text-purple-700',
  Monthly: 'bg-amber-50 text-amber-700',
}
const DAYS = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']

function ScheduleForm({ buildings, users, templates, onSave, onCancel }) {
  const [form, setForm] = useState({
    title: '', buildingId: '', entityType: 'Room', entityName: '',
    frequency: 'Weekly', dayOfWeek: 1, dayOfMonth: 1, hourOfDay: 8,
    assignedToName: '', checklistTemplateId: '', isActive: true
  })
  const [saving, setSaving] = useState(false)

  async function submit(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/PmSchedules', form)
      onSave()
    } catch (_) {}
    setSaving(false)
  }

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-base font-bold text-gray-800">New PM Schedule</h2>
        <button onClick={onCancel} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={16} /></button>
      </div>
      <form onSubmit={submit} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="sm:col-span-2">
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Schedule Title *</label>
          <input required className="input" placeholder="e.g. Washroom Daily Check" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Building *</label>
          <select required className="input" value={form.buildingId} onChange={e => setForm(f => ({ ...f, buildingId: e.target.value }))}>
            <option value="">Select building</option>
            {buildings.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Entity Type</label>
          <select className="input" value={form.entityType} onChange={e => setForm(f => ({ ...f, entityType: e.target.value }))}>
            {['Room','Asset','Floor','Building'].map(t => <option key={t}>{t}</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Location / Entity Name *</label>
          <input required className="input" placeholder="e.g. Washroom A" value={form.entityName} onChange={e => setForm(f => ({ ...f, entityName: e.target.value }))} />
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Frequency *</label>
          <select className="input" value={form.frequency} onChange={e => setForm(f => ({ ...f, frequency: e.target.value }))}>
            {['Daily','Weekly','Monthly'].map(fr => <option key={fr}>{fr}</option>)}
          </select>
        </div>
        {form.frequency === 'Weekly' && (
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Day of Week</label>
            <select className="input" value={form.dayOfWeek} onChange={e => setForm(f => ({ ...f, dayOfWeek: parseInt(e.target.value) }))}>
              {DAYS.map((d, i) => <option key={i} value={i}>{d}</option>)}
            </select>
          </div>
        )}
        {form.frequency === 'Monthly' && (
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Day of Month</label>
            <input type="number" min={1} max={28} className="input" value={form.dayOfMonth} onChange={e => setForm(f => ({ ...f, dayOfMonth: parseInt(e.target.value) }))} />
          </div>
        )}
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Time (Hour)</label>
          <select className="input" value={form.hourOfDay} onChange={e => setForm(f => ({ ...f, hourOfDay: parseInt(e.target.value) }))}>
            {Array.from({length: 24}, (_, i) => <option key={i} value={i}>{String(i).padStart(2,'0')}:00</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Assign To *</label>
          <select required className="input" value={form.assignedToName} onChange={e => setForm(f => ({ ...f, assignedToName: e.target.value }))}>
            <option value="">Select technician</option>
            {users.filter(u => u.role === 'Technician' || u.role === 'Supervisor').map(u => <option key={u.id} value={u.name}>{u.name}</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide block mb-1">Checklist Template</label>
          <select className="input" value={form.checklistTemplateId} onChange={e => setForm(f => ({ ...f, checklistTemplateId: e.target.value }))}>
            <option value="">No checklist</option>
            {templates.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>
        </div>
        <div className="sm:col-span-2 flex gap-3 justify-end pt-2">
          <button type="button" onClick={onCancel} className="btn-secondary">Cancel</button>
          <button type="submit" disabled={saving} className="btn-primary">{saving ? 'Saving...' : 'Create Schedule'}</button>
        </div>
      </form>
    </div>
  )
}

export default function PmScheduler() {
  const [schedules, setSchedules] = useState([])
  const [buildings, setBuildings] = useState([])
  const [users, setUsers] = useState([])
  const [templates, setTemplates] = useState([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [generating, setGenerating] = useState(false)
  const [generated, setGenerated] = useState(null)

  useEffect(() => { fetchAll() }, [])

  async function fetchAll() {
    try {
      const [sr, ur, tr, br] = await Promise.all([
        api.get('/PmSchedules'), api.get('/Users'),
        api.get('/Checklists'), api.get('/Hierarchy/all-buildings'),
      ])
      setSchedules(sr.data)
      setUsers(ur.data)
      setTemplates(tr.data)
      setBuildings(br.data)
    } catch (_) {}
    setLoading(false)
  }

  async function toggle(id) {
    try { await api.put(`/PmSchedules/${id}/toggle`); fetchAll() } catch (_) {}
  }

  async function remove(id) {
    if (!confirm('Delete this schedule?')) return
    try { await api.delete(`/PmSchedules/${id}`); fetchAll() } catch (_) {}
  }

  async function generateNow() {
    setGenerating(true)
    try {
      const r = await api.post('/PmSchedules/generate-tasks')
      setGenerated(r.data.generated)
      setTimeout(() => setGenerated(null), 4000)
    } catch (_) {}
    setGenerating(false)
  }

  const active = schedules.filter(s => s.isActive).length

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">PM Scheduler</h1>
          <p className="text-sm text-gray-500 mt-1">{schedules.length} schedules · {active} active</p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={generateNow} disabled={generating} className="btn-secondary">
            <Play size={15} /> {generating ? 'Generating...' : 'Generate Tasks Now'}
          </button>
          <button onClick={() => setShowForm(true)} className="btn-primary">
            <Plus size={16} /> New Schedule
          </button>
        </div>
      </div>

      {generated !== null && (
        <div className="bg-green-50 border border-green-200 text-green-700 text-sm px-4 py-3 rounded-lg font-medium">
          Generated {generated} new work order{generated !== 1 ? 's' : ''} from active schedules.
        </div>
      )}

      {showForm && (
        <ScheduleForm
          buildings={buildings}
          users={users}
          templates={templates}
          onSave={() => { setShowForm(false); fetchAll() }}
          onCancel={() => setShowForm(false)}
        />
      )}

      {loading ? (
        <div className="text-center text-gray-400 py-16 text-sm">Loading...</div>
      ) : schedules.length === 0 ? (
        <div className="card p-16 text-center">
          <CalendarClock size={40} className="text-gray-300 mx-auto mb-3" />
          <p className="text-sm text-gray-500">No PM schedules yet</p>
          <p className="text-xs text-gray-400 mt-1">Create schedules to auto-generate recurring work orders</p>
        </div>
      ) : (
        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50">
                {['Schedule','Frequency','Location','Assignee','Checklist','Status','Actions'].map(h => (
                  <th key={h} className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {schedules.map(s => {
                const freqLabel = s.frequency === 'Weekly'
                  ? `Weekly · ${DAYS[s.dayOfWeek]}`
                  : s.frequency === 'Monthly'
                    ? `Monthly · Day ${s.dayOfMonth}`
                    : 'Daily'
                return (
                  <tr key={s.id} className="hover:bg-gray-50">
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 bg-brand-50 rounded-lg flex items-center justify-center flex-shrink-0">
                          <CalendarClock size={15} className="text-brand-600" />
                        </div>
                        <p className="font-semibold text-gray-800">{s.title}</p>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <div>
                        <span className={`badge ${FREQ_STYLE[s.frequency]}`}>{s.frequency}</span>
                        <p className="text-xs text-gray-400 mt-1">{freqLabel} · {String(s.hourOfDay).padStart(2,'0')}:00</p>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <p className="text-sm text-gray-700">{s.entityName}</p>
                      <p className="text-xs text-gray-400">{s.entityType}</p>
                    </td>
                    <td className="px-5 py-3.5 text-sm text-gray-600">{s.assignedToName || '—'}</td>
                    <td className="px-5 py-3.5">
                      {s.checklistTemplateId
                        ? <span className="text-xs text-brand-600 font-medium">{templates.find(t => t.id === s.checklistTemplateId)?.name || 'Template'}</span>
                        : <span className="text-xs text-gray-400">—</span>}
                    </td>
                    <td className="px-5 py-3.5">
                      <button onClick={() => toggle(s.id)} className="flex items-center gap-1.5 text-xs font-medium">
                        {s.isActive
                          ? <><ToggleRight size={18} className="text-green-500" /><span className="text-green-600">Active</span></>
                          : <><ToggleLeft size={18} className="text-gray-400" /><span className="text-gray-400">Paused</span></>}
                      </button>
                    </td>
                    <td className="px-5 py-3.5">
                      <button onClick={() => remove(s.id)} className="p-1.5 hover:bg-red-50 rounded-lg text-gray-400 hover:text-red-500 transition-colors">
                        <Trash2 size={14} />
                      </button>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
