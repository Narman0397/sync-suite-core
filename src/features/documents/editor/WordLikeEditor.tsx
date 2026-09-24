// Word-like WYSIWYG editor (TipTap) for bukti/document templates.
// Outputs HTML compatible with the existing PDF renderer (parseHtmlToBlocks)
// and shadcn styling. Supports slash-command placeholder insertion.
import { useEditor, EditorContent, ReactRenderer, type Editor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Underline from "@tiptap/extension-underline";
import TextAlign from "@tiptap/extension-text-align";
import Link from "@tiptap/extension-link";
import Image from "@tiptap/extension-image";
import { Table } from "@tiptap/extension-table";
import { TableRow } from "@tiptap/extension-table-row";
import { TableCell } from "@tiptap/extension-table-cell";
import { TableHeader } from "@tiptap/extension-table-header";
import { Placeholder } from "@tiptap/extension-placeholder";
import { TextStyle } from "@tiptap/extension-text-style";
import { Color } from "@tiptap/extension-color";
import FontFamily from "@tiptap/extension-font-family";
import Suggestion from "@tiptap/suggestion";
import { Extension } from "@tiptap/core";
import tippy, { type Instance as TippyInstance } from "tippy.js";
import {
  Bold, Italic, Underline as UnderlineIcon, Strikethrough,
  AlignLeft, AlignCenter, AlignRight, AlignJustify,
  List, ListOrdered, Quote, Undo2, Redo2, Heading1, Heading2, Heading3,
  Table as TableIcon, Link2, Image as ImageIcon, Minus, Pilcrow,
} from "lucide-react";
import { forwardRef, useEffect, useImperativeHandle, useState, useRef } from "react";
import "tippy.js/dist/tippy.css";

export type PlaceholderItem = { key: string; desc: string };

export type WordLikeEditorHandle = {
  getHTML: () => string;
  setHTML: (html: string) => void;
  insertPlaceholder: (token: string) => void;
  focus: () => void;
};

type Props = {
  initialHTML: string;
  onChange?: (html: string) => void;
  placeholders?: PlaceholderItem[];
};

/* Slash-command extension for placeholder insertion. */
type SlashItem = { key: string; desc: string };

const SlashList = ({
  items, command,
}: { items: SlashItem[]; command: (item: SlashItem) => void }) => {
  const [selected, setSelected] = useState(0);
  useEffect(() => setSelected(0), [items]);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "ArrowDown") {
        setSelected((s) => (s + 1) % Math.max(items.length, 1));
        e.preventDefault();
      } else if (e.key === "ArrowUp") {
        setSelected((s) => (s - 1 + items.length) % Math.max(items.length, 1));
        e.preventDefault();
      } else if (e.key === "Enter") {
        if (items[selected]) command(items[selected]);
        e.preventDefault();
      }
    };
    window.addEventListener("keydown", onKey, true);
    return () => window.removeEventListener("keydown", onKey, true);
  }, [items, selected, command]);
  return (
    <div className="max-h-64 w-72 overflow-y-auto rounded-md border border-border bg-popover p-1 text-xs shadow-lg">
      {items.length === 0 && (
        <div className="p-2 text-muted-foreground">Tidak ada placeholder</div>
      )}
      {items.map((it, i) => (
        <button
          key={it.key}
          onClick={() => command(it)}
          className={`block w-full rounded px-2 py-1.5 text-left ${
            i === selected ? "bg-primary text-primary-foreground" : "hover:bg-muted"
          }`}
        >
          <div className="font-mono">{it.key}</div>
          <div className={`text-[10px] ${i === selected ? "opacity-80" : "text-muted-foreground"}`}>
            {it.desc}
          </div>
        </button>
      ))}
    </div>
  );
};

function buildSlashExt(placeholders: PlaceholderItem[]) {
  return Extension.create({
    name: "slashPlaceholders",
    addProseMirrorPlugins() {
      return [
        Suggestion({
          editor: this.editor,
          char: "/",
          startOfLine: false,
          items: ({ query }: { query: string }) => {
            const q = query.toLowerCase();
            return placeholders
              .filter((p) =>
                p.key.toLowerCase().includes(q) || p.desc.toLowerCase().includes(q),
              )
              .slice(0, 20);
          },
          command: ({ editor, range, props }: { editor: Editor; range: { from: number; to: number }; props: PlaceholderItem }) => {
            editor.chain().focus().deleteRange(range).insertContent(props.key + " ").run();
          },
          render: () => {
            let component: ReactRenderer | null = null;
            let popup: TippyInstance[] = [];
            return {
              onStart: (props: { editor: Editor; clientRect?: (() => DOMRect | null) | null; items: PlaceholderItem[]; command: (item: PlaceholderItem) => void }) => {
                component = new ReactRenderer(SlashList, {
                  props,
                  editor: props.editor,
                });
                if (!props.clientRect) return;
                popup = tippy("body", {
                  getReferenceClientRect: () => props.clientRect?.() ?? new DOMRect(),
                  appendTo: () => document.body,
                  content: component.element,
                  showOnCreate: true,
                  interactive: true,
                  trigger: "manual",
                  placement: "bottom-start",
                });
              },
              onUpdate: (props: { clientRect?: (() => DOMRect | null) | null }) => {
                component?.updateProps(props);
                popup[0]?.setProps({
                  getReferenceClientRect: () => props.clientRect?.() ?? new DOMRect(),
                });
              },
              onKeyDown: (props: { event: KeyboardEvent }) => {
                if (props.event.key === "Escape") {
                  popup[0]?.hide();
                  return true;
                }
                return false;
              },
              onExit: () => {
                popup[0]?.destroy();
                component?.destroy();
              },
            };
          },
        }),
      ];
    },
  });
}

const ToolbarBtn = ({
  onClick, active, disabled, title, children,
}: {
  onClick: () => void; active?: boolean; disabled?: boolean;
  title: string; children: React.ReactNode;
}) => (
  <button
    type="button"
    onClick={onClick}
    disabled={disabled}
    title={title}
    className={`inline-flex h-8 w-8 items-center justify-center rounded border border-transparent hover:bg-muted disabled:opacity-40 ${
      active ? "bg-primary text-primary-foreground" : "text-foreground"
    }`}
  >
    {children}
  </button>
);

export const WordLikeEditor = forwardRef<WordLikeEditorHandle, Props>(
  ({ initialHTML, onChange, placeholders = [] }, ref) => {
    const changeRef = useRef(onChange);
    changeRef.current = onChange;

    const editor = useEditor({
      extensions: [
        StarterKit.configure({ heading: { levels: [1, 2, 3] } }),
        Underline,
        TextStyle,
        Color,
        FontFamily.configure({ types: ["textStyle"] }),
        TextAlign.configure({ types: ["heading", "paragraph"] }),
        Link.configure({ openOnClick: false }),
        Image,
        Table.configure({ resizable: true }),
        TableRow,
        TableHeader,
        TableCell,
        Placeholder.configure({ placeholder: "Ketik konten, atau '/' untuk sisipkan placeholder…" }),
        buildSlashExt(placeholders),
      ],
      content: initialHTML || "<p></p>",
      immediatelyRender: false,
      onUpdate: ({ editor }) => changeRef.current?.(editor.getHTML()),
      editorProps: {
        attributes: {
          class:
            "tiptap prose prose-sm max-w-none min-h-[520px] rounded-md border border-border bg-white text-neutral-900 p-6 focus:outline-none",
        },
      },
    });

    useImperativeHandle(ref, () => ({
      getHTML: () => editor?.getHTML() ?? "",
      setHTML: (html) => editor?.commands.setContent(html || "<p></p>"),
      insertPlaceholder: (token) => {
        editor?.chain().focus().insertContent(token + " ").run();
      },
      focus: () => editor?.commands.focus(),
    }), [editor]);

    if (!editor) {
      return (
        <div className="grid h-[520px] place-items-center rounded-md border border-border text-sm text-muted-foreground">
          Memuat editor…
        </div>
      );
    }

    return (
      <div className="rounded-md border border-border bg-card">
        {/* Toolbar */}
        <div className="flex flex-wrap items-center gap-0.5 border-b border-border bg-muted/40 p-1.5">
          <select
            value={
              editor.isActive("heading", { level: 1 }) ? "h1" :
              editor.isActive("heading", { level: 2 }) ? "h2" :
              editor.isActive("heading", { level: 3 }) ? "h3" : "p"
            }
            onChange={(e) => {
              const v = e.target.value;
              if (v === "p") editor.chain().focus().setParagraph().run();
              else editor.chain().focus().toggleHeading({ level: Number(v.slice(1)) as 1 | 2 | 3 }).run();
            }}
            className="h-8 rounded border border-border bg-background px-2 text-xs"
          >
            <option value="p">Paragraf</option>
            <option value="h1">Judul 1</option>
            <option value="h2">Judul 2</option>
            <option value="h3">Judul 3</option>
          </select>
          <select
            onChange={(e) => {
              if (e.target.value) editor.chain().focus().setFontFamily(e.target.value).run();
              else editor.chain().focus().unsetFontFamily().run();
            }}
            defaultValue=""
            className="h-8 rounded border border-border bg-background px-2 text-xs"
          >
            <option value="">Font default</option>
            <option value="Times New Roman, serif">Times New Roman</option>
            <option value="Arial, sans-serif">Arial</option>
            <option value="Calibri, sans-serif">Calibri</option>
            <option value="Georgia, serif">Georgia</option>
            <option value="Courier New, monospace">Courier New</option>
          </select>
          <span className="mx-1 h-6 w-px bg-border" />
          <ToolbarBtn onClick={() => editor.chain().focus().toggleBold().run()} active={editor.isActive("bold")} title="Bold (Ctrl+B)"><Bold className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().toggleItalic().run()} active={editor.isActive("italic")} title="Italic (Ctrl+I)"><Italic className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().toggleUnderline().run()} active={editor.isActive("underline")} title="Underline (Ctrl+U)"><UnderlineIcon className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().toggleStrike().run()} active={editor.isActive("strike")} title="Coret"><Strikethrough className="h-4 w-4" /></ToolbarBtn>
          <input
            type="color"
            title="Warna teks"
            onChange={(e) => editor.chain().focus().setColor(e.target.value).run()}
            className="h-8 w-8 cursor-pointer rounded border border-border bg-background p-0.5"
          />
          <span className="mx-1 h-6 w-px bg-border" />
          <ToolbarBtn onClick={() => editor.chain().focus().setTextAlign("left").run()} active={editor.isActive({ textAlign: "left" })} title="Rata kiri"><AlignLeft className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().setTextAlign("center").run()} active={editor.isActive({ textAlign: "center" })} title="Rata tengah"><AlignCenter className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().setTextAlign("right").run()} active={editor.isActive({ textAlign: "right" })} title="Rata kanan"><AlignRight className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().setTextAlign("justify").run()} active={editor.isActive({ textAlign: "justify" })} title="Rata kiri-kanan"><AlignJustify className="h-4 w-4" /></ToolbarBtn>
          <span className="mx-1 h-6 w-px bg-border" />
          <ToolbarBtn onClick={() => editor.chain().focus().toggleBulletList().run()} active={editor.isActive("bulletList")} title="List bullet"><List className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().toggleOrderedList().run()} active={editor.isActive("orderedList")} title="List bernomor"><ListOrdered className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().toggleBlockquote().run()} active={editor.isActive("blockquote")} title="Kutipan"><Quote className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().setHorizontalRule().run()} title="Garis horizontal"><Minus className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().setHardBreak().run()} title="Baris baru"><Pilcrow className="h-4 w-4" /></ToolbarBtn>
          <span className="mx-1 h-6 w-px bg-border" />
          <ToolbarBtn
            onClick={() => {
              const url = window.prompt("URL link");
              if (url) editor.chain().focus().setLink({ href: url }).run();
            }}
            active={editor.isActive("link")}
            title="Sisipkan link"
          ><Link2 className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn
            onClick={() => {
              const url = window.prompt("URL gambar");
              if (url) editor.chain().focus().setImage({ src: url }).run();
            }}
            title="Sisipkan gambar"
          ><ImageIcon className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()}
            title="Sisipkan tabel"
          ><TableIcon className="h-4 w-4" /></ToolbarBtn>
          <span className="mx-1 h-6 w-px bg-border" />
          <ToolbarBtn onClick={() => editor.chain().focus().setHeading({ level: 1 }).run()} active={editor.isActive("heading", { level: 1 })} title="H1"><Heading1 className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().setHeading({ level: 2 }).run()} active={editor.isActive("heading", { level: 2 })} title="H2"><Heading2 className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().setHeading({ level: 3 }).run()} active={editor.isActive("heading", { level: 3 })} title="H3"><Heading3 className="h-4 w-4" /></ToolbarBtn>
          <span className="mx-1 h-6 w-px bg-border" />
          <ToolbarBtn onClick={() => editor.chain().focus().undo().run()} disabled={!editor.can().undo()} title="Undo (Ctrl+Z)"><Undo2 className="h-4 w-4" /></ToolbarBtn>
          <ToolbarBtn onClick={() => editor.chain().focus().redo().run()} disabled={!editor.can().redo()} title="Redo (Ctrl+Shift+Z)"><Redo2 className="h-4 w-4" /></ToolbarBtn>
        </div>
        <EditorContent editor={editor} />
      </div>
    );
  },
);
WordLikeEditor.displayName = "WordLikeEditor";
