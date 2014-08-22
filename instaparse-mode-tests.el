(require 'ert)
(require 'ert-x)

(defmacro* instaparse-deftest (name args &body body)
  (declare (indent 2)
           (&define :name test name sexp
                    [&optional [":documentation" stringp]]
                    [&optional [":expected-result" sexp]]
                    def-body))
  `(ert-deftest ,(intern (format "instaparse-ert-%s" name)) ()
     ""
     ,@args
     (let ((instaparse-smie-verbose-p t))
       ,@body)))

(defmacro* instaparse-ert-with-test-buffer ((&rest args) initial-contents &body body)
  (declare (indent 2))
  `(ert-with-test-buffer (,@args)
     (instaparse-mode)
     (insert ,initial-contents)
     ,@body))

(load "test/instaparse-mode-indentation-tests.el")
(load "test/instaparse-mode-tokenizer-tests.el")

(provide 'instaparse-mode-tests)
;;; instaparse-mode-tests.el ends here
