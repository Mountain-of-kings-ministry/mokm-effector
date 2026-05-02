// import { reactRouter } from "@react-router/dev/vite";
// import tailwindcss from "@tailwindcss/vite";
// import { defineConfig } from "vite";

// export default defineConfig({
//   plugins: [tailwindcss(), reactRouter()],
//   resolve: {
//     tsconfigPaths: true,
//   },
// });

import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
  // This is the CRITICAL fix for Asset 404s
  base: "/mokm-effector/",

  plugins: [tailwindcss(), reactRouter()],
  resolve: {
    tsconfigPaths: true,
  },
});
