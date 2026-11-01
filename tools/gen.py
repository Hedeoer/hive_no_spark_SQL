#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 SQLPractise/*.sql 与两份 md 的独有题目，组装成 SQL练习总集.md。

原则：
  1. SQL 正文从源文件按行区间**原样抽取**，绝不手抄、绝不改写（Q8 选 a）。
  2. 只剥掉文件顶部的 `/* ... */` 题干块（已转写成结构化题面），其余一律保留。
  3. 首个 WITH/SELECT 之前的建表/造数语句，若超过 20 行则折叠进 <details>。
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from items import ITEMS, CATS

STATEMENT = re.compile(r'^\s*(WITH|SELECT)\b', re.I)


def read_lines(rel, start=None, end=None):
    path = os.path.join(ROOT, rel)
    lines = open(path, encoding='utf-8', errors='replace').read().split('\n')
    if start is not None:
        lines = lines[start - 1:end]
    return lines


def strip_header(lines):
    """剥掉顶部连续的 /* ... */ 题干块（可多个），保留其余内容。"""
    i = 0
    n = len(lines)
    while i < n and not lines[i].strip():
        i += 1
    while i < n and lines[i].lstrip().startswith('/*'):
        while i < n and '*/' not in lines[i]:
            i += 1
        i += 1
        j = i
        while j < n and not lines[j].strip():
            j += 1
        if j < n and lines[j].lstrip().startswith('/*'):
            i = j
        else:
            break
    return lines[i:]


def split_scaffold(lines):
    """把首个 WITH/SELECT 之前的建表/造数语句切出来（按括号深度与语句边界判断）。"""
    depth, in_stmt = 0, False
    for idx, ln in enumerate(lines):
        s = ln.strip()
        if not s or s.startswith('--') or s.startswith('/*') or s.startswith('*'):
            continue
        if not in_stmt and STATEMENT.match(ln):
            return (lines[:idx] if idx else None), lines[idx:]
        if re.match(r'^(CREATE|INSERT|DROP|USE|SET|TRUNCATE|ALTER)\b', s, re.I):
            in_stmt = True
        if not in_stmt:
            return None, lines
        depth += s.count('(') - s.count(')')
        if depth <= 0 and s.endswith(';'):
            depth, in_stmt = 0, False
    return None, lines


def dedent_block(text):
    lines = [l.rstrip() for l in text.strip('\n').split('\n')]
    widths = [len(l) - len(l.lstrip()) for l in lines if l.strip()]
    m = min(widths) if widths else 0
    return '\n'.join(l[m:] if l.strip() else '' for l in lines)


def sql_block(lines):
    body = '\n'.join(lines)
    scaffold, rest = split_scaffold(lines)
    out = []
    if scaffold and len(scaffold) > 20:
        out.append('<details>\n<summary>建表与造数语句（原文照录，点击展开）</summary>\n')
        out.append('```sql\n' + dedent_block('\n'.join(scaffold)) + '\n```\n')
        out.append('</details>\n')
    elif scaffold:
        rest = lines          # 短头块不折叠，整体给出
    out.append('```sql\n' + dedent_block('\n'.join(rest)) + '\n```')
    return '\n'.join(out)


def read_md_section(rel, needle):
    """从 md 的小节里取出第一个围栏代码块的内容。"""
    path = os.path.join(ROOT, rel)
    lines = open(path, encoding='utf-8', errors='replace').read().split('\n')
    start = None
    for i, ln in enumerate(lines):
        if ln.startswith('## ') and needle.replace(' ', '') in ln.replace(' ', ''):
            start = i + 1
            break
    if start is None:
        raise SystemExit('md 小节未找到：%s -> %s' % (rel, needle))
    body, infence = [], False
    for ln in lines[start:]:
        if ln.startswith('## '):
            break
        s = ln.strip()
        if s.startswith('```'):
            if infence:
                break
            infence = True
            continue
        if infence:
            body.append(ln)
    return body


def resolve(src):
    """返回 (定位说明, 原始行列表)。"""
    if isinstance(src, tuple) and src[0] == 'MD':
        _, rel, needle = src
        return '`%s` §%s' % (rel, needle), read_md_section(rel, needle)
    if isinstance(src, tuple):
        rel, a, b = src
        return '`%s` L%d–L%d' % (rel, a, b), read_lines(rel, a, b)
    return '`%s`' % src, read_lines(src)


def render(item):
    iid, cat, title, src, point, io = item[:6]
    extra = item[6] if len(item) > 6 else None
    loc, lines = resolve(src)
    lines = strip_header(lines)
    buf = ['### %s · %s\n' % (iid, title)]
    buf.append('**源**：%s\n' % loc)
    buf.append('**考点**：%s\n' % point)
    buf.append('**输入 → 输出**：%s\n' % io)
    if extra:
        buf.append('%s\n' % extra)
    buf.append(sql_block(lines))
    out = '\n'.join(buf)
    for pid, vtitle, vsrc, vnote in VARIANTS:
        if pid != iid:
            continue
        vloc, vlines = resolve(vsrc)
        out += '\n\n#### %s\n\n**源**：%s\n\n**差异**：%s\n\n%s\n' % (
            vtitle, vloc, vnote, sql_block(strip_header(vlines)))
    return out


def main():
    order = [c[0] for c in CATS]
    parts = []
    parts.append(HEADER)
    for code, name, desc in CATS:
        rows = [it for it in ITEMS if it[1] == code]
        parts.append('\n---\n\n## %s · %s（%d 题）\n\n%s\n' % (code, name, len(rows), desc))
        for it in rows:
            parts.append('\n' + render(it) + '\n')
    parts.append(render_md_only())
    parts.append(render_appendix())
    doc = ''.join(parts)
    out = os.path.join(ROOT, 'SQL练习总集.md')
    open(out, 'w', encoding='utf-8').write(doc)
    n_rows = len(ITEMS)
    print('写入 %s：%d 条目，%d 字节' % (out, n_rows, len(doc.encode('utf-8'))))


from strings import HEADER, render_md_only, render_appendix, VARIANTS

if __name__ == '__main__':
    main()
