import React, { useEffect, useState } from 'react';
import { Bug, Clock, MonitorSmartphone, Monitor, FileText, CheckCircle, Smartphone, X, History, Send } from 'lucide-react';
import api from '../api/client';

function TicketDrawer({ ticketId, onClose, onUpdated }) {
  const [ticket, setTicket] = useState(null);
  const [loading, setLoading] = useState(true);
  const [resolving, setResolving] = useState(false);
  const [status, setStatus] = useState('Resolved');
  const [comment, setComment] = useState('');

  useEffect(() => {
    fetchTicket();
  }, [ticketId]);

  const fetchTicket = async () => {
    try {
      const res = await api.get(`/DeveloperTickets/${ticketId}`);
      setTicket(res.data);
      setStatus(res.data.status === 'Open' ? 'Resolved' : res.data.status);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleResolve = async (e) => {
    e.preventDefault();
    if (!comment.trim()) return;
    setResolving(true);
    try {
      await api.post(`/DeveloperTickets/${ticketId}/resolve`, { status, comment });
      await fetchTicket();
      onUpdated();
      setComment('');
    } catch (e) {
      console.error(e);
    } finally {
      setResolving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 flex justify-end z-[60]" onClick={onClose}>
      <div className="bg-white w-full max-w-lg h-full shadow-2xl flex flex-col" onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h2 className="font-bold text-gray-900">Ticket Details</h2>
          <button onClick={onClose} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={16} /></button>
        </div>

        {loading ? (
          <div className="flex-1 flex items-center justify-center text-gray-400">Loading details...</div>
        ) : ticket ? (
          <div className="flex-1 overflow-y-auto">
            <div className="p-6 border-b border-gray-100 bg-gray-50/50">
              <div className="flex items-center justify-between mb-4">
                <span className={`px-2.5 py-1 text-xs font-semibold rounded-full ${
                  ticket.status === 'Open' ? 'bg-red-100 text-red-700' :
                  ticket.status === 'InProgress' ? 'bg-amber-100 text-amber-700' :
                  'bg-green-100 text-green-700'
                }`}>
                  {ticket.status}
                </span>
                <span className="text-xs text-gray-400">{new Date(ticket.createdAt).toLocaleString()}</span>
              </div>
              
              <h3 className="font-bold text-gray-900 text-lg mb-2">Issue Description</h3>
              <p className="text-sm text-gray-700 whitespace-pre-wrap mb-6 bg-white p-4 rounded-xl border border-gray-100 shadow-sm">{ticket.description}</p>
              
              <div className="grid grid-cols-2 gap-4 text-xs">
                <div>
                  <span className="text-gray-400 block mb-1">Reported By</span>
                  <span className="font-semibold text-gray-800">{ticket.userEmail}</span>
                  <span className="ml-1 text-gray-400">({ticket.userRole})</span>
                </div>
                <div>
                  <span className="text-gray-400 block mb-1">Context / Screen</span>
                  <span className="font-semibold text-gray-800">{ticket.screenContext || 'Unknown'}</span>
                </div>
                <div>
                  <span className="text-gray-400 block mb-1">Device / OS</span>
                  <span className="font-semibold text-gray-800 truncate block">{ticket.deviceOs || 'Unknown'}</span>
                </div>
                <div>
                  <span className="text-gray-400 block mb-1">App Version</span>
                  <span className="font-semibold text-gray-800">{ticket.appVersion || 'Unknown'}</span>
                </div>
              </div>
            </div>

            {ticket.screenshotUrl && (
              <div className="p-6 border-b border-gray-100">
                <h4 className="text-sm font-bold text-gray-900 mb-3">Screenshot Attachment</h4>
                <a href={api.defaults.baseURL.replace('/api', '') + ticket.screenshotUrl} target="_blank" rel="noreferrer" className="block relative rounded-xl overflow-hidden border border-gray-200 bg-gray-50 group">
                  <div className="aspect-video w-full flex items-center justify-center">
                    <img 
                      src={api.defaults.baseURL.replace('/api', '') + ticket.screenshotUrl} 
                      alt="Screenshot" 
                      className="object-contain h-full w-full"
                      onError={(e) => { e.target.style.display = 'none' }}
                    />
                  </div>
                </a>
              </div>
            )}

            <div className="p-6">
              <h4 className="text-sm font-bold text-gray-900 mb-5 flex items-center gap-2">
                <History size={16} className="text-blue-500" /> Resolution Timeline
              </h4>
              
              <div className="space-y-6 relative before:absolute before:inset-0 before:ml-2.5 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-slate-200 before:to-transparent pl-8 md:pl-0">
                {ticket.history?.map((h, i) => (
                  <div key={h.id} className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
                    <div className="flex items-center justify-center w-5 h-5 rounded-full border-4 border-white bg-blue-500 text-slate-500 shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 absolute left-[-29px] md:left-1/2" />
                    <div className="w-[calc(100%-1rem)] md:w-[calc(50%-1.5rem)] bg-white p-4 rounded-xl border border-slate-100 shadow-sm">
                      <div className="flex items-center justify-between mb-1">
                        <div className="font-bold text-slate-900 text-xs">{h.action}</div>
                        <time className="text-[10px] font-medium text-slate-400">{new Date(h.timestamp).toLocaleDateString()}</time>
                      </div>
                      <div className="text-slate-500 text-xs whitespace-pre-wrap">{h.description}</div>
                      <div className="text-[10px] text-slate-400 mt-2 font-medium">By {h.performedBy}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : null}

        {ticket && ticket.status !== 'Closed' && (
          <form onSubmit={handleResolve} className="p-4 border-t border-gray-100 bg-gray-50 flex flex-col gap-3">
            <div className="flex items-center gap-3">
              <select 
                className="py-2 px-3 rounded-lg border text-sm max-w-[140px] bg-white border-gray-200"
                value={status}
                onChange={e => setStatus(e.target.value)}
              >
                <option value="InProgress">In Progress</option>
                <option value="Resolved">Resolved</option>
                <option value="Closed">Closed</option>
              </select>
              <input 
                placeholder="Add resolution notes..." 
                className="py-2 px-3 rounded-lg border text-sm flex-1 bg-white border-gray-200"
                value={comment}
                onChange={e => setComment(e.target.value)}
                required
              />
              <button disabled={resolving} className="bg-blue-600 text-white rounded-lg py-2 px-3 flex-shrink-0">
                <Send size={16} />
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

export default function DeveloperTickets() {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedTicket, setSelectedTicket] = useState(null);

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
            <div 
              key={ticket.id} 
              onClick={() => setSelectedTicket(ticket.id)}
              className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden flex flex-col hover:shadow-md transition-shadow cursor-pointer group"
            >
              <div className="p-5 flex-1">
                <div className="flex justify-between items-start mb-4">
                  <span className={`px-2.5 py-1 text-xs font-semibold rounded-full ${
                    ticket.status === 'Open' ? 'bg-red-100 text-red-700' :
                    ticket.status === 'InProgress' ? 'bg-amber-100 text-amber-700' :
                    ticket.status === 'Closed' ? 'bg-gray-100 text-gray-600' :
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
                  <p className="text-sm text-gray-800 whitespace-pre-wrap line-clamp-3">{ticket.description}</p>
                </div>

                {ticket.screenshotUrl && (
                  <div className="mb-4">
                    <div className="block relative rounded-lg overflow-hidden border border-gray-200 bg-gray-50">
                      <div className="aspect-video w-full flex items-center justify-center">
                        <img 
                          src={api.defaults.baseURL.replace('/api', '') + ticket.screenshotUrl} 
                          alt="Screenshot" 
                          className="object-cover h-full w-full opacity-70 group-hover:opacity-100 transition-opacity"
                          onError={(e) => { e.target.style.display = 'none' }}
                        />
                      </div>
                    </div>
                  </div>
                )}
              </div>

              <div className="bg-gray-50 px-5 py-4 border-t border-gray-100 space-y-2">
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <MonitorSmartphone size={14} />
                  <span className="truncate">{ticket.deviceOs || 'Unknown OS'}</span>
                  <span>·</span>
                  <span>{ticket.appVersion || 'Unknown Ver'}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <FileText size={14} />
                  <span className="truncate">{ticket.screenContext || 'No context'}</span>
                </div>
                <div className="pt-2 mt-2 border-t border-gray-200 flex items-center justify-between">
                  <div className="text-xs font-medium text-gray-800">
                    {ticket.userEmail} <span className="text-gray-400 font-normal">({ticket.userRole})</span>
                  </div>
                  <span className="text-[10px] uppercase font-bold text-brand-600 opacity-0 group-hover:opacity-100 transition-opacity">View Details</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {selectedTicket && (
        <TicketDrawer 
          ticketId={selectedTicket} 
          onClose={() => setSelectedTicket(null)} 
          onUpdated={fetchTickets}
        />
      )}
    </div>
  );
}
