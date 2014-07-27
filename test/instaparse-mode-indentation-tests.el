;; Macro is taken from elixir-mode

(defmacro* instaparse-def-indentation-test (name args initial-contents expected-output)
  (declare (indent 2))
  `(instaparse-deftest ,name ,args
     (instaparse-ert-with-test-buffer (:name ,(format "(Expected)" name))
         ,initial-contents
       (let ((indented (ert-buffer-string-reindented)))
         (delete-region (point-min) (point-max))
         (insert ,expected-output)
         (ert-with-test-buffer (:name ,(format "(Actual)" name))
           (instaparse-mode)
           (insert indented)
           (should (equal indented ,expected-output)))))))

(instaparse-def-indentation-test
 indents-rule-in-braces ()
 "
foo := (bar
baz)"
 "
foo := (bar
        baz)")

(instaparse-def-indentation-test
 indents-rule-in-brackets ()
 "
foo := {bar
baz}"
 "
foo := {bar
        baz}")

(instaparse-def-indentation-test
 indents-rule-in-angular-brackets ()
 "
foo := <bar
baz>"
 "
foo := <bar
        baz>")
