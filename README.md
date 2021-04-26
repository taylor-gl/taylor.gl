# Taylor G. Lunt's Blog

[My blog](http://taylor.gl) is a Phoenix application, which uses `postcss-loader` and `tailwindcss` for styling, as per [this guide](https://pragmaticstudio.com/tutorials/adding-tailwind-css-to-phoenix).

Since `tailwindcss` generates thousands of CSS classes, most of which are unused by this project, we automatically purge the unneeded classes when we are running in production (but not in development).
