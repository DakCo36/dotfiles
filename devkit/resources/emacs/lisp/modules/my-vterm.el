(use-package vterm
  :ensure t
  :hook (vterm-mode . (lambda ()
                        (display-line-numbers-mode -1)
                        (corfu-mode -1)))
  :custom
  (vterm-timer-delay 0.01))

(provide 'my-vterm)
