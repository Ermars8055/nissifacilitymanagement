import React, { useEffect, useState } from 'react';
import { Bug, Clock, MonitorSmartphone, Monitor, FileText, CheckCircle, Smartphone } from 'lucide-react';
import api from '../api/client';

export default function DeveloperTickets() {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchTickets();
  }, []);

  const fetchTickets = async () => {
    try {
      const res = await api.get('/DeveloperTickets');
      setTickets(res.data);
    } catch (e) {
      setError('Failed to load tickets.');
    } finally {
      setLoading(false);
    }
  };

  const getDeviceIcon = (os) => {
    if (!os) return <Monitor size={16} />;
    const lower = os.toLowerCase();
    if (lower.includes('ios') || lower.includes('android') || lower.includes('mobile')) {
      return <Smartphone size={16} />;
    }
    return <Monitor size={16} />;
  };

  if (loading) return <div className="p-8 text-center text-gray-500">Loading Developer Tickets...</div>;
  if (error) return <div className="p-8 text-center text-red-500">{error}</div>;

  return (
    <div className="max-w-7xl mx-auto p-6">
      <div className="flex items-center gap-3 mb-8">
        <div className="bg-red-100 p-3 rounded-xl text-red-600">
          <Bug size={24} />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Developer Tickets</h1>
          <p className="text-gray-500">Direct bug reports and issues from users</p>
        </div>
      </div>

      {tickets.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-200">
          <CheckCircle size={48} className="mx-auto text-green-500 mb-4" />
          <h2 className="text-xl font-bold text-gray-900 mb-2">All Clear!</h2>
          <p className="text-gray-500">No bugs have been reported yet.</p>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
          {tickets.map(ticket => (
            <div key={ticket.id} className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden flex flex-col">
              
              <div className="p-5 flex-1">
                <div className="flex justify-between items-start mb-4">
                  <span className={`px-2.5 py-1 text-xs font-semibold rounded-full ${
                    ticket.status === 'Open' ? 'bg-red-100 text-red-700' :
                    ticket.status === 'InProgress' ? 'bg-amber-100 text-amber-700' :
                    'bg-green-100 text-green-700'
                  }`}>
                    {ticket.status}
                  </span>
                  <div className="flex items-center text-xs text-gray-400 gap-1.5">
                    <Clock size={14} />
                    {new Date(ticket.createdAt).toLocaleDateString()}
                  </div>
                </div>

                <div className="mb-4">
                  <p className="text-sm text-gray-800 whitespace-pre-wrap">{ticket.description}</p>
                </div>

                {ticket.screenshotUrl && (
                  <div className="mb-4">
                    <a href={api.defaults.baseURL.replace('/api', '') + ticket.screenshotUrl} target="_blank" rel="noreferrer" className="block group relative rounded-lg overflow-hidden border border-gray-200 bg-gray-50">
                      <div className="aspect-video w-full flex items-center justify-center">
                        <img 
                          src={api.defaults.baseURL.replace('/api', '') + ticket.screenshotUrl} 
                          alt="Screenshot" 
                          className="object-contain h-full w-full"
                          onError={(e) => { e.target.style.display = 'none' }}
                        />
                      </div>
                      <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-sm font-semibold">
                        View Full Screenshot
                      </div>
                    </a>
                  </div>
                )}
              </div>

              <div className="bg-gray-50 px-5 py-4 border-t border-gray-100 space-y-2">
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <MonitorSmartphone size={14} />
                  <span className="font-semibold text-gray-700">Context:</span>
                  <span className="truncate">{ticket.screenContext || 'N/A'}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  {getDeviceIcon(ticket.deviceOs)}
                  <span className="font-semibold text-gray-700">Device:</span>
                  <span className="truncate" title={ticket.deviceOs}>{ticket.deviceOs || 'Unknown'}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <FileText size={14} />
                  <span className="font-semibold text-gray-700">Reported By:</span>
                  <span className="truncate">{ticket.userEmail}</span>
                </div>
              </div>

            </div>
          ))}
        </div>
      )}
    </div>
  );
}
