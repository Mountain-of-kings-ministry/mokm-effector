import { type RouteConfig, index, route } from "@react-router/dev/routes";

export default [
  index("routes/home.tsx"),
  // Documentation Route

  route("/docs/*", "routes/DocsPage.jsx"),

  // You can also add more routes like this:
  // route("/about", "routes/about.tsx"),
  // route("/contact", "routes/contact.tsx"),
] satisfies RouteConfig;
