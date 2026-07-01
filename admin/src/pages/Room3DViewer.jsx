import React, { useEffect, useState, useRef } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
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
  }, [engineReady, room, assets])

  if (loading) return <div className="text-center text-gray-400 py-16">Loading 3D Room...</div>
  if (error) return <div className="text-center text-red-500 py-16">{error}</div>

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)]">
      <div className="flex items-center gap-4 mb-4">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <ArrowLeft size={20} className="text-gray-500" />
        </button>
        <h1 className="text-2xl font-bold text-gray-900">{room?.name} — 3D Spatial Editor</h1>
      </div>
      
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
    </div>
  )
}
