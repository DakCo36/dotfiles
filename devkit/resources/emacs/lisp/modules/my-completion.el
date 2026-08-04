;; Shared matching policy
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic)))

;; Minibuffer completion
(use-package vertico
  :ensure t
  :init
  (vertico-mode))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

;; Search and actions
(use-package consult
  :ensure t
  :bind
  (("C-s" . consult-line)
   ("C-c f" . consult-find)
   ("C-c r" . consult-ripgrep)
   ("C-x b" . consult-buffer)
   ("C-c i" . consult-imenu)))

(use-package embark
  :ensure t
  :bind
  ("C-c e" . embark-act))

(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; In-buffer completion
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.3)
  (corfu-quit-at-boundary t)
  (corfu-quit-no-match t)
  :init
  (global-corfu-mode)
  (corfu-popupinfo-mode t))

(use-package corfu-terminal
  :ensure t
  :init
  (unless (display-graphic-p)
    (corfu-terminal-mode +1)))

(use-package cape
  :ensure t
  :init
  (add-hook 'text-mode-hook
            (lambda ()
              (add-to-list 'completion-at-point-functions 'cape-dabbrev)
              (add-to-list 'completion-at-point-functions 'cape-file))))

(provide 'my-completion)
