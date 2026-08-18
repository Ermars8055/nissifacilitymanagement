import React, { useState } from 'react';
import { Bug, X, UploadCloud, CheckCircle, Loader2 } from 'lucide-react';
import api from '../api/client';
import { useLocation } from 'react-router-dom';

export default function ReportBug() {
  const [isOpen, setIsOpen] = useState(false);
  const [description, setDescription] = useState('');
  const [file, setFile] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');
  
  const location = useLocation();

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0]);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!description.trim()) {
      setError('Please provide a description.');
      return;
    }

    setSubmitting(true);
    setError('');

    try {
      const formData = new FormData();
      formData.append('description', description);
      formData.append('screenContext', location.pathname);
      formData.append('deviceOs', navigator.userAgent);
      formData.append('appVersion', 'Admin Web Dashboard');
      
      if (file) {
        formData.append('screenshot', file);
      }

      await api.post('/DeveloperTickets', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      setSuccess(true);
      setTimeout(() => {
        setIsOpen(false);
        setSuccess(false);
        setDescription('');
        setFile(null);
      }, 2000);
      
    } catch (err) {
      console.error(err);
      setError(err.response?.data || 'Failed to submit report. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      {/* Global Floating Action Button */}
      <button
        onClick={() => setIsOpen(true)}
        className="fixed bottom-6 right-6 z-50 bg-red-600 hover:bg-red-700 text-white p-3 rounded-full shadow-lg transition-transform hover:scale-110 flex items-center justify-center group"
        title="Report an issue to Developers"
      >
        <Bug size={24} />
        <span className="max-w-0 overflow-hidden whitespace-nowrap group-hover:max-w-xs transition-all duration-300 ease-in-out pl-0 group-hover:pl-2 text-sm font-semibold">
          Report Issue
        </span>
      </button>

      {/* Modal Overlay */}
      {isOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden transform transition-all">
            
            <div className="bg-red-50 p-4 border-b border-red-100 flex justify-between items-center">
              <div className="flex items-center gap-2 text-red-700">
                <Bug size={20} />
                <h2 className="font-bold">Report an Issue</h2>
              </div>
              <button 
                onClick={() => setIsOpen(false)}
                className="text-red-400 hover:text-red-700 transition-colors p-1"
              >
                <X size={20} />
              </button>
            </div>

            <div className="p-6">
              {success ? (
                <div className="text-center py-8">
                  <div className="w-16 h-16 bg-green-100 text-green-500 rounded-full flex items-center justify-center mx-auto mb-4">
                    <CheckCircle size={32} />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">Thank You!</h3>
                  <p className="text-gray-500">Your report has been securely sent to our developers.</p>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-4">
                  
                  {/* Context Info Display */}
                  <div className="bg-gray-50 p-3 rounded-lg border border-gray-100 text-xs text-gray-500 font-mono space-y-1">
                    <p><span className="font-semibold text-gray-700">Page Context:</span> {location.pathname}</p>
                    <p className="truncate"><span className="font-semibold text-gray-700">Device:</span> Web Browser</p>
                    <p className="text-[10px] text-blue-500 mt-1 italic">This info is automatically sent to help developers reproduce the bug.</p>
                  </div>

                  {error && (
                    <div className="text-red-500 text-sm p-2 bg-red-50 rounded-lg border border-red-100">
                      {error}
                    </div>
                  )}

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      What went wrong? <span className="text-red-500">*</span>
                    </label>
                    <textarea
                      value={description}
                      onChange={e => setDescription(e.target.value)}
                      placeholder="Please describe the issue in detail..."
                      className="w-full px-3 py-2 border border-gray-300 rounded-xl focus:ring-2 focus:ring-red-500 focus:border-red-500 transition-colors min-h-[100px] text-sm"
                      disabled={submitting}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Attach Screenshot <span className="text-gray-400 font-normal">(Optional)</span>
                    </label>
                    <label className="flex flex-col items-center justify-center w-full h-24 border-2 border-gray-300 border-dashed rounded-xl cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors">
                      <div className="flex flex-col items-center justify-center pt-5 pb-6">
                        <UploadCloud className="w-6 h-6 mb-2 text-gray-400" />
                        <p className="text-xs text-gray-500">
                          {file ? <span className="font-semibold text-gray-700">{file.name}</span> : 'Click to upload screenshot'}
                        </p>
                      </div>
                      <input 
                        type="file" 
                        className="hidden" 
                        accept="image/png, image/jpeg, image/webp" 
                        onChange={handleFileChange}
                        disabled={submitting}
                      />
                    </label>
                  </div>

                  <div className="pt-2">
                    <button
                      type="submit"
                      disabled={submitting}
                      className="w-full bg-gray-900 hover:bg-black text-white font-semibold py-2.5 rounded-xl transition-colors flex items-center justify-center gap-2"
                    >
                      {submitting ? (
                        <>
                          <Loader2 size={18} className="animate-spin" />
                          Submitting...
                        </>
                      ) : (
                        'Submit Ticket'
                      )}
                    </button>
                  </div>
                </form>
              )}
            </div>

          </div>
        </div>
      )}
    </>
  );
}
