(instaparse-deftest tokenizer-test ()
  (instaparse-ert-with-test-buffer (:name "tokenizer-test")
      "foo-bar := baz
bar-bar := baz"
      (progn
        (goto-char (point-min))
        (let ((tok (instaparse-smie-forward-token)))
          (should (string= tok  "foo-bar"))))))

