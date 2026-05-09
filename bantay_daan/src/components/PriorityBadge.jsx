const COLORS = {
  high:   'bg-red-900/30 text-red-400 border-red-400/40',
  medium: 'bg-orange-900/30 text-orange-400 border-orange-400/40',
  low:    'bg-gray-900/30 text-gray-400 border-gray-400/40',
};

export default function PriorityBadge({ priority }) {
  return (
    <span className={`text-xs font-semibold px-2.5 py-1 rounded-full border ${COLORS[priority] || COLORS.low}`}>
      {priority ? priority.charAt(0).toUpperCase() + priority.slice(1) : 'Low'}
    </span>
  );
}
