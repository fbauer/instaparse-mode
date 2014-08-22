(instaparse-deftest forward-tokenizer-test ()
  (instaparse-ert-with-test-buffer (:name "forward-tokenizer-test")
      "foo-bar := baz
bar-bar := baz"
    (progn
      (goto-char (point-min))
      (dolist (expected-token '("foo-bar" "=" "baz"
                                "bar-bar" "=" "baz"))
        (let ((token (instaparse-smie-forward-token)))
          (should (string= token expected-token))))
      (should (= (point) (point-max))))))


