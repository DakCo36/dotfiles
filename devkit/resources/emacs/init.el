;; 패키지 매니저 설정
(require 'package)
(setq package-archives
      '(("melpa"  . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("gnu"    . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; use-package 설치
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Disable ring-bell
(setq ring-bell-function 'ignore)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil)
 '(package-vc-selected-packages
   '((copilot :vc-backend Git :url
			  "https://github.com/copilot-emacs/copilot.el"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Line number
(setq display-line-numbers-type t)
;; Turn on line number
(global-display-line-numbers-mode 1)

;; Default indentation (4 spaces/tabs)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; Add lisp directory to load path
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "lisp/modules" user-emacs-directory))

;; Treemacs
(require 'my-treemacs)

;; Completion
(require 'my-completion)

;; Vterm
(require 'my-vterm)

;; Appearance
(require 'appearance)

;; Themes
(require 'themes)

;; Dashboard
(require 'init-dashboard)

;; Markdown
(require 'markdown)

;; Languages
(require 'languages)

;; Artificial Intelligence
(require 'agent)

;; Eldoc-box
(use-package eldoc-box
  :ensure t
  ;; Popup eldoc box on cursor functions
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode)

  :config
  ;; Popup box after 1500 ms
  (setq eldoc-idle-delay 1.5)
  
  ;; Show eldoc buffer manually
  (defun popup-eldoc-buffer ()
    (interactive)
    (let* ((buf (eldoc-doc-buffer))
           (doc-window (and buf (get-buffer-window buf))))
      (if doc-window
          (delete-window doc-window)
        (when buf
          (display-buffer buf
                          '(display-buffer-at-bottom
                            (window-height . fit-window-to-buffer)))))))

  :bind
  ("C-c h" . popup-eldoc-buffer))

;; Magit
(use-package magit
  :ensure t

  :bind
  ("C-c g" . magit-status))

;; diff-hl (git change indicators in the gutter)
(use-package diff-hl
  :ensure t

  :init
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode)

  :hook
  (magit-post-refresh . diff-hl-magit-post-refresh))

;; Which-key (show available keybindings)
(use-package which-key
  :ensure t

  :init
  (which-key-mode))

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

;; Auto close warning buffers after 5 seconds
(defun auto-close-warning-buffer ()
  (when-let ((buf (get-buffer "*Warnings*")))
	(when-let ((win (get-buffer-window buf)))
	  (run-with-timer 5 nil (lambda (w)
							  (when (window-live-p w)
								(delete-window w)))
					  win))))
(add-hook 'after-init-hook
		  (lambda ()
		  (advice-add 'display-warning :after
					  (lambda (&rest _) (auto-close-warning-buffer)))))
