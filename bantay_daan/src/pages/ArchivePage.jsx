import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy, doc, getDoc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../components/Sidebar';
import StatusBadge from '../components/StatusBadge';

const TYPE_COLORS = {
  'Pothole':        '#F4A261',
  'Flooding':       '#61B4F4',
  'Obstruction':    '#F46161',
  'Road Damage':    '#F4844A',
  'Accident':       '#D94F4F',
  'Missing Signage':'#9B8CF4',
};

export default function ArchivePage() {
  const [archived, setArchived] = useState([]);
  const [search, setSearch]     = useState('');
  const [restoring, setRestoring] = useState(null);
  const [deleting, setDeleting]   = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const q = query(collection(db, 'archived_reports'), orderBy('archivedAt', 'desc'));
    const unsub = onSnapshot(q, snap => {
      setArchived(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    return unsub;
  }, []);

  const handleRestore = async (reportId) => {
    if (!window.confirm('Restore this report back to active reports?')) return;
    setRestoring(reportId);
    try {
      const ref = doc(db, 'archived_reports', reportId);
      const snap = await getDoc(ref);
      if (!snap.exists()) return;
      const data = snap.data();
      delete data.archivedAt;
      await setDoc(doc(db, 'reports', reportId), {
        ...data,
        updatedAt: serverTimestamp(),
      });
      await deleteDoc(ref);
    } catch (err) {
      console.error('Restore error:', err);
    } finally {
      setRestoring(null);
    }
  };

  const handleDelete = async (reportId) => {
    if (!window.confirm('Permanently delete this report? This cannot be undone.')) return;
    setDeleting(reportId);
    try {
      await deleteDoc(doc(db, 'archived_reports', reportId));
    } catch (err) {
      console.error('Delete error:', err);
    } finally {
      setDeleting(null);
    }
  };

  const filtered = archived.filter(r => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      (r.type || '').toLowerCase().includes(q) ||
      (r.location?.address || '').toLowerCase().includes(q) ||
      r.id.toLowerCase().includes(q)
    );
  });

  return (
    <div className="flex min-h-screen bg-navy-deep">
      <Sidebar active="archive" />

      <main className="flex-1 p-6 overflow-auto">
        {/* Header */}
        <div className="mb-5 flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <button
                onClick={() => navigate('/reports')}
                className="text-gray-500 hover:text-amber transition-colors"
              >
                <svg viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
                  <path fillRule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clipRule="evenodd" />
                </svg>
              </button>
              <h2 className="text-xl font-bold text-white">Archive</h2>
            </div>
            <p className="text-sm text-gray-400">{archived.length} archived report{archived.length !== 1 ? 's' : ''}</p>
          </div>
        </div>

        {/* Search */}
        <div className="mb-5">
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search archived reports..."
            className="bg-navy-surface text-sm text-white rounded-xl px-4 py-2 border border-navy-elevated focus:border-amber/40 outline-none placeholder:text-gray-600 w-full max-w-sm"
          />
        </div>

        {/* Table */}
        <div className="bg-navy-surface rounded-xl overflow-hidden border border-navy-elevated">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-navy-elevated text-[11px] text-gray-500 font-mono">
                {['ID', 'Type', 'Location', 'Archived On', 'Status', ''].map(h => (
                  <th key={h} className="text-left px-4 py-3 font-medium">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-sm text-gray-500">
                    {search ? 'No archived reports match your search' : 'No archived reports yet'}
                  </td>
                </tr>
              ) : filtered.map(r => (
                <tr key={r.id} className="border-b border-navy-elevated last:border-0 group hover:bg-navy-elevated transition-colors">
                  <td className="px-4 py-3 font-mono text-[11px] text-gray-500">{r.id.slice(0, 8)}…</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <span
                        className="w-2 h-2 rounded-full flex-shrink-0"
                        style={{ backgroundColor: TYPE_COLORS[r.type] || '#F0F4F8' }}
                      />
                      <span className="text-xs text-white">{r.type}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-400 max-w-[180px] truncate">
                    {r.location?.address || '—'}
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500 font-mono whitespace-nowrap">
                    {r.archivedAt?.toDate?.().toLocaleDateString('en-PH', {
                      month: 'short', day: 'numeric', year: 'numeric'
                    }) || '—'}
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={r.status} />
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      {/* Restore */}
                      <button
                        onClick={() => handleRestore(r.id)}
                        disabled={restoring === r.id}
                        className="flex items-center gap-1 text-xs text-green-400 hover:text-green-300 bg-green-900/20 hover:bg-green-900/30 border border-green-400/20 px-2.5 py-1 rounded-lg transition-all disabled:opacity-60"
                      >
                        {restoring === r.id ? (
                          <span className="w-3 h-3 border border-green-400 border-t-transparent rounded-full animate-spin" />
                        ) : (
                          <svg viewBox="0 0 20 20" fill="currentColor" className="w-3 h-3">
                            <path fillRule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clipRule="evenodd" />
                          </svg>
                        )}
                        Restore
                      </button>

                      {/* Permanently Delete */}
                      <button
                        onClick={() => handleDelete(r.id)}
                        disabled={deleting === r.id}
                        className="flex items-center gap-1 text-xs text-red-400 hover:text-red-300 bg-red-900/20 hover:bg-red-900/30 border border-red-400/20 px-2.5 py-1 rounded-lg transition-all disabled:opacity-60"
                      >
                        {deleting === r.id ? (
                          <span className="w-3 h-3 border border-red-400 border-t-transparent rounded-full animate-spin" />
                        ) : (
                          <svg viewBox="0 0 20 20" fill="currentColor" className="w-3 h-3">
                            <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                          </svg>
                        )}
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}