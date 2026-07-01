import React, { useEffect, useState, useRef } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import api from '../api/client'

export default function Building3DViewer() {
  const { id } = useParams()
  const navigate = useNavigate()
  const iframeRef = useRef(null)
  
  const [building, setBuilding] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [engineReady, setEngineReady] = useState(false)

  // 1. Fetch full building structure + all assets for all floors
  useEffect(() => {
    async function fetchAll() {
      try {
        const bldRes = await api.get(`/Hierarchy/building/${id}/full`)
        const bld = bldRes.data
        
        const floors = bld.floors || []
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
          assetMap[floor.id] = allAssets
        }
        
        setBuilding({ ...bld, _assetMap: assetMap })
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
        }
      } catch (err) {}
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])

  // 3. Send data when engine is ready
  useEffect(() => {
    if (engineReady && building && iframeRef.current) {
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
            // Send all assets to the viewer. The 3D script handles placing unpositioned assets in the center.
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
      }, 500)
    }
  }, [engineReady, building])

  if (loading) return <div className="text-center text-gray-400 py-16">Loading 3D Building...</div>
  if (error) return <div className="text-center text-red-500 py-16">{error}</div>

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)]">
      <div className="flex items-center gap-4 mb-4">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <ArrowLeft size={20} className="text-gray-500" />
        </button>
        <h1 className="text-2xl font-bold text-gray-900">{building?.name} — 3D View</h1>
      </div>
      
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
    </div>
  )
}
