#!/usr/bin/env python3
"""Usakame game verification script.

Performs:
1. AST/token-aware Ruby scan for forbidden APIs and unimplemented mrubyedge methods.
2. __END__ section scan for forbidden directives (@MAP/@SFX/@MUSIC) and @SPRITE dimensions.
3. `uk check` (60F) and `uk check -g --frames <N>` (gacha input test).
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

FORBIDDEN_TOPLEVEL_APIS = {
    "play",
    "sleep",
}

FORBIDDEN_METHODS = {
    "sample",
    "shuffle",
    "reverse",
    "delete",
    "key?",
    "include?",
    "fetch",
    "dig",
    "gsub",
    "sub",
    "even?",
    "odd?",
    "upto",
    "downto",
}

SPRITE_HEADER_RE = re.compile(r"^@SPRITE\s+(\S+)\s+(\d+)x(\d+)\b")

OPEN_TO_CLOSE = {"(": ")", "[": "]", "{": "}", "<": ">"}
ASSIGN_OPS = {"=", "+=", "-=", "*=", "/=", "%=", "**=", "||=", "&&=", "&=", "|=", "^="}

# Tokens after which `/` starts a regex literal rather than division.
REGEX_PRECEDERS = {
    "(",
    "[",
    "{",
    ",",
    ";",
    "=>",
    "=",
    "+=",
    "-=",
    "*=",
    "/=",
    "||=",
    "&&=",
    "==",
    "===",
    "!=",
    "=~",
    "!~",
    "<",
    ">",
    "<=",
    ">=",
    "<=>",
    "&&",
    "||",
    "!",
    "~",
    "?",
    ":",
    "..",
    "...",
    "NEWLINE",
}
REGEX_KEYWORDS = {
    "if",
    "elsif",
    "unless",
    "while",
    "until",
    "when",
    "and",
    "or",
    "not",
    "return",
    "yield",
    "then",
    "else",
    "do",
    "begin",
    "ensure",
    "rescue",
    "case",
}

# Tokens that cannot start an argument list in Ruby without parentheses.
NON_ARG_NEXT = {
    "NEWLINE",
    ";",
    ")",
    "[",
    "]",
    "}",
    ",",
    ".",
    "&.",
    "::",
    "=",
    "+=",
    "-=",
    "*=",
    "/=",
    "%=",
    "**=",
    "||=",
    "&&=",
    "==",
    "===",
    "!=",
    "=~",
    "!~",
    "<",
    ">",
    "<=",
    ">=",
    "<=>",
    "+",
    "-",
    "*",
    "/",
    "%",
    "**",
    "&",
    "|",
    "^",
    "&&",
    "||",
    "<<",
    ">>",
    "?",
    ":",
    "=>",
    "..",
    "...",
    "if",
    "unless",
    "while",
    "until",
    "and",
    "or",
    "then",
    "do",
    "end",
    "else",
    "elsif",
    "when",
    "rescue",
    "ensure",
}


@dataclass
class Token:
    kind: str  # IDENT, IVAR, CVAR, GVAR, SYMBOL, STRING, NUMBER, OP, NEWLINE, KEYWORD
    value: str
    line: int
    col: int


class RubyLexer:
    """Lightweight Ruby lexer that handles strings, interpolation, comments, symbols, and % literals."""

    def __init__(self, src: str) -> None:
        self.src = src
        self.n = len(src)
        self.pos = 0
        self.line = 1
        self.col = 1
        self.tokens: list[Token] = []

    def _peek(self, offset: int = 0) -> str:
        idx = self.pos + offset
        return self.src[idx] if 0 <= idx < self.n else ""

    def _advance(self, count: int = 1) -> str:
        chunk = self.src[self.pos : self.pos + count]
        for ch in chunk:
            if ch == "\n":
                self.line += 1
                self.col = 1
            else:
                self.col += 1
        self.pos += count
        return chunk

    def _prev_significant_token(self) -> Token | None:
        return self.tokens[-1] if self.tokens else None

    def _can_start_regex(self) -> bool:
        prev = self._prev_significant_token()
        if prev is None:
            return True
        if prev.kind == "NEWLINE" or prev.value in REGEX_PRECEDERS:
            return True
        if prev.kind == "IDENT" and prev.value in REGEX_KEYWORDS:
            return True
        return False

    def _scan_interpolated_braces(self) -> None:
        """Scan Ruby code inside #{ ... } up to the matching closing brace."""
        depth = 1
        while self.pos < self.n and depth > 0:
            ch = self._peek()
            if ch == "}":
                self._advance()
                depth -= 1
                if depth == 0:
                    self.tokens.append(Token("OP", "}", self.line, self.col))
                    return
            elif ch == "{":
                self.tokens.append(Token("OP", "{", self.line, self.col))
                self._advance()
                depth += 1
            else:
                self._scan_one()

    def _scan_delimited(self, open_ch: str, close_ch: str, allow_interp: bool) -> None:
        nested = open_ch in OPEN_TO_CLOSE
        depth = 1
        while self.pos < self.n:
            ch = self._peek()
            if ch == "\\":
                self._advance(2 if self.pos + 1 < self.n else 1)
                continue
            if allow_interp and ch == "#" and self._peek(1) == "{":
                self.tokens.append(Token("OP", "#{", self.line, self.col))
                self._advance(2)
                self._scan_interpolated_braces()
                continue
            if nested and ch == open_ch:
                depth += 1
                self._advance()
                continue
            if ch == close_ch:
                depth -= 1
                self._advance()
                if depth == 0:
                    return
                continue
            self._advance()

    def _scan_quoted(self, quote: str, allow_interp: bool) -> None:
        start_line, start_col = self.line, self.col
        self._advance()  # opening quote
        self._scan_delimited(quote, quote, allow_interp)
        self.tokens.append(Token("STRING", quote, start_line, start_col))

    def _scan_percent_literal(self) -> bool:
        # Must match %[qQwWiIrx]?<delim>
        if self._peek() != "%":
            return False
        nxt = self._peek(1)
        if not nxt:
            return False
        if nxt in "qQwWiIrx":
            spec = nxt
            delim = self._peek(2)
            if not delim or delim.isalnum() or delim.isspace():
                return False
            start_line, start_col = self.line, self.col
            self._advance(3)
            allow_interp = spec in {"Q", "W", "I", "r", "x"}
            close_ch = OPEN_TO_CLOSE.get(delim, delim)
            self._scan_delimited(delim, close_ch, allow_interp)
            self.tokens.append(Token("STRING", f"%{spec}", start_line, start_col))
            return True
        if not nxt.isalnum() and not nxt.isspace():
            start_line, start_col = self.line, self.col
            self._advance(2)
            close_ch = OPEN_TO_CLOSE.get(nxt, nxt)
            self._scan_delimited(nxt, close_ch, True)
            self.tokens.append(Token("STRING", "%", start_line, start_col))
            return True
        return False

    def _scan_ident(self, start_line: int, start_col: int) -> str:
        start = self.pos
        while self.pos < self.n and (self.src[self.pos].isalnum() or self.src[self.pos] == "_"):
            self._advance()
        if self.pos < self.n and self.src[self.pos] in ("?", "!"):
            # Do not consume `!` if followed by `=` (e.g. `!=`).
            if not (self.src[self.pos] == "!" and self._peek(1) == "="):
                self._advance()
        return self.src[start : self.pos]

    def _scan_one(self) -> None:
        ch = self._peek()

        if ch in (" ", "\t", "\r"):
            self._advance()
            return

        if ch == "\n":
            line, col = self.line, self.col
            self._advance()
            self.tokens.append(Token("NEWLINE", "\n", line, col))
            return

        # Block comment =begin ... =end
        if self.col == 1 and self.src.startswith("=begin", self.pos):
            nxt = self._peek(6)
            if nxt in ("", " ", "\t", "\r", "\n"):
                while self.pos < self.n:
                    if self.col == 1 and self.src.startswith("=end", self.pos):
                        end_nxt = self._peek(4)
                        if end_nxt in ("", " ", "\t", "\r", "\n"):
                            while self.pos < self.n and self._peek() != "\n":
                                self._advance()
                            break
                    self._advance()
                return

        # Line comment
        if ch == "#":
            while self.pos < self.n and self._peek() != "\n":
                self._advance()
            return

        # Strings / backticks
        if ch == '"':
            self._scan_quoted('"', True)
            return
        if ch == "'":
            self._scan_quoted("'", False)
            return
        if ch == "`":
            self._scan_quoted("`", True)
            return

        # % literals (only when not a binary modulo operator after an expression)
        if ch == "%" and self._can_start_regex() and self._scan_percent_literal():
            return

        # Regex literal /.../
        if ch == "/" and self._can_start_regex():
            start_line, start_col = self.line, self.col
            self._advance()
            self._scan_delimited("/", "/", True)
            while self.pos < self.n and self._peek().isalpha():
                self._advance()
            self.tokens.append(Token("STRING", "/", start_line, start_col))
            return

        # Symbols (:foo, :"foo", :'foo') vs ternary `:` vs `::`
        if ch == ":":
            if self._peek(1) == ":":
                self.tokens.append(Token("OP", "::", self.line, self.col))
                self._advance(2)
                return
            nxt = self._peek(1)
            prev = self._prev_significant_token()
            is_ternary_colon = prev is not None and prev.kind in {"IDENT", "NUMBER", "STRING", "SYMBOL", "IVAR", "CVAR", "GVAR"} and prev.value not in REGEX_KEYWORDS
            if not is_ternary_colon and nxt in ('"', "'"):
                start_line, start_col = self.line, self.col
                self._advance()
                self._scan_quoted(nxt, nxt == '"')
                self.tokens[-1] = Token("SYMBOL", self.tokens[-1].value, start_line, start_col)
                return
            if not is_ternary_colon and (nxt.isalpha() or nxt == "_"):
                start_line, start_col = self.line, self.col
                self._advance()
                name = self._scan_ident(start_line, start_col)
                self.tokens.append(Token("SYMBOL", f":{name}", start_line, start_col))
                return
            self.tokens.append(Token("OP", ":", self.line, self.col))
            self._advance()
            return

        # Instance / class / global variables
        if ch == "@":
            start_line, start_col = self.line, self.col
            self._advance()
            if self._peek() == "@":
                self._advance()
                name = self._scan_ident(start_line, start_col)
                self.tokens.append(Token("CVAR", f"@@{name}", start_line, start_col))
            else:
                name = self._scan_ident(start_line, start_col)
                self.tokens.append(Token("IVAR", f"@{name}", start_line, start_col))
            return

        if ch == "$":
            start_line, start_col = self.line, self.col
            self._advance()
            name = self._scan_ident(start_line, start_col)
            self.tokens.append(Token("GVAR", f"${name}", start_line, start_col))
            return

        # Numbers
        if ch.isdigit():
            start_line, start_col = self.line, self.col
            start = self.pos
            while self.pos < self.n and (self.src[self.pos].isalnum() or self.src[self.pos] in "_."):
                if self.src[self.pos] == "." and not self._peek(1).isdigit():
                    break
                self._advance()
            self.tokens.append(Token("NUMBER", self.src[start : self.pos], start_line, start_col))
            return

        # Identifiers & keywords (check for keyword-arg `foo:` suffix)
        if ch.isalpha() or ch == "_":
            start_line, start_col = self.line, self.col
            name = self._scan_ident(start_line, start_col)
            if self._peek() == ":" and self._peek(1) != ":":
                self._advance()
                self.tokens.append(Token("SYMBOL", f"{name}:", start_line, start_col))
            else:
                self.tokens.append(Token("IDENT", name, start_line, start_col))
            return

        # Multi-char operators
        for op in ("<=>", "===", "||=", "&&=", "**=", "...", "&.", "::", "==", "!=", "=~", "!~", "<=", ">=", "=>", "||", "&&", "<<", ">>", "+=", "-=", "*=", "/=", "%=", "**", ".."):
            if self.src.startswith(op, self.pos):
                self.tokens.append(Token("OP", op, self.line, self.col))
                self._advance(len(op))
                return

        # Single-char operators / punctuation
        self.tokens.append(Token("OP", ch, self.line, self.col))
        self._advance()

    def tokenize(self) -> list[Token]:
        while self.pos < self.n:
            self._scan_one()
        return self.tokens


def split_code_and_data(text: str) -> tuple[str, str]:
    lines = text.splitlines(keepends=True)
    for idx, line in enumerate(lines):
        if line.rstrip("\r\n") == "__END__":
            return "".join(lines[:idx]), "".join(lines[idx + 1 :])
    return text, ""


def scan_ruby_code(code: str) -> list[str]:
    errors: list[str] = []
    tokens = RubyLexer(code).tokenize()
    code_lines = code.splitlines()

    def line_preview(line_no: int) -> str:
        if 1 <= line_no <= len(code_lines):
            return code_lines[line_no - 1].strip()
        return ""

    # Track local variable assignments so `map = []` and `map[i]` are allowed.
    local_vars: set[str] = set()

    # Pre-scan simple block params `|a, b|` and method params `def foo(a, b)`.
    for i, tok in enumerate(tokens):
        if tok.kind == "OP" and tok.value == "|":
            # Look ahead for closing `|` on the same line or shortly after.
            j = i + 1
            params: list[str] = []
            valid_block_params = True
            while j < len(tokens) and tokens[j].value != "|":
                t = tokens[j]
                if t.kind == "IDENT":
                    params.append(t.value)
                elif t.value in (",", "*", "&", "=", "NEWLINE"):
                    pass
                else:
                    valid_block_params = False
                    break
                j += 1
            if valid_block_params and j < len(tokens) and tokens[j].value == "|" and params:
                prev = tokens[i - 1] if i > 0 else None
                if prev and prev.value in ("do", "{"):
                    local_vars.update(params)

    i = 0
    while i < len(tokens):
        tok = tokens[i]
        prev_tok = tokens[i - 1] if i > 0 else None
        next_tok = tokens[i + 1] if i + 1 < len(tokens) else None

        # Check Time.now
        if (
            tok.kind == "IDENT"
            and tok.value == "Time"
            and next_tok
            and next_tok.value == "."
            and i + 2 < len(tokens)
            and tokens[i + 2].kind == "IDENT"
            and tokens[i + 2].value == "now"
        ):
            errors.append(f"[FORBIDDEN] line {tok.line}: Time.now in {line_preview(tok.line)}")
            i += 3
            continue

        # Check deprecated integer button IDs in btn(...) / btnp(...): only 1 and 2 are valid integer button IDs
        if (
            tok.kind == "IDENT"
            and tok.value in ("btn", "btnp")
            and not (prev_tok and prev_tok.value in (".", "&.", "::", "def"))
            and next_tok
            and next_tok.value == "("
            and i + 2 < len(tokens)
            and tokens[i + 2].kind == "NUMBER"
            and tokens[i + 2].value not in ("1", "2")
        ):
            errors.append(
                f"[FORBIDDEN] line {tok.line}: {tok.value}({tokens[i + 2].value}) invalid integer button ID (use :left/:right/:up/:down or 1/2) in {line_preview(tok.line)}"
            )
            i += 1
            continue

        # Check method calls: `.sample`, `.shuffle`, etc.
        if tok.kind == "IDENT" and prev_tok and prev_tok.value in (".", "&."):
            if tok.value in FORBIDDEN_METHODS:
                errors.append(f"[FORBIDDEN] line {tok.line}: .{tok.value} in {line_preview(tok.line)}")
            i += 1
            continue

        # Check top-level (receiverless) forbidden APIs
        if tok.kind == "IDENT" and tok.value in FORBIDDEN_TOPLEVEL_APIS:
            # Skip `def map` / `def play` / `::map`
            if prev_tok and prev_tok.value in ("::", "def"):
                i += 1
                continue

            # Local variable assignment: `map = ...`, `map += ...`, `map, x = ...`
            if next_tok and next_tok.value in ASSIGN_OPS:
                local_vars.add(tok.value)
                i += 1
                continue
            if next_tok and next_tok.value == ",":
                # Check for multi-assignment `a, map = ...`
                k = i + 1
                is_multi_assign = False
                while k < len(tokens) and tokens[k].kind != "NEWLINE":
                    if tokens[k].value == "=":
                        is_multi_assign = True
                        break
                    if tokens[k].value in ("(", "[", "{", ";"):
                        break
                    k += 1
                if is_multi_assign:
                    local_vars.add(tok.value)
                    i += 1
                    continue

            # Explicit call with parens: `map(...)`, `play(...)` -> always forbidden
            if next_tok and next_tok.value == "(":
                errors.append(f"[FORBIDDEN] line {tok.line}: {tok.value}(...) in {line_preview(tok.line)}")
                i += 1
                continue

            # If it is a known local variable and not followed by an argument token, allow it
            if tok.value in local_vars:
                has_unparen_arg = next_tok is not None and next_tok.value not in NON_ARG_NEXT and next_tok.kind != "NEWLINE"
                if not has_unparen_arg:
                    i += 1
                    continue

            # Otherwise, flag as top-level forbidden API call
            errors.append(f"[FORBIDDEN] line {tok.line}: {tok.value} in {line_preview(tok.line)}")

        i += 1

    return errors


def scan_data_section(data: str) -> tuple[list[str], list[str]]:
    forbidden_errors: list[str] = []
    sprite_errors: list[str] = []

    if not data:
        return forbidden_errors, sprite_errors

    cur_name: str | None = None
    w = 0
    h = 0
    frame_idx = 0
    row_count = 0

    def finish_frame() -> None:
        if cur_name and row_count != h:
            sprite_errors.append(
                f"[SPRITE ERROR] {cur_name} frame {frame_idx}: rows={row_count} expected={h}"
            )

    for raw in data.splitlines():
        line = raw.strip()
        m = SPRITE_HEADER_RE.match(line)
        if m:
            finish_frame()
            cur_name = m.group(1)
            w = int(m.group(2))
            h = int(m.group(3))
            frame_idx = 0
            row_count = 0
        elif line == "---" and cur_name:
            finish_frame()
            frame_idx += 1
            row_count = 0
        elif line.startswith("@") or line.startswith("#") or line == "":
            if line.startswith("@") and cur_name:
                finish_frame()
                cur_name = None
        elif cur_name:
            row_count += 1
            if len(line) != w:
                sprite_errors.append(
                    f"[SPRITE ERROR] {cur_name} frame {frame_idx} row {row_count} len={len(line)} expected={w}"
                )

    finish_frame()
    return forbidden_errors, sprite_errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify a Usakame game script.")
    parser.add_argument("path", help="Path to the Ruby game file")
    parser.add_argument("--gacha-frames", type=int, default=480, help="Frames for uk check -g (default: 480)")
    parser.add_argument("--uk", default="uk", help="Path to uk executable (default: uk)")
    parser.add_argument("--scan-only", action="store_true", help="Run static scan only (skip uk check)")
    args = parser.parse_args()

    game_path = Path(args.path)
    if not game_path.is_file():
        print(f"Error: File not found: {game_path}", file=sys.stderr)
        return 1

    if not args.scan_only and shutil.which(args.uk) is None and not Path(args.uk).is_file():
        print(f"Error: uk executable not found in PATH or path: {args.uk}", file=sys.stderr)
        return 1

    text = game_path.read_text(encoding="utf-8-sig")
    code, data = split_code_and_data(text)

    code_errors = scan_ruby_code(code)
    data_forbidden, sprite_errors = scan_data_section(data)
    all_forbidden = code_errors + data_forbidden

    for err in all_forbidden:
        print(err)
    for err in sprite_errors:
        print(err)

    print(f"Scan summary: strictForbidden={len(all_forbidden)} spriteErrors={len(sprite_errors)}")
    if all_forbidden or sprite_errors:
        return 1

    if args.scan_only:
        return 0

    res_60 = subprocess.run([args.uk, "check", str(game_path)], check=False)
    if res_60.returncode != 0:
        return res_60.returncode

    res_gacha = subprocess.run(
        [args.uk, "check", str(game_path), "-g", "--frames", str(args.gacha_frames)],
        check=False,
    )
    return res_gacha.returncode


if __name__ == "__main__":
    sys.exit(main())
