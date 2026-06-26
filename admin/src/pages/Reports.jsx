import { useEffect, useState } from 'react'
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts'
import { TrendingUp, Download, ShieldAlert, MapPin } from 'lucide-react'
import api from '../api/client'

const PIE_COLORS = { Critical: '#ef4444', High: '#f97316', Medium: '#3b82f6', Low: '#22c55e' }
const STATUS_COLORS = { Completed: '#22c55e', Pending: '#f59e0b', 'In Progress': '#3b82f6', Missed: '#ef4444' }

export default function Reports() {
  const [tasks, setTasks] = useState([])
  const [complaints, setComplaints] = useState([])
  const [assets, setAssets] = useState([])
  const [buildings, setBuildings] = useState([])
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [activityData, setActivityData] = useState(null)
  const [activityLoading, setActivityLoading] = useState(false)

  useEffect(() => { fetchAll() }, [])

  async function fetchAll() {
    try {
      const [tr, cr, ur, br, ar] = await Promise.all([
        api.get('/Tasks'), api.get('/Complaints'), api.get('/Users'),
        api.get('/Hierarchy/all-buildings'), api.get('/Assets/all'),
      ])
      setTasks(tr.data)
      setComplaints(cr.data)
      setUsers(ur.data)
      setBuildings(br.data)
      setAssets(ar.data)
    } catch (_) {}
    setLoading(false)
    fetchWorkerActivity()
  }

  async function fetchWorkerActivity() {
    setActivityLoading(true)
    try {
      const res = await api.get('/Reports/worker-activity')
      setActivityData(res.data)
    } catch (_) {}
    setActivityLoading(false)
  }

  if (loading) return <div className="flex items-center justify-center h-64 text-gray-400 text-sm">Loading reports...</div>

  // --- Chart data computations ---

  // 1. Task completion last 7 days
  const last7 = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(); d.setDate(d.getDate() - (6 - i))
    const label = d.toLocaleDateString('en', { weekday: 'short' })
    const dateStr = d.toDateString()
    const dayTasks = tasks.filter(t => new Date(t.scheduledTime).toDateString() === dateStr)
    return { name: label, total: dayTasks.length, completed: dayTasks.filter(t => t.status === 'Completed').length }
  })

  // 2. Complaints by priority
  const byPriority = ['Critical','High','Medium','Low'].map(p => ({
    name: p, value: complaints.filter(c => c.priority === p).length
  })).filter(p => p.value > 0)

  // 3. Task status breakdown
  const byStatus = Object.entries(
    tasks.reduce((acc, t) => ({ ...acc, [t.status]: (acc[t.status] || 0) + 1 }), {})
  ).map(([name, value]) => ({ name, value }))

  // 4. Top buildings by open issues
  const buildingIssues = buildings.map(b => ({
    name: b.name,
    open: complaints.filter(c => c.buildingId === b.id && c.status === 'Open').length,
    total: complaints.filter(c => c.buildingId === b.id).length,
  })).sort((a, b) => b.open - a.open).slice(0, 5)

  // 5. Technician performance
  const techPerf = users
    .filter(u => u.role === 'Technician' || u.role === 'Supervisor')
    .map(u => {
      const mine = tasks.filter(t => t.assignedToId === u.id || t.assignedToName === u.name)
      return {
        name: u.name,
        assigned: mine.length,
        completed: mine.filter(t => t.status === 'Completed').length,
        rate: mine.length ? Math.round(mine.filter(t => t.status === 'Completed').length / mine.length * 100) : 0
      }
    }).sort((a, b) => b.rate - a.rate)

  // 6. Assets by category (top 8)
  const byCat = Object.entries(
    assets.reduce((acc, a) => {
      const key = a.category?.name || 'Uncategorized'
      return { ...acc, [key]: (acc[key] || 0) + 1 }
    }, {})
  ).map(([name, value]) => ({ name, value })).sort((a, b) => b.value - a.value).slice(0, 8)

  const completionRate = tasks.length ? Math.round(tasks.filter(t => t.status === 'Completed').length / tasks.length * 100) : 0
  const openComplaints = complaints.filter(c => c.status === 'Open').length
  const resolvedComplaints = complaints.filter(c => c.status === 'Resolved' || c.status === 'Closed').length

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Reports</h1>
          <p className="text-sm text-gray-500 mt-1">Facility performance overview</p>
        </div>
      </div>

      {/* Summary KPIs */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Tasks',       value: tasks.length,       color: 'bg-blue-50 text-blue-700' },
          { label: 'Completion Rate',   value: `${completionRate}%`, color: 'bg-green-50 text-green-700' },
          { label: 'Open Complaints',   value: openComplaints,     color: 'bg-red-50 text-red-700' },
          { label: 'Resolved',          value: resolvedComplaints, color: 'bg-gray-50 text-gray-700' },
        ].map(k => (
          <div key={k.label} className="card p-4">
            <p className="text-xs text-gray-400 font-semibold uppercase tracking-wide">{k.label}</p>
            <p className={`text-2xl font-bold mt-1 ${k.color.split(' ')[1]}`}>{k.value}</p>
          </div>
        ))}
      </div>

      {/* Charts row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="card p-5 lg:col-span-2">
          <h2 className="text-sm font-bold text-gray-700 mb-4 flex items-center gap-2">
            <TrendingUp size={16} className="text-brand-600" /> Task Completion — Last 7 Days
          </h2>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={last7}>
              <XAxis dataKey="name" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 12 }} />
              <Legend wrapperStyle={{ fontSize: 12 }} />
              <Line type="monotone" dataKey="total" stroke="#e5e7eb" strokeWidth={2} dot={false} name="Scheduled" />
              <Line type="monotone" dataKey="completed" stroke="#2563eb" strokeWidth={2} dot={{ r: 3 }} name="Completed" />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="card p-5">
          <h2 className="text-sm font-bold text-gray-700 mb-4">Complaints by Priority</h2>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={byPriority} cx="50%" cy="50%" innerRadius={50} outerRadius={75} paddingAngle={3} dataKey="value">
                {byPriority.map(entry => <Cell key={entry.name} fill={PIE_COLORS[entry.name] || '#9ca3af'} />)}
              </Pie>
              <Tooltip contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 12 }} />
            </PieChart>
          </ResponsiveContainer>
          <div className="flex flex-wrap justify-center gap-3 mt-1">
            {byPriority.map(entry => (
              <div key={entry.name} className="flex items-center gap-1.5 text-xs text-gray-500">
                <span className="w-2.5 h-2.5 rounded-full" style={{ background: PIE_COLORS[entry.name] }} />
                {entry.name} ({entry.value})
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Charts row 2 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card p-5">
          <h2 className="text-sm font-bold text-gray-700 mb-4">Assets by Category</h2>
          {byCat.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-8">No asset data</p>
          ) : (
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={byCat} layout="vertical" barSize={14}>
                <XAxis type="number" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <YAxis type="category" dataKey="name" width={110} tick={{ fontSize: 11, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 12 }} />
                <Bar dataKey="value" fill="#2563eb" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="card p-5">
          <h2 className="text-sm font-bold text-gray-700 mb-4">Top Buildings by Open Issues</h2>
          {buildingIssues.every(b => b.total === 0) ? (
            <p className="text-sm text-gray-400 text-center py-8">No complaint data</p>
          ) : (
            <div className="space-y-3 mt-2">
              {buildingIssues.map(b => (
                <div key={b.name} className="flex items-center gap-3">
                  <p className="text-sm font-medium text-gray-700 w-32 truncate flex-shrink-0">{b.name}</p>
                  <div className="flex-1 bg-gray-100 rounded-full h-2">
                    <div
                      className="bg-red-400 h-2 rounded-full transition-all"
                      style={{ width: b.total ? `${(b.open / b.total) * 100}%` : '0%' }}
                    />
                  </div>
                  <span className="text-xs font-semibold text-gray-500 w-16 text-right">{b.open} open / {b.total}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Technician Performance Table */}
      <div className="card overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100">
          <h2 className="text-sm font-bold text-gray-700">Technician Performance</h2>
        </div>
        {techPerf.length === 0 ? (
          <div className="p-10 text-center text-gray-400 text-sm">No technician data</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50">
                {['Technician','Assigned','Completed','Completion Rate'].map(h => (
                  <th key={h} className="text-left px-5 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {techPerf.map(t => (
                <tr key={t.name} className="hover:bg-gray-50">
                  <td className="px-5 py-3.5 font-semibold text-gray-800">{t.name}</td>
                  <td className="px-5 py-3.5 text-gray-600">{t.assigned}</td>
                  <td className="px-5 py-3.5 text-gray-600">{t.completed}</td>
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-3">
                      <div className="flex-1 max-w-24 bg-gray-100 rounded-full h-1.5">
                        <div className={`h-1.5 rounded-full ${t.rate >= 80 ? 'bg-green-500' : t.rate >= 50 ? 'bg-amber-400' : 'bg-red-400'}`} style={{ width: `${t.rate}%` }} />
                      </div>
                      <span className={`text-xs font-bold ${t.rate >= 80 ? 'text-green-600' : t.rate >= 50 ? 'text-amber-600' : 'text-red-600'}`}>{t.rate}%</span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Worker Activity / Anti-Spoofing Report */}
      <div className="card overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShieldAlert size={16} className="text-red-500" />
            <h2 className="text-sm font-bold text-gray-700">Worker Activity & Anti-Spoofing Report</h2>
            {activityData && activityData.flaggedTasks > 0 && (
              <span className="badge bg-red-50 text-red-600">{activityData.flaggedTasks} flagged</span>
            )}
          </div>
          <button onClick={fetchWorkerActivity} className="text-xs text-brand-600 font-semibold hover:underline">Refresh</button>
        </div>

        {activityLoading ? (
          <div className="p-10 text-center text-gray-400 text-sm">Loading activity data...</div>
        ) : !activityData || activityData.tasks.length === 0 ? (
          <div className="p-10 text-center text-gray-400 text-sm">
            No task activity events yet. Workers must have active tasks with app background tracking enabled.
          </div>
        ) : (
          <div>
            {/* Attendance sessions summary */}
            {activityData.attendanceSessions.length > 0 && (
              <div className="px-5 py-3 bg-blue-50/50 border-b border-blue-100">
                <p className="text-xs font-bold text-blue-700 flex items-center gap-1.5 mb-2"><MapPin size={12} /> Attendance Sessions (Last 7 Days)</p>
                <div className="space-y-1.5">
                  {activityData.attendanceSessions.slice(0, 5).map(s => (
                    <div key={s.id} className="flex items-center justify-between text-xs text-blue-800">
                      <span>Worker {s.workerId.slice(0, 8)}… — {new Date(s.startedAt).toLocaleString()}</span>
                      <span className="font-semibold">{s.distanceFromBuilding ? `${s.distanceFromBuilding.toFixed(0)}m from entrance` : 'Distance N/A'}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  {['Task','Worker','Scheduled','Status','Away Time','App Switches','Flag'].map(h => (
                    <th key={h} className="text-left px-4 py-3 text-xs font-bold text-gray-500 uppercase tracking-wide">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {activityData.tasks.map(t => {
                  const awayMin = Math.floor(t.totalAwaySeconds / 60)
                  const awaySec = t.totalAwaySeconds % 60
                  return (
                    <tr key={t.taskId} className={t.flagged ? 'bg-red-50/40' : 'hover:bg-gray-50'}>
                      <td className="px-4 py-3 font-semibold text-gray-800 max-w-48 truncate">{t.taskTitle}</td>
                      <td className="px-4 py-3 text-gray-600 text-xs">{t.workerName || t.workerId?.slice(0,8)}</td>
                      <td className="px-4 py-3 text-gray-500 text-xs">{new Date(t.scheduledTime).toLocaleDateString()}</td>
                      <td className="px-4 py-3">
                        <span className={`badge text-xs ${t.status === 'Completed' ? 'bg-green-50 text-green-700' : t.status === 'In Progress' ? 'bg-blue-50 text-blue-700' : 'bg-gray-100 text-gray-600'}`}>
                          {t.status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-xs font-mono">
                        {t.totalAwaySeconds > 0
                          ? <span className={t.totalAwaySeconds > 300 ? 'text-red-600 font-bold' : 'text-gray-600'}>{awayMin}m {awaySec}s</span>
                          : <span className="text-gray-400">—</span>}
                      </td>
                      <td className="px-4 py-3 text-xs text-center">
                        {t.switchCount > 0
                          ? <span className={t.switchCount > 3 ? 'text-red-600 font-bold' : 'text-gray-600'}>{t.switchCount}×</span>
                          : <span className="text-gray-400">—</span>}
                      </td>
                      <td className="px-4 py-3">
                        {t.flagged
                          ? <span className="badge bg-red-100 text-red-700 font-bold">⚠ Flagged</span>
                          : <span className="text-green-500 text-xs">✓ OK</span>}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
