;;; instaparse-mode.el --- Highlight mode for instaparse grammars in EBNF

;; Copyright (C) 2014 Florian Bauer
;; Based on ebnf-mode by Jeramey Crawford (http://github.com/jeramey/instaparse-mode)
;; Author: Florian Bauer
;; Keywords: faces

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This major mode provides basic syntax highlighting for instaparse
;; grammars that use Extended Backus-Naur Form (EBNF) metasyntax. See
;; <https://github.com/Engelberg/instaparse>

;; For more information on what EBNF is, consult Wikipedia:
;; <http://en.wikipedia.org/wiki/Extended_Backus-Naur_Form>

;;; Code:

(require 'smie)

(defconst instaparse-smie-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    '((id)
      ;; <rules> = <opt-whitespace> rule+

      ;; alt = cat (<opt-whitespace> <"|"> <opt-whitespace> cat)*
      ;; hide = <"<"> <opt-whitespace> alt-or-ord <opt-whitespace> <">">
      ;; nt = !epsilon #"[^, \r\t\n<>(){}\[\]+*?:=|'\"#&!;./]+(?x) #Non-terminal"
      ;; string = #"'[^'\\]*(?:\\.[^'\\]*)*'(?x) #Single-quoted string" | #"\"[^\"\\]*(?:\\.[^\"\\]*)*\"(?x) #Double-quoted string"
      ;; neg = <"!"> <opt-whitespace> factor
      ;; comment = "(*" inside-comment "*)"
      ;; ord = cat (<opt-whitespace> <"/"> <opt-whitespace> cat)+
      ;; paren = <"("> <opt-whitespace> alt-or-ord <opt-whitespace> <")">
      ;; inside-comment = #"(?s)(?:(?!(?:\(\*|\*\))).)*(?x) #Comment text" (comment #"(?s)(?:(?!(?:\(\*|\*\))).)*(?x) #Comment text")*
      ;; regexp = #"#'[^'\\]*(?:\\.[^'\\]*)*'(?x) #Single-quoted regexp" | #"#\"[^\"\\]*(?:\\.[^\"\\]*)*\"(?x) #Double-quoted regexp"
      ;; hide-nt = <"<"> <opt-whitespace> nt <opt-whitespace> <">">
      ;; opt = <"["> <opt-whitespace> alt-or-ord <opt-whitespace> <"]"> | factor <opt-whitespace> <"?">
      ;; cat = (<opt-whitespace> (factor | look | neg) <opt-whitespace>)+
      ;; epsilon = "Epsilon" | "epsilon" | "EPSILON" | "eps" | "ε"
      ;; opt-whitespace = #"[,\s]*(?x) #optional whitespace" (comment #"[,\s]*(?x) #optional whitespace")*
      ;; rule-separator = ":" | ":=" | "::=" | "="
      ;; star = <"{"> <opt-whitespace> alt-or-ord <opt-whitespace> <"}"> | factor <opt-whitespace> <"*">
      ;; look = <"&"> <opt-whitespace> factor
      (look ("&" factor))
      ;; <factor> = nt | string | regexp | opt | star | plus | paren | hide| epsilon
      (factor (nt)
              (string)
              (regexp)
              (opt)
              (star)
              (plus)
              (paren)
              (hide)
              (epsilon))
      ;; rule = (nt | hide-nt) <opt-whitespace> <rule-separator> <opt-whitespace> alt-or-ord (<opt-whitespace | opt-whitespace (";" | ".") opt-whitespace>)
      (rule
        (hide-nt rule-separator alt-or-ord ".")
        (hide-nt rule-separator alt-or-ord ";")
        (hide-nt rule-separator alt-or-ord) 

        (nt rule-separator alt-or-ord ".")
        (nt rule-separator alt-or-ord ";")
        (nt rule-separator alt-or-ord)) 

      ;; <alt-or-ord> = alt | ord
      ;; plus = factor <opt-whitespace> <"+">
       )
    '((assoc "="))
    '((assoc ","))
    '((assoc "+") (assoc "*")))))

(defcustom instaparse-indent-basic 2 "Basic indentation for instaparse-mode.")

(defun instaparse-smie-rules (kind token)
  (print "smie-rules")
  (princ  kind)
  (princ token)
  (pcase (cons kind token)
    (`(:elem . basic) 0)
    (`(:before . "(") 0)))

(defun instaparse-smie-setup ()
  (smie-setup instaparse-smie-grammar
              'instaparse-smie-rules
;              :forward-token 'instaparse-smie-forward-token
;              :backward-token 'instaparse-smie-backward-token
              ))

(add-hook 'instaparse-mode-hook 'instaparse-smie-setup)


;;;###autoload
(define-generic-mode 'instaparse-mode
  ;; comments
  '(("(*" . "*)"))
  ;; use keyword for operators
  '("::=" ":=" "=" ":" ; rule definition
    "|" "?" "+" "*" "!"
    "Epsilon" "epsilon" "EPSILON" "eps" "ε")
  '(
    (
     "^\s*\<?\s*\\([a-zA-Z][a-zA-Z-0-9]+\\)\s*\>?\s*\\(=\\|:\\)" 1 font-lock-variable-name-face)
    ("['\"].*?['\"]" . font-lock-string-face)
    ;;("[()<>\\[\\]]" . font-lock-type-face)
    ;("[a-zA-Z][a-zA-Z-0-9]+" . font-lock-function-name-face)
    )
  '("\\.ebnf\\'")
  `(,(lambda ()
       (setq mode-name "instaparse")
       (set (make-local-variable 'indent-line-function)
            'instaparse-indent-line)))
  "Major mode for instaparses EBNF metasyntax text highlighting.")

(defun instaparse-indent-line ()
  (interactive)
  (indent-line-to 34))
(provide 'instaparse-mode)
;;; instaparse-mode.el ends here
