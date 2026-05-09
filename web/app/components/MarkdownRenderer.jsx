import React from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import rehypeRaw from 'rehype-raw';

const MarkdownRenderer = ({ content }) => {
  return (
    <div className="prose prose-neutral dark:prose-invert max-w-none 
                    prose-headings:font-semibold 
                    prose-a:text-blue-600 hover:prose-a:underline
                    prose-code:bg-gray-100 dark:prose-code:bg-gray-800
                    prose-pre:bg-gray-900">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeRaw]}
        components={{
          // You can customize any tag
          h1: ({ node, ...props }) => <h1 className="text-4xl font-bold mt-8 mb-4" {...props} />,
          h2: ({ node, ...props }) => <h2 className="text-3xl font-semibold mt-10 mb-3" {...props} />,
          a: ({ node, ...props }) => <a className="text-blue-600 hover:underline" {...props} />,
          code: ({ node, inline, ...props }) => 
            inline ? 
              <code className="bg-gray-200 dark:bg-gray-800 px-1.5 py-0.5 rounded" {...props} /> :
              <code {...props} />
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
};

export default MarkdownRenderer;