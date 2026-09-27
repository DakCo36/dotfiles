;;; init-agent.el  -*- lexical-binding: t; -*-

(use-package agent-shell
    :ensure t

    :ensure-system-package
    (
        ;; Claude
        (claude . "brew install claude-code")
        (claude-agent-acp . "npm install -g @zed-industries/claude-agent-acp")

        ;; Codex
        (codex . "npm install -g @openai/codex")
        (codex-acp . "npm install -g @zed-industries/codex-acp")
    ))

;; Copilot
(unless (package-installed-p 'copilot)
  (package-vc-install "https://github.com/copilot-emacs/copilot.el"))

(use-package copilot
  :hook (prog-mode . copilot-mode)
  :custom (copilot-idle-delay 2.0)
  :bind (:map copilot-mode-map
              ("C-c c" . copilot-complete)
         :map copilot-completion-map
              ("M-RET" . copilot-accept-completion)
              ("M-]" . copilot-next-completion)
              ("M-[" . copilot-previous-completion)))

(with-eval-after-load 'copilot
  (setf (alist-get 'emacs-lisp-mode copilot-indentation-alist)
        '(lisp-indent-offset 2)))

(provide 'init-agent)
