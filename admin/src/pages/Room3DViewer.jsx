import React, { useEffect, useState, useRef } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Box, MapPin, Search } from 'lucide-react'
import api from '../api/client'

export default function Room3DViewer() {
  const { id } = useParams()
  const navigate = useNavigate()
  const iframeRef = useRef(null)
  
  const [room, setRoom] = useState(null)
  const [assets, setAssets] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [engineReady, setEngineReady] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')

  // 1. Fetch room details + assets
  useEffect(() => {
    async function fetchAll() {
      try {
        const [roomRes, assetsRes] = await Promise.all([
          api.get(`/Hierarchy/rooms/single/${id}`),
          api.get(`/Assets/room/${id}`)
        ])
        setRoom(roomRes.data)
        setAssets(assetsRes.data || [])
      } catch (e) {
        setError(e.message)
      } finally {
        setLoading(false)
      }
    }
    fetchAll()
  }, [id])

  // 2. Handle iframe messages
  useEffect(() => {
    function handleMessage(e) {
      try {
        let data = e.data
        if (typeof data === 'string') data = JSON.parse(data)
        
        if (data.type === 'engine_ready') {
          setEngineReady(true)
        } else if (data.type === 'asset_moved') {
          api.put(`/Assets/${data.id}/position`, {
            assetPosX: data.x,
            assetPosY: data.z
          }).catch(console.error)
          
          setAssets(prev => {
            const next = [...prev]
            const idx = next.findIndex(a => a.id === data.id)
            if (idx > -1) {
              next[idx] = { ...next[idx], assetPosX: data.x, assetPosY: data.z }
            }
            return next
          })
        }
      } catch (err) {}
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])

  // 3. Send data when engine is ready
  useEffect(() => {
    if (engineReady && room && iframeRef.current) {
      const iframe = iframeRef.current
      
      // Inject placed assets
      const placed = assets.filter(a => a.assetPosX != null && a.assetPosY != null)
      for (const asset of placed) {
        iframe.contentWindow.postMessage(JSON.stringify({
          type: 'add_asset',
          id: asset.id,
          name: asset.name,
          x: asset.assetPosX,
          z: asset.assetPosY
        }), '*')
      }
    }
  }, [engineReady, room]) // Intentionally not dependent on `assets` so it doesn't re-trigger add_asset multiple times for all items

  const handlePlaceAsset = async (asset) => {
    try {
      const defaultX = 200
      const defaultZ = 150
      
      await api.put(`/Assets/${asset.id}/position`, {
        assetPosX: defaultX,
        assetPosY: defaultZ
      })
      
      setAssets(prev => {
        const next = [...prev]
        const idx = next.findIndex(a => a.id === asset.id)
        if (idx > -1) {
          next[idx] = { ...next[idx], assetPosX: defaultX, assetPosY: defaultZ }
        }
        return next
      })
      
      if (iframeRef.current) {
        iframeRef.current.contentWindow.postMessage(JSON.stringify({
          type: 'add_asset',
          id: asset.id,
          name: asset.name,
          x: defaultX,
          z: defaultZ
        }), '*')
      }
    } catch (err) {
      console.error('Failed to place asset', err)
    }
  }

  if (loading) return <div className="text-center text-gray-400 py-16">Loading 3D Room...</div>
  if (error) return <div className="text-center text-red-500 py-16">{error}</div>

  let unplacedAssets = assets.filter(a => a.assetPosX == null)
  let placedAssets = assets.filter(a => a.assetPosX != null)
  
  if (searchQuery) {
    const q = searchQuery.toLowerCase()
    unplacedAssets = unplacedAssets.filter(a => a.name.toLowerCase().includes(q) || a.category?.name?.toLowerCase().includes(q))
    placedAssets = placedAssets.filter(a => a.name.toLowerCase().includes(q) || a.category?.name?.toLowerCase().includes(q))
  }

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)]">
      <div className="flex items-center gap-4 mb-4 shrink-0">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <ArrowLeft size={20} className="text-gray-500" />
        </button>
        <h1 className="text-2xl font-bold text-gray-900">{room?.name} — 3D Spatial Editor</h1>
      </div>
      
      <div className="flex-1 flex gap-4 min-h-0">
        {/* 3D Canvas */}
        <div className="flex-1 rounded-xl overflow-hidden border border-gray-200 shadow-sm relative bg-gray-900">
          <iframe
            ref={iframeRef}
            src="/3d-web/3d_editor.html"
            className="w-full h-full border-none"
            title="3D Room Editor"
            allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />
        </div>
        
        {/* Inventory Sidebar */}
        <div className="w-80 flex flex-col bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden shrink-0">
          <div className="p-4 border-b border-gray-100 bg-gray-50">
            <h2 className="font-semibold text-gray-800">Inventory</h2>
            <p className="text-xs text-gray-500 mt-1">Viewing: {room?.name}</p>
            
            <div className="mt-3 relative">
              <Search size={14} className="absolute left-2.5 top-2.5 text-gray-400" />
              <input
                type="text"
                placeholder="Search assets..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full pl-8 pr-3 py-1.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all bg-white"
              />
            </div>
          </div>
          
          <div className="flex-1 overflow-y-auto p-4 space-y-6">
            
            {/* Unplaced Assets */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-semibold text-gray-900 flex items-center gap-2">
                  <Box size={14} className="text-orange-500" />
                  Unplaced ({unplacedAssets.length})
                </h3>
              </div>
              
              {unplacedAssets.length === 0 ? (
                <p className="text-xs text-gray-400 italic">No unplaced items.</p>
              ) : (
                <div className="space-y-2">
                  {unplacedAssets.map(asset => (
                    <div key={asset.id} className="p-3 bg-white border border-orange-200 rounded-lg shadow-sm hover:border-orange-300 transition-colors">
                      <div className="flex justify-between items-start">
                        <div>
                          <p className="text-sm font-medium text-gray-800 line-clamp-1" title={asset.name}>{asset.name}</p>
                          <p className="text-xs text-gray-500">{asset.category?.name || 'Asset'}</p>
                        </div>
                        <button 
                          onClick={() => handlePlaceAsset(asset)}
                          className="text-[10px] uppercase font-bold bg-orange-100 text-orange-700 px-2 py-1 rounded hover:bg-orange-200 transition-colors"
                        >
                          Place
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Placed Assets */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-semibold text-gray-900 flex items-center gap-2">
                  <MapPin size={14} className="text-emerald-500" />
                  Placed ({placedAssets.length})
                </h3>
              </div>
              
              {placedAssets.length === 0 ? (
                <p className="text-xs text-gray-400 italic">No placed items.</p>
              ) : (
                <div className="space-y-2">
                  {placedAssets.map(asset => (
                    <div key={asset.id} className="p-3 bg-gray-50 border border-gray-200 rounded-lg flex items-start gap-3 opacity-80 hover:opacity-100 transition-opacity">
                      <div className="mt-0.5">
                        <MapPin size={14} className="text-emerald-500" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-700 line-clamp-1">{asset.name}</p>
                        <p className="text-xs text-gray-500">{asset.category?.name || 'Asset'}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

          </div>
        </div>
      </div>
    </div>
  )
}
