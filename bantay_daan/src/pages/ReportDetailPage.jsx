import { useEffect, useState } from 'react';
import { doc, onSnapshot, updateDoc, serverTimestamp, getDoc, setDoc, deleteDoc } from 'firebase/firestore';
import { db, auth } from '../firebase/firebase';
import { useParams, useNavigate } from 'react-router-dom';
import Sidebar from '../components/Sidebar';
import StatusBadge from '../components/StatusBadge';
import PriorityBadge from '../components/PriorityBadge';

const TYPE_COLORS = {
  'Pothole':        '#F4A261',
  'Flooding':       '#61B4F4',
  'Obstruction':    '#F46161',
  'Road Damage':    '#F4844A',
  'Accident':       '#D94F4F',
  'Missing Signage':'#9B8CF4',
};

export default function ReportDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [report, setReport]     = useState(null);
  const [status, setStatus]     = useState('');
  const [priority, setPriority] = useState('low');
  const [remark, setRemark]     = useState('');
  const [saving, setSaving]     = useState(false);
  const [saved, setSaved]       = useState(false);
  const [archiving, setArchiving] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'reports', id), snap => {
      if (!snap.exists()) return;
      const data = { id: snap.id, ...snap.data() };
      setReport(data);
      setStatus(prev => prev || data.status || 'pending');
      setPriority(prev => prev || data.priority || 'low');
      setRemark(prev => prev || data.adminRemark || '');
    });
    return unsub;
  }, [id]);

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateDoc(doc(db, 'reports', id), {
        status,
        priority,
        adminRemark: remark,
        verifiedBy: auth.currentUser?.uid || null,
        updatedAt: serverTimestamp(),
      });
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } catch (err) {
      console.error('Save error:', err);
    } finally {
      setSaving(false);
    }
  };

  const handleArchive = async () => {
    if (!window.confirm('Archive this report? You can restore it later from the Archive page.')) return;
    setArchiving(true);
    try {
      const ref = doc(db, 'reports', id);
      const snap = await getDoc(ref);
      if (!snap.exists()) return;
      await setDoc(doc(db, 'archived_reports', id), {
        ...snap.data(),
        archivedAt: serverTimestamp(),
      });
      await deleteDoc(ref);
      navigate('/reports');
    } catch (err) {
      console.error('Archive error:', err);
    } finally {
      setArchiving(false);
    }
  };

  if (!report) {
    return (
      <div className="flex min-h-screen bg-navy-deep">
        <Sidebar active="reports" />
        <main className="flex-1 flex items-center justify-center">
          <div className="w-6 h-6 border-2 border-amber border-t-transparent rounded-full animate-spin" />
        </main>
      </div>
    );
  }

  const typeColor = TYPE_COLORS[report.type] || '#F0F4F8';

  return (
    <div className="flex min-h-screen bg-navy-deep">
      <Sidebar active="reports" />

      <main className="flex-1 p-6 overflow-auto">
        {/* Back */}
        <button
          onClick={() => navigate('/reports')}
          className="flex items-center gap-1.5 text-xs text-gray-400 mb-5 hover:text-amber transition-colors"
        >
          <svg viewBox="0 0 20 20" fill="currentColor" className="w-3.5 h-3.5">
            <path fillRule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clipRule="evenodd" />
          </svg>
          Back to Reports
        </button>

        <div className="max-w-2xl">
          {/* Title */}
          <div className="flex items-center gap-3 mb-1">
            <span className="w-3 h-3 rounded-full flex-shrink-0" style={{ backgroundColor: typeColor }} />
            <h2 className="text-xl font-bold text-white">{report.type}</h2>
            <StatusBadge status={report.status} />
            <div className="ml-auto">
              <button
                onClick={handleArchive}
                disabled={archiving}
                className="flex items-center gap-1.5 text-xs text-red-400 hover:text-red-300 bg-red-900/20 hover:bg-red-900/30 border border-red-400/20 px-3 py-1.5 rounded-xl transition-all disabled:opacity-60"
              >
                {archiving ? (
                  <span className="w-3 h-3 border border-red-400 border-t-transparent rounded-full animate-spin" />
                ) : (
                  <svg viewBox="0 0 20 20" fill="currentColor" className="w-3.5 h-3.5">
                    <path d="M4 3a2 2 0 100 4h12a2 2 0 100-4H4z" />
                    <path fillRule="evenodd" d="M3 8h14v7a2 2 0 01-2 2H5a2 2 0 01-2-2V8zm5 3a1 1 0 011-1h2a1 1 0 110 2H9a1 1 0 01-1-1z" clipRule="evenodd" />
                  </svg>
                )}
                {archiving ? 'Archiving…' : 'Archive Report'}
              </button>
            </div>
          </div>
          <p className="text-xs text-gray-500 font-mono mb-5">
            ID: {report.id} · Reported {report.createdAt?.toDate?.().toLocaleDateString('en-PH', {
              month: 'long', day: 'numeric', year: 'numeric'
            }) || '—'}
          </p>

          {/* Photo */}
          {report.photoUrl ? (
            <div className="mb-5 rounded-xl overflow-hidden border border-navy-elevated">
              <img src={report.photoUrl} alt="Report photo" className="w-full max-h-72 object-cover" />
            </div>
          ) : (
            <div className="mb-5 rounded-xl border border-navy-elevated bg-navy-surface h-40 flex items-center justify-center">
              <p className="text-xs text-gray-600">No photo attached</p>
            </div>
          )}

          {/* Details */}
          <div className="bg-navy-surface rounded-xl p-5 mb-4 border border-navy-elevated">
            <p className="text-[11px] text-gray-500 font-mono mb-3 tracking-wider">REPORT DETAILS</p>
            <div className="grid grid-cols-2 gap-x-6 gap-y-3 mb-4">
              <div>
                <p className="text-[11px] text-gray-500 mb-0.5">Location</p>
                <p className="text-sm text-white">{report.location?.address || '—'}</p>
              </div>
              <div>
                <p className="text-[11px] text-gray-500 mb-0.5">Coordinates</p>
                <p className="text-xs font-mono text-gray-400">
                  {report.location?.lat?.toFixed(5)}, {report.location?.lng?.toFixed(5)}
                </p>
              </div>
              <div>
                <p className="text-[11px] text-gray-500 mb-0.5">Current Priority</p>
                <PriorityBadge priority={report.priority || 'low'} />
              </div>
              <div>
                <p className="text-[11px] text-gray-500 mb-0.5">Reporter</p>
                <p className="text-xs text-gray-400 font-mono">{report.userId?.slice(0, 12) || '—'}…</p>
              </div>
            </div>
            <div className="border-t border-navy-elevated pt-4">
              <p className="text-[11px] text-gray-500 mb-1.5">Description</p>
              <p className="text-sm text-gray-300 leading-relaxed">
                {report.description || 'No description provided.'}
              </p>
            </div>
            {report.adminRemark && (
              <div className="border-t border-navy-elevated mt-4 pt-4">
                <p className="text-[11px] text-gray-500 mb-1.5">Previous Admin Remark</p>
                <p className="text-sm text-gray-400 leading-relaxed italic">"{report.adminRemark}"</p>
              </div>
            )}
          </div>

          {/* Admin Actions */}
          <div className="bg-navy-surface rounded-xl p-5 border border-navy-elevated">
            <p className="text-[11px] text-gray-500 font-mono mb-4 tracking-wider">ADMIN ACTIONS</p>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <label className="text-[11px] text-gray-400 mb-1.5 block">Update Status</label>
                <select
                  value={status}
                  onChange={e => setStatus(e.target.value)}
                  className="w-full bg-navy-elevated text-sm text-white rounded-xl px-3 py-2.5 border border-navy-elevated focus:border-amber/40 outline-none cursor-pointer"
                >
                  <option value="pending">Pending</option>
                  <option value="verified">Verified</option>
                  <option value="in_progress">In Progress</option>
                  <option value="resolved">Resolved</option>
                </select>
              </div>
              <div>
                <label className="text-[11px] text-gray-400 mb-1.5 block">Set Priority</label>
                <select
                  value={priority}
                  onChange={e => setPriority(e.target.value)}
                  className="w-full bg-navy-elevated text-sm text-white rounded-xl px-3 py-2.5 border border-navy-elevated focus:border-amber/40 outline-none cursor-pointer"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                </select>
              </div>
            </div>
            <div className="mb-4">
              <label className="text-[11px] text-gray-400 mb-1.5 block">Admin Remark</label>
              <textarea
                value={remark}
                onChange={e => setRemark(e.target.value)}
                rows={3}
                placeholder="Notes or action taken..."
                className="w-full bg-navy-elevated text-sm text-white rounded-xl px-4 py-3 border border-navy-elevated focus:border-amber/40 outline-none resize-none placeholder:text-gray-600"
              />
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={handleSave}
                disabled={saving}
                className="bg-amber text-navy-deep font-bold px-6 py-2.5 rounded-xl text-sm hover:opacity-90 active:scale-[0.98] transition-all disabled:opacity-60 flex items-center gap-2"
              >
                {saving && <span className="w-3.5 h-3.5 border-2 border-navy-deep border-t-transparent rounded-full animate-spin" />}
                {saving ? 'Saving…' : 'Save Changes'}
              </button>
              {saved && (
                <span className="text-green-400 text-xs flex items-center gap-1.5">
                  <svg viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  Changes saved
                </span>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}