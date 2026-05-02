import type { Config } from "@react-router/dev/config";

export default {
  ssr: false, // Required for GitHub Pages (SPA Mode)
  basename: "/mokm-effector/", // Tells the router where it lives

  // Only change appDirectory if your source code is actually inside a folder with this name
  // If your code is in web/app, use "app"
  appDirectory: "app",
} satisfies Config;
