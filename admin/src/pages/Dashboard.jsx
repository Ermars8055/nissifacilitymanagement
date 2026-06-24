import { useEffect, useState } from 'react'
import { Building2, Package, AlertCircle, CheckCircle2, ClipboardList, TrendingUp, ChevronDown } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'
import StatCard from '../components/StatCard'
import api from '../api/client'

const COLORS = ['#2563eb', '#10b981', '#f59e0b', '#ef4444']

export default function Dashboard() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [buildings, setBuildings] = useState([])
  const [selectedBuilding, setSelectedBuilding] = useState('')

  useEffect(() => { loadBuildings() }, [])
  useEffect(() => { loadDashboard() }, [selectedBuilding])

  async function loadBuildings() {
    try {
      const r = await api.get('/Hierarchy/all-buildings')
      setBuildings(r.data)
    } catch (_) {}
  }

  async function loadDashboard() {
    setLoading(true)
    try {
      const params = selectedBuilding ? `?buildingId=${selectedBuilding}` : ''
      const r = await api.get(`/Dashboard${params}`)
      setData(r.data)
    } catch (_) {}
    setLoading(false)
  }

  const kpi = data?.kpi || {}
  const activity = data?.recentActivity || []

  const pieData = [
    { name: 'Completed', value: parseInt(kpi.completedTasks) || 0 },
    { name: 'Pending',   value: Math.max(0, (parseInt(kpi.todayTasks) || 0) - (parseInt(kpi.completedTasks) || 0)) },
  ]

  const barData = [
    { name: 'Buildings',   value: kpi.totalBuildings || 0 },
    { name: 'Assets',      value: kpi.totalAssets || 0 },
    { name: 'Open Issues', value: kpi.openComplaints || 0 },
    { name: 'Today Tasks', value: kpi.todayTasks || 0 },
  ]

  const selectedName = buildings.find(b => b.id === selectedBuilding)?.name

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-sm text-gray-500 mt-1">
            {selectedName ? `Showing data for ${selectedName}` : 'Live overview — all facilities'}
          </p>
        </div>
        {/* Building Filter */}
        <div className="relative">
          <select
            className="appearance-none pl-3 pr-8 py-2 text-sm bg-white border border-gray-200 rounded-lg outline-none focus:ring-2 focus:ring-brand-500 text-gray-700 cursor-pointer"
            value={selectedBuilding}
            onChange={e => setSelectedBuilding(e.target.value)}
          >
            <option value="">All Buildings</option>
            {buildings.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
          <ChevronDown size={13} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-64 text-gray-400 text-sm">Loading...</div>
      ) : (
        <>
          {/* KPI Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
            <StatCard label="Buildings"       value={kpi.totalBuildings}          icon={Building2}     color="blue"   />
            <StatCard label="Total Assets"    value={kpi.totalAssets}             icon={Package}       color="green"  />
            <StatCard label="Open Complaints" value={kpi.openComplaints}          icon={AlertCircle}   color="red"    />
            <StatCard label="Resolution Rate" value={kpi.complaintResolutionRate} icon={TrendingUp}    color="purple" />
            <StatCard label="Today's Tasks"   value={kpi.todayTasks}              icon={ClipboardList} color="amber"  />
            <StatCard label="Completed"       value={kpi.completedTasks}          icon={CheckCircle2}  color="cyan"   />
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="card p-5 lg:col-span-2">
              <h2 className="text-sm font-bold text-gray-700 mb-4">Portfolio Overview</h2>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={barData} barSize={40}>
                  <XAxis dataKey="name" tick={{ fontSize: 12, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 12, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 12 }} />
                  <Bar dataKey="value" fill="#2563eb" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>

            <div className="card p-5">
              <h2 className="text-sm font-bold text-gray-700 mb-4">Today's Task Status</h2>
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius={55} outerRadius={80} paddingAngle={3} dataKey="value">
                    {pieData.map((_, i) => <Cell key={i} fill={COLORS[i]} />)}
                  </Pie>
                  <Tooltip contentStyle={{ borderRadius: 8, border: '1px solid #e5e7eb', fontSize: 12 }} />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex justify-center gap-4 mt-2">
                {pieData.map((entry, i) => (
                  <div key={i} className="flex items-center gap-1.5 text-xs text-gray-500">
                    <span className="w-2.5 h-2.5 rounded-full" style={{ background: COLORS[i] }} />
                    {entry.name}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Recent Activity */}
          <div className="card">
            <div className="p-5 border-b border-gray-100">
              <h2 className="text-sm font-bold text-gray-700">Recent Activity</h2>
            </div>
            {activity.length === 0 ? (
              <div className="p-10 text-center text-gray-400 text-sm">No recent activity</div>
            ) : (
              <div className="divide-y divide-gray-50">
                {activity.map((item, i) => {
                  const isTask = item.type === 'task'
                  return (
                    <div key={i} className="flex items-center gap-4 px-5 py-3.5">
                      <div className={`w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 ${isTask ? 'bg-blue-50' : 'bg-red-50'}`}>
                        {isTask
                          ? <ClipboardList size={16} className="text-blue-600" />
                          : <AlertCircle size={16} className="text-red-500" />}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-gray-800 truncate">{item.title}</p>
                        <p className="text-xs text-gray-400">{item.subtitle}</p>
                      </div>
                      <div className="text-right flex-shrink-0">
                        <span className={`badge ${isTask ? 'bg-blue-50 text-blue-700' : 'bg-amber-50 text-amber-700'}`}>{item.status}</span>
                        <p className="text-xs text-gray-400 mt-1">{new Date(item.time).toLocaleDateString()}</p>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </>
      )}
    </div>
  )
}
