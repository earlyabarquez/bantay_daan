export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        navy: {
          deep:     '#0D1B2A',
          surface:  '#152535',
          elevated: '#1E3448',
        },
        amber: {
          DEFAULT: '#F4A261',
          muted:   '#2a2010',
        },
      },
      fontFamily: {
        sans: ['DM Sans', 'sans-serif'],
        mono: ['Space Mono', 'monospace'],
      },
    },
  },
  plugins: [],
}
