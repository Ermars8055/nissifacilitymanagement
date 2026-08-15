import React, { useEffect, useState, useRef } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Box, MapPin, Search, X } from 'lucide-react'
import api from '../api/client'

export default function Building3DViewer() {
  const { id } = useParams()
  const navigate = useNavigate()
  const iframeRef = useRef(null)
  
  const [building, setBuilding] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [engineReady, setEngineReady] = useState(false)
  
  const [activeFloorId, setActiveFloorId] = useState(null)
  const [searchQuery, setSearchQuery] = useState('')

  const buildingRef = useRef(building)
  useEffect(() => { buildingRef.current = building }, [building])

  const buildingLoadedRef = useRef(false)

  // 1. Fetch full building structure + all assets for all floors
  useEffect(() => {
    async function fetchAll() {
      try {
        const bldRes = await api.get(`/Hierarchy/building/${id}/full`)
        const bld = bldRes.data
        
        const floors = bld.floors || []
        floors.sort((a, b) => (a.level || 0) - (b.level || 0))
        const assetMap = {}
        for (const floor of floors) {
          const rooms = floor.rooms || []
          const allAssets = []
          for (const room of rooms) {
            try {
              const res = await api.get(`/Assets/room/${room.id}`)
              allAssets.push(...res.data)
            } catch(e) {}
          }
          // Group assets by floor
          assetMap[floor.id] = allAssets
        }
        
        setBuilding({ ...bld, floors, _assetMap: assetMap })
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
          
          setBuilding(prev => {
            if (!prev) return prev
            const next = { ...prev }
            const floorId = data.floorId
            if (next._assetMap[floorId]) {
              const idx = next._assetMap[floorId].findIndex(a => a.id === data.id)
              if (idx > -1) {
                next._assetMap[floorId][idx] = { ...next._assetMap[floorId][idx], assetPosX: data.x, assetPosY: data.z }
              }
            }
            return next
          })
        } else if (data.type === 'floor_isolated') {
          setActiveFloorId(data.floorId)
        } else if (data.type === 'asset_dropped') {
          const { id: assetId, floorId, x, z } = data;
          const bld = buildingRef.current;
          if (!bld) return;
          
          let foundAsset = null;
          for (const fId of Object.keys(bld._assetMap)) {
            const ast = bld._assetMap[fId].find(a => a.id === assetId);
            if (ast) { foundAsset = ast; break; }
          }
          
          if (foundAsset) {
            api.put(`/Assets/${assetId}/position`, { assetPosX: x, assetPosY: z }).catch(console.error);
            setBuilding(prev => {
              const next = { ...prev };
              for (const fId of Object.keys(next._assetMap)) {
                const idx = next._assetMap[fId].findIndex(a => a.id === assetId);
                if (idx > -1) {
                   next._assetMap[fId][idx] = { ...next._assetMap[fId][idx], assetPosX: x, assetPosY: z };
                }
              }
              return next;
            });
            if (iframeRef.current) {
               iframeRef.current.contentWindow.postMessage(JSON.stringify({
                 type: 'add_asset',
                 id: assetId,
                 name: foundAsset.name,
                 floorId: floorId,
                 x: x,
                 z: z
               }), '*');
            }
          }
        }
      } catch (err) {}
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])

  // 3. Send data when engine is ready
  useEffect(() => {
    if (engineReady && building && iframeRef.current && !buildingLoadedRef.current) {
      buildingLoadedRef.current = true;
      const iframe = iframeRef.current
      iframe.contentWindow.postMessage(JSON.stringify({
        type: 'load_building',
        data: building
      }), '*')

      setTimeout(() => {
        const floors = building.floors || []
        for (const floor of floors) {
          const assets = building._assetMap[floor.id] || []
          for (const asset of assets) {
            // ONLY send placed assets initially
            if (asset.assetPosX != null && asset.assetPosY != null) {
              iframe.contentWindow.postMessage(JSON.stringify({
                type: 'add_asset',
                id: asset.id,
                name: asset.name,
                floorId: floor.id,
                x: asset.assetPosX,
                z: asset.assetPosY
              }), '*')
            }
          }
        }
      }, 500)
    }
  }, [engineReady, building])

  const handleUnplaceAsset = async (asset) => {
    try {
      await api.put(`/Assets/${asset.id}/position`, { assetPosX: null, assetPosY: null });
      setBuilding(prev => {
        const next = { ...prev };
        for (const fId of Object.keys(next._assetMap)) {
          const idx = next._assetMap[fId].findIndex(a => a.id === asset.id);
          if (idx > -1) {
             next._assetMap[fId][idx] = { ...next._assetMap[fId][idx], assetPosX: null, assetPosY: null };
          }
        }
        return next;
      });
      if (iframeRef.current) {
        iframeRef.current.contentWindow.postMessage(JSON.stringify({ type: 'remove_asset', id: asset.id }), '*');
      }
    } catch (e) {
      console.error('Failed to unplace asset', e);
    }
  }

  const handleDragStart = (e, asset) => {
    e.dataTransfer.setData('text/plain', asset.id);
    e.dataTransfer.effectAllowed = 'copy';
  }

  if (loading) return <div className="text-center text-gray-400 py-16">Loading 3D Building...</div>
  if (error) return <div className="text-center text-red-500 py-16">{error}</div>

  const floors = building?.floors || []
  let displayFloorName = "All Floors"
  
  let unplacedAssets = []
  let placedAssets = []
  
  if (activeFloorId) {
    const floorAssets = building?._assetMap?.[activeFloorId] || []
    displayFloorName = floors.find(f => f.id === activeFloorId)?.name || "Floor"
    
    floorAssets.forEach(a => {
      const ast = { ...a, _floorId: activeFloorId }
      if (ast.assetPosX == null) unplacedAssets.push(ast)
      else placedAssets.push(ast)
    })
  } else {
    floors.forEach(f => {
      const arr = building?._assetMap?.[f.id] || []
      arr.forEach(a => {
        const ast = { ...a, _floorId: f.id }
        if (ast.assetPosX == null) unplacedAssets.push(ast)
        else placedAssets.push(ast)
      })
    })
  }
  
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
        <h1 className="text-2xl font-bold text-gray-900">{building?.name} — 3D View</h1>
      </div>
      
      <div className="flex-1 flex gap-4 min-h-0">
        {/* 3D Canvas */}
        <div className="flex-1 rounded-xl overflow-hidden border border-gray-200 shadow-sm relative bg-gray-900">
          <iframe
            ref={iframeRef}
            src="/3d-web/building_3d_viewer.html"
            className="w-full h-full border-none"
            title="3D Building Viewer"
            allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />
        </div>
        
        {/* Inventory Sidebar */}
        <div className="w-80 flex flex-col bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden shrink-0">
          <div className="p-4 border-b border-gray-100 bg-gray-50">
            <h2 className="font-semibold text-gray-800">Inventory</h2>
            <p className="text-xs text-gray-500 mt-1">Viewing: {displayFloorName}</p>
            
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
                    <div 
                      key={asset.id} 
                      draggable={true}
                      onDragStart={(e) => handleDragStart(e, asset)}
                      className="p-3 bg-white border border-orange-200 rounded-lg shadow-sm hover:border-orange-300 transition-colors cursor-grab active:cursor-grabbing"
                      title="Drag and drop onto the 3D floor to place"
                    >
                      <div className="flex justify-between items-start">
                        <div>
                          <p className="text-sm font-medium text-gray-800 line-clamp-1">{asset.name}</p>
                          <p className="text-xs text-gray-500">{asset.category?.name || 'Asset'}</p>
                        </div>
                        <div className="text-[10px] uppercase font-bold text-orange-400 border border-orange-200 px-1.5 py-0.5 rounded pointer-events-none">
                          Drag
                        </div>
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
                    <div key={asset.id} className="p-3 bg-gray-50 border border-gray-200 rounded-lg flex items-start gap-3 group">
                      <div className="mt-0.5">
                        <MapPin size={14} className="text-emerald-500" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-700 line-clamp-1">{asset.name}</p>
                        <p className="text-xs text-gray-500">{asset.category?.name || 'Asset'}</p>
                      </div>
                      <button 
                        onClick={() => handleUnplaceAsset(asset)}
                        className="text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity p-1 -mr-1"
                        title="Remove from floor"
                      >
                        <X size={16} />
                      </button>
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
