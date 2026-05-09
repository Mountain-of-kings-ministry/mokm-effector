import { useState, useEffect } from "react";
import { useParams, Link } from "react-router";
import MarkdownRenderer from "../components/MarkdownRenderer";

// Import all markdown files as raw strings
const markdownFiles = import.meta.glob("../docs/**/*.md", {
  as: "raw",
  eager: true,
});

const DocsPage = () => {
  const { "*": slug } = useParams(); // Catch all route
  const [content, setContent] = useState("");
  const [loading, setLoading] = useState(true);

  const currentPath = slug ? `../docs/${slug}.md` : "../docs/introduction.md";

  useEffect(() => {
    setLoading(true);

    if (markdownFiles[currentPath]) {
      setContent(markdownFiles[currentPath]);
    } else {
      setContent("# 404 - Document Not Found");
    }

    setLoading(false);
  }, [slug]);

  // Generate sidebar navigation
  const sidebarItems = Object.keys(markdownFiles).map((path) => {
    const name = path.replace("../docs/", "").replace(".md", "");
    const title = name
      .split("/")
      .pop()
      .replace(/-/g, " ")
      .replace(/\b\w/g, (c) => c.toUpperCase());
    return { path: name, title };
  });

  return (
    <div className="flex min-h-screen bg-gray-50 dark:bg-gray-950">
      {/* Sidebar */}
      <div className="w-72 border-r border-gray-200 dark:border-gray-800 p-6 overflow-auto">
        <h2 className="text-xl font-bold mb-6">Documentation</h2>
        <nav className="space-y-1">
          {sidebarItems.map((item) => (
            <Link
              key={item.path}
              to={`/docs/${item.path}`}
              className={`block px-4 py-2 rounded-lg transition-colors ${
                slug === item.path
                  ? "bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 font-medium"
                  : "hover:bg-gray-100 dark:hover:bg-gray-800"
              }`}
            >
              {item.title}
            </Link>
          ))}
        </nav>
      </div>

      {/* Content */}
      <div className="flex-1 p-10 max-w-4xl">
        {loading ? <p>Loading...</p> : <MarkdownRenderer content={content} />}
      </div>
    </div>
  );
};

export default DocsPage;
