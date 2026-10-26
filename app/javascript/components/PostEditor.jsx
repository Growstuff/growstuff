import React, {useState} from 'react';
import {EditorContent, useEditor, useEditorState} from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import {Markdown} from '@tiptap/markdown';

const BLOCKS = [
  {value: 'paragraph', label: 'Paragraph'},
  {value: 'h2', label: 'Heading'},
  {value: 'h3', label: 'Subheading'},
];

function ToolButton({label, active, onClick, children, ...rest}) {
  return (
    <button
      type="button"
      className={`btn btn-sm btn-outline-secondary post-editor-tool${active ? ' active' : ''}`}
      aria-label={label}
      aria-pressed={active}
      onClick={onClick}
      {...rest}
    >
      {children}
    </button>
  );
}

function Toolbar({editor}) {
  const state = useEditorState({
    editor,
    selector: ({editor: e}) => ({
      block: e.isActive('heading', {level: 2}) ? 'h2' : e.isActive('heading', {level: 3}) ? 'h3' : 'paragraph',
      bold: e.isActive('bold'),
      italic: e.isActive('italic'),
      link: e.isActive('link'),
      bulletList: e.isActive('bulletList'),
      blockquote: e.isActive('blockquote'),
    }),
  });

  const setBlock = (value) => {
    const chain = editor.chain().focus();
    if (value === 'paragraph') chain.setParagraph().run();
    else chain.toggleHeading({level: Number(value[1])}).run();
  };

  const setLink = () => {
    const previous = editor.getAttributes('link').href || '';
    const url = window.prompt('Link address', previous);
    if (url === null) return;
    if (url === '') editor.chain().focus().extendMarkRange('link').unsetLink().run();
    else editor.chain().focus().extendMarkRange('link').setLink({href: url}).run();
  };

  return (
    <div className="post-editor-toolbar" role="toolbar" aria-label="Formatting">
      <select
        className="form-select form-select-sm post-editor-block"
        aria-label="Text style"
        value={state.block}
        onChange={(e) => setBlock(e.target.value)}
      >
        {BLOCKS.map((b) => <option key={b.value} value={b.value}>{b.label}</option>)}
      </select>
      <ToolButton label="Bold" active={state.bold} onClick={() => editor.chain().focus().toggleBold().run()}>
        <strong>B</strong>
      </ToolButton>
      <ToolButton label="Italic" active={state.italic} onClick={() => editor.chain().focus().toggleItalic().run()}>
        <em>I</em>
      </ToolButton>
      <ToolButton label="Link" active={state.link} onClick={setLink}>Link</ToolButton>
      <ToolButton
        label="Bulleted list"
        active={state.bulletList}
        onClick={() => editor.chain().focus().toggleBulletList().run()}
      >
        • List
      </ToolButton>
      <ToolButton
        label="Quote"
        active={state.blockquote}
        onClick={() => editor.chain().focus().toggleBlockquote().run()}
      >
        ❝ Quote
      </ToolButton>
    </div>
  );
}

// A rich text editor for a post body that stores markdown, so people can
// format without knowing it. The Markdown tab shows and edits the raw text.
// The markdown goes in a hidden field called `name`, so the surrounding form
// submits it as it would a textarea.
export default function PostEditor({name, value = '', id = 'post_body'}) {
  const [markdown, setMarkdown] = useState(value);
  const [tab, setTab] = useState('write');

  const editor = useEditor({
    extensions: [StarterKit, Markdown],
    content: value,
    contentType: 'markdown',
    onUpdate: ({editor: e}) => setMarkdown(e.getMarkdown().trim()),
    editorProps: {attributes: {class: 'post-editor-content', 'aria-label': 'Post body', role: 'textbox', 'aria-multiline': 'true'}},
  });

  const showTab = (next) => {
    if (next === 'write' && editor) {
      editor.commands.setContent(markdown, {contentType: 'markdown'});
    }
    setTab(next);
  };

  return (
    <div className="post-editor">
      <input type="hidden" name={name} value={markdown} />
      <div className="post-editor-tabs" role="tablist">
        {[['write', 'Write'], ['markdown', 'Markdown']].map(([key, label]) => (
          <button
            key={key}
            type="button"
            role="tab"
            aria-selected={tab === key}
            className={`post-editor-tab${tab === key ? ' active' : ''}`}
            onClick={() => showTab(key)}
          >
            {label}
          </button>
        ))}
      </div>
      <div className="post-editor-panel">
        {tab === 'write' && editor && (
          <>
            <Toolbar editor={editor} />
            <EditorContent editor={editor} id={id} />
          </>
        )}
        {tab === 'markdown' && (
          <textarea
            id={id}
            className="form-control post-editor-raw"
            rows={14}
            aria-label="Post body as markdown"
            value={markdown}
            onChange={(e) => setMarkdown(e.target.value)}
          />
        )}
      </div>
    </div>
  );
}
