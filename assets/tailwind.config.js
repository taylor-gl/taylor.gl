module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
    fontFamily: {
      sans: ["Montserrat", "sans-serif"],
      serif: ["Alegreya", "serif"],
    },
  },
  variants: {
    extend: {
      visibility: ['hover', 'focus', 'group-hover', 'group-focus'],
    },
  },
  plugins: [],
}
