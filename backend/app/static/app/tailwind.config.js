/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      borderRadius: {
        xl: '12px',
      },
      boxShadow: {
        subtle: '0 1px 2px 0 rgba(0,0,0,0.04)'
      },
    },
  },
  plugins: [],
}

