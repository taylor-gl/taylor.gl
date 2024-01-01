const colors = require('tailwindcss/colors')

module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.heex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      screens: {
        'print': {'raw': 'print'}
      }
    },
    fontFamily: {
      sans: ["Montserrat", "sans-serif"],
      serif: ["Alegreya", "serif"],
    },
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      gray: colors.coolGray,
      black: colors.black,
      white: colors.white,
      blue: colors.cyan,
      red: colors.red,
      yellow: colors.amber,
      green: colors.lime,
      purple: colors.violet
    }
  },
  variants: {
    extend: {
      visibility: ['hover', 'focus', 'group-hover', 'group-focus'],
    },
  },
  plugins: [
    require('@tailwindcss/aspect-ratio')
  ],
}
