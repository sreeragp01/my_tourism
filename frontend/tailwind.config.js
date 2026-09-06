/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        forest: {
          DEFAULT: '#144032',
          dark: '#0F2823',
          light: '#1A5340',
          50: '#E7EFEA',
          100: '#C5D8CD',
          200: '#9FBFA9',
          300: '#75A584',
          400: '#4D8A61',
          500: '#144032',
          600: '#10352A',
          700: '#0C2B22',
          800: '#09211A',
          900: '#051611',
        },
        terracotta: {
          DEFAULT: '#C35B3A',
          dark: '#A84B2E',
          light: '#D97250',
          50: '#FAF0ED',
          100: '#F2D9D1',
          200: '#E6B9AC',
          300: '#D99885',
          400: '#CE785F',
          500: '#C35B3A',
        },
        gold: {
          DEFAULT: '#D4AF37',
          dark: '#B99A62',
          light: '#E5C65C',
          50: '#FAF7EE',
          100: '#F3ECD2',
          500: '#D4AF37',
        },
        sage: {
          DEFAULT: '#6A8F71',
          light: '#8CAE92',
          dark: '#4D7054',
        },
        sand: {
          DEFAULT: '#F3E8D2',
          light: '#FAF5EA',
          dark: '#E2D3B8',
        },
        coconut: '#F7F3E8',
        charcoal: {
          DEFAULT: '#1C231E',
          light: '#2E3831',
        },
        deepbrown: '#382F26',
      },
      fontFamily: {
        serif: ['"Playfair Display"', 'Georgia', 'serif'],
        sans: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', 'sans-serif'],
        cinzel: ['"Cinzel"', 'serif'],
      },
      boxShadow: {
        'glass': '0 8px 32px 0 rgba(20, 64, 50, 0.12)',
        'glass-dark': '0 8px 32px 0 rgba(15, 40, 35, 0.37)',
        'earth': '0 10px 25px -5px rgba(195, 91, 58, 0.15)',
        'gold': '0 10px 25px -5px rgba(212, 175, 55, 0.25)',
      },
      backdropBlur: {
        'xs': '2px',
      }
    },
  },
  plugins: [],
}
