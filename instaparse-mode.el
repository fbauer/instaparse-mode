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

;; This major mode provides syntax highlighting and indentation
;; support for instaparse grammars that use Extended Backus-Naur Form
;; (EBNF) metasyntax. See <https://github.com/Engelberg/instaparse>

;; For more information on what EBNF is, consult Wikipedia:
;; <http://en.wikipedia.org/wiki/Extended_Backus-Naur_Form>

;;; Code:

(require 'smie)

(defconst instaparse-bnf-grammar
  (smie-bnf->prec2
   '(
     ;; The original instaparse ebnf is mentioned here for reference
     ;;
     ;; The top level production
     ;; <rules> = <opt-whitespace> rule+
     ;; has no corresponding smie production.
     ;;
     ;; The top level productin in smie bnf is a single rule
     ;; rule = (nt | hide-nt) <opt-whitespace> <rule-separator>
     ;;         <opt-whitespace> alt-or-ord
     ;;         (<opt-whitespace | opt-whitespace
     ;;          (";" | ".") opt-whitespace>)
     ;; smie does ignore whitespace, the difference between nt and
     ;; hide-nt is not relevant for indentatin purposes, and we
     ;; replace the rule-separator production
     ;; rule-separator = ":" | ":=" | "::=" | "=" 
     ;; with the "=" token, that is returned by the tokenizer as the only
     ;; rule-separator token.
     (rule
      (nt "=" alt-or-ord ".")
      (nt "=" alt-or-ord ";")
      (nt "=" alt-or-ord))

     ;; We ruthlessly simplify the nt production from
     ;; nt = !epsilon
     ;;      #"[^, \r\t\n<>(){}\[\]+*?:=|'\"#&!;./]+(?x) #Non-terminal"
     ;; to
     (nt)

     ;; <alt-or-ord> = alt | ord
     (alt-or-ord (alt) (ord))
                     
     ;; alt = cat (<opt-whitespace> <"|"> <opt-whitespace> cat)*
     (alt (cat)
          (cat "|" alt))

     ;; ord = cat (<opt-whitespace> <"/"> <opt-whitespace> cat)+
     (ord (ord "/" cat)
          (cat "/" cat))

     ;; cat = (<opt-whitespace> (factor | look | neg) <opt-whitespace>)+
     ;; we inline the look and neg productions and treat them as
     ;; binary operators.
     ;; neg = <"!"> <opt-whitespace> factor
     ;; look = <"&"> <opt-whitespace> factor
     (cat (cat "&" factor)
          (cat "!" factor))
     ;; The factor rule can be simplified as well
     ;; <factor> = nt | string | regexp | opt | star | plus | paren | hide| epsilon
     ;; Treat string regexp  hide and epsilon as nt.
     ;; Ignore the parenthetical forms of opt and star and paren as
     ;; they are treated as sexprs by the syntax table.
     ;; Inline opt star and plus and treat them as binary operators.
     (factor (nt)
             (factor "?" factor)
             (factor "*" factor)
             (factor "+" factor)))
   '((assoc "*") (assoc "+"))
   '((assoc "?") (assoc "*") (assoc "+"))
   '((assoc "+"))
   '((assoc "/"))
   '((assoc "|"))))


(defconst instaparse-smie-grammar
  (smie-prec2->grammar
   instaparse-bnf-grammar))

(defcustom instaparse-indent-basic 2 "basic indentation")

(defun instaparse-smie-rules (kind token)
  (pcase (cons kind token)
    (`(:elem . basic) 0)
    (`(:after . "=") instaparse-indent-basic)))

(defvar instaparse-keywords-regexp (regexp-opt '("+" "*" "?"
                                                 "&" "!"
                                                 "|" "/"
                                                 "." ";")))

(defvar instaparse-ruledef-regexp (regexp-opt '(":" "::=" ":=" "=")))

(defun instaparse-smie-forward-token ()
  (forward-comment (point-max))
  (cond
   ((looking-at instaparse-keywords-regexp)
    (goto-char (match-end 0))
    (match-string-no-properties 0))
   ((looking-at instaparse-ruledef-regexp)
    (goto-char (match-end 0))
    "=")
   (t (buffer-substring-no-properties
       (point)
       (progn (skip-syntax-forward "w_")
              (point))))))

(defun instaparse-smie-backward-token ()
  (forward-comment (- (point)))
  (cond
   ((looking-back instaparse-keywords-regexp (- (point) 1) t)
    (goto-char (match-beginning 0))
    (match-string-no-properties 0))
   ((looking-back instaparse-ruledef-regexp (- (point) 3) t)
    (goto-char (match-beginning 0))
    "=")
   (t (buffer-substring-no-properties
       (point)
       (progn (skip-syntax-backward "w_")
              (point))))))

(defun instaparse-smie-setup ()
  (smie-setup instaparse-smie-grammar
              'instaparse-smie-rules
              :forward-token 'instaparse-smie-forward-token
              :backward-token 'instaparse-smie-backward-token
              ))

(add-hook 'instaparse-mode-hook 'instaparse-smie-setup)

;;;###autoload
(define-generic-mode 'instaparse-mode
  ;; comments
  '(("(*" . "*)"))
  ;; use keyword for epsilon
  '("Epsilon" "epsilon" "EPSILON" "eps" "ε")
  '(("^\s*\<?\s*\\([a-zA-Z][a-zA-Z-0-9]+\\)\s*\>?\s*\\(=\\|:\\)" 1 font-lock-variable-name-face)
    ("::=\\|:=\\|[/!*+=?|:]" . font-lock-keyword-face))
  '("\\.ebnf\\'")
  `(,(lambda ()
       (setq mode-name "instaparse")
       (set (make-local-variable 'indent-line-function)
            'instaparse-indent-line)
       (modify-syntax-entry ?< "(")
       (modify-syntax-entry ?> ")")
       (modify-syntax-entry ?= ".")
       (modify-syntax-entry ?? ".")
       (modify-syntax-entry ?& ".")
       (modify-syntax-entry ?! ".")
       (modify-syntax-entry ?* ". 23")
       (modify-syntax-entry ?+ ".")
       (modify-syntax-entry ?' "\"")))
  "Major mode for instaparses EBNF metasyntax text highlighting.")

(provide 'instaparse-mode)
;;; instaparse-mode.el ends here
